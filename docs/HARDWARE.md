# Hardware do S20 FE 5G (SM-G781B, r8q)

Levantamento feito no Android 13 (firmware G781BXXSIHYJ2) com root, antes da instalação.
A coluna "Mainline" se refere ao suporte no kernel Linux oficial na época. Este porte usa o
kernel downstream (LineageOS 4.19) e os drivers do vendor; veja o README para o estado atual.


| Componente | Chip / modelo | Barramento | Mainline (em 2026-10) |
|---|---|---|---|
| SoC | Qualcomm SM8250 (Snapdragon 865, "kona"), 4x A77 até 2.84 GHz + 4x A55 | – | Sim, bom |
| RAM | 6 GB (5.76 GB visíveis) | – | Sim |
| Armazenamento | Samsung UFS KLUDG4UHDB-B2D1 (128 GB) | UFS | Sim (já no dts r8q) |
| GPU | Adreno 650 v3 | – | Sim (msm/freedreno), precisa de a650_zap assinado (salvo) |
| Tela | Samsung S6E3FC3 / AMS646YD01, 1080x2400 FHD+, 120 Hz, lcd_id 0x805081 | DSI | Só framebuffer simples; falta driver de painel (pode ser gerado do dtb downstream) |
| **Touch** | **STMicro FTS5CU56A**, FW ST05160009, 16x34 canais | I2C-5 @0x49 | **Patches "Input: stmfts – support FTS5" em revisão (v8, set/2026), ainda não incorporados** |
| Teclas | Power/Vol (PM8150 pon + gpio-keys) | – | Sim (já no dts) |
| Wi-Fi | Qualcomm QCA6390 (PCIe 17cb:1101) | PCIe 0 | Sim, driver ath11k; precisa de board data do aparelho |
| Bluetooth | QCA6390 "hastings" | UART | Sim (hci_qca) |
| Modem 5G | Qualcomm SDX55 (PCIe 17cb:0306) | PCIe 2 / MHI | Parcial (mhi + ModemManager) |
| Carregador / PMIC | Maxim MAX77705 (charger + fuel gauge), NXP PCA9468 (carga direta), IDT MFC (sem fio), Halo HL6111R | I2C-2/0/10 | MAX77705 tem driver mainline; demais não |
| Bateria | 4500 mAh (GH43-05052C) | – | Depende do MAX77705 |
| Áudio | 2x Cirrus CS35L41 (amplificadores) + WCD/ADSP kona | I2C-7 | CS35L41 tem driver; roteamento ADSP precisa de trabalho |
| Câmeras | Traseira IMX555 (principal), S5K3L6 (tele), HI847 (ultra); frontal IMX616 | CCI | Não (sem driver para esses sensores) |
| Sensores | LSM6DSO (acel/giro), AK09918 (bússola), STK31610 (luz), TCS3407 | SLPI (sensor hub) | Difícil: ficam atrás do SLPI/Qualcomm sensors |
| NFC | Samsung sec-nfc + NXP nq-nci | I2C-10/3 | Não / parcial |
| Botão de grip | A96T3X6 | I2C-1 | Não |
| Digital | Goodix GW9558X (sob a tela) | SPI-7 | Não |
| Rádio FM | RTC6226 | I2C-10 | Não |

## Kernel original (downstream)

- Linux 4.19.113-27223811 (clang 10), **monolítico**: todos os drivers estão compilados dentro do kernel (só 5 módulos `=m`, nenhum instalado).
- A configuração do kernel original desliga coisas que distros Linux exigem (DEVTMPFS, VT, SYSVIPC, USER_NS), então o binário original **não serve direto** para Linux. Para o caminho "downstream" é preciso recompilar com o código-fonte da Samsung (opensource.samsung.com, SM-G781B).
