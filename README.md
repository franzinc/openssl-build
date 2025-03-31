# OpenSSL build script for Windows

## Pre-requisites

* Microsoft Visual Studio 2015 was used for the build.
* Cygwin `make`, `bash` and various other tools
* `NASM` is needed for the build.  The included installer (version
  2.11.05) was downloaded from https://www.nasm.us/ and this snapshot
  is here for convenience.  We recommend you get the latest version
  from them.

## Building

Download the `tar.gz` from openssl.org and place it into the cloned
repository and do:

    $ ./build.sh -32 --test --build 3.4.1
    $ ./build.sh -64 --test --build 3.4.1

If your VS 2015 environment is set up correctly, the above will
produce two files `openssl-3.4.1.32.zip` and `openssl-3.4.1.64.zip`
in the `signed/` directory.

IMPORTANT: in the signing phase, if there is an error, the process
	   DOES NOT STOP.

Note that `--test` TAKES A LONG, LONG TIME, mate.  Don't do it more
than once, or you will be sad.

If you need to run the script a 2nd time and don't want to build,
just run:

    $ ./build.sh -32 3.4.1
    $ ./build.sh -64 3.4.1

## License

The files in this repo are in the public domain, except for the `NASM`
executable, which has a separate license.
