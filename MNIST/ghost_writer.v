module ghost_writer (
    input wire clk, input wire rst_n,
    output reg [9:0] wr_addr, output reg wr_data, output reg wr_en
);
    reg [9:0] counter;
    always @(posedge clk) begin
        if (!rst_n) begin
            counter <= 0; wr_en <= 0;
        end else begin
            wr_en <= 1; 
            wr_addr <= counter;
            
            // Pinta os primeiros 392 pixels (METADE DE CIMA) com 1
            // Pinta o resto com 0
            if (counter < 392) wr_data <= 1'b1;
            else wr_data <= 1'b0;

            if (counter == 783) counter <= 0;
            else counter <= counter + 1;
        end
    end
endmodule