module uart_TXD (
    input clk,
    input rst,
    input en,
    input [7:0] data,
    output reg tx
);
    reg [3:0] state;
    parameter IDLE = 4'b0001;
    parameter START = 4'b0010;
    parameter DATA = 4'b0100;
    parameter STOP = 4'b1000;

    parameter bps = 9600;
    parameter CLK_F = 12_000_000;
    parameter CLK = CLK_F / bps; //时钟

    reg [15:0] count;
    reg [7:0] fifo [0:7];
    reg [15:0] in_ptr;
    reg [15:0] out_ptr;
    reg [15:0] count_fifo;

    initial begin
        state <= IDLE;
        in_ptr <= 0;
        out_ptr <= 0;
        count_fifo <= 0;
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            state <= IDLE;
            in_ptr <= 0;
            out_ptr <= 0;
            count_fifo <= 0;
        end else begin
            state <= state;
        end
    end//复位

    always @(posedge clk) begin
        case(state)
            IDLE: begin
                if ((en == 1) && (count_fifo > 0)) begin
                    tx <= 0;
                    count <= CLK - 1;
                    state <= START;
                end
            end

            START: begin
                tx <= 1;
                if (count == 0) begin
                    count <= CLK - 1;
                    state <= DATA;
                end else begin
                    count <= count - 1;
                end
            end

            DATA: begin
                tx <= fifo[out_ptr];
                if (count == 0) begin
                    count <= CLK - 1;
                    out_ptr <= out_ptr + 1;
                    count_fifo <= count_fifo - 1;
                    if (count_fifo == 0) begin
                        state <= STOP;
                    end else begin
                        state <= DATA;
                    end
                end else begin
                    count <= count - 1;
                end
            end

            STOP: begin
                tx <= 0;
                if (count == 0) begin
                    count <= CLK - 1;
                    state <= IDLE;
                    en <= 0; //结束，使能归0
                end else begin
                    count <= count - 1;
                end
            end

            default: begin
                state <= IDLE;
                en <= 0;
            end
        endcase
    end

    always @(posedge clk) begin
        if (!rst) begin
            in_ptr <= 0;
            out_ptr <= 0;
            count_fifo <= 0;
        end else if (count_fifo < 8) begin
            fifo[in_ptr] <= data;
            in_ptr <= in_ptr + 1;
            count_fifo <= count_fifo + 1;
        end
    end
endmodule
