module camera_get_pic (
    input  wire        dclk,        // PINO DA CÂMERA OV2640
    input  wire        href,        // PINO DA CÂMERA OV2640     
    input  wire        vsync,       // PINO DA CÂMERA OV2640
    input  wire [7:0]  data_in,     // data_in

    output reg  [15:0] data_out,    // Saída 16 bits (RGB565)
    output reg         wr_en,       // Habilita a escrita
    output reg  [16:0] out_addr     // Endereço para 320x240 (76800 pixels)
);

    reg [15:0] rgb565 = 0;
    reg [16:0] next_addr = 0;
    reg [1:0]  status = 0; 

    always @(posedge dclk) begin

        // vsync alto durante captura
        if (vsync == 1'b0) begin
            out_addr  <= 0;
            next_addr <= 0;
            status    <= 0;
            wr_en     <= 0;
        end else begin
            // Atribui o dado montado para a saída
            data_out <= rgb565; 
            
            // Atualiza endereço e enable de escrita baseados no ciclo anterior
            out_addr <= next_addr;
            wr_en    <= status[1];
            
            // Lógica de Deslocamento de Status (Detecta par de bytes)
            // status[0] vira 1 quando href é 1 e ainda não tínhamos pego o primeiro byte
            status <= {status[0], (href && !status[0])};
            
            // Shift dos dados: O byte novo entra na parte baixa, o antigo sobe
            rgb565 <= {rgb565[7:0], data_in};
                
            // Se status[1] for 1, completamos um pixel no ciclo passado, incrementa endereço
            if (status[1] == 1'b1) begin
                if (next_addr < 76800 - 1) // Limite 320x240
                    next_addr <= next_addr + 1;
            end
        end
    end

endmodule