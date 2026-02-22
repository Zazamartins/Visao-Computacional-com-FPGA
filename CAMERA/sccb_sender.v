module sccb_sender(
    // -----------------------------ENTRADAS----------------------------
    input wire clk,                             // 25MHz da FPGA
    input wire rst_n,                           // reset ativo-baixo
    input wire reg_ok,                          // Há registradores para enviar do reg_init
    input wire [7:0] slave_id,                  // Endereço da câmera
    input wire [7:0] reg_addr,                  // Endereço do registrador
    input wire [7:0] value,                     // Dado para escrever no registrador

    // -------------------------BIDIRECIONAL-----------------------------
    inout scio_d,                               // SDA Linha de dados
    // ---------------------------SAÍDAS---------------------------------
    output reg scio_c,                          // SCL Linha de Clock
    output reg sccb_ok                          // Confirma que enviou o valor do registrador
);

    // ----------------CONTADOR PARA DIVISÃO DE CLOCK DA SCL (MÁX DE 400 kHz)---------------
    reg [10:0] clk_div_count;                   // 11 bits contam até 2048, 25MHz/2048 = 12 KHz
    wire clk_div_tick;                          // Sinal alto quando completarmos um BAUD, isto é, o tempo de um estado
    assign clk_div_tick = (clk_div_count == 11'd2047) ? 1'b1: 1'b0;

    // -----------------------------CONTADOR DE ESTADOS-------------------------
    reg [4:0] state_count;
    // 5 bits contam 32 estados, que correspondem justamente ao envio dos 32 bits
    // state_count = 0 : IDLE (ocioso)
    // state_count = 1 : START
    // state_count = [2:9] : ENVIO 1° BYTE = slave_id
    // state_count = 10 : ACK
    // state_count = [11:18] : ENVIO 2° BYTE = reg_addr
    // state_count = 19 : ACK
    // state_count = [20:27] : ENVIO 3³ VYTE = value
    // state_count = 28 : ACK
    // state_count = [29:31] : STOP

    // -----------------------LÓGICA CONTADOR DE ESTADO-------------------------------
    always @(posedge clk)
        begin
            if (!rst_n)
                begin
                    state_count <= 0;
                end
            // IDLE (ocioso)
            else if (state_count == 0)
                begin
                    // TEMOS REGISTRADOR PARA ENVIAR -> START
                    if (reg_ok)
                        begin
                            state_count <= 1;                   // START
                        end
                    else 
                        begin
                            state_count <= state_count;       // Continua na mesma
                        end
                end
            // SE ENTROU AQUI JÁ ENTROU NO START
            else if (clk_div_tick)                              // SÓ MUDA ESTADO NO BAUD CERTO
                begin
                    if (state_count == 31)                      // ÚLTIMO ESTADO
                    begin
                        state_count <= 0;                       // RETORNA INICIAL
                    end
                    else
                        begin
                            state_count <= state_count + 1;
                        end
                end
        end

    // --------------------------LÓGICA CONTADOR DE DIVISÃO DE CLOCK-----------------
    always @(posedge clk)
        begin
            if (!rst_n)
                begin
                    clk_div_count <= 0;
                end
            // IDLE (ocioso)
            else if (state_count == 0)
                begin
                    clk_div_count <= 0;
                end
            // SE ENTROU AQUI ENTÃO JÁ INICIOU O START
            else if (clk_div_tick)
                begin
                    clk_div_count <= 0;                 // Completou o ciclo então reseta
                end
            else
                begin
                    clk_div_count <= clk_div_count + 1;
                end
        end

    // -----------------------LÓGICA sccb_ok(enviei o registrador)------------
    always @(posedge clk)
        begin
            sccb_ok <= (state_count == 1'b0) && (reg_ok == 1'b1);   // IDLE(ocioso) && Registrador para enviar
        end

    // -----------------------LÓGICA SCIO_C (SCL linha de clock do SCCB)-------------
    // state_count = 0 : IDLE (ocioso)                          scio_c = 1'b1
    // state_count = 1 : START                                  REGIME ESPECIAL START
    // state_count = [2:9] : ENVIO 1° BYTE = slave_id           BAIXO,ALTO,ALTO,BAIXO
    // state_count = 10 : ACK                                   BAIXO,ALTO,ALTO,BAIXO
    // state_count = [11:18] : ENVIO 2° BYTE = reg_addr         BAIXO,ALTO,ALTO,BAIXO
    // state_count = 19 : ACK                                   BAIXO,ALTO,ALTO,BAIXO
    // state_count = [20:27] : ENVIO 3³ VYTE = value            BAIXO,ALTO,ALTO,BAIXO
    // state_count = 28 : ACK                                   BAIXO,ALTO,ALTO,BAIXO
    // state_count = [29:31] : STOP                             REGIME ESPECIAL STOP
    always @(posedge clk)
        begin
            if (!rst_n)
                begin
                    scio_c <= 1'b1;
                end
            
            // -------------IDLE (ocioso)--------------
            else if (state_count == 0)
                begin
                    scio_c <= 1'b1;
                end
            // -------------START---------------------
            // FICA ALTA 3/4 TEMPO ATÉ SDA PUXAR A LINHA P/BAIXO AÍ SCL SOBE
            else if (state_count == 1)
                begin
                    // Só fica baixa no último 1/4 
                    if (clk_div_count[10:9] == 2'b11)
                        begin
                            scio_c <= 1'b0;
                        end
                    else
                        begin
                            scio_c <= 1'b1;
                        end
                end
            // ---------INICIO STOP----------------
            // FICA 1/4 TEMPO BAIXO E 3/4 ALTA PARA SDA PUXAR A LINHA PARA CIMA
            else if (state_count == 29)
                begin
                    if (clk_div_count[10:9] == 2'b00)
                        begin
                            scio_c <= 1'b0;
                        end
                    else
                        begin
                            scio_c <= 1'b1;
                        end
                end
            // ----------STOP 2/3 E 3/3------------------
            else if (state_count == 30 || state_count == 31)
                begin
                    scio_c <= 1'b1;
                end
            
            // ----------DEMAIS ESTADOS DE ENVIO 1 BYTE E ACK-------------------
            // BAIXO, ALTO, ALTO, BAIXO
            else
                begin
                    if (clk_div_count[10:9] == 2'b00)           // PREPARA DADO
                        scio_c <= 1'b0; 
                    else if (clk_div_count[10:9] == 2'b01)           // LÊ DADO
                        scio_c <= 1'b1;
                    else if (clk_div_count[10:9] == 2'b10)           // SEGURA
                        scio_c <= 1'b1;
                    else if (clk_div_count[10:9] == 2'b11)           // ABAIXA LINHA
                        scio_c <= 1'b0;
                end
        end

    // ------------TRI-STATE DE QUEM ESTÁ CONTROLANDO SDA--------------------
    reg scio_d_send;                    // 1'b1 então SDA Controla se 1'b0 Câmera controla para mandar ACK
    always @(posedge clk)
        begin
            if (!rst_n)
                begin
                    scio_d_send <= 1'b1;
                end
            // SÓ SOLTA A LINHA NOS ACKs
            else if ((state_count == 10) ||(state_count == 19) || (state_count == 28))
                begin
                    scio_d_send <= 1'b0;
                end
            else
                begin
                    scio_d_send <= 1'b1;
                end
        end
        
    // --------------------REGISTRADOR DE DESLOCAMENTO PARA OS DADOS--------------------
    // OS DADOS SEMPRE VÃO SAIR DO MSB
    reg [31:0] data_reg;
    always @(posedge clk)
        begin
            if (!rst_n)
                begin
                    data_reg <= 32'hffffffff;                       // FICA TODO ALTO PELA IMPEDÂNCIA
                end
            else
                begin
                    // LOAD OS DADOS se DISPONÍVEIS
                    if ((state_count == 0) && (reg_ok == 1))
                        begin
                            // START->SLAVE_ID->ACK->REG_ADDR->ACK->VALUE->ACK->STOP
                            data_reg <= {2'b10, slave_id, 1'bx, reg_addr, 1'bx, value, 1'bx, 3'b011};
                        end
                    // INICIO DE NOVO ESTADO
                    else if ((state_count != 0) && (clk_div_count == 0))
                        begin
                            // DESLOCA PARA ESQUERDA
                            data_reg <= {data_reg[30:0], 1'b1};
                        end
                end
        end
    
    // ---------------------------TRI-STATE FINAL DO SDA-----------------------
    assign scio_d = scio_d_send ? data_reg[31] : 'bz;           // SDA é dirigida então manda dado, se não alta impedância para o ACK

endmodule