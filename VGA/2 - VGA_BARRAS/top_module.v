module top_module (

    input  wire clk,                // 25.000 MHz da placa
    input  wire rst_n,              // reset ativo-baixo
    output wire VGAHS,              // Sinal sincronismo HORIZONTAL
    output wire VGAVS,              // Sinal sincronismo VERTICAL
    output reg [2:0] VGA_R,        // Sinal 3 Bits VERMELHO
    output reg [2:0] VGA_G,        // Sinal 3 bits VERDE
    output reg [2:0] VGA_B         // Sinal 3 Bits AZUL
);

    // FIOS PARA POSIÇÃO DO PIXEL e DATA ENABLE
    wire [9:0] x, y;
    wire data_enable;

    vga_control VGA_CONTROL (
        .vga_clk(clk),
        .rst_n(rst_n),
        .x_pixel(x),
        .y_pixel(y),
        .VGAHS(VGAHS),
        .VGAVS(VGAVS),
        .data_enable(data_enable)
    );

    // SIMULAÇÃO COR AZUL
    always @(*)
        begin
            if (data_enable)
                begin
                    // -------------------8 barras de 80 pixels (640 / 8 = 80) -------------------
                    // Barra 1: Branco (x de 0 a 79)
                    if (x < 80) 
                    begin
                        VGA_R = 3'b111;
                        VGA_G = 3'b111;
                        VGA_B = 3'b111;
                    end
                    // Barra 2: Amarelo (x de 80 a 159)
                    else if (x < 160) 
                    begin
                        VGA_R = 3'b111;
                        VGA_G = 3'b111;
                        VGA_B = 3'b000;
                    end
                    // Barra 3: Ciano (x de 160 a 239)
                    else if (x < 240) 
                    begin
                        VGA_R = 3'b000;
                        VGA_G = 3'b111;
                        VGA_B = 3'b111;
                    end
                    // Barra 4: Verde (x de 240 a 319)
                    else if (x < 320) 
                    begin
                        VGA_R = 3'b000;
                        VGA_G = 3'b111;
                        VGA_B = 3'b000;
                    end
                    // Barra 5: Magenta (x de 320 a 399)
                    else if (x < 400) 
                    begin
                        VGA_R = 3'b111;
                        VGA_G = 3'b000;
                        VGA_B = 3'b111;
                    end
                    // Barra 6: Vermelho (x de 400 a 479)
                    else if (x < 480) 
                    begin
                        VGA_R = 3'b111;
                        VGA_G = 3'b000;
                        VGA_B = 3'b000;
                    end
                    // Barra 7: Azul (x de 480 a 559)
                    else if (x < 560) 
                    begin
                        VGA_R = 3'b000;
                        VGA_G = 3'b000;
                        VGA_B = 3'b111;
                    end
                    // Barra 8: Preto (x de 560 a 639)
                    else 
                    begin
                        VGA_R = 3'b000;
                        VGA_G = 3'b000;
                        VGA_B = 3'b000;
                    end
                end
                
            else
                begin
                    VGA_R = 3'b000;
                    VGA_G = 3'b000;
                    VGA_B = 3'b000;
                end
        end

endmodule