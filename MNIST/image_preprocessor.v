module image_preprocessor (
    input wire dclk, input wire rst_n, input wire vsync, input wire href,
    input wire [15:0] pixel_rgb,
    input wire pixel_valid,       

    output reg [9:0] mnist_addr,  
    output reg       mnist_data,  
    output reg       mnist_wr_en, 
    
    // Saídas de Coordenadas para o Top Module usar no desenho
    output wire [9:0] roi_x_start, output wire [9:0] roi_x_end,
    output wire [9:0] roi_y_start, output wire [9:0] roi_y_end,
    output wire in_roi,            
    output reg debug_ink_detected 
);

    // ROI 112x112 (Para caber a grade 28x28 com blocos de 4px)
    localparam X_START = 104;
    localparam Y_START = 64;
    localparam ROI_SIZE = 112; 
    
    assign roi_x_start = X_START; assign roi_x_end = X_START + ROI_SIZE;
    assign roi_y_start = Y_START; assign roi_y_end = Y_START + ROI_SIZE;

    reg [9:0] cam_x;
    reg [9:0] cam_y;
    reg href_last;

    assign in_roi = (cam_x >= X_START && cam_x < (X_START + ROI_SIZE) && 
                     cam_y >= Y_START && cam_y < (Y_START + ROI_SIZE));

    always @(posedge dclk) begin
        if (!rst_n) href_last <= 0; else href_last <= href;
    end
    wire href_falling = (href_last && !href);

    always @(posedge dclk) begin
        if (!rst_n || !vsync) begin 
           cam_x <= 0; cam_y <= 0; debug_ink_detected <= 0; 
        end else begin
            if (href && pixel_valid) cam_x <= cam_x + 1;
            if (href_falling) begin cam_x <= 0; cam_y <= cam_y + 1; end
        end
    end

    // --- VISÃO BINÁRIA ---
    wire [5:0] raw_green = pixel_rgb[10:5]; 
    wire [6:0] boosted = raw_green * 2; 
    wire [5:0] val = (boosted > 63) ? 6'd63 : boosted[5:0];
    
    // TINTA = Lógica 1 (Para a RAM)
    wire is_ink = (val < 50); 

    // Coordenadas da Grade 28x28 (Divide por 4)
    wire [4:0] grid_x = (cam_x - X_START) >> 2; 
    wire [4:0] grid_y = (cam_y - Y_START) >> 2; 
    
    // Amostra no meio do bloco 4x4 para garantir estabilidade
    wire sample_now = (((cam_x - X_START) & 3) == 2) && (((cam_y - Y_START) & 3) == 2); 

    always @(posedge dclk) begin
        if (!vsync) begin
            mnist_wr_en <= 0; mnist_addr <= 0; mnist_data <= 0;
        end else if (pixel_valid && in_roi && href) begin 
            if (is_ink) debug_ink_detected <= 1;

            if (sample_now) begin
                mnist_wr_en <= 1;
                mnist_addr <= (grid_y * 28) + grid_x;
                mnist_data <= is_ink; // Grava 1 se for preto
            end else begin
                mnist_wr_en <= 0;
            end
        end else begin
            mnist_wr_en <= 0;
        end
    end
endmodule