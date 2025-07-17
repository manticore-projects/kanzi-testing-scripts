# Kanzi testing scripts


This repository currently contains these bash scripts for testing and verifying [kanzi](https://github.com/flanglet/kanzi-cpp):

* [checksum-kanzi-d-filelist.sh](#checksum-kanzi-d-filelist.sh)
* [recompress-old-kanzi-files.sh](#recompress-old-kanzi-files.sh)
* [size-kanzi-algos-etc.sh](#size-kanzi-algos-etc.sh)

## checksum-kanzi-d-filelist.sh

A quite short and simple script for generating a list of sha256sums of decompressions of kanzi-compressed files.
Includes almost no error checking, so completely failed kanzi decompressions will return the checksum of a zero-length file
like in this example where `kanzi` is a new version (July 2025) unable to decompress some earlier test files
(compressed with a December 2024 kanzi.old, bitstream version 6 format being in development and
[changing incompatibly](https://github.com/flanglet/kanzi-cpp/commit/140790b26a6acbd413b145d248f9967ff4cc00ad)
in that period):
```
$ ls -1 test.txt.knz-*tNONE* | ../checksum-kanzi-d-filelist.sh /dev/stdin; sha256sum /dev/null
91a0b88ca03915f704ce7155b119a1b5b24621419f23e9ed5e4320be026e01c3 test.txt.knz-new-tNONE_eTPAQ-no-size
91a0b88ca03915f704ce7155b119a1b5b24621419f23e9ed5e4320be026e01c3 test.txt.knz-new-tNONE_eTPAQ-with-size
Invalid bitstream, header checksum mismatch. Error code: 19
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855 test.txt.knz-old-tNONE_eTPAQ-no-size
Invalid bitstream, header checksum mismatch. Error code: 19
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855 test.txt.knz-old-tNONE_eTPAQ-with-size
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  /dev/null

$ ls -1 test.txt.knz-*tNONE*|KANZI=kanzi.old ../checksum-kanzi-d-filelist.sh /dev/stdin
Invalid bitstream, header checksum mismatch. Error code: 19
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855 test.txt.knz-new-tNONE_eTPAQ-no-size
Invalid bitstream, header checksum mismatch. Error code: 19
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855 test.txt.knz-new-tNONE_eTPAQ-with-size
91a0b88ca03915f704ce7155b119a1b5b24621419f23e9ed5e4320be026e01c3 test.txt.knz-old-tNONE_eTPAQ-no-size
91a0b88ca03915f704ce7155b119a1b5b24621419f23e9ed5e4320be026e01c3 test.txt.knz-old-tNONE_eTPAQ-with-size
```
Originally created for verifying a previously saved list of filenames and comparing a new list of checksums with an older one.
That's why it doesn't read the names of the compressed files as individual arguments.

## recompress-old-kanzi-files.sh

Recompresses kanzi-compressed files with the same blocksize, transforms and entropy codec as
they were previously compressed with, but possibly using another kanzi version for the initial
decompression than for the recompression.  The script also does this:

* verifies, possibly with a third kanzi version, that the recompressed file can be correctly decompressed
* adds 64-bit checksum at end of each block (option -x64 to kanzi) no matter if in original or not
* adds decompressed file size in file header (since compression done of real file, not from pipe)

See comments in script for more detail.  Example run:
```
$ ll
totalt 12
lrwxrwxrwx. 1 ukd ukd 35 17 jul 15:54 symlink-to-ignore.knz -> test.txt.knz-old-tLZX_eNONE-no-size
-rw-r-----. 1 ukd ukd 53 15 jul 11:09 test.txt.knz-new-tNONE_eTPAQ-no-size
-rwxr-xr-x. 1 ukd ukd 52 15 jul 11:30 test.txt.knz-old-tLZX_eNONE-no-size

### Will fail on new file but work for old:

$ OLDKANZI=kanzi.old ../recompress-old-kanzi-files.sh *.knz*
../recompress-old-kanzi-files.sh: 'symlink-to-ignore.knz' skipped because not a regular file or not readable
Invalid bitstream, header checksum mismatch. Error code: 19
../recompress-old-kanzi-files.sh: Error decompressing 'test.txt.knz-new-tNONE_eTPAQ-no-size', skipping it (consider changing OLDKANZI)
test.txt.knz-old-tLZX_eNONE-no-size : OK

$ ll
totalt 12
lrwxrwxrwx. 1 ukd ukd 35 17 jul 15:54 symlink-to-ignore.knz -> test.txt.knz-old-tLZX_eNONE-no-size
-rw-r-----. 1 ukd ukd 53 15 jul 11:09 test.txt.knz-new-tNONE_eTPAQ-no-size
-rwxr-xr-x. 1 ukd ukd 62 15 jul 11:30 test.txt.knz-old-tLZX_eNONE-no-size

### Test recompressing with new kanzi (will add size in header to new file, now no errors)

$ ../recompress-old-kanzi-files.sh *.knz*
../recompress-old-kanzi-files.sh: 'symlink-to-ignore.knz' skipped because not a regular file or not readable
test.txt.knz-new-tNONE_eTPAQ-no-size : OK
test.txt.knz-old-tLZX_eNONE-no-size : OK

$ ll
totalt 12
lrwxrwxrwx. 1 ukd ukd 35 17 jul 15:54 symlink-to-ignore.knz -> test.txt.knz-old-tLZX_eNONE-no-size
-rw-r-----. 1 ukd ukd 63 15 jul 11:09 test.txt.knz-new-tNONE_eTPAQ-no-size
-rwxr-xr-x. 1 ukd ukd 62 15 jul 11:30 test.txt.knz-old-tLZX_eNONE-no-size

### mtimes, permissions, blocksizes and transforms/codecs preserved; checksum and size in all headers

$ for f in test*;do echo "=== $f ==="; kanzi -d -v 3 -o none -i $f|grep -E 'Block|stage|Original';done
=== test.txt.knz-new-tNONE_eTPAQ-no-size ===
Block checksum: 64 bits
Block size: 4194304 bytes
Using TPAQ entropy codec (stage 1)
Using no transform (stage 2)
Original size: 27 bytes
=== test.txt.knz-old-tLZX_eNONE-no-size ===
Block checksum: 64 bits
Block size: 4194304 bytes
Using no entropy codec (stage 1)
Using LZX transform (stage 2)
Original size: 27 bytes
```

## size-kanzi-algos-etc.sh

The main focus of the script is to test [kanzi](https://github.com/flanglet/kanzi-cpp) compression
of a given file with a lot of different combinations of transforms and entropy coders.

For comparison the script also tests compression with various other compression programs like
[xz](https://tukaani.org/xz/) and [zpaq](http://mattmahoney.net/dc/zpaq.html).

The script takes a single filename as argument and produces a long list of "size algorithm" pairs
where the size is the size of the input file when processed by the listed compression algorithm
(or `cat` = no compression).  The output should be redirected to a log file and sorted numerically
by size after the script has finished.

### Prerequisites

* [GNU Parallel](https://www.gnu.org/software/parallel/)
* [kanzi](https://github.com/flanglet/kanzi-cpp) (Go or Java version may work too if you name it "kanzi")
* [7za](http://p7zip.sourceforge.net/)
* Preferably many other compression programs too unless you live with errors from not having them:
	- [xz](https://tukaani.org/xz/)
	- [zpaq](http://mattmahoney.net/dc/zpaq.html)
	- [bzip3](https://github.com/kspalaiologos/bzip3)
	- [lrzip](https://github.com/ckolivas/lrzip)
	- [zstd](https://github.com/facebook/zstd)
	- [lz4](https://lz4.github.io/lz4/)
	- [bzip2](http://www.bzip.org/)
	- [gzip](https://www.gzip.org/)
	- [arj](http://arj.sourceforge.net/)

### Example 1 -- a default full run on enwik7

Here the script is first run on the exactly 10000000 bytes large
[enwik7](http://www.mattmahoney.net/dc/text.html) text file,
then the first 9-10 lines of output shown, finally start and end of numerically sorted output shown:
```
$ (date; size-kanzi-algos-etc.sh enwik7; date) > sizes-enwik7.log

$ head sizes-enwik7.log
søn  5 jan 11:36:48 CET 2025
 10000000 cat
  3685296 gzip -9
  4232930 lz4 -12
  2795014 zstd -19
  2793456 zstd --ultra -22
  2916026 bzip2
  2723036 xz
  2722096 xz -e
  2720256 xz -9e

$ sort -nr sizes-enwik7.log | (head -3;echo ...;tail)
 10002422 kanzi -x64 -b 64m -t BWT+BWTS+MM -e NONE
 10002418 kanzi -x64 -b 64m -t BWTS+BWT+MM -e NONE
 10002105 kanzi -x64 -b 64m -t BWT+MM+SRT -e NONE
...
  2102696 kanzi -x64 -b 64m -t MM+RLT+TEXT -e TPAQX
  2102696 kanzi -x64 -b 64m -t EXE+RLT+TEXT -e TPAQX
  2102689 kanzi -x64 -b 128m -l 9 -j 2
  2102513 kanzi -x64 -b 256m -l 9 -j 1
  2102512 kanzi -x64 -b 256m -t RLT+TEXT+PACK -e TPAQX -j 1
  2091358 zpaq a ... -m58 -t8
  2091358 zpaq a ... -m57 -t8
  2091358 zpaq a ... -m56 -t8
søn  5 jan 13:47:29 CET 2025
søn  5 jan 11:36:48 CET 2025
```

### Example 2 -- interrupted run with explicit NJOBS on a 191 MiB highly repetitive journalctl log file

In practice I didn't set NJOBS explicitly but I *could* have done so like this:
```
$ (date; NJOBS=8 size-kanzi-algos-etc.sh j-191M.txt; date) > sizes-j-191M.log
^C
^C$ cat sizes-j-191M.log | (head;echo ...;tail -5)
fre  3 jan 20:05:07 CET 2025
200114536 cat
 18213896 gzip -9
 23149150 lz4 -12
   937153 zstd -19
   909778 zstd --ultra -22
  3160640 bzip2
   960032 xz
   847904 xz -e
   828052 xz -9e
...
   949817 kanzi -x64 -b 64m -t RLT+BWTS+SRT -e CM
 15716301 kanzi -x64 -b 64m -t RLT+BWTS+EXE -e HUFFMAN
 14170436 kanzi -x64 -b 64m -t RLT+BWTS+EXE -e ANS0
   834872 kanzi -x64 -b 64m -t RLT+BWTS+SRT -e TPAQ
fre  3 jan 22:09:32 CET 202

$ sort -nr sizes-j-191M.log | grep -E 'zpaq|l 9'
  1787319 kanzi -x64 -b 256m -l 9 -j 1
   901245 zpaq a ... -m46
   791981 zpaq a ... -m53
   770750 kanzi -x64 -b 128m -l 9 -j 2
   627947 zpaq a ... -m56 -t8
   616508 kanzi -x64 -l 9 -j 1
   613962 zpaq a ... -m57 -t8
   605669 zpaq a ... -m58 -t8
   572075 kanzi -x64 -b 64m -l 9 -j 1
   555140 kanzi -x64 -b  96m -l 9 -j 4

$ sort -nr sizes-j-191M.log | tail
   502840 kanzi -x64 -b 256m -t TEXT+RLT+PACK -e TPAQX -j 1
   499447 kanzi -x64 -b 256m -t TEXT+RLT+LZP -e TPAQX -j 1
   496471 kanzi -x64 -b 256m -t TEXT+RLT+LZP+RLT -e TPAQX -j 1
   495052 kanzi -x64 -b 256m -t TEXT+RLT+PACK+RLT+LZP -e TPAQX -j 1
   495051 kanzi -x64 -b 256m -t TEXT+RLT+PACK+LZP -e TPAQX -j 1
   494040 kanzi -x64 -b 256m -t TEXT+RLT+PACK+LZP+RLT -e TPAQX -j 1
   490659 kanzi -x64 -b 256m -t TEXT+RLT+LZP+PACK -e TPAQX -j 1
   489820 kanzi -x64 -b 256m -t TEXT+RLT+LZP+PACK+RLT -e TPAQX -j 1
fre  3 jan 22:09:32 CET 2025
fre  3 jan 20:05:07 CET 2025

$ calc '1787319/616508;616508/605669;605669/555140;555140/489820'
	~2.89910106600400968033 ### kanzi level 9 w/ 256m blocks ~3 times larger than default 32m blocks!!!
	~1.01789591344447214568 ### kanzi level 9 w/  32m blocks ~1.8% larger than zpaq w/ 256m blocks
	~1.09102028317181251576 ### zpaq          w/ 256m blocks ~9% larger than kanzi -l 9 w/ 96m blocks
	~1.13335511004042301254 ### kanzi level 9 w/  96m blocks ~13% larger than best kanzi w/ 256m blocks
```
This example shows that in some cases kanzi is very sensitive to block size -- bigger is not always better --
but that with careful tuning it may beat even (untuned) zpaq considerably on size even though being
approximately a factor 10 faster than zpaq with these options.

### More test results

More test results and more detailed descriptions of the test files can be found in the [wiki](https://github.com/udickow/kanzi-testing-scripts/wiki).
