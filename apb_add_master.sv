`timescale 1ns/1ps

module apb_slave_tb;

logic        pclk;
logic        preset_n;
logic [1:0]  add_i;

logic        psel_o;
logic        penable_o;
logic        pwrite_o;
logic [31:0] paddr_o;
logic [31:0] pwdata_o;

logic [31:0] prdata_i;
logic        pready_i;

apb_add_master dut (
    .pclk(pclk),
    .preset_n(preset_n),
    .add_i(add_i),
    .psel_o(psel_o),
    .penable_o(penable_o),
    .paddr_o(paddr_o),
    .pwrite_o(pwrite_o),
    .pwdata_o(pwdata_o),
    .prdata_i(prdata_i),
    .pready_i(pready_i)
);

initial pclk = 0;
always #5 pclk = ~pclk;

initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, apb_slave_tb);

    preset_n = 0;
    add_i    = 0;
    prdata_i = 0;
    pready_i = 0;

    #20;
    preset_n = 1;

    // READ transaction
    @(posedge pclk);
    add_i = 2'b01;

    @(posedge pclk);
    add_i = 2'b00;

    repeat(5) @(posedge pclk);

    // WRITE transaction
    @(posedge pclk);
    add_i = 2'b11;

    @(posedge pclk);
    add_i = 2'b00;

    repeat(5) @(posedge pclk);

    $finish;
end

always_ff @(posedge pclk or negedge preset_n) begin
    if(!preset_n) begin
        pready_i <= 0;
        prdata_i <= 0;
    end
    else begin
        if(psel_o && penable_o) begin
            pready_i <= 1;
            prdata_i <= 32'h5;
        end
        else begin
            pready_i <= 0;
        end
    end
end

always @(posedge pclk) begin
    $display("T=%0t state: psel=%b penable=%b pwrite=%b pready=%b",
              $time, psel_o, penable_o, pwrite_o, pready_i);

    if(psel_o && penable_o && pready_i) begin
        if(pwrite_o)
            $display("WRITE Addr=%h Data=%h", paddr_o, pwdata_o);
        else
            $display("READ  Addr=%h Data=%h", paddr_o, prdata_i);
    end
end

endmodule