`timescale 1ns/1ps
// 제16장: 원본 MAC 및 파이프라인 MAC의 INT8 signed 누산 검증.
// RTL 수정 없이 동일 입력을 두 DUT에 주고 서로 다른 출력 지연을 검사한다.
module tb_mac_integer;
    reg clk = 0;
    reg resetn = 0, clear_i = 0, valid_i = 0;
    reg signed [7:0] a_i = 0, b_i = 0;
    wire signed [15:0] acc_basic, acc_pipe;
    wire valid_basic, valid_pipe;
    reg signed [15:0] model_basic = 0, model_pipe = 0;
    reg signed [15:0] pending_product = 0;
    reg pending_valid = 0;
    reg expected_basic_valid = 0, expected_pipe_valid = 0;
    integer cycles = 0, valid_count = 0, pipe_count = 0;
    integer i;
    reg signed [15:0] product;
    reg signed [7:0] va, vb;

    always #5 clk = ~clk;

    mac_core #(.DATA_WIDTH(8), .ACC_WIDTH(16)) basic (
        .clk(clk), .resetn(resetn), .clear_i(clear_i),
        .valid_i(valid_i), .a_i(a_i), .b_i(b_i),
        .acc_o(acc_basic), .valid_o(valid_basic)
    );
    mac_pipeline_core #(.DATA_WIDTH(8), .ACC_WIDTH(16)) piped (
        .clk(clk), .resetn(resetn), .clear_i(clear_i),
        .valid_i(valid_i), .a_i(a_i), .b_i(b_i),
        .acc_o(acc_pipe), .valid_o(valid_pipe)
    );

    // 기대 모델은 DUT의 내부 신호를 참조하지 않는다.
    // 16비트 누산에서 오버플로는 하위 16비트만 남긴다.
    always @(posedge clk) begin
        if (!resetn || clear_i) begin
            model_basic = 0;
            model_pipe = 0;
            pending_product = 0;
            pending_valid = 0;
            expected_basic_valid = 0;
            expected_pipe_valid = 0;
        end else begin
            expected_pipe_valid = pending_valid;
            if (pending_valid)
                model_pipe = model_pipe + pending_product;
            expected_basic_valid = valid_i;
            if (valid_i) begin
                product = $signed(a_i) * $signed(b_i);
                model_basic = model_basic + product;
                pending_product = product;
            end
            pending_valid = valid_i;
        end
        // 비차단 대입이 완료된 뒤 두 결과를 비교한다.
        #1;
        cycles = cycles + 1;
        if (acc_basic !== model_basic ||
            valid_basic !== expected_basic_valid)
            $fatal(1, "FAIL BASIC cycle=%0d got=%0d/%b expected=%0d/%b",
                   cycles, acc_basic, valid_basic,
                   model_basic, expected_basic_valid);
        if (acc_pipe !== model_pipe ||
            valid_pipe !== expected_pipe_valid)
            $fatal(1, "FAIL PIPE cycle=%0d got=%0d/%b expected=%0d/%b",
                   cycles, acc_pipe, valid_pipe,
                   model_pipe, expected_pipe_valid);
        if (expected_basic_valid) valid_count = valid_count + 1;
        if (expected_pipe_valid) pipe_count = pipe_count + 1;
    end

    // 모든 입력은 하강 에지에서 변경해 상승 에지 경합을 방지한다.
    task automatic apply(
        input bit rst, input bit clr, input bit v,
        input signed [7:0] aa, input signed [7:0] bb
    );
        begin
            @(negedge clk);
            resetn = rst;
            clear_i = clr;
            valid_i = v;
            a_i = aa;
            b_i = bb;
        end
    endtask

    initial begin
        #100000;
        $fatal(1, "FAIL GLOBAL_TIMEOUT");
    end

    initial begin
        $dumpfile("ch16_mac_integer.vcd");
        $dumpvars(0, tb_mac_integer);
        // 최초 2클록 동안 동기 리셋 유지.
        repeat(2) @(negedge clk);
        apply(1, 0, 1, 127, 127);    // 양수 최댓값 곱
        apply(1, 0, 1, -128, 127);   // 음수 최솟값 곱
        apply(1, 0, 1, -128, -128);  // 양수 16384
        apply(1, 0, 0, 8, 9);        // 버블: 누산 유지
        apply(1, 0, 1, 127, 127);    // 누산 오버플로 검증
        apply(1, 1, 1, 100, 100);   // clear 우선: 입력 폐기
        apply(1, 0, 1, -3, 7);      // clear 후 새 누산
        apply(1, 0, 1, 5, -6);
        apply(1, 0, 0, 0, 0);        // 파이프라인 마지막 곱 배출
        apply(0, 0, 1, 2, 3);        // reset 우선
        apply(1, 0, 1, -128, 127);
        apply(1, 0, 0, 0, 0);
        apply(1, 0, 0, 0, 0);
        @(negedge clk);
        if (valid_count < 6 || pipe_count < 5)
            $fatal(1, "FAIL COVERAGE basic=%0d pipe=%0d",
                   valid_count, pipe_count);
        $display("PASS CH16 cycles=%0d basic_valid=%0d pipe_valid=%0d",
                 cycles, valid_count, pipe_count);
        $finish;
    end
endmodule
