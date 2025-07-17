#! /bin/bash
# -*- indent-tabs-mode: nil; -*-
# Copyright 2025 Ulrik Dickow <u.dickow@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Purpose:
#   Recompress one or more kanzi-compressed files given on the command line,
#   verifying after the recompression that the resulting file can still be decompressed to
#   output with the same checksum as the originally recompressed output.  If the verification
#   is successful, the original file is forcibly replaced with the recompressed version,
#   preserving file name, modification time and basic read-write access rights of the old file
#   (but not owner, SELinux security context, ACLs or other metadata; not intended to run as root).
#   The location of each input file must have sufficient free space to temporarily contain both
#   the decompressed version of the file and the recompressed version, in addition to the original.
#   The recompressed files are created with these options:
#   * always decompressed file size in the file header (since compression done of real file, not from pipe)
#   * always 64-bit checksum at end of each block (option -x64 to kanzi)
#   * same block size, transforms and entropy codec as used for the original compressed file
#
#   By default program "kanzi" is used for both initial decompression (OLDKANZI),
#   recompression (NEWKANZI) and the decompression in the verification stage (CHKKANZI).
#   All 3 can be changed via environment variables OLDKANZI, NEWKANZI and CHKKANZI.
#   This is especially useful if the input files were created with a snapshot version of kanzi
#   and are not readable by a later version of kanzi (e.g. December 2024 kanzi files are not
#   decompressible by June 2025 kanzi because both claim bistream version 6 even though the bitstream
#   format changed 2025-03-19 by moving the padding section in the header):
#
#      OLDKANZI=kanzi.old recompress-old-kanzi-files.sh *.knz*
#
OLDKANZI="${OLDKANZI:-kanzi}"
NEWKANZI="${NEWKANZI:-kanzi}"
CHKKANZI="${CHKKANZI:-${NEWKANZI}}"
# May be set to e.g. "xxh128sum" instead; must be a program checksumming stdin without being given any args:
HASHPROG="${HASHPROG:-sha256sum}"

usage () { echo "Usage: $0 KNZFILE..."; }
[ "x$1" = "x--help" ] && { usage; exit 0; }
# Be compatible with getopt(1) and getopt(3) where "--" signals end of options:
[ "$1" = "--" ] && shift
# At least one input file is required:
[ $# -ge 1 ] || { usage >&2 ; exit 1; }

for f in "$@"; do
    if [ -h "$f" -o ! -f "$f" -o ! -r "$f" ]; then
        echo "$0: '$f' skipped because not a regular file or not readable" 1>&2
        continue
    fi
    ### Step 1: Get info from block header -- skip file if not readable by kanzi decompression ###

    # Force 2 threads even though reading only a block header.  This is to work around an old bug causing
    # "No more data to read in the bitstream. Error code: 13" for some files; bug still here as of 2.3.0-254-gacf6e3dd.
    # We read the first block header to determine block size, entropy codec and transform to use at recompress.
    # Will fail if e.g. this file has already been recompressed with a newer incompatible kanzi, so in that case just
    # skip the file gracefully and continue with the next one instead.
    infolines=$("$OLDKANZI" -d --from=1 --to=1 -v 4 -j 2 -o none -i "$f") || \
        { echo "$0: Error reading kanzi header of '$f', skipping it (consider changing OLDKANZI)" 1>&2; continue; }
    #echo "DEBUG: infolines = '$infolines'"
    #continue
    # Parse output expected to contain lines like these:
    #    Block size: 4194304 bytes
    #    Using no entropy codec (stage 1)
    #    Using PACK+LZ transform (stage 2)
    bsize=0; entropy="?"; transform="?"
    eval $(perl -lne '/^Block size: (\d+)/ and print "bsize=$1";
                      s/^Using ([+\w]+) (entropy|transform).*/$2=$1/ and s/=no$/=NONE/, print' <<<"$infolines")
    #echo "DEBUG: bsize=$bsize; entropy='$entropy'; transform='$transform'"
    #continue
    [ $bsize -ne 0 ] || { echo "$0: Couldn't determine block size for '$f', skipping this file" 1>&2; continue; }
    [ "$entropy" != "?" ] || { echo "$0: Couldn't determine entropy for '$f', skipping this file" 1>&2; continue; }
    [ "$transform" != "?" ] || { echo "$0: Couldn't determine transform for '$f', skipping this file" 1>&2; continue; }

    ### Step 2: Decompress file to (possibly big) temporary output file in same dir as input; get checksum of it ###
    fdir=`dirname "$f"`
    fbig=`mktemp --tmpdir="$fdir"` || { echo "$0: mktemp in '$fdir' failed, aborting" 1>&2; exit 2; }
    "$OLDKANZI" -d -i "$f" -o stdout >> "$fbig" || \
        { echo "$0: Error decompressing '$f', aborting" 1>&2; echo "  To cleanup: rm '$fbig'"; exit 3; }
    # Note: important to checksum from stdin so that output string doesn't depend on the file name
    csumstr1=$("$HASHPROG" < "$fbig")

    ### Step 3: Compress uncompressed version to new temporary recompressed version using options from step 1 ###
    fnew=`mktemp --tmpdir="$fdir" --suffix=.knz` || { echo "$0: mktemp in '$fdir' failed, aborting" 1>&2; exit 4; }
    "$NEWKANZI" -c -x64 -i "$fbig" -b $bsize -t "$transform" -e "$entropy" -o stdout >> "$fnew" || \
        { echo "$0: Error recompressing '$f', aborting" 1>&2; echo "  To cleanup: rm '$fbig' '$fnew'"; exit 5; }

    ### Step 4: Verify checksum of pipeline decompressing new version ###
    # $? would be the exit status of the hash program, not kanzi; but if kanzi fails, the comparison fails anyway
    csumstr2=$("$CHKKANZI" -d < "$fnew" | "$HASHPROG")
    [ "x$csumstr1" = "x$csumstr2" ] || \
        { echo "$0: Error verifying new '$f', aborting" 1>&2; echo "  To cleanup: rm '$fbig' '$fnew'"; exit 6; }
    # Now we don't need the uncompressed version anymore
    rm "$fbig"

    ### Step 5: Set (some of the) metadata of new file to be the same as the old compressed file ###
    # 5a: Set modification time (and access time but that may already be changed by our reading of the original)
    touch -r "$f" "$fnew" || \
        { echo "$0: Error setting modification time of new '$f', aborting" 1>&2;
          echo "  To cleanup: rm '$fnew'"; exit 7; }
    # 5b: Set access rights
    # However we'll consider failure to set access rights as nonfatal; they're bogus in Git Bash on Windows anyway
    chmod --reference="$f" "$fnew" || \
        { echo "$0: Warning: Can't set access rights of new '$f'; will attempt to replace anyway" 1>&2; }
    # If you're on a SELinux-enabled system you might do this too, plus error checking:
    #chcon --reference="$f" "$fnew"
    # Similarly, if you're root or running on an unusual system with sloppy security, you could set owner:
    #chown --reference="$f" "$fnew"
    # If you're on Linux or a system with similar ACL support you could replace the chmod(1) with this:
    #getfacl "$f" | setfacl --set-file=- "$fnew"

    ### Step 6: Replace old file with new, forcibly since we've been careful with checking the new is ok ###
    mv -f "$fnew" "$f" || \
        { echo "$0: Error replacing '$f' with '$fnew'; leaving the latter so you can try manually" 1>&2; continue; }

    # Output path of successfully recompressed file to stdout; all warnings and errors were to stderr
    echo "$f : OK"
done
