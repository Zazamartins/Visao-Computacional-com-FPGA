module camera_top(
    input wire clk, input wire rst_n,
    input wire dclk, input wire href, input wire vsync, input wire [7:0] data,      
    output wire scio_c, inout  wire scio_d, output wire reset, output wire pwdn,
    output wire VGAHS, output wire VGAVS, output wire [2:0] VGA_R, output wire [2:0] VGA_G, output wire [2:0] VGA_B,
    
    // NOME RESTAURADO: Agora bate com seu LPF original
    output wire [3:0] leds,
    
    // Nova saída para o display (adicione aquela parte nova no LPF)
    output wire [7:0] segment_pins 
);

    wire [15:0] cam_pixel; wire cam_wr_en; wire [16:0] cam_addr;
    wire [16:0] fb_rd_addr; wire [15:0] fb_pixel; wire fb_rd_en;
    wire [9:0] x_pixel, y_pixel; wire VGAHS_in, VGAVS_in, data_enable;
    
    wire [9:0] mnist_wr_addr; wire mnist_wr_data; wire mnist_wr_en;
    wire [9:0] class_rd_addr; wire class_rd_data; 
    wire [3:0] result_num; wire class_done;
    wire [9:0] roi_x_s, roi_x_e, roi_y_s, roi_y_e; wire is_inside_roi;

    // --- CÂMERA ---
    camera_init CAMERA_INIT(.clk(clk), .rst_n(rst_n), .scio_c(scio_c), .scio_d(scio_d), .reset(reset), .pwdn(pwdn));
    camera_get_pic CAMERA_GET_PIC(.dclk(dclk), .href(href), .vsync(vsync), .data_in(data), .data_out(cam_pixel), .wr_en(cam_wr_en), .out_addr(cam_addr));

    // --- CÉREBRO ---
    image_preprocessor MNIST_PREPROC (
        .dclk(dclk), .rst_n(rst_n), .vsync(vsync), .href(href), .pixel_rgb(cam_pixel),
        .pixel_valid(cam_wr_en), 
        .mnist_addr(mnist_wr_addr), .mnist_data(mnist_wr_data), .mnist_wr_en(mnist_wr_en),
        .roi_x_start(roi_x_s), .roi_x_end(roi_x_e), .roi_y_start(roi_y_s), .roi_y_end(roi_y_e),
        .in_roi(is_inside_roi), .debug_ink_detected()
    );

    mnist_ram MNIST_MEMORY (
        .wr_clk(dclk), .wr_addr(mnist_wr_addr), .wr_data(mnist_wr_data), .wr_en(mnist_wr_en), 
        .rd_clk(clk), .rd_addr(class_rd_addr), .rd_data(class_rd_data)
    );
    
    reg [2:0] vsync_sync; always @(posedge clk) vsync_sync <= {vsync_sync[1:0], vsync};
    wire start_ai_clean = (vsync_sync[2] && !vsync_sync[1]); 

    mnist_classifier MY_AI (
        .clk(clk), .rst_n(rst_n), .start(start_ai_clean), 
        .ram_addr(class_rd_addr), .ram_data(class_rd_data), 
        .prediction(result_num), .done(class_done)
    );

    // --- VISÃO (MONITOR) ---
    wire [15:0] px_final = cam_pixel;

    framebuffer FRAMEBUFFER(
        .wr_clk(dclk), .wr_en(cam_wr_en), .wr_addr(cam_addr), .wr_data(px_final), 
        .rd_clk(clk), .rd_en(fb_rd_en), .rd_addr(fb_rd_addr), .rd_data(fb_pixel)
    );

    vga_control VGA_CONTROL (
        .vga_clk(clk), .rst_n(rst_n), .x_pixel(x_pixel), .y_pixel(y_pixel), 
        .VGAHS(VGAHS_in), .VGAVS(VGAVS_in), .data_enable(data_enable)
    );

    wire [2:0] r_ups, g_ups, b_ups; wire hs_out, vs_out;
    vga_upscaler VGA_PIPELINE (
        .vga_clk(clk), .rst_n(rst_n), .x_pixel(x_pixel), .y_pixel(y_pixel), 
        .data_enable(data_enable), .VGAHS_in(VGAHS_in), .VGAVS_in(VGAVS_in), 
        .fb_rd_en(fb_rd_en), .fb_rd_addr(fb_rd_addr), .fb_pixel(fb_pixel), 
        .VGA_R(r_ups), .VGA_G(g_ups), .VGA_B(b_ups), .VGAHS(hs_out), .VGAVS(vs_out)
    );
    
    // --- BORDA VERDE ---
    wire [9:0] vga_roi_x_s = roi_x_s << 1; wire [9:0] vga_roi_x_e = roi_x_e << 1; 
    wire [9:0] vga_roi_y_s = roi_y_s << 1; wire [9:0] vga_roi_y_e = roi_y_e << 1;
    
    wire is_border = ((x_pixel >= vga_roi_x_s && x_pixel <= vga_roi_x_e && (y_pixel == vga_roi_y_s || y_pixel == vga_roi_y_e)) || 
                      (y_pixel >= vga_roi_y_s && y_pixel <= vga_roi_y_e && (x_pixel == vga_roi_x_s || x_pixel == vga_roi_x_e)));

    assign VGAHS = hs_out; 
    assign VGAVS = vs_out;
    assign VGA_R = is_border ? 3'b000 : r_ups;
    assign VGA_G = is_border ? 3'b111 : g_ups; 
    assign VGA_B = is_border ? 3'b000 : b_ups;

    // --- CAPTURA DO RESULTADO ---
    reg [3:0] stable_result;
    always @(posedge clk) if (class_done) stable_result <= result_num;

    // --- SAÍDA 1: LEDS BINÁRIOS (Corrigido para usar 'leds') ---
    wire [3:0] leds_final = (stable_result > 9) ? 4'b0000 : stable_result;
    
    // Mapeamento mantido conforme seu LPF original
    assign leds[3] = leds_final[0]; 
    assign leds[2] = leds_final[1]; 
    assign leds[1] = leds_final[2]; 
    assign leds[0] = leds_final[3]; 

    // --- SAÍDA 2: DISPLAY DE 7 SEGMENTOS ---
    seven_segment_decoder SEG_DEC (
        .num(stable_result),
        .seg_out(segment_pins)
    );

endmodule