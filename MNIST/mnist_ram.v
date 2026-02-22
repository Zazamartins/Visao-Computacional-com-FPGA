module mnist_ram (
    // Porta A: Escrita (Câmera)
    input wire wr_clk,
    input wire [9:0] wr_addr,
    input wire       wr_data,
    input wire       wr_en,
    
    // Porta B: Leitura (IA / FPGA)
    input wire rd_clk,
    input wire [9:0] rd_addr,
    output reg       rd_data
);

    // Memória Block RAM (Inferida)
    reg memory [0:1023]; 

    // Processo de Escrita
    always @(posedge wr_clk) begin
        if (wr_en) begin
            memory[wr_addr] <= wr_data;
        end
    end

    // Processo de Leitura
    always @(posedge rd_clk) begin
        rd_data <= memory[rd_addr];
    end

endmodule