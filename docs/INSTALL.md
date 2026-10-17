# Instalação

Aparelho testado: **SM-G781B** (S20 FE 5G, Snapdragon 865, `r8q`), firmware Android 13
`G781BXXSIHYJ2`. Outros modelos (G780F/G780G Exynos, G781U/W/N) **não** são compatíveis.

> **Aviso:** desbloquear o bootloader dispara o Knox (irreversível), apaga o aparelho e tira o
> Samsung Pay/Pasta Segura de vez. Faça backup antes.

## 0. Ferramentas no PC

- `heimdall` (ramo do grimler, 2.2.x) para o modo download.
- `adb` e TWRP para o r8q (`twrp-3.7.1_12-3-r8q.img` foi o usado).
- Docker (ou Debian trixie) para compilar o kernel, `mkbootimg`, `xz`.

## 1. Bootloader, vbmeta e TWRP

1. Opções do desenvolvedor → **Desbloqueio OEM**. Desligue, segure Volume+ e Volume− e conecte
   o cabo; no modo download, segure Volume+ para desbloquear.
2. Grave uma `vbmeta.img` com verificação desligada (flags = 3, por exemplo a gerada pelo Magisk
   ou por `avbtool make_vbmeta_image --flags 3`) e o TWRP:
   ```
   heimdall flash --VBMETA vbmeta-disabled.img --RECOVERY twrp.img --no-reboot
   ```
3. Para entrar no TWRP: Volume− + Power para reiniciar, e logo em seguida Volume+ + Power com o
   cabo conectado.
4. **Faça backup** das partições `efs`, `sec_efs`, `modemst1`, `modemst2`, `fsg` e `persist`
   (`dd` pelo `adb shell`). Guarde em local privado: contém o IMEI.
5. No TWRP: `twrp format data` (deixa `/data` em f2fs). Isso também acaba com o loop em que o
   TWRP reiniciava sozinho.

Dicas de heimdall:
- Depois de uma sessão que falhou, o heimdall só volta a funcionar após reiniciar o aparelho
  no modo download.
- `heimdall print-pit --no-reboot` seguido de `heimdall flash --resume ...` evita reinícios.
- Imagens **menores que a partição** gravadas na BOOT terminam com "Failed to receive session
  end confirmation" e o aparelho volta ao modo download. Grave a boot.img com `dd` (TWRP ou o
  próprio Linux) ou complete-a até 64 MiB.
- Depois de qualquer gravação, a Samsung entra no recovery uma vez: escolha **Reboot**, nunca
  "wipe".

## 2. Rootfs do Droidian (API 30)

O vendor do r8q é **VNDK 30** (`ro.vndk.version=30`). Use o rootfs **api30**; o api33 quebra o
linkerconfig do contêiner Android.

Imagem usada: `droidian-OFFICIAL-phosh-phone-rootfs-api30-arm64-101.20251130_20251207.zip`.

O instalador do zip travava o TWRP no meio da extração. Os passos dele, feitos à mão:

```
unzip droidian-...api30...zip data/rootfs.img         # no PC
adb push data/rootfs.img /data/rootfs.img              # TWRP
adb shell e2fsck -fy /data/rootfs.img
adb shell resize2fs /data/rootfs.img 90G               # deixe espaço livre para swap
adb shell ln -s /halium-system/var/lib/lxc/android/android-rootfs.img /data/android-rootfs.img
```

## 3. Kernel e boot.img

```
kernel/build.sh                                        # gera kout/arch/arm64/boot/Image
tools/extract-stock-dtb.py boot.img stock-dtb.img      # boot.img do firmware original
tools/make-initrd.sh linux-initramfs-halium-generic_*_arm64.deb droidian-initrd.xz
tools/make-bootimg.sh kout/arch/arm64/boot/Image droidian-initrd.xz stock-dtb.img boot-r8q.img
```

Grave no TWRP:
```
adb push boot-r8q.img /tmp/ && adb shell dd if=/tmp/boot-r8q.img of=/dev/block/by-name/boot
```

