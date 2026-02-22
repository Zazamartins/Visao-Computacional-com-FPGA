module top_module(
    input wire clk,                     // CLOCK FPGA 25 MHz
    input wire rst_n,                   // Botão Físico reset baixo
    
    // ------------------------- OV2640 -------------------------------------
    input wire dclk,                    // CLOCK DA CAM
    input wire href,                    // ALTO SE LINHA VÁLIDA
    input wire vsync,                   // ALTO SE QUADRO VÁLIDO
    input wire [7:0] data,              // Dado de 1 byte
    
    // --------- PROTOCOL SCCB/I2C DA CÂMERA
    output wire scio_c,                 // SCL
    inout  wire scio_d,                 // SDA
    output wire reset,                  // RESET DA CAM
    output wire pwdn,                   // POWER DOWN DA CÂMERA

    // ------------------------VGA-----------------------------------
    output wire VGAHS,                  // Sinal Sincronismo horizontal
    output wire VGAVS,                  // Sinal sincronismo vertical
    output wire [2:0] VGA_R,            // 3 bits R
    output wire [2:0] VGA_G,            // 3 bits G
    output wire [2:0] VGA_B,            // 3 bits B
    
    // ------------------- LEDS PARA DEBUG --------------------------
    output wire led_vermelho,           // Alto se tem a cor
    output wire led_verde,              // Alto se está contando pixels válidos
    output wire led_azul                // Alto se achou objeto
);

    // ----------------- CONEXÕES OV2640 -> RAM ------------------------------
    wire [15:0] cam_pixel;              // PIXEL MONTADO DE 2 BYTES
    wire cam_wr_en;                     // ENABLE DE ESCRITA NA RAM
    wire [16:0] cam_addr;               // ENDEREÇO DE ESCRITA
    
    // ----------------- CONEXÕES RAM -> VGA -----------------------------
    wire [16:0] fb_rd_addr;             // ENDEREÇO LEITURA         
    wire [15:0] fb_pixel;               // PIXEL LIDO RAM
    wire fb_rd_en;                      // ENABLE DE LEITURA

    // ------------------- CONTROLE VGA -----------------------
    wire [9:0]  vga_x, vga_y;           // COORDENADAS DA TELA/MONITOR
    wire vga_de, vga_hs_in, vga_vs_in;  // ÁREA VISÍVEL E SINCRONISMOS
    
    // ------------------- DADOS DO RASTREADOR -------------------
    wire [9:0]  track_x, track_y;       // COORDENADAS DO CENTRO DO OBJETO
    wire track_valid;                   // OBJETO DETECTADO OU NÃO
    wire [9:0] track_w, track_h;        // TAMANHO DO OBJETO


    // ----------------------- FILTRO DA COR DE INTERESSE ---------------------------------------
    wire [4:0] tr_min = 5'd12; wire [4:0] tr_max = 5'd31;       // VERMLHO MÉDIO PARA CIMA ORIGINAL [15:31]
    wire [5:0] tg_min = 6'd00; wire [5:0] tg_max = 6'd10;       // POUCO VERDE
    wire [4:0] tb_min = 5'd00; wire [4:0] tb_max = 5'd10;       // POUCO AZUL



    // --------------- INSTÂNCIA DOS MÓDULOS ----------------------------------
    // --------- 1 INICIALIZAÇÃO DA OV2640 ---------------
    camera_init u_init (
        .clk(clk), 
        .rst_n(rst_n), 
        .scio_c(scio_c), 
        .scio_d(scio_d), 
        .reset(reset), 
        .pwdn(pwdn)
    );

    // --------- 2 CAPTURA DA IMAGEM ----------
    camera_get_pic u_capture (
        .dclk(dclk), 
        .href(href), 
        .vsync(vsync), 
        .data_in(data), 
        .data_out(cam_pixel), 
        .wr_en(cam_wr_en), 
        .out_addr(cam_addr)
    );

    // -------- 3 VISÃO COMPUTACIONAL (HUHU) -----
    color_tracker u_tracker (
        .clk(dclk), 
        .rst_n(rst_n), 
        .vsync(vsync), 
        .href(href), 
        .valid_pixel(cam_wr_en), 
        .pixel_data(cam_pixel),
        .target_r_min(tr_min), 
        .target_r_max(tr_max),
        .target_g_min(tg_min), 
        .target_g_max(tg_max),
        .target_b_min(tb_min), 
        .target_b_max(tb_max),
        .obj_x(track_x), 
        .obj_y(track_y), 
        .obj_detected(track_valid),
        .obj_half_w(track_w), 
        .obj_half_h(track_h),
        .led_debug_r(led_vermelho), 
        .led_debug_g(led_verde), 
        .led_debug_b(led_azul)
    );

    // ------- 4 MEMÓRIA RAM/FRAMEBUFFER --------
    framebuffer u_ram (
        .wr_clk(dclk), 
        .wr_en(cam_wr_en), 
        .wr_addr(cam_addr), 
        .wr_data(cam_pixel),
        .rd_clk(clk),  
        .rd_en(fb_rd_en),  
        .rd_addr(fb_rd_addr), 
        .rd_data(fb_pixel)
    );

    // ----------- 5 VGA -------------------
    vga_control u_vga_ctrl (
        .vga_clk(clk), 
        .rst_n(rst_n), 
        .x_pixel(vga_x), 
        .y_pixel(vga_y), 
        .VGAHS(vga_hs_in), 
        .VGAVS(vga_vs_in), 
        .data_enable(vga_de)
    );

    // ----------- 6 UPSCALER ----------------
    vga_upscaler u_vga_up (
        .vga_clk(clk), 
        .rst_n(rst_n),
        .x_pixel(vga_x), 
        .y_pixel(vga_y), 
        .data_enable(vga_de),
        .VGAHS_in(vga_hs_in), 
        .VGAVS_in(vga_vs_in),
        .fb_rd_en(fb_rd_en), 
        .fb_rd_addr(fb_rd_addr), 
        .fb_pixel(fb_pixel),
        .track_x(track_x), 
        .track_y(track_y), 
        .track_valid(track_valid),
        .box_half_w(track_w), 
        .box_half_h(track_h),  
        .VGA_R(VGA_R), 
        .VGA_G(VGA_G), 
        .VGA_B(VGA_B), 
        .VGAHS(VGAHS), 
        .VGAVS(VGAVS)
    );
    
endmodule