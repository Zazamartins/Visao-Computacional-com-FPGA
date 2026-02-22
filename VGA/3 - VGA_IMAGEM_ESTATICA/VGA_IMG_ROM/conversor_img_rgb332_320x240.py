
""" 
Converte uma imagem qualquer (PNG/JPG/etc) para um arquivo .hex no formato RGB332 (1 byte por pixel), com resolução 320x240.
Cada linha do .hex = 1 pixel em hexadecimal (dois dígitos, 00..FF)
linha 1 = PIXEL(0,0)
linha 2 = PIXEL(1,0)
linha 3 = PIXEL(2,0)
...
linha 320 = PIXEL(319,0)
linha 321 = PIXEL(0,1)
linha 322 = PIXEL(1,1)
"""
from PIL import Image   # Biblioteca Pillow, para abrir/transformar imagens
import os               # Para trabalhar com caminhos de arquivo (paths)

# -------------------------- PARÂMETROS DA IMAGEM --------------------------
H_IMG = 320
V_IMG = 240
IMAGEM = "minha_imagem.png"
ARQUIVO_SAIDA = "imagem_rgb332_320x240.hex"


# -------------------------- FUNÇÃO DE CONVERSÃO RGB -> RGB332 --------------------------

def to_rgb332(r, g, b):
    """
    Converte um pixel em RGB de 8 bits por canal (0..255)
    para o formato RGB332 (1 byte):

        bits 7..5: R (3 bits)
        bits 4..2: G (3 bits)
        bits 1..0: B (2 bits)
        
    """

    # Reduz R de 8 bits -> 3 bits
    r3 = (r >> 5) & 0x07  # 0x07 = 0b00000111

    # Reduz G de 8 bits -> 3 bits
    g3 = (g >> 5) & 0x07

    # Reduz B de 8 bits -> 2 bits
    b2 = (b >> 6) & 0x03

    # Saída função
    return (r3 << 5) | (g3 << 2) | b2


# -------------------------- TRATAMENTO DE CAMINHOS --------------------------

# base_dir = pasta onde este script está salvo.
# Isso garante que o script funciona mesmo se você rodar de outra pasta no terminal.
base_dir = os.path.dirname(os.path.abspath(__file__))

# Caminho completo da imagem de entrada:
img_path = os.path.join(base_dir, IMAGEM)

# Caminho completo do arquivo de saída .hex:
out_path = os.path.join(base_dir, ARQUIVO_SAIDA)


# -------------------------- ABRINDO E PREPARANDO A IMAGEM --------------------------

print("Lendo imagem em:", img_path)

# Abre a imagem usando Pillow.
# .convert("RGB") garante que teremos 3 canais (R,G,B) de 8 bits cada,
# .resize((H_IMG, V_IMG), Image.BILINEAR) redimensiona para 320x240
img = Image.open(img_path).convert("RGB").resize((H_IMG, V_IMG), Image.BILINEAR)


# -------------------------- GERANDO O ARQUIVO .HEX --------------------------

# Abre o arquivo de saída em modo escrita de texto ("w").
# Cada linha escrita será um pixel em hexadecimal (dois dígitos, 00..FF).
with open(out_path, "w") as f:
    # Varredura em ordem de linhas (raster scan):
    # y = 0..V_IMG-1 (linhas)
    for y in range(V_IMG):
        # x = 0..H_IMG-1 (colunas)
        for x in range(H_IMG):
            # Pega o pixel (R,G,B) na posição (x,y) da imagem já redimensionada.
            r, g, b = img.getpixel((x, y))

            # Converte esse pixel 24 bits (8+8+8) para RGB332 (8 bits).
            val = to_rgb332(r, g, b)

            # Escreve o valor no arquivo como 2 dígitos hexadecimais (00..FF),
            # seguido de uma quebra de linha.
            # f"{val:02X}" formata o inteiro 'val' em hexadecimal com 2 dígitos,
            f.write(f"{val:02X}\n")

print("Arquivo .hex gerado em:", out_path)