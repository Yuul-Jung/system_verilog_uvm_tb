`timescale 1ns/1ps
// 제23장: 원본 npu_engine4 + DSP lane + multiplier 통합 검증.
// 정답은 DUT 내부 누산기가 아니라 독립 integer 참조 모델로 계산한다.
module tb_npu_integrated;
    reg clk=0, resetn=0, start_i=0;
    reg [6:0] length_i=0;
    reg x_wr_en=0, w_wr_en=0, b_wr_en=0;
    reg [5:0] addr_i=0;
    reg [1:0] neuron_i=0;
    reg signed [15:0] data_i=0;
    reg signed [39:0] bias_i=0;
    wire load_ready_o, busy_o, done_o, error_o;
    wire [1:0] class_o;
    wire [163:0] scores_o;

    // 원본 포트와 폭을 그대로 연결한다.
    npu_engine4 dut (
        .clk(clk), .resetn(resetn), .start_i(start_i),
        .length_i(length_i), .x_wr_en(x_wr_en),
        .w_wr_en(w_wr_en), .b_wr_en(b_wr_en),
        .addr_i(addr_i), .neuron_i(neuron_i),
        .data_i(data_i), .bias_i(bias_i),
        .load_ready_o(load_ready_o), .busy_o(busy_o),
        .done_o(done_o), .error_o(error_o),
        .class_o(class_o), .scores_o(scores_o)
    );
    always #5 clk=~clk;

    // TB 전용 입력/가중치/편향 복제본: DUT 내부 메모리 참조 금지.
    integer model_x[0:63];
    integer model_w[0:3][0:63];
    reg signed [39:0] model_bias[0:3];
    reg signed [40:0] expected[0:3];
    integer i,j,cycles,tests=0;
    reg [1:0] expected_class;
    reg signed [40:0] best;

    task automatic load_x(input [5:0] addr, input signed [15:0] value);
        begin
            @(negedge clk);
            if (load_ready_o !== 1'b1) $fatal(1,"FAIL LOAD_X_READY");
            addr_i=addr; data_i=value; x_wr_en=1;
            @(negedge clk);
            x_wr_en=0; model_x[addr]=value;
        end
    endtask

    task automatic load_w(input [1:0] neuron, input [5:0] addr,
                          input signed [15:0] value);
        begin
            @(negedge clk);
            if (load_ready_o !== 1'b1) $fatal(1,"FAIL LOAD_W_READY");
            neuron_i=neuron; addr_i=addr; data_i=value; w_wr_en=1;
            @(negedge clk);
            w_wr_en=0; model_w[neuron][addr]=value;
        end
    endtask

    task automatic load_bias(input [1:0] neuron,
                             input signed [39:0] value);
        begin
            @(negedge clk);
            neuron_i=neuron; bias_i=value; b_wr_en=1;
            @(negedge clk);
            b_wr_en=0; model_bias[neuron]=value;
        end
    endtask

    // 4개 뉴런의 signed 곱-누산 + bias를 별도로 계산한다.
    // 동점이면 낮은 뉴런 번호를 선택한다(원본의 > 비교 계약).
    task automatic calculate(input integer len);
        integer n,k;
        reg signed [40:0] acc;
        begin
            for(n=0;n<4;n=n+1) begin
                acc=$signed(model_bias[n]);
                for(k=0;k<len;k=k+1)
                    acc=acc+$signed(model_x[k])*$signed(model_w[n][k]);
                expected[n]=acc;
            end
            expected_class=0;
            best=expected[0];
            for(n=1;n<4;n=n+1)
                if(expected[n]>best) begin
                    best=expected[n];
                    expected_class=n;
                end
        end
    endtask

    // 시작 에지를 0으로 세고 done_o가 올라오는 에지까지 측정.
    // 원본 FSM: READ/ISSUE 각각 len회, DRAIN1/2 이후 done.
    // done 관측 지연: 2*len+3 클록(시작 에지 제외).
    task automatic execute(input integer len);
        integer n;
        begin
            calculate(len);
            @(negedge clk);
            if(load_ready_o !== 1'b1) $fatal(1,"FAIL NOT_IDLE");
            length_i=len; start_i=1;
            @(posedge clk);
            #1;
            if(busy_o !== 1'b1) $fatal(1,"FAIL BUSY_START");
            @(negedge clk);
            start_i=0;
            cycles=0;
            while(done_o !== 1'b1) begin
                @(posedge clk);
                #1;
                cycles=cycles+1;
                if(cycles>2*len+10) $fatal(1,"FAIL DONE_TIMEOUT");
            end
            if(cycles != 2*len+3)
                $fatal(1,"FAIL LATENCY got=%0d expected=%0d",cycles,2*len+3);
            if(busy_o !== 1'b0 || error_o !== 1'b0 ||
               class_o !== expected_class)
                $fatal(1,"FAIL STATUS_CLASS got=%0d expected=%0d",
                       class_o,expected_class);
            for(n=0;n<4;n=n+1)
                if($signed(scores_o[n*41+:41]) !== expected[n])
                    $fatal(1,"FAIL SCORE neuron=%0d got=%0d expected=%0d",
                           n,$signed(scores_o[n*41+:41]),expected[n]);
            tests=tests+1;
            $display("CHECK len=%0d cycles=%0d class=%0d",len,cycles,class_o);
            @(posedge clk);
            #1;
            if(done_o !== 1'b0) $fatal(1,"FAIL DONE_NOT_PULSE");
        end
    endtask

    initial begin
        #1000000;
        $fatal(1,"FAIL GLOBAL_TIMEOUT");
    end

    initial begin
        $dumpfile("ch23_npu_integrated.vcd");
        $dumpvars(0,tb_npu_integrated);
        repeat(5) @(negedge clk);
        resetn=1;
        // 길이 2, 음수 가중치, 네 클래스의 독립 정답 비교.
        for(i=0;i<4;i=i+1) begin
            model_bias[i]=0;
            load_w(i,0,(i&2)?-16'sd1:16'sd1);
            load_w(i,1,(i&1)?-16'sd1:16'sd1);
        end
        for(j=0;j<4;j=j+1) begin
            load_x(0,(j&2)?-16'sd1:16'sd1);
            load_x(1,(j&1)?-16'sd1:16'sd1);
            execute(2);
            if(class_o !== j[1:0]) $fatal(1,"FAIL CLASS_CASE %0d",j);
        end
        // 편향은 누산 결과에 더해지며 뉴런 3이 우승한다.
        load_x(0,16'sd1); load_x(1,16'sd1);
        load_bias(3,40'sd10);
        execute(2);
        if(class_o !== 2'd3) $fatal(1,"FAIL BIAS_CLASS");
        // 길이 1: 남은 유효 가중치에 대한 결과만 비교.
        execute(1);
        // 길이 3: 세 번째 입력이 없어 오류, busy/done 미발생.
        @(negedge clk);
        length_i=3; start_i=1;
        @(posedge clk); #1;
        if(error_o !== 1'b1 || busy_o !== 1'b0 || done_o !== 1'b0)
            $fatal(1,"FAIL INVALID_LENGTH");
        @(negedge clk);
        start_i=0;
        $display("PASS CH23 cases=%0d invalid_length=1",tests);
        $finish;
    end
endmodule
