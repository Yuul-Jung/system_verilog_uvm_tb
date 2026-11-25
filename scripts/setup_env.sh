#!/usr/bin/env bash
# Source this file from the repository root: source scripts/setup_env.sh

UVM_TB_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VIVADO_SETTINGS="${VIVADO_SETTINGS:-/tools/Xilinx/Vivado/2024.2/settings64.sh}"

if [[ -f "$VIVADO_SETTINGS" ]]; then
    # Vivado's own script owns its variables; do not modify the installation.
    # shellcheck disable=SC1090
    source "$VIVADO_SETTINGS"
else
    printf 'WARN: Vivado settings not found: %s\n' "$VIVADO_SETTINGS" >&2
fi

if [[ -d "$UVM_TB_ROOT/.tools/root/usr/bin" ]]; then
    PATH="$UVM_TB_ROOT/.tools/root/usr/bin:$PATH"
fi

if [[ -x "$UVM_TB_ROOT/.tools/verilator-5.054/bin/verilator" ]]; then
    PATH="$UVM_TB_ROOT/.tools/verilator-5.054/bin:$PATH"
    unset VERILATOR_ROOT
fi

export UVM_TB_ROOT PATH

uvm_tb_check_tools() {
    local tool
    local missing=0

    for tool in xvlog xelab xsim xcrg iverilog verilator z3 python3 make g++; do
        if command -v "$tool" >/dev/null 2>&1; then
            printf '%-10s %s\n' "$tool" "$(command -v "$tool")"
        else
            printf '%-10s NOT_FOUND\n' "$tool" >&2
            missing=1
        fi
    done

    return "$missing"
}

printf 'UVM_TB_ROOT=%s\n' "$UVM_TB_ROOT"
printf 'VIVADO_SETTINGS=%s\n' "$VIVADO_SETTINGS"
uvm_tb_check_tools
