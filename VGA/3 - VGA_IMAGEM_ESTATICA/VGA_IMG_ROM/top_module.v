module top_module(

    // ------------------------ENTRADAS-----------------------------------
    input wire clk,                              // 25 MHz FPGA
    input wire rst_n,                            // reset ativo_baixo
    
    // -----------------------SAÍDAS--------------------------------------
    output wire VGAHS,                          // Sinal sincronismo HORIZONTAL
    output wire VGAVS,                          // Sinal sincronismo VERTICAL
    output wire [2:0] VGA_R,                    // Sinal 3 bits VERMELHO
    output wire [2:0] VGA_G,                    // Sinal 3 bits VERDE
    output wire [2:0] VGA_B                     // Sinal 3 bits AZUL
);

    // ----------------- VGA_CONTROL--------------------------------------
    wire [9:0] x_pixel;                        // Posição X pixel
    wire [9:0] y_pixel;                        // Posição y pixel
    wire VGAHS_in;                    
    wire VGAVS_in;
    wire data_enable;

    vga_control VGA_CONTROL (
        .vga_clk(clk),
        .rst_n(rst_n),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .VGAHS(VGAHS_in),
        .VGAVS(VGAVS_in),
        .data_enable(data_enable)
    );

    // ----------------------- VGA_IMG_ROM -------------------------------------
    vga_img_rom VGA_IMG_ROM (
        .vga_clk(clk),
        .rst_n(rst_n),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .data_enable(data_enable),
        .VGAHS_in(VGAHS_in),
        .VGAVS_in(VGAVS_in),
        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B),
        .VGAHS(VGAHS),
        .VGAVS(VGAVS)
    );


endmodule