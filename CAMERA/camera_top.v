module camera_top(
    // ------------------------------ENTRADAS--------------------------------------
    input wire clk,             // Clock FPGA 25MHz
    input wire rst_n,           // Reset ativo-baixo

    // -----------------OV2640------------------------------
    input wire dclk,            // PCLK da câmera
    input wire href,            // PINO OV2640          
    input wire vsync,           // PINO OV2640      
    input wire [7:0] data,      // PINO OV2640    
    output wire scio_c,         // SCCB Clock
    inout  wire scio_d,         // SCCB Data (Bidirecional)
    output wire reset,          // Reset da câmera
    output wire pwdn,           // Power down da câmera

    // ----------------VGA----------------------------------
    output wire        VGAHS,   // SINCRONIA HORIZONTAL
    output wire        VGAVS,   // SINCRONIA VERTICAL
    output wire [2:0]  VGA_R,   // 3 BITS VERMELHO
    output wire [2:0]  VGA_G,   // 3 BITS VERDE
    output wire [2:0]  VGA_B    // 3 BITS AZUL
);

    
    // Conexão Camera Capture -> Framebuffer
    wire [15:0] cam_pixel;   
    wire        cam_wr_en;
    wire [16:0] cam_addr;    
    
    // Conexão VGA Upscaler -> Framebuffer
    wire [16:0] fb_rd_addr;  
    wire [15:0] fb_pixel;    
    wire        fb_rd_en;

    // Conexão VGA Control -> VGA Upscaler
    wire [9:0] x_pixel;
    wire [9:0] y_pixel;
    wire       VGAHS_in;
    wire       VGAVS_in;
    wire       data_enable;

    // --------------------1. INICIALIZAÇÃO OV2640---------------------
    camera_init CAMERA_INIT(
        .clk(clk), 
        .rst_n(rst_n), 
        .scio_c(scio_c), 
        .scio_d(scio_d),
        .reset(reset), 
        .pwdn(pwdn)
    );

    // -------------------2. CAPTURA PIXELS--------------------------------
    camera_get_pic CAMERA_GET_PIC(
        .dclk(dclk),        
        .href(href),
        .vsync(vsync),
        .data_in(data),
        .data_out(cam_pixel),
        .wr_en(cam_wr_en),
        .out_addr(cam_addr)
    );

    // ---------------------3. MEMÓRIA RAM---------------------------------
    framebuffer FRAMEBUFFER(
        // Porta de Escrita (Câmera)
        .wr_clk  (dclk),    
        .wr_en   (cam_wr_en),
        .wr_addr (cam_addr),
        .wr_data (cam_pixel),

        // Porta de Leitura (VGA)
        .rd_clk  (clk),        
        .rd_en   (fb_rd_en),
        .rd_addr (fb_rd_addr),
        .rd_data (fb_pixel)
    );

    // ------------------4. CONTROLE VGA---------------------------------------
    vga_control VGA_CONTROL (
        .vga_clk     (clk),
        .rst_n       (rst_n),
        .x_pixel     (x_pixel),
        .y_pixel     (y_pixel),
        .VGAHS       (VGAHS_in),
        .VGAVS       (VGAVS_in),
        .data_enable (data_enable)
    );

    // ----------------------5. UPSCALE DA IMAGEM E SAÍDA VGA-----------------------
    vga_upscaler VGA_PIPELINE (
        .vga_clk     (clk),
        .rst_n       (rst_n),

        // Inputs do Control
        .x_pixel     (x_pixel),
        .y_pixel     (y_pixel),
        .data_enable (data_enable),
        .VGAHS_in    (VGAHS_in),
        .VGAVS_in    (VGAVS_in),
        
        // Interface com Memória
        .fb_rd_en    (fb_rd_en),
        .fb_rd_addr  (fb_rd_addr),
        .fb_pixel    (fb_pixel),
        
        // Saídas Físicas VGA
        .VGA_R       (VGA_R),
        .VGA_G       (VGA_G),
        .VGA_B       (VGA_B),
        .VGAHS       (VGAHS),
        .VGAVS       (VGAVS)
    );

endmodule