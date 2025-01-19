# Kanzi testing scripts


Initially this repository just contains a single bash script.  More may be added later.

The main focus of the script is to test [kanzi](https://github.com/flanglet/kanzi-cpp) compression
of a given file with a lot of different combinations of transforms and entropy coders.

For comparison the script also tests compression with various other compression programs like
[xz](https://tukaani.org/xz/) and [zpaq](http://mattmahoney.net/dc/zpaq.html).

The script takes a single filename as argument and produces a long list of "size algorithm" pairs
where the size is the size of the input file when processed by the listed compression algorithm
(or `cat` = no compression).  The output should be redirected to a log file and sorted numerically
by size after the script has finished.

## Prerequisites

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

## Example 1 -- a default full run on enwik7

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

## Example 2 -- interrupted run with explicit NJOBS on a 191 MiB highly repetitive journalctl log file

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
