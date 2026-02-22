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
                    VGA_R = 3'b000;
                    VGA_G = 3'b000;
                    VGA_B = 3'b111;
                end
            else
                begin
                    VGA_R = 3'b000;
                    VGA_G = 3'b000;
                    VGA_B = 3'b000;
                end
        end

endmodule