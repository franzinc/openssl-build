#! /usr/bin/env bash
# Build OpenSSL for Windows, for use by ACL.

set -eu

function usage {
    if [ "${*-}" ]; then
	echo "Error: $*" 1>&2
    fi
    cat 1>&2 <<EOF
Usage: $0 { -32 | -64 } version

Example:
# Build the 32-bit OpenSSL 1.0.1h zip:
  \$ $0 -32 1.0.1h
# Build the 64-bit OpenSSL 1.0.1h zip:
  \$ $0 -64 1.0.1h
EOF
    exit 1
}

function errordie {
    if [ "${*-}" ]; then
	echo "Error: $*" 1>&2
    else
	echo "Error" 1>&2
    fi
    exit 1
}

if [ ! -d acl ]; then
    git clone git:/repo/git/acl
fi
subs=acl/bin/subswin.sh
[ -f "$subs" ] || errordie cannot find $subs
source $subs

rootdir=$(pwd)

debug=
ver=
bit=

while test $# -gt 0; do
    case $1 in
	--debug) debug=$1 ;;
	-3*) bit=32 ;;
	-6*) bit=64 ;;
	-*) usage ;;
	*)  ver=$1
	    break
	    ;;
    esac
    shift
done

function d {
    echo "+ $*"
    if test -z "$debug"; then
	"$@"
    fi
}

[ "$bit" ] || usage did not specify -3 od -6
[ "$ver" ] || usage did not specify version

src=openssl-${ver}.tar.gz
[ -f "$src" ] || usage $src does not exist

outdir=openssl-${ver}.${bit}
zipout=openssl-${ver}-${bit}.zip

d rm -fr "openssl-${ver}"
d rm -fr "$outdir"
d rm -f "$zipout"
d adoitw rm -fr "/c/$outdir"

d tar zxf openssl-${ver}.tar.gz
d mv openssl-${ver} "$outdir"

aclbuildenv=${bit}bit

if [ "$bit" = "32" ]; then
    cd /c/src/scm/acl10.1.32/src/cl/src/
else
    cd /c/src/scm/acl10.1.64/src/cl/src/
fi
source env.sh
cd $rootdir

d cd "$outdir"

export PATH=/c/perl64/bin:$PATH

if [ "$bit" = "32" ]; then
    d perl Configure VC-WIN32 no-asm --prefix=c:/$outdir
    if [[ $ver =~ ^1\.0 ]]; then
	d ms/do_nasm.bat
    fi
else
    if [[ $ver =~ ^1\.0 ]]; then
	d perl Configure VC-WIN64A --prefix=c:/$outdir
	d ms/do_win64a.bat
    else
	d perl Configure VC-WIN64A no-asm --prefix=c:/$outdir
    fi
fi

if [[ $ver =~ ^1\.0 ]]; then
    margs="-f ms/ntdll.mak"
else
    margs=
fi

# A horrible hack.  Not that many people will use that version of link.exe.
# Only builds with gcc inside of Cygwin would.  Still, it's horrible.
[ -f /usr/bin/link.exe ] && d mv /usr/bin/link.exe /usr/bin/link.exe.save
d nmake $margs
d nmake $margs test
d adoitw nmake $margs install
# undo the horrible hack
[ -f /usr/bin/link.exe.save ] && d mv /usr/bin/link.exe.save /usr/bin/link.exe 

# So the zip file goes in the current directory
d cd "$rootdir"
fromdir=$(pwd | sed -e 's,^/c,,' -e 's,/,\\,g')
prog7z="/c/Program Files/7-Zip/7z.exe"

d cd /c

d "$prog7z" u '-wc:\tmp' -tzip -r "$fromdir\\$zipout" "${outdir}\\*.*"
