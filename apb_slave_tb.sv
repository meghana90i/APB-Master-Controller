module apb_add_master (
    input  logic        pclk,
    input  logic        preset_n,
    input  logic [1:0]  add_i,

    output logic        psel_o,
    output logic        penable_o,
    output logic [31:0] paddr_o,
    output logic        pwrite_o,
    output logic [31:0] pwdata_o,

    input  logic [31:0] prdata_i,
    input  logic        pready_i
);

typedef enum logic [1:0] {
    ST_IDLE,
    ST_SETUP,
    ST_ACCESS
} state_t;

state_t state_q, state_n;

logic pwrite_q;
logic [31:0] rdata_q;

always_ff @(posedge pclk or negedge preset_n) begin
    if (!preset_n) begin
        state_q  <= ST_IDLE;
        pwrite_q <= 0;
        rdata_q  <= 0;
    end
    else begin
        state_q <= state_n;

        if (state_q == ST_IDLE && add_i != 2'b00)
            pwrite_q <= add_i[1];

        if (state_q == ST_ACCESS && pready_i && !pwrite_q)
            rdata_q <= prdata_i;
    end
end

always_comb begin
    state_n = state_q;

    case(state_q)
        ST_IDLE:
            if(add_i != 2'b00)
                state_n = ST_SETUP;

        ST_SETUP:
            state_n = ST_ACCESS;

        ST_ACCESS:
            if(pready_i)
                state_n = ST_IDLE;
    endcase
end

assign psel_o    = (state_q == ST_SETUP) || (state_q == ST_ACCESS);
assign penable_o = (state_q == ST_ACCESS);

assign pwrite_o = pwrite_q;
assign paddr_o  = 32'hA000;
assign pwdata_o = rdata_q + 1;

endmodule