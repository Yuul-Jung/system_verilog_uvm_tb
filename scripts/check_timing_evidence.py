#!/usr/bin/env python3
"""공개 VCD/로그를 도식의 시간·값 계약과 비교한다 (실패 시 비정상 종료)."""

import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parent.parent
BUNDLE = ROOT / "docs/evidence/v59"


def read_vcd(path):
    text = path.read_text()
    assert re.search(r'\$timescale\s+1\s*ps\s+\$end', text), 'expected 1ps VCD'
    scope, names, events = [], {}, {}
    time = 0
    for line in text.splitlines():
        line = line.strip()
        parts = line.split()
        if line.startswith('$scope'):
            scope.append(parts[2])
        elif line.startswith('$upscope'):
            scope.pop()
        elif line.startswith('$var'):
            names['.'.join(scope + [parts[4]])] = parts[3]
        elif line.startswith('#'):
            time = int(line[1:])
        elif line and line[0] in '01xXzZbB':
            value, key = (parts[0][1:], parts[1]) if line[0].lower() == 'b' else (line[0], line[1:])
            events.setdefault(key, []).append((time / 1000, value.lower()))
    return names, events


def value_at(vcd, name, ns):
    names, events = vcd
    value = next(value for time, value in reversed(events[names[name]]) if time <= ns)
    return int(value, 2)


def main():
    rows = []
    for n, name in ((1, 'ch01_uart_echo.vcd'), (2, 'ch02_pwm_clock_reset.vcd'),
                    (7, 'ch07_uart_interface.vcd'), (23, 'ch23_npu_integrated.vcd')):
        vcd = read_vcd(BUNDLE / 'waves' / name)
        def check(signal, time, expected):
            actual = value_at(vcd, signal, time)
            assert actual == expected, (n, signal, time, expected, actual)
            rows.append(dict(chapter=n, signal=signal, time_ns=time,
                             expected=expected, actual=actual, status='PASS'))
        if n == 1:
            for time, data, valid, ready in ((0, 0, 0, 0), (10, 65, 1, 1), (20, 90, 1, 0), (30, 0, 0, 1)):
                for signal, value in (('rx_data_i', data), ('tx_data_o', data),
                                      ('tx_valid_o', valid), ('rx_ready_o', ready)):
                    check('tb_uart_echo_basics.' + signal, time, value)
        elif n == 2:
            for signal, time, value in (('pending', 35, 1), ('pending', 95, 0),
                                        ('active_duty', 95, 3), ('pwm_out', 95, 1),
                                        ('pwm_out', 125, 0), ('pwm_out', 190, 0),
                                        ('active_duty', 190, 3), ('active_duty', 195, 0)):
                check('tb_pwm_clock_reset.' + signal, time, value)
        elif n == 7:
            for time, data, valid, ready, checked in ((5, 65, 1, 1, 0), (15, 90, 1, 0, 1),
                                                     (25, 90, 1, 1, 2), (35, 90, 0, 1, 3),
                                                     (45, 90, 0, 1, 4)):
                for signal, value in (('stream.rx_data_i', data), ('stream.rx_valid_i', valid),
                                      ('stream.tx_ready_i', ready), ('agent.checked', checked)):
                    check('tb_uart_interface.' + signal, time, value)
        else:
            names, events = vcd
            starts = [t for t, v in events[names['tb_npu_integrated.busy_o']] if v == '1']
            dones = [t for t, v in events[names['tb_npu_integrated.done_o']] if v == '1']
            expected = [60] * 5 + [40, 40, 1300]
            actual = [b - a for a, b in zip(starts, dones)]
            assert len(starts) == len(dones) == 8 and actual == expected, actual
            rows.append(dict(chapter=23, contract='2*length+2 clocks, 10ns clock',
                             expected_ns=expected, actual_ns=actual, status='PASS'))
    negative = (BUNDLE / 'runs/ch11/ch11_negative.log').read_text()
    assert 'DETECTED_SVA_PENDING t=55' in negative
    rows.append(dict(chapter=11, contract='next-edge SVA violation at 55ns', status='PASS'))
    coverage = (BUNDLE / 'runs/ch12/output.log').read_text()
    cases = re.findall(r'CHECK duty=(\d+) en=(\d) pol=(\d) highs=(\d+)', coverage)
    assert len(cases) == 12
    for duty, en, pol, highs in (map(int, c) for c in cases):
        assert highs == (8 - duty if pol else duty) * en
    rows.append(dict(chapter=12, contract='12 cross cells, expected HIGH counts', status='PASS'))
    print(json.dumps(rows, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
