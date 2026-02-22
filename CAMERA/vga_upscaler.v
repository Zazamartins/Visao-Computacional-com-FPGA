module vga_upscaler (
    input  wire        vga_clk,         // clock do VGA, FPGA 25 MHz
    input  wire        rst_n,           // Botão de reset ativo-baixo

    // Sinais do VGA Control
    input  wire [9:0]  x_pixel,         // 0..639
    input  wire [9:0]  y_pixel,         // 0..479
    input  wire        data_enable,     // alto se pronto para leitura 
    input  wire        VGAHS_in,        // Sinal de sincronismo HORIZONTAL
    input  wire        VGAVS_in,        // Siinal de sincronismo VERTICAL

    // SINAIS PARA MEMÓRIA
    output reg         fb_rd_en,        // alto se pode ler 
    output reg  [16:0] fb_rd_addr,      // endereço leitura
    input  wire [15:0] fb_pixel,        // dado do pixel lido

    // ----------------------------SAÍDAS PARA O VGA PS2 BOARD ----------------------------------------
    output reg [2:0]  VGA_R,            // 3 BITS VERMELHO
    output reg [2:0]  VGA_G,            // 3 BITS VERDE
    output reg [2:0]  VGA_B,            // 3 BITS AZUL
    output reg        VGAHS,            // SINAL DE SINCRONIA HORIZONTAL
    output reg        VGAVS             // SINAL DE SINCRONIA VERTICAL
);

    // LARGURA IMAGEM CAPTURADA NA CÂMERA OV2640
    localparam LARGURA_ORIGEM = 320;

    // -----------------PIPELINE DE SINCRONIA (CHAVE DO FUNCIONAMENTO)--------------------------------
    // Shift Registers de 4 estágios (bits 0, 1, 2, 3).
    // Servem para atrasar os sinais de controle para compensar a demora da memória RAM.
    reg [3:0] pipe_hs;                  // SINAL SINCRONIA HORIZONTAL
    reg [3:0] pipe_vs;                  // SINAL SINCRONIA VERTICAL
    reg [3:0] pipe_de;                  // ALTA PARA DATA  ENABLE
    reg [15:0] delay_pixel;             // 2 BYTES DE INFORMAÇÃO DO PIXEL
    
    // PARA O LAÇO
    integer i;

    always @(posedge vga_clk) 
        begin
            if (!rst_n) 
                begin
                    pipe_hs <= 4'b1111;
                    pipe_vs <= 4'b1111; 
                    pipe_de <= 0;
                    fb_rd_en <= 0; 
                    fb_rd_addr <= 0;
                    VGA_R <= 0; 
                    VGA_G <= 0; 
                    VGA_B <= 0;
                    VGAHS <= 1; 
                    VGAVS <= 1;
                end 
            else 
                begin
                
                // --- CÁLCULO DE ENDEREÇO COM ZOOM 2X ---
                if (data_enable) 
                    begin
                        // HABILITA LEITURA
                        fb_rd_en <= 1'b1;     
                        // UPSCALE: Shift Right (>>1) é divisão por 2
                        // Endereço = (X / 2) + ( (Y / 2) * 320 )
                        fb_rd_addr <= x_pixel[9:1] + (y_pixel[9:1] * LARGURA_ORIGEM);
                        // Avisa o pipeline que teremos pixel
                        pipe_de[0] <= 1'b1;
                    end 
                    else 
                        begin
                            fb_rd_en   <= 1'b0;
                            pipe_de[0] <= 1'b0; 
                         end

                // --- PIPELINE DE SINCRONIA (Igual ao anterior) ---
                pipe_hs[0] <= VGAHS_in;
                pipe_vs[0] <= VGAVS_in;

                for(i=0; i<3; i=i+1) begin
                    pipe_hs[i+1] <= pipe_hs[i];
                    pipe_vs[i+1] <= pipe_vs[i];
                    pipe_de[i+1] <= pipe_de[i];
                end

                // Recebe o dado da RAM
                delay_pixel <= fb_pixel;

                // Saída para os pinos
                VGAHS <= pipe_hs[3];
                VGAVS <= pipe_vs[3];

                if (pipe_de[3]) begin
                    // Exibe RGB565 (16 bits) convertido para 3 bits por cor
                    VGA_R <= delay_pixel[15:13]; 
                    VGA_G <= delay_pixel[10:8];  
                    VGA_B <= delay_pixel[4:2];   
                end else begin
                    VGA_R <= 3'b000;
                    VGA_G <= 3'b000;
                    VGA_B <= 3'b000;
                end
            end
        end
endmodule