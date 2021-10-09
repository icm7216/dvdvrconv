# dvdvrconv [![Gem Version](https://badge.fury.io/rb/dvdvrconv.svg)](https://badge.fury.io/rb/dvdvrconv)

  
dvdvrconv extracts the `vob` files from the `vro` files on the DVD-VR format disc and converts them to `mp4` files.
dvdvrconv is also a wrapper for [pixelb/dvd-vr](https://github.com/pixelb/dvd-vr/).

For Windows users, I attached `dvd-vr.exe` for cygwin environment.

## dependent libraries

*  [dvd-vr](https://github.com/pixelb/dvd-vr/)
*  [FFmpeg](https://www.ffmpeg.org/)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'dvdvrconv'
```

And then execute:
```ruby
$ bundle install
```
Or install it yourself as:
```ruby
$ gem install dvdvrconv
```


## Usage

View video information from dvd-ram disc in dvd-vr format.

`dvdvrconv -i` or `dvdvrconv`
```
>dvdvrconv
== Use these paths ==
  => VR_MANGR.IFO: ./DVD_RTAV/VR_MANGR.IFO
  => VR_MOVIE.VRO ./DVD_RTAV/VR_MOVIE.VRO
  => dvd-vr.exe: ./win/dvd-vr.exe
----- view dvd-vr info -----
format: DVD-VR V1.1
Encryption: CPRM supported

tv_system   : NTSC
resolution  : 704x480
aspect_ratio: 4:3
video_format: MPEG2
audio_channs: 2
audio_coding: Dolby AC-3

num  : 1
title: TEST1
date : 2019-10-30 22:32:07
size : 3534848
-
num  : 2
title: TEST2
date : 2019-10-30 22:33:05
size : 2965504
-
num  : 3
title: TEST3
date : 2019-10-30 22:33:37
size : 2394112
-
```

Execute the VRO file to mp4 conversion.

`dvdvrconv -e` or `dvdvrconv --exec`

Command options
```
>dvdvrconv -h
Usage: dvdvrconv [options]
    -v, --version                    Show version
    -i, --info                       Show file information
    -c, --config=FILE                Use YAML format FILE.
    -e, --exec                       Execute the VRO file to mp4 conversion.
```

### Configure dvdvrconv

dvdvrconv reads `default_dvdvrconv.yml` in the current working directory as dvdvrconv's configuration file. It can contain the following settings:

*  vr_mangr_ifo
*  vr_movie_vro
*  dvd_vr_cmd
*  use_customize_title
*  base_dst_name
*  number_list

#### vr_mangr_ifo, vr_movie_vro

`vr_mangr_ifo` and `vr_movie_vro` specify the path to the dvd-ram disc.
Drive D is assumed, if different you need to write its path.

windows default
```
vr_mangr_ifo: "/cygdrive/D/DVD_RTAV/VR_MANGR.IFO"
vr_movie_vro: "/cygdrive/D/DVD_RTAV/VR_MOVIE.VRO"
```

WSL(ubuntu) default
```
vr_mangr_ifo: "/mnt/d/DVD_RTAV/VR_MANGR.IFO"
vr_movie_vro: "/mnt/d/DVD_RTAV/VR_MOVIE.VRO"
```

#### dvd_vr_cmd

On Windows, you can use the included dvd-vr command.

On WSL(ubuntu), you can use the dvd-vr command that you have compiled yourself.
*  See the section below, "install dependent libraries for WSL(ubuntu)"

#### use_customize_title, base_dst_name, number_list

customize the title name of vob files.

If specify individual file names. Write "base_dst_name:" as an Array.
```
use_customize_title: 1
base_dst_name: ["name_one", "name_two"]
number_list: []
```
The resulting file name is => ["name_one", "name_two"]


If add a sequence number to the file name. Write "base_dst_name:" as String.
```
use_customize_title: 2
base_dst_name: "output_name_"
number_list: []
```
The resulting file name is => ["output_name_01", "output_name_02", ...]

If specify sequence numbers individually.
Write "base_dst_name:" as String and Write "number_list" as an Array.
```
use_customize_title: 3
base_dst_name: "output_name_"
number_list: [12, 13, 14, 15]
```
The resulting file name is => ["output_name_12", "output_name_13", "output_name_14", "output_name_15"]

 
If do not want to customize the title name, 
Specify `use_customize_title: no`.
```
use_customize_title: no
base_dst_name: []
number_list: []
```


## Install dependent libraries for WSL(ubuntu)

### dvd-vr

*  [pixelb/dvd-vr](https://github.com/pixelb/dvd-vr/)

```
$ git clone https://github.com/pixelb/dvd-vr.git
Cloning into 'dvd-vr'...
remote: Enumerating objects: 140, done.
remote: Total 140 (delta 0), reused 0 (delta 0), pack-reused 140
Receiving objects: 100% (140/140), 260.97 KiB | 40.00 KiB/s, done.
Resolving deltas: 100% (37/37), done.

$ cd dvd-vr/

$ sudo make install
cc -std=gnu99 -Wall -Wextra -Wpadded -DVERSION='"0.9.8b"' -O3 -DNDEBUG -DHAVE_ICONV -DICONV_CONST=""  -c -o dvd-vr.o dvd-vr.c
cc  dvd-vr.o -Wl,-S -o dvd-vr
cp -p dvd-vr /usr/local/bin
gzip -c man/dvd-vr.1 > /usr/local/share/man/man1/dvd-vr.1.gz

$ dvd-vr --help
Usage: dvd-vr [OPTION]... VR_MANGR.IFO [VR_MOVIE.VRO]
Print info about and optionally extract vob data from DVD-VR files.

If the VRO file is specified, the component programs are
extracted to the current directory or to stdout.

  -p, --program=NUM  Only process program NUM rather than all programs.

  -n, --name=NAME    Specify a basename to use for extracted vob files
                     rather than using one based on the timestamp.
                     If you pass `-' the vob files will be written to stdout.
                     If you pass `[label]' the names will be based on
                     a sanitized version of the title or label.

      --help         Display this help and exit.
      --version      Output version information and exit.
```


### FFmpeg

```
sudo apt install ffmpeg
```

## Install dependent libraries for Windows

### dvd-vr

Compile dvd-vr command in Cygwin environment.

Download Cygwin for 64-bit version. => [setup-x86_64.exe](https://cygwin.com/setup-x86_64.exe)


Install Cygwin for 64-bit version. At the Windows command prompt.
```
setup-x86_64.exe ^
   --root c:\cygwin64 ^
   --local-package-dir c:\cygwin64\packages ^
   --site https://ftp.iij.ad.jp/pub/cygwin/ ^
   --quiet-mode ^
   --packages libiconv,libiconv-devel,gcc-core,gcc-g++,git,make
```

Compile dvd-vr. At the Cygwin terminal.
```
$ git clone https://github.com/pixelb/dvd-vr.git
Cloning into 'dvd-vr'...
remote: Enumerating objects: 140, done.
remote: Total 140 (delta 0), reused 0 (delta 0), pack-reused 140
Receiving objects: 100% (140/140), 260.97 KiB | 954.00 KiB/s, done.
Resolving deltas: 100% (37/37), done.

$ cd dvd-vr/

$ make install
cc -std=gnu99 -Wall -Wextra -Wpadded -DVERSION='"0.9.8b"' -O3 -DNDEBUG -DHAVE_ICONV -DICONV_CONST="const"  -c -o dvd-vr.o dvd-vr.c
dvd-vr.c: In function ‘text_convert’:
dvd-vr.c:414:24: warning: passing argument 2 of ‘libiconv’ from incompatible pointer type [-Wincompatible-pointer-types]
  414 |         if (iconv (cd, (ICONV_CONST char**)&src, &srclen, &dst, &dstlen) != (size_t)-1) {
      |                        ^~~~~~~~~~~~~~~~~~~~~~~~
      |                        |
      |                        const char **
In file included from dvd-vr.c:124:
/usr/include/iconv.h:82:43: note: expected ‘char **’ but argument is of type ‘const char **’
   82 | extern size_t iconv (iconv_t cd,  char* * inbuf, size_t *inbytesleft, char* * outbuf, size_t *outbytesleft);
      |                                   ~~~~~~~~^~~~~
cc  dvd-vr.o -liconv -Wl,-S -o dvd-vr.exe
cp man/dvd-vr.man man/dvd-vr.1
cp -p dvd-vr.exe /usr/local/bin
gzip -c man/dvd-vr.1 > /usr/local/share/man/man1/dvd-vr.1.gz
```

After compile success, you will get the following files.
*  dvd-vr.exe     (c:\cygwin64\home\user_name\dvd-vr)
*  cygwin1.dll    (c:\cygwin64\bin)
*  cygiconv-2.dll (c:\cygwin64\bin)


### FFmpeg

*  [FFmpeg](https://www.ffmpeg.org/download.html)
From the Windows EXE Files link above, select the following website.
*  [Releases · BtbN/FFmpeg-Builds](https://github.com/BtbN/FFmpeg-Builds/releases) (daily auto-build).

As an example, download Auto-Build 2021-09-28 12:22.
*  [ffmpeg-N-103899-g855014ff83-win64-gpl.zip 100MB](https://github.com/BtbN/FFmpeg-Builds/releases/download/autobuild-2021-09-28-12-22/ffmpeg-N-103899-g855014ff83-win64-gpl.zip)


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).



## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

pixelb/dvd-vr is licensed under the GNU General Public License v2.0