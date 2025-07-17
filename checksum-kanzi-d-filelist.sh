#! /bin/bash
# Author: Ulrik Dickow <u.dickow@gmail.com> 20250524
# Purpose: Output list of (sha256sum,filename) pairs for given list of files but with
#   the sha256sum being calculated on the file piped through 'kanzi -d' (decompressed).
[ $# == 1 ] && [ -e "$1" ] || { echo "Usage: $0 FILE"; exit 1; }
for f in $(< "$1"); do
    if [ -f "$f" ] && [ -r "$f" ]; then
	csum=$(kanzi -d -i "$f" -o stdout | sha256sum)
	echo "${csum%% *-} $f"
    else
	echo "$0: '$f' skipped because not a file or not readable" 1>&2
    fi
done
