#!/usr/bin/env python3
# 제16장: 8비트 부호 있는 곱과 16비트 누산의 독립 정수 모델.
def signed16(value):
    value &= 0xffff
    return value - 65536 if value & 0x8000 else value

vectors = [(127, 127), (-128, 127), (-128, -128), (127, 127)]
acc = 0
for a, b in vectors:
    acc = signed16(acc + a * b)
    print(f"a={a:4d} b={b:4d} product={a*b:7d} acc={acc:7d}")
