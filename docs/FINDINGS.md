# Defeitos encontrados e como foram resolvidos

Cada linha: sintoma → causa → correção (arquivo deste repositório).

## Kernel (LineageOS 4.19, `kernel/patches/`)

| # | Sintoma | Causa | Correção |
|---|---|---|---|
| 0001 | Kernel não compila com `CONFIG_FANOTIFY` (exigido pelo Droidian) | variável `old_memcg` não declarada no fanotify do LineageOS | declarar a variável |
| 0002 | Todo `open()` de dispositivo misc trava (câmera a 100% de CPU) | `f_ncm.c` da Samsung chama `misc_register` a cada instância do gadget NCM, criando uma lista circular | contador de referências no registro |
| 0003 | IPv4 sem rotas: NetworkManager falha com "Nexthop has invalid gateway" | backport CIP marca `fc_gw_family` mesmo com gateway 0.0.0.0 | gateway 0.0.0.0 significa "sem gateway", como no upstream |
| 0004 | Bluetooth: `BUG_ON`/pânico ao abrir socket HCI (bluebinder) | Samsung desativou `hci_sock.c` com 10 blocos `#if 0` | restaurar `hci_sock.c` do 4.19.325 oficial |
| 0005 | Fones/viva-voz: `socket(RFCOMM): Protocol not supported` | Samsung comentou `rfcomm/`, `bnep/` e `hidp/` no Makefile | descomentar; ligar BNEP e RFCOMM_TTY |
| 0006 | Celular reinicia (pânico) quando o modem 5G cai | após SSR do SDX55 com falha (`MSI -ENOSPC`), `mhi_deinit_free_irq` usa `irq` nulo | checar ponteiro nulo |

Configuração: `CFI_CLANG`, `FTRACE` e `KALLSYMS_ALL` desligados e `RD_XZ` ligado. Assim o kernel
cru (51,7 MB) + initramfs xz + DTB cabem na partição BOOT de 64 MiB.

## Telefonia

| Sintoma | Causa | Correção |
|---|---|---|
| oFono: "SIM ausente", rádio nunca liga | RIL Samsung v5.0 em IRadio 1.5 só preenche a lista de apps 1.5 de `getIccCardStatus`; o plugin lê a lista antiga → 0 apps, fila bloqueada, `setRadioPower` nunca sai | `radioInterface = 1.4` (`rootfs/etc/ofono/binder.d/50-r8q.conf`) |
| `ofonod` com segfault em loop | abrir canal lógico do ISIM falha (`MISSING_RESOURCE`) e `open_channel_cb` percorre a lista de watches enquanto o simfs remove o item atual (use-after-free) | `userspace-patches/ofono/` |
| `rild` cai ~1 s depois de ligar o rádio, em loop | o probe `getMute` (`RIL_REQUEST_GET_MUTE`) do plugin derruba o gerenciador de som do `libsec-ril` (scudo/SIGSEGV na thread ESAR) | `userspace-patches/ofono-binder-plugin/` |
| `rild` cai ao consultar bloqueio de chamadas | `ofono2mm` faz `GetProperties` em CallBarring/Forwarding/Settings; o caminho de erro do `libsec-ril` libera memória duas vezes | `userspace-patches/ofono2mm/` |
| Modem fica desligado após reinício do `rild` | o oFono recria o modem com `Online=false` e rede 3G | `r8q-modem-keeper` |
| Dados móveis não sobem sozinhos | conexão "Padrão" com `autoconnect=no` | `nmcli c modify Padrão connection.autoconnect yes` |

## Áudio

| Sintoma | Causa | Correção |
|---|---|---|
| PulseAudio com segfault ao abrir o alto-falante | HAL Samsung é API 2.0 (sem `create_audio_patch`), incompatível com o módulo "modern" | `pulseaudio-modules-droid-jb2q` + HAL vendor no contêiner (`r8q-audio-hal.service`) |
| Microfone grava silêncio | porta padrão era `input-wired_headset` (o aparelho não tem P2) | política sem portas P2/FM/aux (`rootfs/etc/pulse/r8q/`) + `set-source-port` |
| Volume sempre no máximo | o sink usa controle por hardware, que o HAL ignora | `quirks=+no_hw_volume` |

## Outros

| Sintoma | Causa | Correção |
|---|---|---|
| Watchdog do kernel reinicia ao tirar o cabo USB | netconsole no gadget USB + nível de log 8 prendiam a CPU | netconsole só com `/etc/r8q/netconsole`; `kernel.printk = 4 4 1 7` |
| Tela preta para sempre após uma falha do Phosh | `OnFailure=getty@tty1`, que tem `Conflicts` com o phosh | mascarar `getty@tty1`; `90-r8q-robust.conf` |
| Vibração imperceptível | intensidade caía para 40 de 10000 | `tmpfiles.d/52-r8q-vibrator.conf` |
| Lanterna não acende | o LED da PM8150L não está ligado; o flash é o KTD2692 em `rear_flash`, e valores fora de 0/1/100/1001-1010 disparam o **flash em corrente máxima** | flashlightd no modo 1/0 + regra udev |
| Apps pedem senha que não é a do usuário | chaveiro de login criado com outra senha | recriar `~/.local/share/keyrings/login.keyring` |
| Podman com root: erro na rede | `nftables` do kernel incompleto | `firewall_driver = "iptables"` |
| Podman com root: `crun: cannot resolve null` | crun no kernel 4.19 | `runtime = "runc"` |
| Pânico do kernel em uso pesado | memória esgotada → modem perde a EFS e reinicia → defeito MHI | swap em arquivo + patch 0006 |

## Ainda em aberto

- **Digital (Goodix GW9558 sob a tela):** `r8q-udfps` liga o modo FOD do toque e envia
  `sehRequest(22, 2/1)` ao HAL, que aceita, mas o sensor não captura. Falta a "máscara de
  digital" com brilho alto, que no Android vem de uma camada marcada no HWC.
- **Indicador de sinal:** com IRadio 1.4 o oFono mostra 1% mesmo com RSRP −112 dBm.
- **Tentativa com kernel mainline** (`attempts/mainline/`): o Mu-Silicium UEFI e o kernel 7.1
  rodavam, mas um núcleo travava acima do EL1, preso no firmware.
