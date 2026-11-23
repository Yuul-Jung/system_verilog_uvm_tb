// 제06장: 기대값의 자료형을 재사용 가능한 패키지에 모은다.
// 이 파일은 검증용이며 합성 대상 DUT에 포함하지 않는다.
package uart_expect_pkg;
    // packed: valid, ready, data를 하나의 10비트 값으로 묶는다.
    typedef struct packed {
        logic       valid;
        logic       ready;
        logic [7:0] data;
    } uart_sample_t;

    // 검증 결과 기록용 2상태 열거형.
    typedef enum bit [1:0] {
        CASE_IDLE  = 2'd0,
        CASE_SEND  = 2'd1,
        CASE_STALL = 2'd2,
        CASE_RESUME = 2'd3
    } case_kind_t;
endpackage
