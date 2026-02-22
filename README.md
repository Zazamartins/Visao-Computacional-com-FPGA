# 🚀 Visão Computacional em Hardware (FPGA) | Edge AI
**Classificação de Dígitos (MNIST) em Tempo Real com OV2640 e Saída VGA**

![Status](https://img.shields.io/badge/Status-Concluído-success)
![Hardware](https://img.shields.io/badge/Hardware-Lattice_ECP5-blue)
![Linguagem](https://img.shields.io/badge/Linguagem-Verilog-purple)
![Licença](https://img.shields.io/badge/Licença-MIT-green)

Este repositório contém a implementação completa em nível de transferência de registradores (RTL) de um sistema de visão computacional operando estritamente na borda (Edge Computing). Desenvolvido como projeto final para a **3ª Fase do programa Embarcatech**.

O grande diferencial deste projeto é a **ausência total de microprocessadores (CPUs) ou sistemas operacionais**. Todo o processamento de vídeo — desde a configuração I2C da câmera, passando pelo rastreamento espacial (Color Tracker), até a inferência estatística (Template Matching) — ocorre nativamente através de portas lógicas sintetizadas em uma FPGA.

---

## 🌟 Principais Recursos

* 🧠 **Inteligência Artificial em Hardware:** Aceleração de inferência do dataset MNIST utilizando Correspondência de Molde (Template Matching) com mitigação de erro espacial ("Visão Periférica") puramente combinacional.
* 📸 **Biblioteca Completa OV2640 em Verilog:** Módulos robustos e reutilizáveis para integração de sensores CMOS, incluindo protocolo SCCB (I2C) para configuração, decodificador de pixels DVP e travessia de domínio de clock (CDC).
* 🎯 **Rastreamento de Cor em Tempo Real:** Módulo `color_tracker` que binariza imagens, filtra ruídos espaciais na imagem e calcula Bounding Boxes instantaneamente.
* 🖥️ **Interface de Usuário Zero-RAM:** Geração de sobreposição gráfica (o quadrado verde de rastreamento) direto no fluxo VGA via multiplexador de vídeo, economizando blocos de memória interna da FPGA.

---

## 🛠️ Hardware Utilizado

* **FPGA:** Placa de desenvolvimento baseada no chip **Lattice ECP5 (LFE5U-25F)**.
* **Sensor de Imagem:** Câmera **OV2640** (Configurada para RGB565 via I2C).
* **Interface de Saída:** Módulo adaptador **VGA PS2 Board (Waveshare)** operando a 640x480 @ 60Hz.
* **Interface Física:** Display de 7 Segmentos e LEDs indicadores GPIO.

---

## 📂 Estrutura do Repositório (Metodologia Evolutiva)

O código foi organizado para refletir a evolução do aprendizado e do projeto. Cada pasta é autossuficiente e representa um estágio arquitetural. **Se você precisa de uma biblioteca OV2640, a pasta `CAMERA` está pronta para uso!**

```text
📦 Visao-Computacional-com-FPGA
 ┣ 📜 3__FASE_EMBARCATECH.pdf       # 📄 Relatório Técnico Completo (Tese do Projeto)
 ┃
 ┣ 📂 VGA                           # ESTÁGIO 1: Domínio da Interface de Vídeo
 ┃ ┣ 📂 1 - VGA_TELA_MONOCROMATICA  # Teste de temporizadores (Vsync/Hsync) e cor sólida
 ┃ ┣ 📂 2 - VGA_BARRAS              # Teste de varredura e mapeamento RGB horizontal
 ┃ ┗ 📂 3 - VGA_IMAGEM_ESTATICA     # Upscaler e leitura de memória ROM
 ┃   ┗ 📜 conversor_img_rgb332_320x240.py # Script Python para gerar .hex
 ┃
 ┣ 📂 CAMERA                        # ESTÁGIO 2: A Biblioteca OV2640
 ┃ ┣ 📜 camera_init.v & reg_init.v  # Mestre SCCB (I2C) e registros de setup
 ┃ ┣ 📜 camera_get_pic.v            # Decodificador do barramento DVP
 ┃ ┗ 📜 framebuffer.v               # BRAM Dual-Port (Sincroniza Câmera com o VGA)
 ┃
 ┣ 📂 COLOR_TRACKER                 # ESTÁGIO 3: Visão Computacional de Baixo Nível
 ┃ ┗ 📜 color_tracker.v             # Binarização, filtro anti-ruído e Bounding Box
 ┃
 ┣ 📂 MNIST                         # ESTÁGIO 4: O Sistema Integrado Final (IA)
 ┃ ┣ 📜 mnist_classifier.v          # Núcleo da IA (Template Matching paralelo)
 ┃ ┣ 📜 mnist_ram.v                 # Memória SRAM para armazenar o desenho (28x28)
 ┃ ┣ 📜 seven_segment_decoder.v     # Interface com o Display de 7 Seg para a resposta
 ┃ ┣ 📜 top_module.v & .lpf         # Top-level final e mapeamento físico dos pinos
 ┃ ┗ 📜 digitos_rom.pdf             # Geometria do dataset gravada na placa
 ┃
 ┗ 📂 MÍDIA                         # 📷 Fotos e Vídeos da bancada operando

 ⚙️ Como Funciona a Arquitetura Final (Pasta MNIST)
A pasta MNIST contém a versão definitiva que integra todos os subsistemas:

Captura: A OV2640 envia os pixels; o camera_top concatena em RGB565 e grava na RAM assíncrona.

Atenção Visual: O image_preprocessor extrai a Região de Interesse (ROI) utilizando thresholds físicos.

Inferência: No final de cada quadro de vídeo, o classificador recorta a imagem isolada, acessa os moldes na ROM e avalia, em 784 ciclos de clock e com paralelismo de 10 acumuladores, qual dígito foi escrito.

Exibição: O Controlador VGA renderiza a imagem com um overlay de Bounding Box, e o Display acende com o resultado numérico em nanossegundos de atraso lógico.

🚀 Como Sintetizar e Gravar na FPGA
Este projeto foi sintetizado e validado utilizando a toolchain de código aberto para Lattice (Yosys + NextPNR), mas é compatível com o software Lattice Diamond.

Clone o repositório:

Bash
git clone [https://github.com/Zazamartins/Visao-Computacional-com-FPGA.git](https://github.com/Zazamartins/Visao-Computacional-com-FPGA.git)
Navegue até a pasta do módulo que deseja testar (recomendado: cd MNIST).

Ajuste o arquivo top_module.lpf com os pinos exatos da sua variação da placa ECP5 e dos conectores que você está usando para a câmera/VGA.

Rode as ferramentas de síntese (ou use os scripts .config / SINTETIZA_FPGA.txt disponíveis nas pastas).

Grave o bitstream (out.bit) gerado na placa.

👨‍💻 Autor
Isaac Martins de Oliveira Braga e Sousa Estudante de Engenharia de Computação e Matemática na Universidade de Brasília (UnB) | Participante do Programa de Residência Tecnológica Embarcatech.

Sinta-se à vontade para abrir Issues, fazer forks ou utilizar os módulos .v da OV2640 nos seus próprios projetos de hardware embarcado!
