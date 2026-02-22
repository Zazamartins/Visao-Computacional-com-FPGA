module seven_segment_decoder (
    input wire [3:0] num,
    output reg [7:0] seg_out 
    // Mapeamento:
    // Bit 0 = a
    // Bit 1 = b
    // Bit 2 = c
    // Bit 3 = d
    // Bit 4 = e
    // Bit 5 = f
    // Bit 6 = g
    // Bit 7 = dp (Ponto Decimal)
);

    always @(*) begin
        case (num)
            //               dp g f e d c b a
            4'd0: seg_out = 8'b00111111; // 0x3F
            4'd1: seg_out = 8'b00000110; // 0x06
            4'd2: seg_out = 8'b01011011; // 0x5B
            4'd3: seg_out = 8'b01001111; // 0x4F
            4'd4: seg_out = 8'b01100110; // 0x66
            4'd5: seg_out = 8'b01101101; // 0x6D
            4'd6: seg_out = 8'b01111101; // 0x7D
            4'd7: seg_out = 8'b00000111; // 0x07
            4'd8: seg_out = 8'b01111111; // 0x7F
            4'd9: seg_out = 8'b01101111; // 0x6F
            
            // Se for 15 (Erro/Nada) ou qualquer outra coisa -> APAGA TUDO
            default: seg_out = 8'b00000000; 
        endcase
    end
endmodule