Mantenha a partição **DTBO original**: as overlays de placa ficam nela.

## 4. Antes do primeiro boot: overlay do rootfs

Monte `rootfs.img` num Linux (ou no TWRP com `setenforce 0`) e copie a pasta `rootfs/` deste
repositório para dentro dela, preservando os caminhos. Depois, já no aparelho:

```
systemctl enable r8q-usbdebug r8q-audio-hal r8q-modem-keeper
systemctl mask getty@tty1                       # OnFailure do phosh deixava a tela preta
systemctl mask mtp-configfs@rndis.service       # a USB passa a ser a rede NCM do r8q-usbdebug
systemctl --global mask audiosystem-passthrough.service   # conflita com o HAL de áudio no PulseAudio
systemd-tmpfiles --create /etc/tmpfiles.d/52-r8q-vibrator.conf
```

As regras udev de `rootfs/etc/udev/rules.d/` precisam estar no lugar **antes** do primeiro boot:
sem a `71-r8q-binder.rules`, o Phosh não consegue falar com o hwcomposer e a tela fica preta.

`r8q-usbdebug` cria a rede USB `172.16.42.1/24` (NCM, funciona no macOS). Com o arquivo
`/etc/r8q/usb-serial-debug`, cria também um terminal root pela USB, útil só na primeira
configuração. Apague-o depois.

## 5. Pacotes

```
apt install openssh-server pulseaudio-modules-droid-jb2q
```

- **PulseAudio:** troque `pulseaudio-modules-droid-modern` por `-jb2q`. O HAL da Samsung é API
  2.0, e o módulo "modern" dá segfault. Desvie o `module-droid-hidl.so`:
  `dpkg-divert --local --rename --divert .../module-droid-hidl.so.r8q-disabled --add .../module-droid-hidl.so`.
- **oFono:** recompile com `userspace-patches/ofono/` (empacotamento do Droidian, versão
  `+r8q1`).
- **ofono-binder-plugin:** recompile `binderplugin.so` do fork `droidian/ofono-binder-plugin`
  (commit 828e0a0) com `userspace-patches/ofono-binder-plugin/` e instale com `dpkg-divert`.
- **ofono2mm** e **flashlightd:** aplique os patches e instale com `dpkg-divert`.
- Trave os pacotes corrigidos:
  ```
  apt-mark hold ofono ofono-binder-plugin libofonobinderpluginext ofono2mm flashlightd pulseaudio-modules-droid-jb2q
  ```

## 6. Contêineres (opcional)

```
apt install podman runc uidmap passt slirp4netns fuse-overlayfs netavark aardvark-dns catatonit
systemctl --user enable --now podman.socket            # como o usuário droidian
flatpak install flathub com.github.marhkb.Pods         # interface touch
```

As configurações em `rootfs/etc/containers/containers.conf.d/` mudam a rede para `iptables`
(o `nftables` do kernel é incompleto) e o executor para `runc` (o `crun` falha com root).

## 7. Swap (recomendado)

Com 6 GB de RAM, o Waydroid e navegadores esgotam a memória. Quando isso acontece, o modem
externo perde a transferência da EFS e reinicia. Crie um arquivo de swap no f2fs:

```python
import os, fcntl, struct
fd = os.open("/userdata/swapfile", os.O_CREAT | os.O_EXCL | os.O_RDWR, 0o600)
fcntl.ioctl(fd, 0x4004f50d, struct.pack("I", 1))     # F2FS_IOC_SET_PIN_FILE
os.posix_fallocate(fd, 0, 10 * 1024**3)
os.close(fd)
```
```
mkswap /userdata/swapfile && swapon /userdata/swapfile
echo "/userdata/swapfile none swap defaults,pri=-10,nofail 0 0" >> /etc/fstab
```

## 8. Conferência

```
echo "$(stat -c%s boot-r8q.img) $(sha256sum boot-r8q.img | cut -c1-16)" > /etc/r8q/expected-boot
sudo r8q-check
```
