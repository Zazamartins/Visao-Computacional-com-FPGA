module top_module(
    // ---------------------ENTRADAS GERAL FPGA--------------------------------------
    input wire clk,            // Clock principal (25MHz ou 27MHz, depende da placa)
    input wire rst_n,          // Botão de reset

    // -----------------------------OV2640---------------------------------------
    input wire dclk,           
    input wire href,           
    input wire vsync,          
    input wire [7:0] data,     
    output wire scio_c,        
    inout  wire scio_d,        
    output wire reset,         
    output wire pwdn,          

    // -----------------------VGA----------------------------------------------------
    output wire        VGAHS,
    output wire        VGAVS,
    output wire [2:0]  VGA_R,
    output wire [2:0]  VGA_G,
    output wire [2:0]  VGA_B
);

    // ---------------------CÂMERA OV2640-------------------------------------------
    camera_top u_camera_top (
        // FPGA
        .clk    (clk),
        .rst_n  (rst_n),

        // ENTRADA OV2640
        .dclk   (dclk),
        .href   (href),
        .vsync  (vsync),
        .data   (data),

        // SAIDA OV2640
        .scio_c (scio_c),
        .scio_d (scio_d),
        .reset  (reset),
        .pwdn   (pwdn),

        // SAIDA VGA
        .VGAHS  (VGAHS),
        .VGAVS  (VGAVS),
        .VGA_R  (VGA_R),
        .VGA_G  (VGA_G),
        .VGA_B  (VGA_B)
    );

endmodule