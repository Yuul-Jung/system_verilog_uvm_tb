`timescale 1ns/1ps
// 제07장: UART Byte Stream(바이트 데이터 흐름)의 6개 신호를 한 묶음으로 관리한다.
// tb_clk은 테스트벤치의 샘플링 기준이며, 원본 DUT의 입력 포트가 아니다.
interface uart_stream_if(input logic tb_clk);
    logic [7:0] rx_data_i;
    logic       rx_valid_i;
    logic       tx_ready_i;
    logic       rx_ready_o;
    logic [7:0] tx_data_o;
    logic       tx_valid_o;

    // (추가) TB 관점에서 출력은 구동, 입력은 관찰 대상이다.
    // input #1step: 현재 상승 에지 직전의 안정된 값을 샘플링한다.
    // output #0  : 상승 에지의 Re-NBA 영역에서 다음 구간의 입력을 구동한다.
    clocking cb @(posedge tb_clk);
        default input #1step output #0;
        output rx_data_i, rx_valid_i, tx_ready_i;
        input  rx_ready_o, tx_data_o, tx_valid_o;
    endclocking

    // (추가) TB에서는 cb로만 구동·샘플링하도록 접근 방식을 지정한다.
    modport TB (clocking cb);

    // (추가) 원본의 6개 평면 포트를 연결할 Adapter용 방향 선언.
    // DUT 원본 자체는 interface 포트를 갖지 않는다.
    modport DUT (
        input  rx_data_i, rx_valid_i, tx_ready_i,
        output rx_ready_o, tx_data_o, tx_valid_o
    );
endinterface
