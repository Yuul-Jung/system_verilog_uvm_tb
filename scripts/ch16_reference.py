#!/usr/bin/env python3
# 제16장: 무한 정밀도 정수와 입력 이력으로 기대값을 독립 계산한다.
def signed(value, width):
    value %= 1 << width
    return value - (1 << width) if value >= (1 << (width - 1)) else value

# resetn, clear, valid, a, b: 최초 3개 상승 에지의 reset 포함
vectors = [(0, 0, 0, 0, 0)] * 3 + [
    (1, 0, 1, 127, 127), (1, 0, 1, -128, 127),
    (1, 0, 1, -128, -128), (1, 0, 0, 8, 9),
    (1, 0, 1, 127, 127), (1, 0, 1, 127, 127),
    (1, 0, 1, 1, 1), (1, 1, 1, 100, 100),
    (1, 0, 1, -3, 7), (1, 0, 1, 5, -6),
    (1, 0, 0, 0, 0), (1, 0, 1, 9, 9),
    (0, 0, 1, 2, 3), (1, 0, 1, -128, 127),
    (1, 0, 1, -128, 127), (1, 0, 1, -128, 127),
    (1, 0, 0, 0, 0), (1, 0, 0, 0, 0),
]
history = []
basic_count = pipe_count = 0
print("cycle basic16 pipe16 basic24 pipe24 valid_basic valid_pipe")
for cycle, (rst, clr, v, a, b) in enumerate(vectors, 1):
    if not rst or clr:
        history.clear()
        vb = vp = 0
    else:
        vp = int(bool(history) and history[-1] is not None)
        vb = v
        history.append(a * b if v else None)
    # 파이프라인은 현재 에지의 입력 한 개를 제외한 이력을 합산한다.
    basic = sum(x for x in history if x is not None)
    pipe = sum(x for x in history[:-1] if x is not None)
    basic_count += vb
    pipe_count += vp
    print(cycle, signed(basic, 16), signed(pipe, 16),
          signed(basic, 24), signed(pipe, 24), vb, vp)
assert (len(vectors), basic_count, pipe_count) == (21, 12, 10)
assert (basic, pipe) == (-48768, -48768)
print("MODEL CH16 cycles=21 basic_valid=12 pipe_valid=10")
