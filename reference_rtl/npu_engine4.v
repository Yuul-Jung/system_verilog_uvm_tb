// (추가) 04장 BRAM 구조 + 02장 DSP 레지스터 곱 + 4개 누산기 통합.
// 12장 최종 경로는 기존 ch07 벡터 닷의 곱 경로를 중복 사용하지 않는다.
// 메모리 쓰기는 IDLE에서만 허용하며 Reset 시 유효 비트만 지운다.
module npu_engine4(
    input wire clk,resetn,start_i,
    input wire [6:0] length_i,
    input wire x_wr_en,w_wr_en,b_wr_en,
    input wire [5:0] addr_i,
    input wire [1:0] neuron_i,
    input wire signed [15:0] data_i,
    input wire signed [39:0] bias_i,
    output wire load_ready_o,
    output reg busy_o,done_o,error_o,
    output reg [1:0] class_o,
    output reg [163:0] scores_o
);
    localparam [2:0] IDLE=0,READ=1,ISSUE=2,DRAIN1=3,DRAIN2=4;
    reg [2:0] state;
    reg [6:0] length_q;
    reg [5:0] index_q;
    (* ram_style="block" *) reg signed [15:0] xmem[0:63];
    (* ram_style="block" *) reg signed [15:0] w0[0:63];
    (* ram_style="block" *) reg signed [15:0] w1[0:63];
    (* ram_style="block" *) reg signed [15:0] w2[0:63];
    (* ram_style="block" *) reg signed [15:0] w3[0:63];
    reg [63:0] x_seen,w0_seen,w1_seen,w2_seen,w3_seen;
    reg signed [39:0] bias0,bias1,bias2,bias3;
    reg signed [15:0] x_sample,w_sample0,w_sample1,w_sample2,w_sample3;

    reg input_valid;
    integer k;
    always @* begin
        input_valid=(length_i!=0 && length_i<=64);
        for(k=0;k<64;k=k+1)
            if(k<length_i &&
               (!x_seen[k] || !w0_seen[k] || !w1_seen[k] ||
                !w2_seen[k] || !w3_seen[k]))
                input_valid=0;
    end
    wire any_write=x_wr_en||w_wr_en||b_wr_en;
    wire launch=(state==IDLE)&&start_i&&input_valid&&!any_write;
    wire mul_valid=(state==ISSUE);
    assign load_ready_o=resetn&&!busy_o&&!start_i;

    wire signed [39:0] acc0,acc1,acc2,acc3;
    npu_dsp_mac_lane lane0(.clk(clk),.resetn(resetn),.clear_i(launch),
        .valid_i(mul_valid),.x_i(x_sample),.w_i(w_sample0),.acc_o(acc0));
    npu_dsp_mac_lane lane1(.clk(clk),.resetn(resetn),.clear_i(launch),
        .valid_i(mul_valid),.x_i(x_sample),.w_i(w_sample1),.acc_o(acc1));
    npu_dsp_mac_lane lane2(.clk(clk),.resetn(resetn),.clear_i(launch),
        .valid_i(mul_valid),.x_i(x_sample),.w_i(w_sample2),.acc_o(acc2));
    npu_dsp_mac_lane lane3(.clk(clk),.resetn(resetn),.clear_i(launch),
        .valid_i(mul_valid),.x_i(x_sample),.w_i(w_sample3),.acc_o(acc3));
    // 41비트 signed: 40비트 누산값에 Bias를 더할 때 부호 확장 1비트.
    wire signed [40:0] score0=$signed({acc0[39],acc0})+$signed({bias0[39],bias0});
    wire signed [40:0] score1=$signed({acc1[39],acc1})+$signed({bias1[39],bias1});
    wire signed [40:0] score2=$signed({acc2[39],acc2})+$signed({bias2[39],bias2});
    wire signed [40:0] score3=$signed({acc3[39],acc3})+$signed({bias3[39],bias3});
    reg [1:0] best_class;
    reg signed [40:0] best_score;
    always @*begin
        best_class=0;best_score=score0;
        if(score1>best_score)begin best_score=score1;best_class=1;end
        if(score2>best_score)begin best_score=score2;best_class=2;end
        if(score3>best_score)begin best_score=score3;best_class=3;end
    end

    always @(posedge clk)begin
        if(!resetn)begin
            state<=IDLE;busy_o<=0;done_o<=0;error_o<=0;
            class_o<=0;scores_o<=0;length_q<=0;index_q<=0;
            x_seen<=0;w0_seen<=0;w1_seen<=0;w2_seen<=0;w3_seen<=0;
            bias0<=0;bias1<=0;bias2<=0;bias3<=0;
            x_sample<=0;w_sample0<=0;w_sample1<=0;w_sample2<=0;w_sample3<=0;
        end else begin
            done_o<=0;error_o<=0;
            if(load_ready_o)begin
                if(x_wr_en)begin
                    xmem[addr_i]<=data_i;x_seen[addr_i]<=1;
                end
                if(w_wr_en)case(neuron_i)
                    0:begin w0[addr_i]<=data_i;w0_seen[addr_i]<=1;end
                    1:begin w1[addr_i]<=data_i;w1_seen[addr_i]<=1;end
                    2:begin w2[addr_i]<=data_i;w2_seen[addr_i]<=1;end
                    3:begin w3[addr_i]<=data_i;w3_seen[addr_i]<=1;end
                endcase
                if(b_wr_en)case(neuron_i)
                    0:bias0<=bias_i;
                    1:bias1<=bias_i;
                    2:bias2<=bias_i;
                    3:bias3<=bias_i;
                endcase
            end else if(any_write)error_o<=1;
            case(state)
                IDLE:if(start_i)begin
                    if(!input_valid||any_write)error_o<=1;
                    else begin
                        state<=READ;length_q<=length_i;index_q<=0;busy_o<=1;
                    end
                end
                READ:begin
                    x_sample<=xmem[index_q];
                    w_sample0<=w0[index_q];w_sample1<=w1[index_q];
                    w_sample2<=w2[index_q];w_sample3<=w3[index_q];
                    state<=ISSUE;
                end
                ISSUE:begin
                    if({1'b0,index_q}+7'd1==length_q)state<=DRAIN1;
                    else begin index_q<=index_q+1'b1;state<=READ;end
                end
                DRAIN1:state<=DRAIN2;
                DRAIN2:begin
                    scores_o<={score3,score2,score1,score0};
                    class_o<=best_class;done_o<=1;busy_o<=0;state<=IDLE;
                end
                default:begin state<=IDLE;busy_o<=0;error_o<=1;end
            endcase
        end
    end
endmodule
