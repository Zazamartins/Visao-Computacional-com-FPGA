module reg_init(
    // ---------------------------ENTRADAS----------------------------
    input wire clk,                     // Clock FPGA 25MHz
    input wire rst_n,                   // reset ativo-baixo
    input wire sccb_ok,                 // Conectado ao SSBC_SENDER, alto quando dado enviado

    // --------------------------SAÍDAS-------------------------------
    output reg [15:0] data_out,         // [15:8] Endereço_registrador [7:0] Valor
    output wire reg_ok                  // Alto ENQUANTO NÃO acabarem de enviar
);

    // NÚMERO DE REGISTRADORES
    parameter NUMERO_REGISTRADORES = 177;

    // CONTADOR
    reg [($clog2(NUMERO_REGISTRADORES)) -1:0] count;

    // -------------------------REG_OK--------------------------------------
    assign reg_ok = (count < NUMERO_REGISTRADORES); 

    // --------------------------LÓGICA CONTADOR-------------------------------
    always @(posedge clk)
    begin
        if (!rst_n)
            begin
                count <= 0;
            end
        else if ((reg_ok) && (sccb_ok))
            begin
                count <= count + 1;
            end
    end

    // -----------------------ENVIO DOS REGISTRADORES---------------------------
    // Configuração para QVGA (320x240) RGB565
    
    always @ (posedge clk)
        case (count)
            // --- INICIALIZAÇÃO E RESET ---
            8'h00: data_out <= 16'hFF01; // REG: RA_DLMT (0xFF). Seleciona Banco 1 (Sensor).
            8'h01: data_out <= 16'h1280; // REG: COM7 (0x12). Bit[7]=1 (SRST). Inicia Reset do Sistema.
            8'h02: data_out <= 16'hFF00; // REG: RA_DLMT (0xFF). Seleciona Banco 0 (DSP).
            8'h03: data_out <= 16'h2CFF; // REG: Reservado (0x2C). Ajuste de fábrica.
            8'h04: data_out <= 16'h2EDF; // REG: Reservado (0x2E). Ajuste de fábrica.
            8'h05: data_out <= 16'hFF01; // REG: RA_DLMT (0xFF). Seleciona Banco 1 (Sensor).
            8'h06: data_out <= 16'h3C32; // REG: Reservado (0x3C).
            
            // --- CONFIGURAÇÃO DE CLOCK E SISTEMA (BANCO 1) ---
            8'h07: data_out <= 16'h1101; // REG: CLKRC (0x11). Clock Divider.
            8'h08: data_out <= 16'h0902; // REG: COM2 (0x09). Output Drive 2x.
            8'h09: data_out <= 16'h0420; // REG: REG04 (0x04). Orientação padrão.
            8'h0A: data_out <= 16'h13E5; // REG: COM8 (0x13). Banding Filter, AGC Auto, AEC Auto.
            8'h0B: data_out <= 16'h1448; // REG: COM9 (0x14). Gain Ceiling.
            8'h0C: data_out <= 16'h2C0C; // REG: Reservado (0x2C).
            8'h0D: data_out <= 16'h3378; // REG: Reservado (0x33).
            8'h0E: data_out <= 16'h3A33; // REG: Reservado (0x3A).
            8'h0F: data_out <= 16'h3BFB; // REG: Reservado (0x3B).
            
            // --- AJUSTES RESERVADOS DE SENSOR ---
            8'h10: data_out <= 16'h3E00; // REG: Reservado (0x3E).
            8'h11: data_out <= 16'h4311; // REG: Reservado (0x43).
            8'h12: data_out <= 16'h1610; // REG: Reservado (0x16).
            8'h13: data_out <= 16'h3992; // REG: Reservado (0x39).
            8'h14: data_out <= 16'h35DA; // REG: Reservado (0x35).
            8'h15: data_out <= 16'h221A; // REG: Reservado (0x22).
            8'h16: data_out <= 16'h37C3; // REG: Reservado (0x37).
            8'h17: data_out <= 16'h2300; // REG: Reservado (0x23).
            
            // --- CONFIGURAÇÃO DE JANELA E GEOMETRIA ---
            8'h18: data_out <= 16'h34C0; // REG: ARCOM2 (0x34).
            8'h19: data_out <= 16'h361A; // REG: REG32 (0x36).
            8'h1A: data_out <= 16'h0688; // REG: Reservado (0x06).
            8'h1B: data_out <= 16'h07C0; // REG: Reservado (0x07).
            8'h1C: data_out <= 16'h0D87; // REG: COM4 (0x0D).
            8'h1D: data_out <= 16'h0E41; // REG: Reservado (0x0E).
            8'h1E: data_out <= 16'h4C00; // REG: Reservado (0x4C).
            8'h1F: data_out <= 16'h4800; // REG: COM19 (0x48).
            8'h20: data_out <= 16'h5B00; // REG: Reservado (0x5B).
            8'h21: data_out <= 16'h4203; // REG: Reservado (0x42).
            8'h22: data_out <= 16'h4A81; // REG: Reservado (0x4A).
            8'h23: data_out <= 16'h2199; // REG: Reservado (0x21).
            8'h24: data_out <= 16'h2440; // REG: AEW (0x24).
            8'h25: data_out <= 16'h2538; // REG: AEB (0x25).
            8'h26: data_out <= 16'h2682; // REG: VV (0x26).
            8'h27: data_out <= 16'h5C00; // REG: Reservado (0x5C).
            8'h28: data_out <= 16'h6300; // REG: Reservado (0x63).
            8'h29: data_out <= 16'h4600; // REG: FLL (0x46).
            8'h2A: data_out <= 16'h0C3C; // REG: COM3 (0x0C).
            8'h2B: data_out <= 16'h6170; // REG: HISTO_LOW (0x61).
            8'h2C: data_out <= 16'h6280; // REG: HISTO_HIGH (0x62).
            8'h2D: data_out <= 16'h7C05; // REG: Reservado (0x7C).
            8'h2E: data_out <= 16'h2080; // REG: Reservado (0x20).
            8'h2F: data_out <= 16'h2830; // REG: Reservado (0x28).
            8'h30: data_out <= 16'h6C00; // REG: Reservado (0x6C).
            8'h31: data_out <= 16'h6D80; // REG: Reservado (0x6D).
            8'h32: data_out <= 16'h6E00; // REG: Reservado (0x6E).
            8'h33: data_out <= 16'h7002; // REG: Reservado (0x70).
            8'h34: data_out <= 16'h7194; // REG: Reservado (0x71).
            8'h35: data_out <= 16'h73C1; // REG: Reservado (0x73).
            8'h36: data_out <= 16'h1240; // REG: COM7 (0x12). SVGA (0x40). O DSP fará o downscale de SVGA para 320x240.
            8'h37: data_out <= 16'h1711; // REG: HREFST (0x17).
            8'h38: data_out <= 16'h1839; // REG: HREFEND (0x18).
            8'h39: data_out <= 16'h1900; // REG: VSTRT (0x19).
            8'h3A: data_out <= 16'h1A3C; // REG: VEND (0x1A).
            8'h3B: data_out <= 16'h3209; // REG: REG32 (0x32).
            8'h3C: data_out <= 16'h37C0; // REG: Reservado (0x37).
            8'h3D: data_out <= 16'h4FCA; // REG: BD50 (0x4F).
            8'h3E: data_out <= 16'h50A8; // REG: BD60 (0x50).
            8'h3F: data_out <= 16'h5A23; // REG: Reservado (0x5A).
            8'h40: data_out <= 16'h6D00; // REG: Reservado (0x6D).
            8'h41: data_out <= 16'h3D38; // REG: Reservado (0x3D).
            
            // --- SELEÇÃO DE BANCO DSP E PARÂMETROS ---
            8'h42: data_out <= 16'hFF00; // REG: RA_DLMT (0xFF). Seleciona Banco 0 (DSP).
            8'h43: data_out <= 16'hE57F; // REG: Reservado (0xE5).
            8'h44: data_out <= 16'hF9C0; // REG: MC_BIST (0xF9).
            8'h45: data_out <= 16'h4124; // REG: Reservado (0x41).
            8'h46: data_out <= 16'hE014; // REG: Reservado (0xE0).
            8'h47: data_out <= 16'h76FF; // REG: Reservado (0x76).
            8'h48: data_out <= 16'h33A0; // REG: Reservado (0x33).
            8'h49: data_out <= 16'h4220; // REG: Reservado (0x42).
            8'h4A: data_out <= 16'h4318; // REG: Reservado (0x43).
            8'h4B: data_out <= 16'h4C00; // REG: Reservado (0x4C).
            8'h4C: data_out <= 16'h87D5; // REG: CTRL3 (0x87).
            8'h4D: data_out <= 16'h883F; // REG: Reservado (0x88).
            8'h4E: data_out <= 16'hD703; // REG: Reservado (0xD7).
            8'h4F: data_out <= 16'hD910; // REG: Reservado (0xD9).
            8'h50: data_out <= 16'hD382; // REG: R_DVP_SP (0xD3).
            8'h51: data_out <= 16'hC808; // REG: Reservado (0xC8).
            8'h52: data_out <= 16'hC980; // REG: Reservado (0xC9).
            
            // --- ACESSO INDIRETO AO DSP (CONFIGURAÇÃO DE COR/GAMMA) ---
            8'h53: data_out <= 16'h7C00; // REG: BPADDR (0x7C).
            8'h54: data_out <= 16'h7D00; // REG: BPDATA (0x7D).
            8'h55: data_out <= 16'h7C03; // REG: BPADDR (0x7C).
            8'h56: data_out <= 16'h7D48; // REG: BPDATA (0x7D).
            8'h57: data_out <= 16'h7D48; // REG: BPDATA (0x7D).
            8'h58: data_out <= 16'h7C08; // REG: BPADDR (0x7C).
            8'h59: data_out <= 16'h7D20; // REG: BPDATA (0x7D).
            8'h5A: data_out <= 16'h7D10; // REG: BPDATA (0x7D).
            8'h5B: data_out <= 16'h7D0E; // REG: BPDATA (0x7D).
            8'h5C: data_out <= 16'h9000; // REG: Reservado (0x90).
            8'h5D: data_out <= 16'h910E; // REG: Reservado (0x91).
            8'h5E: data_out <= 16'h911A; // REG: Reservado (0x91).
            8'h5F: data_out <= 16'h9131; // REG: Reservado (0x91).
            8'h60: data_out <= 16'h915A; // REG: Reservado (0x91).
            8'h61: data_out <= 16'h9169; // REG: Reservado (0x91).
            8'h62: data_out <= 16'h9175; // REG: Reservado (0x91).
            8'h63: data_out <= 16'h917E; // REG: Reservado (0x91).
            8'h64: data_out <= 16'h9188; // REG: Reservado (0x91).
            8'h65: data_out <= 16'h918F; // REG: Reservado (0x91).
            8'h66: data_out <= 16'h9196; // REG: Reservado (0x91).
            8'h67: data_out <= 16'h91A3; // REG: Reservado (0x91).
            8'h68: data_out <= 16'h91AF; // REG: Reservado (0x91).
            8'h69: data_out <= 16'h91C4; // REG: Reservado (0x91).
            8'h6A: data_out <= 16'h91D7; // REG: Reservado (0x91).
            8'h6B: data_out <= 16'h91E8; // REG: Reservado (0x91).
            8'h6C: data_out <= 16'h9120; // REG: Reservado (0x91).
            8'h6D: data_out <= 16'h9200; // REG: Reservado (0x92).
            8'h6E: data_out <= 16'h9306; // REG: Reservado (0x93).
            8'h6F: data_out <= 16'h93E3; // REG: Reservado (0x93).
            8'h70: data_out <= 16'h9305; // REG: Reservado (0x93).
            8'h71: data_out <= 16'h9305; // REG: Reservado (0x93).
            8'h72: data_out <= 16'h9300; // REG: Reservado (0x93).
            8'h73: data_out <= 16'h9304; // REG: Reservado (0x93).
            8'h74: data_out <= 16'h9300; // REG: Reservado (0x93).
            8'h75: data_out <= 16'h9300; // REG: Reservado (0x93).
            8'h76: data_out <= 16'h9300; // REG: Reservado (0x93).
            8'h77: data_out <= 16'h9300; // REG: Reservado (0x93).
            8'h78: data_out <= 16'h9300; // REG: Reservado (0x93).
            8'h79: data_out <= 16'h9300; // REG: Reservado (0x93).
            8'h7A: data_out <= 16'h9300; // REG: Reservado (0x93).
            8'h7B: data_out <= 16'h9600; // REG: Reservado (0x96).
            8'h7C: data_out <= 16'h9708; // REG: Reservado (0x97).
            8'h7D: data_out <= 16'h9719; // REG: Reservado (0x97).
            8'h7E: data_out <= 16'h9702; // REG: Reservado (0x97).
            8'h7F: data_out <= 16'h970C; // REG: Reservado (0x97).
            8'h80: data_out <= 16'h9724; // REG: Reservado (0x97).
            8'h81: data_out <= 16'h9730; // REG: Reservado (0x97).
            8'h82: data_out <= 16'h9728; // REG: Reservado (0x97).
            8'h83: data_out <= 16'h9726; // REG: Reservado (0x97).
            8'h84: data_out <= 16'h9702; // REG: Reservado (0x97).
            8'h85: data_out <= 16'h9798; // REG: Reservado (0x97).
            8'h86: data_out <= 16'h9780; // REG: Reservado (0x97).
            8'h87: data_out <= 16'h9700; // REG: Reservado (0x97).
            8'h88: data_out <= 16'h9700; // REG: Reservado (0x97).
            8'h89: data_out <= 16'hC3ED; // REG: Reservado (0xC3).
            8'h8A: data_out <= 16'hA400; // REG: Reservado (0xA4).
            8'h8B: data_out <= 16'hA800; // REG: Reservado (0xA8).
            8'h8C: data_out <= 16'hC511; // REG: Reservado (0xC5).
            8'h8D: data_out <= 16'hC651; // REG: Reservado (0xC6).
            8'h8E: data_out <= 16'hBF80; // REG: Reservado (0xBF).
            8'h8F: data_out <= 16'hC710; // REG: Reservado (0xC7).
            8'h90: data_out <= 16'hB666; // REG: Reservado (0xB6).
            8'h91: data_out <= 16'hB8A5; // REG: Reservado (0xB8).
            8'h92: data_out <= 16'hB764; // REG: Reservado (0xB7).
            8'h93: data_out <= 16'hB97C; // REG: Reservado (0xB9).
            8'h94: data_out <= 16'hB3AF; // REG: Reservado (0xB3).
            8'h95: data_out <= 16'hB497; // REG: Reservado (0xB4).
            8'h96: data_out <= 16'hB5FF; // REG: Reservado (0xB5).
            8'h97: data_out <= 16'hB0C5; // REG: Reservado (0xB0).
            8'h98: data_out <= 16'hB194; // REG: Reservado (0xB1).
            8'h99: data_out <= 16'hB20F; // REG: Reservado (0xB2).
            8'h9A: data_out <= 16'hC45C; // REG: Reservado (0xC4).
            8'h9B: data_out <= 16'hC050; // REG: HSIZE8 (0xC0).
            8'h9C: data_out <= 16'hC13C; // REG: VSIZE8 (0xC1).
            8'h9D: data_out <= 16'h8C00; // REG: SIZEL (0x8C).
            8'h9E: data_out <= 16'h863D; // REG: CTRL2 (0x86).
            8'h9F: data_out <= 16'h5000; // REG: CTRL1 (0x50).
            8'hA0: data_out <= 16'h51A0; // REG: HSIZE (0x51).
            8'hA1: data_out <= 16'h5278; // REG: VSIZE (0x52).
            8'hA2: data_out <= 16'h5300; // REG: XOFFL (0x53).
            8'hA3: data_out <= 16'h5400; // REG: YOFFL (0x54).
            8'hA4: data_out <= 16'h5500; // REG: VHYX (0x55).
            
            // --- ALTERAÇÃO DE RESOLUÇÃO DE SAÍDA PARA 320x240 (QVGA) ---
            // Fórmula: Valor = Dimensão_Desejada / 4
            // 320 / 4 = 80 = 0x50
            // 240 / 4 = 60 = 0x3C
            
            8'hA5: data_out <= 16'h5A50; // REG: ZMOW (0x5A). Output Width = 320 (0x50 * 4).
            8'hA6: data_out <= 16'h5B3C; // REG: ZMOH (0x5B). Output Height = 240 (0x3C * 4).
            
            8'hA7: data_out <= 16'h5C00; // REG: ZMHH (0x5C).
            
            // --- FINALIZAÇÃO ---
            8'hA8: data_out <= 16'hD382; // REG: R_DVP_SP (0xD3). Velocidade DVP.
            8'hA9: data_out <= 16'hC3ED; // REG: Reservado (0xC3).
            8'hAA: data_out <= 16'h7F00; // REG: Reservado (0x7F).
            8'hAB: data_out <= 16'hDA08; // REG: IMAGE_MODE (0xDA). RGB565.
            8'hAC: data_out <= 16'hE51F; // REG: Reservado (0xE5).
            8'hAD: data_out <= 16'hE167; // REG: Reservado (0xE1).
            8'hAE: data_out <= 16'hE000; // REG: Reservado (0xE0).
            8'hAF: data_out <= 16'hDD7F; // REG: Reservado (0xDD).
            8'hB0: data_out <= 16'h0500; // REG: R_BYPASS (0x05). Ativa DSP.
        endcase
endmodule