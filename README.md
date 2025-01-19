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

## Example run

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
