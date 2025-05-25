#! /bin/bash
# Author: Ulrik Dickow <udickow@gmail.com>, 2024-11-03.
# Purpose: print lines with compressed size and algorithm for given input file,
#   mostly trying lots of different transform-entropy kombis for kanzi in parallel after initial non-parallel
#   testing of a few other compressors and the level 1-9 kanzi presets.
#   This script is _not_ for speed testing.  The parallelly looped kanzis are single-threaded.
# Changes:
#   ukd v.. ..........: See https://github.com/udickow/kanzi-testing-scripts for later versions
#   ukd v05 2025-01-03: Add more 256m kanzi tests useful for syslogs; reorder transforms in multi-level loops
#   ukd v04 2025-01-02: Add more block sizes, more multi-threading before GNU parallel loops, more flexibility,
#                       MM instead of DNA in 2+-level loops, ...
#   ukd v03 2024-11-30: Add kanzi -l X with blocksize 64M too; add -x64 to all kanzi; add zpaq -m46; add xz 9e;
#                       add EXE transform to the parallel kanzi tests too
#   ukd v02 2024-11-03: Add zpaq with 64M buffer and change parallel kanzi blocksize to 64M since it can increase
#                       compression ratio by as much as 2.6% going from 8m to 16m even for only 3.6m input

