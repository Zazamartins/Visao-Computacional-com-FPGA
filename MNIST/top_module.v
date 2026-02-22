module top_module(
    // ---------------------ENTRADAS GERAL FPGA--------------------------------------
    input wire clk,            // Clock principal
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
    output wire [2:0]  VGA_B,

    // -----------------------LEDS DEBUG--------------------------------------------
    output wire [3:0] leds,      // Seus 4 LEDs

    // -----------------------NOVO: DISPLAY 7 SEGMENTOS-----------------------------
    // ATENÇÃO: Isso aqui que faltava! Sem isso o LPF não acha os pinos.
    output wire [7:0] segment_pins 
);

    // ---------------------CÂMERA OV2640 + IA-------------------------------------------
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
        .VGA_B  (VGA_B),
        
        // SAÍDA LEDS (Corrigido para .leds conforme o último camera_top)
        .leds (leds),

        // SAÍDA DISPLAY (A conexão nova!)
        .segment_pins (segment_pins)
    );

endmodule