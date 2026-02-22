// Possivelmente o mais complexo, pois são três tarefas
// 1- UPSCALER: 320X240 OV2640 -> 640X480, ou seja, 1 pixel da imagem vira 4 pixels da imagem do monitor, um bloco 2x2
// 2- PINTA BOUNDING BOX: Lê os dados e vê se o pixel for do bouding box, ele IGNORA o pixel da memória nessa posição e pinta de verde no lugar
// 3- SINCRONISMO: Leitura de memória e cálculos tem muitos delays, por isso o uso de vários registradores intermediários

module vga_upscaler (

    input  wire vga_clk,                // CLOCK DO VGA É O MESMO DA FPGA 25MHz
    input wire rst_n,                   // Botão reset baixo

    // -------------------------------CONTROLES DO VGA_CONTROL -----------------
    input  wire [9:0]  x_pixel,         // Posição X da tela [0, 639]
    input wire [9:0] y_pixel,           // Posição Y da tela [0, 479]
    input wire data_enable,             // Posição Válida na tela
    input  wire VGAHS_in,               // Sincronismo Horizontal entrada
    input wire VGAVS_in,                // Sincronismo Vertical entrada

    // ----------------------------INTERFACE COM FRAMEBUFFER -----------------------
    output reg fb_rd_en,                // Enable leitura da RAM
    output reg [16:0] fb_rd_addr,       // Endereço do pixel na RAM
    input wire [15:0] fb_pixel,         // O dado do pixel da RAM
    
    // ---------------------------INTERFACE COM COLOR_TRACKER--------------------------
    input  wire [9:0]  track_x,         // Centro X do objeto
    input wire [9:0] track_y,           // Centro Y do objeto
    input wire track_valid,             // Alto se o objeto foi detectado
    
    // ------------------------ PARÂMETROS DO BOUNDING BOX -----------------------------
    input  wire [9:0]  box_half_w,      // RAIO HORIZONTAL DA CAIXA
    input  wire [9:0]  box_half_h,      // RAIO VERTICAL DA CAIXA

    // ----------------- SAÍDAS PARA O VGA/CORRIGINDO DELAY DAS LEITURAS DA RAM E CÁLCULOS ------
    output reg [2:0] VGA_R,             // 3 bits RED
    output reg [2:0] VGA_G,             // 3 bits GREEN
    output reg [2:0] VGA_B,             // 3 bits BLUE
    output reg VGAHS,                   // Sincronismo Horizontal SAÍDA
    output reg VGAVS                    // Sincronismo Vertical Saída
);
    // -------------- SINAIS E MEMÓRIA INTERNA DO MÓDULO -----------------
    localparam LARGURA_ORIGEM = 320;
    reg [3:0] pipe_hs, pipe_vs, pipe_de; // ATRASOS NA LEITURA DA RAM, por isso o pipeline
    reg [15:0] delay_pixel;             
    integer i;



    // ---------------------------------BOUNDING BOX-----------------------------------------
    // CÁLCULO DO CENTRO Multipliaco por 2 por conta da escala, em hardware LEFT SHIFTING
    wire [9:0] center_x = track_x << 1;
    wire [9:0] center_y = track_y << 1;
    
    // Tamanho Dinâmico da caixa escalado por dois
    // Se o objeto tem 10px na câmera, terá 20px no monitor.
    // Boa solução para que a caixa tenha no mínimo 10 pixels, o que é ÓTIMO visualmente
    wire [9:0] radius_w = (box_half_w < 5) ? 10 : (box_half_w << 1); // RAIO HORIZONTAL
    wire [9:0] radius_h = (box_half_h < 5) ? 10 : (box_half_h << 1); // RAIO VERTICAL
    localparam THICKNESS = 3;   // Espessura da caixa razoável

    // ---------- Distância do pixel ao centro do objeto/ DISTÂNCIA ABSOLUTA, por isso o ternário ?
    wire [9:0] dist_x = (x_pixel > center_x) ? (x_pixel - center_x) : (center_x - x_pixel);
    wire [9:0] dist_y = (y_pixel > center_y) ? (y_pixel - center_y) : (center_y - y_pixel);

    // ------------------------------ SINAIS DE CONTROLE -------------------------
    // ESTAMOS DENTRO DA CAIXA? SIM OU NÃO
    wire inside_box_area = (dist_x <= radius_w) && (dist_y <= radius_h);
    // ESTAMOS NA BORDA DA CAIXA? SIM OU NÃO
    wire is_border = inside_box_area && ( (dist_x >= (radius_w - THICKNESS)) || (dist_y >= (radius_h - THICKNESS)) );
    // DESENHA OU NÃO A CAIXA
    wire draw_box = is_border && track_valid;

    // LÓGICA SÍNCRONA DESENHANDO NA TELA
    always @(posedge vga_clk) 
        begin
            if (!rst_n) 
                begin
                    pipe_hs <= 4'b1111; 
                    pipe_vs <= 4'b1111; 
                    pipe_de <= 0;
                    fb_rd_en <= 0; 
                    fb_rd_addr <= 0;
                    VGA_R <= 0; 
                    VGA_G <= 0; 
                    VGA_B <= 0; 
                    VGAHS <= 1; 
                    VGAVS <= 1;
                end 
            else 
                begin
                    // 1------------------- LEITURA RAM ------------------------
                    if (data_enable) 
                    begin
                        fb_rd_en <= 1'b1; 
                        
                        // -- CÁLCULO DO ENDEREÇO ---
                        // 1 PIXEL -> BLOCO 2X2, por isso pegamos [9:1] estamos SHIFT OU MELHOR DIVINDO POR DOIS
                        fb_rd_addr <= x_pixel[9:1] + (y_pixel[9:1] * LARGURA_ORIGEM); 

                        // PIPELINE Do "Data Enable"
                        pipe_de[0] <= 1'b1;
                    end 
                    else 
                        begin
                            fb_rd_en <= 1'b0; 
                            pipe_de[0] <= 1'b0; 
                        end

                    // 2 ------------------- PIPELINE DE SINCRONISMO DO VGA ----------------------
                    // EMPURRA OS SINAIS POR REGISTRADORES DE DESLOCAMENTO PARA COMPESAR O ATRASO
                    pipe_hs[0] <= VGAHS_in; 
                    pipe_vs[0] <= VGAVS_in;

                    // LÓGICA DO ATRASO: 0 PEDE O DADO PARA RAM 1 RAM POE O DADO A DISPOSIÇÃO 2 O DADO FINALMENTE CHEGA
                    for(i=0; i<3; i=i+1) 
                        begin
                            pipe_hs[i+1] <= pipe_hs[i]; 
                            pipe_vs[i+1] <= pipe_vs[i]; 
                            pipe_de[i+1] <= pipe_de[i];
                        end


                    // 3 ----------------------- SAÍDA FINAL NA TELA --------------------------
                    // Pixel atrasado da RAM prontinho
                    delay_pixel <= fb_pixel;
                    // Sinais de sincronismo atrasados
                    VGAHS <= pipe_hs[3]; 
                    VGAVS <= pipe_vs[3];

                    // ÚLTIMO ESTADO DO PIPELINE, então podemos desenhar
                    if (pipe_de[3]) 
                        begin
                            // CAIXA VERDE PRIORIDADE SOBRE A CAMADA DA CAM
                            if (draw_box) 
                                begin
                                    // CAIXA VERDE
                                    VGA_R <= 3'b000; 
                                    VGA_G <= 3'b111; 
                                    VGA_B <= 3'b000;
                                end
                                
                            else 
                                begin
                                // IMAGEM DA CAM
                                    VGA_R <= delay_pixel[15:13]; 
                                    VGA_G <= delay_pixel[10:8]; 
                                    VGA_B <= delay_pixel[4:2];   
                                end
                        end 
                    // Fora da área ativa do VGA
                    else 
                        begin
                            VGA_R <= 0; 
                            VGA_G <= 0; 
                            VGA_B <= 0;
                        end
                end
        end
endmodule