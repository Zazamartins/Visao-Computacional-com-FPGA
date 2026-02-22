module framebuffer (
    // ----------------ESCRITA: OV2640----------------------------------------------
    input  wire        wr_clk,          // Clock de escrita dclk da OV2640
    input  wire        wr_en,           // alto quando se pode escrever 
    input  wire [16:0] wr_addr,         // Endereço de onde vamos escrever
    input  wire [15:0] wr_data,         // 2 bytes de dados

    // --------------------LEITURA: VGA--------------------------------------------
    input  wire        rd_clk,          // 25 MHz da FPGA   
    input  wire        rd_en,           // alto quando se pode escrever  
    input  wire [16:0] rd_addr,         // Endereço onde vamos ler  
    output reg  [15:0] rd_data          // Saída com o dado lido  
);
    
    // N° de pixels que é 320 X 240
    localparam NUM_PIXELS = 76800;

    // ----------------------MEMÓRIA RAM---------------------------------------------
    (* ram_style = "block" *)
    reg [15:0] mem [0:NUM_PIXELS-1];       // CADA POSIÇÃO DE MEMÓRIA É UM PIXEL RGB565 = 2 BYTES DE MEMÓRIA

    // --------------------LÓGICA ESCRITA DA CÂMERA ----------------------------------------
    always @(posedge wr_clk) 
        begin
            if (wr_en) 
                mem[wr_addr] <= wr_data;
        end

    // ------------------------LÓGICA LEITURA DO VGA----------------------------------------
    reg [15:0] mem_read_internal;           // ARMAZENA O DADO LIDO
    always @(posedge rd_clk) 
        begin
            if (rd_en) 
                begin
                    mem_read_internal <= mem[rd_addr];
                    rd_data           <= mem_read_internal;
                end
        end
endmodule