# Linux (Droidian) no Samsung Galaxy S20 FE 5G — SM-G781B (r8q)

> **English summary:** Droidian (Debian + Phosh, Halium/libhybris) running on the Galaxy S20 FE 5G
> (Snapdragon 865, codename r8q) with a patched LineageOS 4.19 downstream kernel. Calls, SMS,
> 4G data, Wi-Fi, Bluetooth, GPS, audio, sensors, camera (photos) and Podman containers work.
> This repo holds the kernel patches, userspace patches, rootfs overlay and the notes on every
> bug found along the way.

Este repositório reúne tudo o que foi preciso para transformar o S20 FE 5G (SM-G781B) num
celular Linux de uso diário: **Droidian** (Debian trixie + Phosh) sobre o kernel **downstream
4.19** do LineageOS, com os drivers e serviços do Android (vendor) rodando num contêiner
Halium.

## Estado

| Componente | Estado | Observação |
|---|---|---|
| Tela, toque, GPU | Funciona | Phosh via hwcomposer (libhybris) |
| Wi-Fi | Funciona | QCA6390 |
| Chamadas e SMS | Funciona | oFono (binder) + correções no oFono e no plugin |
| Dados móveis 4G | Funciona | TIM BR testada |
| Áudio (alto-falante, microfone, volume) | Funciona | HAL vendor + pulseaudio-modules-droid-jb2q |
| Bluetooth | Funciona | precisou de 3 correções no kernel |
| GPS | Funciona | geoclue (hybris) |
| Sensores (acelerômetro, luz, proximidade, bússola) | Funciona | sensorfw / iio-sensor-proxy |
| Vibração, lanterna | Funciona | correções de intensidade e de controle do flash |
| Câmera | Fotos funcionam | vídeo a confirmar |
| Contêineres | Funciona | Podman (com e sem root) + Pods (interface touch) |
| Waydroid | Instala e roda | |
| NFC | Chip responde | leitura de etiquetas a confirmar |
| Digital (sob a tela) | Não funciona | o sensor óptico não captura sem o modo de brilho especial |
| Indicador de sinal | Mostra valor errado | conversão de RSRP para % com IRadio 1.4 |

## Estrutura

| Pasta | Conteúdo |
|---|---|
| `kernel/` | patches, configuração completa, fragmento Droidian e `build.sh` |
| `userspace-patches/` | patches do oFono, plugin binder do oFono, ofono2mm e flashlightd |
| `rootfs/` | arquivos instalados no aparelho (serviços, regras udev, configs, scripts `r8q-*`) |
| `tools/` | montar a boot.img, extrair a DTB original, gerar o initramfs, utilitários do PC |
| `docs/` | instalação, hardware e a lista de defeitos encontrados com causa e correção |
| `attempts/mainline/` | tentativa anterior com kernel mainline (abandonada) |

## Como começar

1. Leia `docs/INSTALL.md`. **O processo apaga o aparelho e dispara o Knox.**
2. Compile o kernel com `kernel/build.sh` e monte a imagem com `tools/make-bootimg.sh`.
3. Instale o rootfs do Droidian (api30), aplique `rootfs/` e os pacotes corrigidos.
4. Rode `sudo r8q-check` no aparelho para conferir se tudo está no lugar.

## Segurança

- O usuário padrão do Droidian é `droidian` com senha `1234`. Troque-a.
- O terminal root pela USB só existe se o arquivo `/etc/r8q/usb-serial-debug` for criado.
- O SSH aceita apenas chave (`/etc/ssh/sshd_config.d/10-r8q-keyonly.conf`).
- **Nunca publique** cópias das partições EFS/modemst/persist do seu aparelho: elas contêm IMEI e
  dados de calibração.

## Créditos

- [Droidian](https://droidian.org), [LineageOS](https://lineageos.org) (kernel `android_kernel_samsung_sm8250`),
  mer-hybris (oFono binder plugin, libgbinder), Phosh, ofono2mm, mobile-power-saver.
- Os patches do kernel seguem a licença do kernel (GPL-2.0). Os patches de cada programa seguem a
  licença do respectivo projeto.
