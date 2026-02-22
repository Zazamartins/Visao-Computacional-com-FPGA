module vga_img_rom(
    // ----------------------------ENTRADAS-----------------------------------
    input wire vga_clk,
    input wire rst_n,
    // --------DO VGA_CONTROL--------------------------------------------------
    input wire [9:0] x_pixel,            // Posição x pixel
    input wire [9:0] y_pixel,            // Posição y pixel
    input wire data_enable,              // Alto quando área ativaa
    input wire VGAHS_in,                 // Sinal sincronismo horizontal
    input wire VGAVS_in,                 // Sinal sincronismo vertical

    // -----------------------------SAÍDAS-------------------------------------
    output reg [2:0] VGA_R,
    output reg [2:0] VGA_G,
    output reg [2:0] VGA_B,
    output reg VGAHS,
    output reg VGAVS
);

    // ---------------------PARÂMETROS VGA / IMAGEM ROM---------------------------
    // -------RESOLUÇÃO VGA------------
    parameter HORIZONTAL_ATIVA = 640;
    parameter VERTICAL_ATIVA = 480;
    // -------RESOLUÇÃO IMAGEM--------
    parameter HORIZONTAL_IMAGEM = 320;
    parameter VERTICAL_IMAGEM = 240;
    // -------NOME ARQUIVO ROM .HEX----
    parameter IMAGEM_HEX = "imagem_rgb332_320x240.hex";

    // ----------------------- ROM IMAGEM --------------------------------------
    localparam QTD_PIXEL_IMAGEM = HORIZONTAL_IMAGEM * VERTICAL_IMAGEM;       // Quantidade de pixel da imagem
    reg [7:0] pixel_imagem [0:QTD_PIXEL_IMAGEM -1]; // CADA POSIÇÃO REPRESENTA UM PIXEL DA IMAGEM, A POSIÇÃO É UM REG DE 1BYTE NO PADRÃO RGB332
    // INSTÂNCIANDO ROM NA COMPILAÇÃO DO PROGRAMA
    initial begin
        $readmemh(IMAGEM_HEX, pixel_imagem);
    end
    // PIXEL(0,0) = PIXEL_IMAGEM[0], PIXEL(1,0) PIXEL_IMAGEM[1] ... PIXEL(319,0) = PIXEL_IMAGEM[319], PIXEL(0,1) = PIXEL_IMAGEM[320]


    // ---------------------UPSCALE 320X240 -> 640X480---------------------------
    // 1 PIXEL IMAGEM -> BLOCO 2X2 VGA; PIXEL(0,0) -> PIXELS VGA(0,0), (1,0), (0,1) (1,1)
    // RECEBE AS POSIÇÕES PIXELS DA VGA (X,Y), (X+1,Y), (X,Y+1), (X+1,Y+1), divide por 2 (right_shift >> 1) e o resultado é o pixel (X/2, Y/2) IMAGEM
    wire [8:0] x_pixel_imagem;          // POSIÇÃO X PIXEL IMAGEM
    wire [8:0] y_pixel_imagem;          // POSIÇÃO Y PIXLE IMAGEM (X,Y)
    assign x_pixel_imagem = x_pixel >> 1;
    assign y_pixel_imagem = y_pixel >> 1;

    // ---------------------CÁLCULO ENDEREÇO DO PIXEL NA ROM .HEX--------------------
    // PIXEL(0,0) = PIXEL_IMAGEM[0], PIXEL(1,0) PIXEL_IMAGEM[1] ... PIXEL(319,0) = PIXEL_IMAGEM[319], PIXEL(0,1) = PIXEL_IMAGEM[320]
    // ENDEREÇO DO PIXEL NA ROM
    wire [($clog2(QTD_PIXEL_IMAGEM)) -1:0] endereco_pixel_rom;
    // PIXEL(X,Y) = PIXEL_IMAGEM[X + Y*HORIZONTAL_IMAGEM]
    // NOTA: HORIZONTAL_IMAGEM = 320 = 256 + 64, AO INVES DE MULTIPLICAR POR 320 (CUSTO) PODEMOS FAZER
    // Y*HORIZONTAL_IMAGEM = Y*320= Y*256 + Y*64 = Y*(2^8) + Y*(2^6) = (Y<<8) + (Y<<6)
    assign endereco_pixel_rom = ({y_pixel_imagem, 8'd0}) + ({y_pixel_imagem, 6'd0}) + x_pixel_imagem;

    // --------------------------DELAY 1 CICLO PARA LEITURA DO ENDEREÇO -> LEITURA ROM (LATÊNCIA)----------------
    reg delay_data_enable;                     // SINAL ÁREA ATIVA DELAY
    reg [7:0] delay_1byte_pixel_rom;           // 1 BYTE COM RGB DO PIXEL LIDO: [7:5] = R, [4:2] = G, [1:0] = B;
    reg delay_VGAHS;                           // Sinal sincronismo HORIZONTAL DELAY
    reg delay_VGAVS;                           // Sinal sincronismo VERTICAL DELAY

    // -------------------MAPEAMENTO COR AZUL 2BITS(PIXEL_IMAGEM) -> 3BITS(VGA_PS2_BOARD)
    wire [2:0] mapeamento_azul = 
        (delay_1byte_pixel_rom[1:0] == 2'b00) ? 3'b000 :
        (delay_1byte_pixel_rom[1:0] == 2'b01) ? 3'b011 :
        (delay_1byte_pixel_rom[1:0] == 2'b10) ? 3'b101 :
                                                3'b111;
    
    // ---------------------------------LÓGICA FINAL-------------------------------------------
    always @(posedge vga_clk)
        begin
            if (!rst_n)
                begin
                    VGA_R <= 3'b000;
                    VGA_G <= 3'b000;
                    VGA_B <= 3'b000;
                    VGAHS <= 1'b1;
                    VGAVS <= 1'b1;
                    // DELAYS
                    delay_data_enable <= 1'b0;
                    delay_1byte_pixel_rom <= 8'b0000_0000;
                    delay_VGAHS <= 1'b1;
                    delay_VGAVS <= 1'b1;
                end
            
            else
                begin
                    // ------------------ LEITURA ROM ----------------
                    if (data_enable)
                        begin
                            delay_1byte_pixel_rom <= pixel_imagem[endereco_pixel_rom];
                        end
                    else
                    // SE NÃO ATIVO, CONTINUA MESMO PIXEL
                        begin
                            delay_1byte_pixel_rom <= delay_1byte_pixel_rom;
                        end
                

                // ----------------FLIP-FLOPS PARA COMPENSAR DELAY ROM---------------
                delay_data_enable <= data_enable;
                delay_VGAHS <= VGAHS_in;
                delay_VGAVS <= VGAVS_in;
                // ATUALIZA SINAIS DE SAÍDA PELOS FLIP-FLOPS DE DELAY
                VGAHS <= delay_VGAHS;
                VGAVS <= delay_VGAVS;

                // ------------------- SAÍDA DO RGB ---------------------------
                if (delay_data_enable)
                    begin
                        VGA_R <= delay_1byte_pixel_rom[7:5];        // 3 BITS R
                        VGA_G <= delay_1byte_pixel_rom[4:2];        // 3 BITS G
                        VGA_B <= mapeamento_azul;                   // 2 BITS B MAPEAMENTO
                    end
                else
                    begin
                        VGA_R <= 3'b000;        
                        VGA_G <= 3'b000;       
                        VGA_B <= 3'b000;                           
                    end
                end
        end

endmodule