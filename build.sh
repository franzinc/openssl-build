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
    echo "Error: $*" 1>&2
    exit 1
}

if [ ! -d acl ]; then
    git clone git:/repo/git/acl
fi
subs=acl/bin/subswin.sh
[ -f "$subs" ] || errordie "cannot find $subs"
source $subs

origdir=$(pwd)

debug=
ver=
bit=
remove=
dotest=

while test $# -gt 0; do
    case $1 in
	--debug) debug=$1 ;;
        --build) remove=$1 ;;
        --test) dotest=$1 ;;
	-32|--32) bit=32 ;;
	-64|--64) bit=64 ;;
	-*) usage ;;
	*)  ver=$1
	    break
	    ;;
    esac
    shift
done

[ "$bit" ] || usage did not specify -3 od -6
[ "$ver" ] || usage did not specify version

src=openssl-${ver}.tar.gz
[ -f "$src" ] || usage $src does not exist

function d {
    echo "+ $*"
    if [ -z "$debug" ]; then
	"$@"
    fi
}

# usage: zipit source-directory output-zip-file
function zipit {
    rm -f "$2"
    $find "$1" -type f -print | $zip "$2" -@9
}

{

zip=$(type -p zip)
find=$(type -p find)

outdir=openssl-${ver}.${bit}
zipout=openssl-${ver}.${bit}.zip

d rm -fr "openssl-${ver}"
if [ "$remove" ]; then
    d rm -fr "$outdir"
    d tar zxf openssl-${ver}.tar.gz
    d mv openssl-${ver} "$outdir"
elif [ ! -d "$outdir" ]; then
    errordie "$outdir does not exist"
fi

d rm -f "signed/$zipout"
d adoitw rm -fr "/c/$outdir"

# used by env.sh
aclbuildenv=${bit}bit

if [ "$bit" = "32" ]; then
    cd /c/src/scm/acl10.1.32/src/cl/src/
else
    cd /c/src/scm/acl10.1.64/src/cl/src/
fi
source env.sh

export PATH=/c/perl64/bin:$PATH

d cd "$origdir/$outdir"

if [ "$remove" ]; then
    if [ "$bit" = "32" ]; then
        d perl Configure VC-WIN32 no-asm --prefix=c:/$outdir
    else
        d perl Configure VC-WIN64A no-asm --prefix=c:/$outdir
    fi
fi

# We need /usr/bin/ to be at the end PATH so /usr/bin/link.exe is NOT
# used by the build.
PATH=$(echo $PATH | sed -e 's,:/bin:,:,g' -e 's,:/usr/bin:,:,g'):/bin:/usr/bin

if ! d nmake; then
    echo "build failed"
    echo "command: nmake"
    echo "directory: $(pwd)"
    exit 1
fi

[ "$dotest" ] && d nmake test
d adoitw nmake install

# The above builds and installs into c:/... now we need to make the zip file, so
# we can sign the contents of it.  NOTE: we can't sign in place, in c:/...
# because Administrator owns those files.  Sad face.

cd "$origdir"

d rm -fr "tmp/$outdir"
d cp -rp "/c/$outdir" "tmp/$outdir"

export FI_CODESIGN_FOR_RELEASE=yes
for bin in $($find "tmp/$outdir" '(' -name '*.exe' -o -name '*.dll' ')' -print); do
    d ficodesign  "$(cygpath -w "$bin")"
done

d cd tmp
d zipit "$outdir" "$origdir/signed/$zipout"

exit 0
}
