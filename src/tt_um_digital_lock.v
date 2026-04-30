/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_digital_lock (
    input  [7:0] ui_in,
    output [7:0] uo_out,
    input  [7:0] uio_in,
    output [7:0] uio_out,
    output [7:0] uio_oe,
    input        ena,
    input        clk,
    input        rst_n
);

    wire unlock;
    wire error;
    wire locked;
    wire [1:0] attempts_unused;
    wire [2:0] state_dbg_unused;

    digital_lock u_lock (
        .clk(clk),
        .rst_n(rst_n),
        .clear(ui_in[3]),
        .enter(ui_in[2]),
        .code_in(ui_in[1:0]),
        .unlock(unlock),
        .error(error),
        .locked(locked),
        .attempts(attempts_unused),
        .state_dbg(state_dbg_unused)
    );

    assign uo_out = {5'b00000, locked, error, unlock};

    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;

    wire _unused = &{ena, uio_in, ui_in[7:4]};

endmodule
