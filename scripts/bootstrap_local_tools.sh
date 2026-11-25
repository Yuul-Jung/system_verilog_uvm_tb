#!/usr/bin/env bash
# Install missing open-source verification tools below .tools without sudo.

set -euo pipefail

UVM_TB_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLS_DIR="$UVM_TB_ROOT/.tools"
PACKAGE_DIR="$TOOLS_DIR/packages"
LOCAL_ROOT="$TOOLS_DIR/root"
SOURCE_DIR="$TOOLS_DIR/src/verilator"
INSTALL_DIR="$TOOLS_DIR/verilator-5.054"

if [[ -x "$INSTALL_DIR/bin/verilator" && -x "$LOCAL_ROOT/usr/bin/z3" ]]; then
    printf 'Local tools already installed.\n'
    "$INSTALL_DIR/bin/verilator" --version
    "$LOCAL_ROOT/usr/bin/z3" --version
    exit 0
fi

mkdir -p "$PACKAGE_DIR" "$LOCAL_ROOT" "$TOOLS_DIR/src"

(
    cd "$PACKAGE_DIR"
    apt-get download \
        autoconf bison flex help2man libfl-dev libfl2 \
        liblocale-gettext-perl m4 z3
)

for package in "$PACKAGE_DIR"/*.deb; do
    dpkg-deb -x "$package" "$LOCAL_ROOT"
done

# Ubuntu's autoconf package records its data directory as /usr/share/autoconf.
# Point only the extracted private copy at the matching private data directory.
AUTOM4TE_CFG="$LOCAL_ROOT/usr/share/autoconf/autom4te.cfg"
if [[ -f "$AUTOM4TE_CFG" ]]; then
    sed -i "s|/usr/share/autoconf|$LOCAL_ROOT/usr/share/autoconf|g" "$AUTOM4TE_CFG"
fi

if [[ ! -d "$SOURCE_DIR/.git" ]]; then
    git clone --branch v5.054 --depth 1 \
        https://github.com/verilator/verilator.git "$SOURCE_DIR"
fi

export PATH="$LOCAL_ROOT/usr/bin:$PATH"
unset VERILATOR_ROOT

(
    cd "$SOURCE_DIR"
    autoconf
    ./configure --prefix="$INSTALL_DIR"
    make -j"$(nproc)"
    make install
)

"$INSTALL_DIR/bin/verilator" --version
"$LOCAL_ROOT/usr/bin/z3" --version
printf 'Run: source scripts/setup_env.sh\n'
