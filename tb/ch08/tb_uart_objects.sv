`timescale 1ns/1ps
// 제08장: 원본 UART Echo의 6개 포트를 변경하지 않고 객체 기반 입력을 검증한다.
// class, new, extends, rand, constraint, randomize()를 직접 실습한다.

class uart_txn;
    rand bit [7:0] data;
    rand bit       valid;
    rand bit       ready;

    // (추가) 출력 가능한 ASCII(아스키) 문자 범위로 데이터를 제한한다.
    constraint c_printable { data inside {[8'h20:8'h7e]}; }

    function new();
        data = 8'h41;
        valid = 1'b1;
        ready = 1'b1;
    endfunction

    function string describe();
        return $sformatf("data=%02h valid=%0b ready=%0b",
                         data, valid, ready);
    endfunction
endclass

// (추가) 부모의 데이터 범위 제약을 물려받고 정지 조건을 추가한다.
class uart_stall_txn extends uart_txn;
    constraint c_stall { valid == 1'b1; ready == 1'b0; }
endclass

module tb_uart_objects;
    logic [7:0] rx_data_i;
    logic       rx_valid_i;
    wire        rx_ready_o;
    wire [7:0]  tx_data_o;
    wire        tx_valid_o;
    logic       tx_ready_i;

    integer checked = 0;
    uart_txn normal;
    uart_stall_txn stalled;

    // 원본 DUT: 데이터/유효/준비를 그대로 전달하는 조합회로이다.
    uart_echo_controller dut (
        .rx_data_i(rx_data_i),
        .rx_valid_i(rx_valid_i),
        .rx_ready_o(rx_ready_o),
        .tx_data_o(tx_data_o),
        .tx_valid_o(tx_valid_o),
        .tx_ready_i(tx_ready_i)
    );

    // (추가) 객체의 속성을 DUT 포트에 적용하고 4상태 비교로 확인한다.
    task automatic apply_and_check(input uart_txn tr, input string label_name);
        begin
            rx_data_i  = tr.data;
            rx_valid_i = tr.valid;
            tx_ready_i = tr.ready;
            #1; // 조합 출력이 안정되도록 TB에서만 기다린다. DUT 지연이 아니다.
            if ((tx_data_o !== tr.data) ||
                (tx_valid_o !== tr.valid) ||
                (rx_ready_o !== tr.ready))
                $fatal(1, "FAIL %s expected %s got %02h/%b/%b",
                       label_name, tr.describe(), tx_data_o,
                       tx_valid_o, rx_ready_o);
            checked++;
            $display("PASS %s %s", label_name, tr.describe());
        end
    endtask

    initial begin
        $display("=== CH08 OBJECT / CONSTRAINT START ===");
        normal = new();
        stalled = new();

        // (추가) 부모 객체에 특정 값을 넣어 기준 동작부터 확인한다.
        normal.data = 8'h41;
        normal.valid = 1'b1;
        normal.ready = 1'b1;
        apply_and_check(normal, "DIRECT_A");

        // (추가) 인라인 제약으로 유효한 IDLE 사례를 생성한다.
        if ((normal.randomize() with { valid == 0; ready == 1; }) == 0)
            $fatal(1, "RANDOMIZE_FAIL IDLE");
        // (추가) 생성 성공뿐 아니라 실제 IDLE 제약 만족 여부도 검사한다.
        if (!(normal.data >= 8'h20 && normal.data <= 8'h7e &&
              normal.valid == 1'b0 && normal.ready == 1'b1))
            $fatal(1, "CONSTRAINT_FAIL IDLE");
        apply_and_check(normal, "RANDOM_IDLE");

        // (추가) 상속된 제약은 데이터 범위를 유지하고 정지를 강제한다.
        if (stalled.randomize() == 0) $fatal(1, "RANDOMIZE_FAIL STALL");
        if (!(stalled.data >= 8'h20 && stalled.data <= 8'h7e &&
              stalled.valid == 1'b1 && stalled.ready == 1'b0))
            $fatal(1, "CONSTRAINT_FAIL STALL");
        apply_and_check(stalled, "RANDOM_STALL");

        // (추가) 부모 타입 인자로 자식 객체를 전달해 공통 검사 태스크를 재사용한다.
        apply_and_check(stalled, "POLYMORPHIC_STALL");
        if (checked != 4) $fatal(1, "COUNT_FAIL %0d", checked);
        $display("CH08 PASS: %0d cases checked", checked);
        $finish;
    end

    initial begin
        #100;
        $fatal(1, "CH08 TIMEOUT");
    end
endmodule
