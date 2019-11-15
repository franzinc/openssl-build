# OpenSSL build script for Windows

## Pre-requisites

* Microsoft Visual Studio 2015 was used for the build.
* Cygwin `make`, `bash` and various other tools

## Building

Download the `tar.gz` from openssl.org and place it into the cloned
repository, then do:

    $ ./build.sh -32 1.1.1d
    $ ./build.sh -64 1.1.1d

If your VS 2015 environment is set up correctly, the above will
produce two files `openssl-1.1.1d-32.zip` and `openssl-1.1.1d-64.zip`.

## License

The files in this repo are in the public domain.
