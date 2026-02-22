module camera_get_pic (
    input  wire        dclk,        // PINO DA CÂMERA OV2640, seu próprio clock
    input  wire        href,        // PINO DA CÂMERA OV2640, alto qunado CAM envia uma linha válida de pixels  
    input  wire        vsync,       // PINO DA CÂMERA OV2640, alto quando quadro ativo
    input  wire [7:0]  data_in,     // data_in, CAM manda 1 byte de dados por vez

    output reg  [15:0] data_out,    // Saída 16 bits (RGB565)
    output reg         wr_en,       // Habilita a escrita
    output reg  [16:0] out_addr     // Endereço para 320x240 (76800 pixels)
);

    // --------------- REGISTRADORES INTERNOS (MEMÓRIA TEMPORÁRIA) ---------------------
    reg [15:0] rgb565 = 0;          // Armazena os bytes enquanto são montados
    reg [16:0] next_addr = 0;       // Endereço do próximo pixel a ser alocado
    
    // ------------------------- Mini-FSM para controlar o armazenamento dos dois bytes que é o RGB565 ---------------
    // status[0] = 1'b1, capturado primeiro byte (parte alta)
    // status[1] = 1'b1, capturado segundo byte (parte baixa), PIXEL RGB565 PRONTO
    reg [1:0]  status = 0; 


    // SINCRONISMO COM O CLOCK DA OV2640
    always @(posedge dclk) 
        begin
            // vsync alto durante captura, se não zera todas as saídas e memória interna do módulo
            if (vsync == 1'b0) 
                begin
                    out_addr  <= 0;
                    next_addr <= 0;
                    status    <= 0;
                    wr_en     <= 0;
                end
            
            else 
                begin
                    // Dado montado para a saída
                    data_out <= rgb565; 
                    
                    // Atualiza endereço e enable de escrita baseados no ciclo anterior
                    out_addr <= next_addr;
                    // Só fica alto se COMPLETARMOS O CICLO, ou seja, capturamos os dois bytes para o pixel RGB565
                    wr_en    <= status[1];
                    
                    // ----------------- LÓGICA MINI-FSM DO STATUS/CAPTURA-MONTAGEM PIXEL -----------------
                    // status[0] vira 1 quando href é 1 e ainda não tínhamos pego o primeiro byte
                    status <= {status[0], (href && !status[0])};
                    
                    // Shift dos dados: O byte novo entra na parte baixa, o antigo sobe
                    rgb565 <= {rgb565[7:0], data_in};
                        
                    // Se status[1] for 1, completamos um pixel no ciclo passado, incrementa endereço
                    if (status[1] == 1'b1) 
                        begin
                            if (next_addr < 76800 - 1) // Limite 320x240
                                    next_addr <= next_addr + 1;
                        end
                end
        end

endmodule