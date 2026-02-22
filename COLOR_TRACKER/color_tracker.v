// --------------------------VISÃO COMPUTACIONAL EM HARDWARE --------------
// PIXEL_OV2640 -> FILTRO -> CALCULA POSIÇÃO E TAMANHO OBJETO COM BOUNDING BOX

module color_tracker (
    // -------------------------------------------------ENTRADAS------------------------------------------------------
    input  wire clk,                            // Clock da OV2640, o DCLK                                
    input wire rst_n,                           // Botão reset do sistema
    input  wire vsync,                          // PINO OV2640, alto quando quadro válida
    input wire href,                            // PINO OV2640, alto quando linha pixel válida
    input wire valid_pixel,                     // Alto quando é um pixel válido
    input  wire [15:0] pixel_data,              // Pixel vindo da CAM no formato RGB565

    // ------------------ FILTRO DE CORES ACEITAS/CONFIGURADAS NO TOP_MODULE ---------------
    input  wire [4:0]  target_r_min,            // min R 
    input wire [4:0] target_r_max,              // MAX R
    input  wire [5:0]  target_g_min,            // min G
    input wire [5:0] target_g_max,              // MAX G
    input  wire [4:0]  target_b_min,            // min B
    input wire [4:0] target_b_max,              // MAX B


    // ---------------------------------------------------SAÍDAS-----------------------------------------
    // ------------ CENTRO GEOMÉTRICO DO OBJETO------------------
    output reg [9:0]   obj_x,       
    output reg [9:0]   obj_y,

    // ------------- MÉTRICAS PARA BOUDING BOX ------------------
    output reg [9:0]   obj_half_w,              // RAIO HORIZONTAL
    output reg [9:0]   obj_half_h,              // RAIO VERTICAL
    output reg         obj_detected,            // Flag para dizer se tem OBJETO IDENTIFICADO OU NÃO

    // LEDS PARA DEBUGAR
    output reg led_debug_r,                     // LED VERMELHO PISCA SE ACHOU A COR
    output reg led_debug_g,                     // LED VERDE PISCA SE CONTAGEM > 100, métrica para avaliar se está percorrendo todos os pixels
    output reg led_debug_b                      // ACENDE SE FOI IDENTIFICADO UM OBJETO COM A COR DOS PARÂMETROS PASSADOS
);

    // REGISTRADORES PARA CALCULAR A POSIÇÃO DO PIXEL, O ENDEREÇO É LINEAR!
    reg [9:0] curr_x, curr_y;

    // -----------------DETECDOR DE BORDA DE DESCIDA DO HREF (linha acabou)--------------------
    reg last_href;
    wire end_of_line = (last_href && !href);    // ÚLTIMO_ALTO -> ATUAL BAIXO = BORDA DESCIDA
    always @(posedge clk) last_href <= href;

    always @(posedge clk) 
        begin
            // QUADRO NÃO VÁLIDO ZERA A POSIÇÃO (curr_x, curr_y) do pixel
            if (!vsync) 
                begin 
                    curr_x <= 0; 
                    curr_y <= 0; 
                end 
            else 
                begin
                    // CONTA PIXEL QUANDO HREF ALTO (Linha válida) e VALID_PIXEL ALTO (Píxel Válido)
                    if (href && valid_pixel) 
                        curr_x <= curr_x + 1; 
                    // RESETA A POSIÇÃO X a cada fim de linha
                    else if (!href) 
                        curr_x <= 0;
                    // INCREMENTA O CONTADOR DAS LINHAS PARA O Y
                    if (end_of_line) 
                        curr_y <= curr_y + 1;
                end
        end



    // ------------------------- FILTRO DE COR / É A COR OU NÃO É A COR -----------------------------
    wire [4:0] r = pixel_data[15:11];               // parte vermelha do pixel
    wire [5:0] g = pixel_data[10:5];                // parte verde do pixel
    wire [4:0] b = pixel_data[4:0];                 // parte azul do pixel
    // is_color é intuitivo, só é um comparador para ver se está nos limtes passados no TOP_MODULE
    wire is_color = (r >= target_r_min && r <= target_r_max) && (g >= target_g_min && g <= target_g_max) && (b >= target_b_min && b <= target_b_max);



    // -------------------------------- LÓGICA DO BOUNDING BOX-------------------------------------------------
    // Registradores para os vértices da caixa
    reg [9:0] x_min, x_max, y_min, y_max;
    // Contador para a quantidade total de pixels válidos da cor desejada
    reg [19:0] count;
    // !!CHAVE!! Vamos contar se tem uma quantidade mínima de pixels vermelho seguidos, para evitar que ruídos(pequenos vermelhos) entrem na métrica do Bounding BOX
    reg [3:0] streak_count;
    


    // ------------------- DETECTOR DA BORDA DE DESCIDA DO VSYNC ---------------
    reg vsync_d;    // ÚLTIMO ESTADO DO VSYNC
    always @(posedge clk) vsync_d <= vsync;
    // Detectetor de borda de descida : ALTO -> BAIXO
    wire end_of_frame = (vsync_d && !vsync); 

    always @(posedge clk) 
        begin
            // RESET_BAIXO DO SISTEMA
            if (!rst_n) 
                begin
                    obj_x <= 160; 
                    obj_y <= 120; 
                    obj_half_w <= 20; 
                    obj_half_h <= 20;
                    obj_detected <= 0; 
                    count <= 0; 
                    streak_count <= 0;
                    x_min <= 319; 
                    x_max <= 0; 
                    y_min <= 239; 
                    y_max <= 0;
                    led_debug_r <= 0; 
                    led_debug_g <= 0; 
                    led_debug_b <= 0;
                end 
            
            else 
                begin
                    // FIM DO QUADRO
                    if (end_of_frame) 
                    begin
                        // --------- FILTRO DA QUANTIDADE MÍNIMA DE PIXELS PARA SER CONSIDERADO OBJETO, 100 É UM TAMANHO RAZOÁVEL MAS PODE MEXER PARA MENOS OU MAIS DEPENDENDO
                        if (count > 100) 
                            begin
                                // CENTRO DO OBJETO É A MÉDIA DO p_min e p_max, ou seja RIGHT_SHIFT, /2 em Hardware
                                obj_x <= (x_min + x_max) >> 1; 
                                obj_y <= (y_min + y_max) >> 1;
                                
                                // ---------------CALCULA O TAMANHO DINÂMICO DA CAIXA--------------
                                // (Max - Min) dividido por 2 é o RAIO,
                                // Adicionamos +4 pixels de folga para a caixa não ficar colada, pode ser alterada mas é razoável também
                                obj_half_w <= ((x_max - x_min) >> 1) + 4;
                                obj_half_h <= ((y_max - y_min) >> 1) + 4;

                                // OBJETO DETECTADO
                                obj_detected <= 1; 
                            end 
                        else 
                            begin
                                obj_detected <= 0; 
                            end
                        
                        // -------ZERA A MEMÓRIA INTERNA PARA O PRÓXIMO FRAME-------
                        count <= 0; 
                        x_min <= 319; 
                        x_max <= 0; 
                        y_min <= 239; 
                        y_max <= 0;
                    end

                    // ------------ BUSCA PIXEL POR PIXEL -------------------- 
                    else if (vsync && href && valid_pixel) 
                        begin
                            // ACHOU UM PIXEL COM COR DENTRO DOS FILTROS
                            if (is_color) 
                                begin
                                    // INCREMENTA O STREK PARA AVALIAR SE NÃO É RUÍDO
                                    if (streak_count < 15) streak_count <= streak_count + 1;

                                    // MIN DE 4 PIXEL DE CORTE PARA SER CONSIDERADO RUÍDO, TALVEZ RAZOÁVEL, podemos alterar essa porra
                                    if (streak_count >= 4) 
                                        begin
                                            count <= count + 1;                     // Soma na qtd de pixels válidos

                                            // Avalia o tempo inteiro os vértices da nossa bouding box
                                            if (curr_x < x_min) x_min <= curr_x;    
                                            if (curr_x > x_max) x_max <= curr_x;
                                            if (curr_y < y_min) y_min <= curr_y;
                                            if (curr_y > y_max) y_max <= curr_y;

                                            // Se achou a cor o LED VERMELHO ACENDE, Debugzinho
                                            led_debug_r <= 1; 
                                        end
                                end 
                            // Não é da cor, então zera o contador de ruídos e apaga o led vermelho
                            else 
                                begin
                                    streak_count <= 0; 
                                    led_debug_r <= 0;
                                end
                        end 
                    // FIM DA LINHA NÃO TEM COMO CONECTAR BORDA
                    else if (!href) streak_count <= 0;

                    // LEDS PARA DEBUG
                    led_debug_g <= (count > 100);   // LED_VERDE ACENDE SE QUANTIDADE SUFICIENTE DE PIXEL DO OBJETO
                    led_debug_b <= obj_detected;    // LED_AZUL ACENDE SE TEM UM OBJETO DETECTADO
                
                
                end


        end
endmodule