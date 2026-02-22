// ------------------- VGA 640 X 480 60 Hz --------------------------
module vga_control(

  // ------------------ENTRADAS--------------------------------------
  input wire vga_clk,                 // CLOCK VGA 
  input wire rst_n,                   // RESET EM BAIXO

  // -----------------SAÍDAS-----------------------------------------
  output reg [9:0] x_pixel,           // Posição x pixel na matriz
  output reg [9:0] y_pixel,           // Posição y pixel na matriz
  output reg VGAHS,                   // Sinal Sincronismo horizontal
  output reg VGAVS,                   // Sinal sincronismo vertical
  output reg data_enable              // Posição válida para escrita na tela
);

  // ----------------------TIMERS HORIZONTAL------------------------------
  parameter END_AREA_ATIVA_HORIZONTAL = 639;                                    // ÚLTIMO PIXEL DA ÁREA VÁLIDA
  parameter INICIO_SINCRONISMO_HORIZONTAL = END_AREA_ATIVA_HORIZONTAL + 16;     // SINCRONISMO INICIA APÓS FRONT PORCH
  parameter FIM_SINCRONISMO_HORIZONTAL = INICIO_SINCRONISMO_HORIZONTAL + 96;    // TERMINA SINCRONISMO
  parameter ULTIMO_PIXEL_HORIZONTAL = 799;

  // ----------------------TIMERS VERTICAL------------------------------
  parameter END_AREA_ATIVA_VERTICAL = 479;                                      // ÚLTIMO PIXEL DA ÁREA VÁLIDA
  parameter INICIO_SINCRONISMO_VERTICAL = END_AREA_ATIVA_VERTICAL + 10;         // SINCRONISMO INICIA APÓS FRONT PORCH
  parameter FIM_SINCRONISMO_VERTICAL = INICIO_SINCRONISMO_VERTICAL + 2;         // TERMINA SINCRONISMO
  parameter ULTIMO_PIXEL_VERTICAL = 524;

  // -----------------------LÓGICA PARA CONTADORES DAS POSIÇÕES (X,Y) NA  MATRIZ---------------
  always @(posedge vga_clk)
    begin
      if (!rst_n)
        begin
          x_pixel <= 10'b0;
          y_pixel <= 10'b0;
          VGAHS <= 1'b1;
          VGAVS <= 1'b1;
          data_enable <= 1'b0;
        end
      
      else
        begin
          // -----------------LÓGICA PARA SINAIS DE SINCRONISMO E DATA_ENABLE----------------------
          VGAHS <= ((x_pixel >= INICIO_SINCRONISMO_HORIZONTAL) && (x_pixel < FIM_SINCRONISMO_HORIZONTAL)) ? 1'b0: 1'b1;  // BAIXO DURANTE SINCRONISMO
          VGAVS <= ((y_pixel >= INICIO_SINCRONISMO_VERTICAL) && (y_pixel < FIM_SINCRONISMO_VERTICAL)) ? 1'b0 : 1'b1;     // BAIXO DURANTE SINCRONISMO
          data_enable <= ((x_pixel <= END_AREA_ATIVA_HORIZONTAL) && (y_pixel <= END_AREA_ATIVA_VERTICAL)) ? 1'b1: 1'b0;  // ALTO QUANDO É ÁREA VÁLIDA DE ESCRITA
        
          // -------------------CONTADOR PARA POSIÇÃO HORIZONTAL X---------------------
          if (x_pixel == ULTIMO_PIXEL_HORIZONTAL)
            begin
              x_pixel <= 0;
              // --------------CONTADOR PARA POSIÇÃO VERTICAL Y-----------------
              if (y_pixel == ULTIMO_PIXEL_VERTICAL)
                begin
                  y_pixel <= 0;
                end
              else
                begin
                  y_pixel <= y_pixel + 1;
                end
            end
          else
            begin
              x_pixel <= x_pixel + 1;
            end
        end
    end


endmodule