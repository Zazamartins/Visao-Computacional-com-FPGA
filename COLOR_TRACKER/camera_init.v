// 237.5 kB RAM FPGA Lattice ECP5 45f 
module camera_init(

    // -------------------------ENTRADAS--------------------------------------
    input wire clk,                                         // 25MHz da FPGA
    input wire rst_n,                                       // reset ativo-baixo

    // -----------------PROTOCOLO SSCB (sscb_sender)-------------------------
    output wire scio_c,                                     // SCL Câmera      
    inout scio_d,                                           // SDA Câmera

    // ----------------PINOS CONTROLE DA CÂMERA OV2640------------------------
    output wire reset,                                      // NÃO É DO BOTÃO, É DA CÂMERA
    output wire pwdn,                                       // Só para ficar simétrico comentários rsrs
);

    // ------------------SINAIS DE CONTROLE PARA LIGAR A CÂMERA-------------
    assign reset = 1'b1;
    assign pwdn = 1'b0;

    // --------------LIGAÇÃO sscb_sender e reg_init---------------------
    wire [15:0] data_send;
    wire        reg_ok;
    wire        sccb_ok;

    // INICIALIZANDO REGISTRADORES
    reg_init u_reg_init (
        .clk      (clk),                // 25 MHz placa
        .rst_n    (rst_n),              // reset ativo-baixo
        .sccb_ok  (sccb_ok),            // alto se enviou o conteúdo do registrador
        .data_out (data_send),          // Valor armazenado no registrador
        .reg_ok   (reg_ok)              // alto enquanto houver registradores para mandar INFO
    );

    // PROCOLO SCCB
    sccb_sender u_sccb_sender (
        .clk      (clk),                // 25 MHz placa
        .rst_n    (rst_n),              // reset ativo-baixo
        .reg_ok   (reg_ok),             // alto enquanto houver registradores para mandar INFO
        .slave_id (8'h60),              // endereço SCCB da OV2640 (escrita)
        .reg_addr (data_send[15:8]),    // endereço do registrador
        .value    (data_send[7:0]),     // valor a ser escrito
        .scio_d   (scio_d),             // SDA
        .scio_c   (scio_c),             // SCL
        .sccb_ok  (sccb_ok)             // alto se enviou o conteúdo do registrador
    );

endmodule