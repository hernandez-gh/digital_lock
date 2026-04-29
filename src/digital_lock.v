`default_nettype none

module digital_lock (
    input        clk,
    input        rst_n,
    input        clear,
    input        enter,
    input  [1:0] code_in,
    output       unlock,
    output reg   error,
    output       locked,
    output [1:0] attempts,
    output [2:0] state_dbg
);

    reg [2:0] state;
    reg [1:0] attempts_reg;
    reg       enter_d;
    reg [23:0] error_timer;

    localparam ERROR_TIME = 24'd12000000;

    localparam S0        = 3'd0;
    localparam S1        = 3'd1;
    localparam S2        = 3'd2;
    localparam S3        = 3'd3;
    localparam UNLOCKED  = 3'd4;
    localparam LOCKED_ST = 3'd5;

    wire enter_pulse = enter & ~enter_d;

    assign attempts  = attempts_reg;
    assign state_dbg = state;
    assign unlock    = (state == UNLOCKED);
    assign locked    = (state == LOCKED_ST);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state        <= S0;
            attempts_reg <= 2'd0;
            enter_d      <= 1'b0;
            error        <= 1'b0;
            error_timer  <= 24'd0;
        end else begin
            enter_d <= enter;
            if (error_timer != 24'd0) begin
                error_timer <= error_timer - 24'd1;
                error       <= 1'b1;
            end else begin
                error   <= 1'b0;
            end
            
            if (clear) begin
                state        <= S0;
                attempts_reg <= 2'd0;
                error        <= 1'b0;
                error_timer  <= 24'd0;
            end else if (enter_pulse) begin
                case (state)
                    S0: begin
                        if (code_in == 2'b01)
                            state <= S1;
                        else begin
                            error       <= 1'b1;
                            error_timer <= ERROR_TIME;
                            if (attempts_reg == 2'd2)
                                state <= LOCKED_ST;
                            else begin
                                attempts_reg <= attempts_reg + 2'd1;
                                state <= S0;
                            end
                        end
                    end

                    S1: begin
                        if (code_in == 2'b10)
                            state <= S2;
                        else begin
                            error       <= 1'b1;
                            error_timer <= ERROR_TIME;
                            if (attempts_reg == 2'd2)
                                state <= LOCKED_ST;
                            else begin
                                attempts_reg <= attempts_reg + 2'd1;
                                state <= S0;
                            end
                        end
                    end

                    S2: begin
                        if (code_in == 2'b11)
                            state <= S3;
                        else begin
                            error       <= 1'b1;
                            error_timer <= ERROR_TIME;
                            if (attempts_reg == 2'd2)
                                state <= LOCKED_ST;
                            else begin
                                attempts_reg <= attempts_reg + 2'd1;
                                state <= S0;
                            end
                        end
                    end

                    S3: begin
                        if (code_in == 2'b00)
                            state <= UNLOCKED;
                        else begin
                            error       <= 1'b1;
                            error_timer <= ERROR_TIME;
                            if (attempts_reg == 2'd2)
                                state <= LOCKED_ST;
                            else begin
                                attempts_reg <= attempts_reg + 2'd1;
                                state <= S0;
                            end
                        end
                    end

                    UNLOCKED: begin
                        state <= UNLOCKED;
                    end

                    LOCKED_ST: begin
                        state <= LOCKED_ST;
                    end

                    default: begin
                        state        <= S0;
                        attempts_reg <= 2'd0;
                    end
                endcase
            end
        end
    end

endmodule
