#! /bin/bash

set -eu

usage()
{
    if test -n "${*-}"; then
	echo "Error: $*" 1>&2
    fi
    cat 1>&2 <<EOF
Usage: $0 { -3 | -6 } version

Example:
# Build the 32-bit OpenSSL 1.0.1h zip:
  \$ $0 -3 1.0.1h
# Build the 64-bit OpenSSL 1.0.1h zip:
  \$ $0 -6 1.0.1h
EOF
    exit 1
}

errordie()
{
    if test -n "${*-}"; then
	echo "Error: $*" 1>&2
    fi
    exit 1
}

debug=
ver=
bit=

while test $# -gt 0; do
    case $1 in
	--debug) debug=$1 ;;
	-3) bit=32 ;;
	-6) bit=64 ;;
	-*) usage ;;
	*)  ver=$1
	    break
	    ;;
    esac
    shift
done

d()
{
    echo "+ $*"
    if test -z "$debug"; then
	"$@"
    fi
}

[ -z "$bit" ] && usage did not specify -3 od -6
[ -z "$ver" ] && usage did not specify version

src=openssl-${ver}.tar.gz

[ ! -f "$src" ] && usage $src does not exist

outdir=openssl-${ver}.${bit}
zipout=openssl-${ver}-${bit}.zip

d rm -fr "openssl-${ver}"
d rm -fr "$outdir"
d rm -f "$zipout"
d rm -fr "/c/$outdir"

d tar zxf openssl-${ver}.tar.gz
d mv openssl-${ver} "$outdir"

d cd "$outdir"

aclbuildenv=${bit}bit
. /c/src/scm/acl82.${bit}/src/cl/src/bin/windows_.env

if [ "$bit" = "32" ]; then
    export PATH=/c/perl/bin:$PATH
    d perl Configure VC-WIN32 no-asm --prefix=c:/$outdir
    d ms/do_nasm.bat
else
    export PATH=/c/perl/bin:/c/nasm:$PATH
    d perl Configure VC-WIN64A --prefix=c:/$outdir
    d ms/do_win64a.bat
fi

d nmake -f ms/ntdll.mak
d nmake -f ms/ntdll.mak test
d nmake -f ms/ntdll.mak install

# So the zip file goes in the current directory
d cd -

back=$(pwd | sed -e 's,^/c,,' -e 's,/,\\,g')
prog7z="/c/Program Files/7-Zip/7z.exe"

d cd /c

d "$prog7z" u '-wc:\tmp' -tzip -r "$back\\$zipout" "${outdir}\\*.*"