if [ $# -ne 1 -o ! -r "$1" ]; then
    echo "Usage: $0 FILE"
    exit 1
fi

# Number of parallel kanzis in 2+-level loops; allow override via environment, default half number of processors.
# Also used in a few initial multi-threaded compressions.
NJOBS=${NJOBS:-$(($(nproc) / 2))}

# export to be used by GNU parallel later
export ifile="$1"

# Other than kanzi first:

printf '%9d cat\n'   $(cat "$ifile"|wc -c)
printf '%9d gzip -9\n' $(gzip -9c "$ifile"|wc -c)
printf '%9d lz4 -12\n' $(lz4 -12c "$ifile"|wc -c)
printf '%9d zstd -19\n' $(zstd -19c "$ifile"|wc -c)
printf '%9d zstd --ultra -22\n' $(zstd --ultra -22c "$ifile"|wc -c)
printf '%9d bzip2\n' $(bzip2 -c "$ifile"|wc -c)
printf '%9d xz\n'    $(xz -c "$ifile"|wc -c)
printf '%9d xz -e\n' $(xz -ec "$ifile"|wc -c)
printf '%9d xz -9e\n' $(xz -9ec "$ifile"|wc -c)
printf '%9d xz --lzma2=preset=9e,dict=256MiB\n' $(xz -c --lzma2=preset=9e,dict=256MiB "$ifile"|wc -c)
printf '%9d xz --lzma2=preset=6,lc=4,pb=0\n' $(xz -c --lzma2=preset=6,lc=4,pb=0 "$ifile"|wc -c)
printf '%9d xz --lzma2=preset=6e,lc=4,pb=0\n' $(xz -c --lzma2=preset=6e,lc=4,pb=0 "$ifile"|wc -c)
printf '%9d xz --lzma2=preset=9e,lc=4,pb=0\n' $(xz -c --lzma2=preset=9e,lc=4,pb=0 "$ifile"|wc -c)
printf '%9d xz --lzma2=preset=9e,lc=4,pb=0,dict=256MiB\n' $(xz -c --lzma2=preset=9e,lc=4,pb=0,dict=256MiB "$ifile"|wc -c)
printf '%9d xz --delta=dist=4 --lzma2=preset=7e,lc=4\n'   $(xz -c --delta=dist=4 --lzma2=preset=7e,lc=4 "$ifile"|wc -c)
printf '%9d bzip3\n' $(bzip3 -c -j$NJOBS "$ifile"|wc -c)
printf '%9d bzip3 -b32\n' $(bzip3 -c -j$NJOBS -b32 "$ifile"|wc -c)
printf '%9d bzip3 -b64\n' $(bzip3 -c -j$NJOBS -b64 "$ifile"|wc -c)
printf '%9d bzip3 -b128\n' $(bzip3 -c -b128 "$ifile"|wc -c)
printf '%9d bzip3 -b256\n' $(bzip3 -c -b256 "$ifile"|wc -c)

printf '%9d lrzip -p1 \n'  $(lrzip -p1 -qo- "$ifile"|wc -c)
printf '%9d lrzip -zp1 \n' $(lrzip -zp1 -qo- "$ifile"|wc -c)
printf '%9d zpaq a ... -m46\n' \
       $(t=`mktemp` && zpaq a $t "$ifile" -m46 >& /dev/null && wc -c < $t && rm $t)
printf '%9d zpaq a ... -m53\n' \
       $(t=`mktemp` && zpaq a $t "$ifile" -m53 >& /dev/null && wc -c < $t && rm $t)
printf "%9d zpaq a ... -m56 -t$NJOBS\n" \
       $(t=`mktemp` && zpaq a $t "$ifile" -m56 -t$NJOBS >& /dev/null && wc -c < $t && rm $t)
printf "%9d zpaq a ... -m57 -t$NJOBS\n" \
       $(t=`mktemp` && zpaq a $t "$ifile" -m57 -t$NJOBS >& /dev/null && wc -c < $t && rm $t)
printf "%9d zpaq a ... -m58 -t$NJOBS\n" \
       $(t=`mktemp` && zpaq a $t "$ifile" -m58 -t$NJOBS >& /dev/null && wc -c < $t && rm $t)
printf '%9d arj\n' \
       $(t=`mktemp -u` && arj a $t "$ifile" > /dev/null && wc -c < $t && rm $t)
printf '%9d 7za a -m0=ppmd\n' \
       $(t=`mktemp -u` && 7za a -m0=ppmd $t "$ifile" > /dev/null && wc -c < $t && rm $t)

# 7za ppmd order 2 to 32 (entire valid range)(and force buffer size 64 MiB)
for o in {2..32}; do
    printf "%9d 7za a -m0=ppmd:mem=26:o=$o\n" \
	   $(t=`mktemp -u` && 7za a -m0=ppmd:mem=26:o=$o $t "$ifile" > /dev/null && wc -c < $t && rm $t)
done

# 7za ppmd order 14 with 256 MiB memory
printf "%9d 7za a -m0=ppmd:mem=28:o=14\n" \
       $(t=`mktemp -u` && 7za a -m0=ppmd:mem=28:o=14 $t "$ifile" > /dev/null && wc -c < $t && rm $t)
# 7za ppmd order 32 with 256 MiB memory
printf "%9d 7za a -m0=ppmd:mem=28:o=32\n" \
       $(t=`mktemp -u` && 7za a -m0=ppmd:mem=28:o=32 $t "$ifile" > /dev/null && wc -c < $t && rm $t)
# 7za ppmd order 32 with 2048 MiB memory
printf "%9d 7za a -m0=ppmd:mem=31:o=32\n" \
       $(t=`mktemp -u` && 7za a -m0=ppmd:mem=31:o=32 $t "$ifile" > /dev/null && wc -c < $t && rm $t)

# kanzi level 1 to 9 with the default blocksize for each level (higher levels default to larger sizes)
for level in {1..9}; do
    printf "%9d kanzi -x64 -l $level -j 1\n" $(kanzi -c -x64 -l $level -j 1 -i "$ifile" -o stdout|wc -c)
done

# kanzi level 1 to 9 with 64m blocksize for all levels
for level in {1..9}; do
    printf "%9d kanzi -x64 -b 64m -l $level -j 1\n" $(kanzi -c -x64 -b 64m -l $level -j 1 -i "$ifile" -o stdout|wc -c)
done

# kanzi larger blocks for level 9 and for some of the more interesting combinations of transforms
# (PACK ones good for large systemd journalctl(1) outputs, especially with many identical systemd-coredumps;
#  BWT/BWTS ones good for e.g. Fedora Linux /var/log/boot.log files with thousands of similar boots)
printf "%9d kanzi -x64 -b  96m -l 9 -j 3\n" $(kanzi -c -x64 -b  96m -l 9 -j 3 -i "$ifile" -o stdout|wc -c)
printf "%9d kanzi -x64 -b 128m -l 9 -j 2\n" $(kanzi -c -x64 -b 128m -l 9 -j 2 -i "$ifile" -o stdout|wc -c)
printf "%9d kanzi -x64 -b 256m -l 9 -j 1\n" $(kanzi -c -x64 -b 256m -l 9 -j 1 -i "$ifile" -o stdout|wc -c)
for trans in \
    RLT                   PACK                  \
    PACK+ZRLT+PACK        PACK+RLT              \
    RLT+PACK              RLT+TEXT+PACK         \
    RLT+PACK+LZP          RLT+PACK+LZP+RLT      \
    TEXT+ZRLT+PACK        RLT+LZP+PACK+RLT      \
    TEXT+ZRLT+PACK+LZP    TEXT+RLT+PACK         \
    TEXT+RLT+LZP          TEXT+RLT+PACK+LZP     \
    TEXT+RLT+LZP+RLT      TEXT+RLT+PACK+LZP+RLT \
    TEXT+RLT+LZP+PACK     TEXT+RLT+PACK+RLT+LZP \
    TEXT+RLT+LZP+PACK+RLT TEXT+PACK+RLT         \
    TEXT+BWTS+SRT+ZRLT    BWTS+SRT+ZRLT         \
    TEXT+BWTS+MTFT+RLT    BWTS+MTFT+RLT         \
    TEXT+BWT+MTFT+RLT     BWT+MTFT+RLT
do
    printf "%9d kanzi -x64 -b 256m -t $trans -e TPAQX -j 1\n" $(kanzi -c -x64 -b 256m -t $trans -e TPAQX -j 1 -i "$ifile" -o stdout|wc -c)
done

# kanzi with blocksize 64 MiB and 4 transforms but only the 24 combinations with
#   -t TEXT+{BWT,BWTS}+{MTFT,SRT}+{RLT,ZRLT} -e {CM,TPAQ,TPAQX}
# testing NJOBS in parallel.  Useful for some highly repetitive text files.
# The combinations without TEXT are included in the larger 3-transform loop further below.
# Even if TEXT shrinks the output of the transform stage, it doesn't necessarily shrink the final output.  But worth trying.
for t2 in BWT BWTS; do
    for t3 in MTFT SRT; do
	for t4 in RLT ZRLT; do
	    for e in CM TPAQ TPAQX; do
		echo -x64 -b 64m -t TEXT+$t2+$t3+$t4 -e $e
	    done
	done
    done
done | parallel -j$NJOBS 'printf "%9d kanzi {=uq=}\n" $(kanzi -c -j 1 {=uq=} -i "$ifile" -o stdout|wc -c)'

# kanzi with one transform (including NONE) and one entropy coding, testing NJOBS in parallel, forcing blocksize 64 MiB
#   (for 2+ transforms we will drop the last 2 in trans_list and reorder the rest)
trans_list="NONE PACK BWT BWTS LZ LZX LZP ROLZ ROLZX RLT ZRLT MTFT RANK SRT TEXT EXE MM UTF DNA"
entropy_list="NONE HUFFMAN ANS0 ANS1 RANGE CM FPAQ TPAQ TPAQX"
for t1 in $trans_list; do
    for e in $entropy_list; do
	echo -x64 -b 64m -t $t1 -e $e
    done
done | parallel -j$NJOBS 'printf "%9d kanzi {=uq=}\n" $(kanzi -c -j 1 {=uq=} -i "$ifile" -o stdout|wc -c)'

trans_list="TEXT RLT LZP PACK ZRLT BWTS MTFT BWT LZ LZX ROLZ ROLZX RANK SRT EXE MM"

# kanzi with two non-null transforms and one entropy coding, testing NJOBS in parallel, forcing blocksize 64 MiB
for t1 in $trans_list; do
    for t2 in $trans_list; do
	# Two identical transforms in a row isn't useful, skip that
	if [ $t1 != $t2 ]; then
	    for e in $entropy_list; do
		echo -x64 -b 64m -t $t1+$t2 -e $e
	    done
	fi
    done
done | parallel -j$NJOBS 'printf "%9d kanzi {=uq=}\n" $(kanzi -c -j 1 {=uq=} -i "$ifile" -o stdout|wc -c)'

# kanzi with 3 non-null transforms and one entropy coding, testing NJOBS in parallel, forcing blocksize 64 MiB
for t1 in $trans_list; do
    for t2 in $trans_list; do
	# Two identical transforms in a row isn't useful, skip that
	if [ $t1 != $t2 ]; then
	    for t3 in $trans_list; do
		# Two identical transforms in a row isn't useful, skip that
		if [ $t2 != $t3 ]; then
		    for e in $entropy_list; do
			echo -x64 -b 64m -t $t1+$t2+$t3 -e $e
		    done
		fi
	    done
	fi
    done
done | parallel -j$NJOBS 'printf "%9d kanzi {=uq=}\n" $(kanzi -c -j 1 {=uq=} -i "$ifile" -o stdout|wc -c)'
