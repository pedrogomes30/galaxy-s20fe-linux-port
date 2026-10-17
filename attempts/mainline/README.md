# Tentativa com kernel mainline (abandonada)

Antes do Droidian, o aparelho rodou Arch Linux ARM com kernel **mainline 7.1.2** usando o
projeto [Itzkristis/r8q-arch](https://github.com/Itzkristis/r8q-arch): UEFI Mu-Silicium na
partição BOOT, ESP na `cache`, rootfs na `userdata`. Plasma Mobile chegou a rodar na GPU, com
toque, Wi-Fi e bateria.

Patches extras usados nessa fase:

| Patch | Motivo |
|---|---|
| `0009-r8q-ufs-qcom-disable-writebooster.patch` | a UFS deste aparelho rejeita a consulta de WriteBooster; o console ficava em loop de erro |
| `0010-r8q-rcu-stall-psci-affinity-info.patch` | diagnóstico: imprime o estado PSCI do núcleo travado no aviso de RCU stall |

Achados:
- O cmdline forçado do r8q-arch exige `/r8q.dtb` na raiz da ESP; sem ele, o EFI stub aborta
  ("Failed to Find an Operating System").
- Serviços de runtime EFI do Mu-Silicium (rtc-efi) travavam um núcleo: use `efi=noruntime`.
- Mesmo com `efi=noruntime nohlt`, um núcleo para de responder após alguns minutos, inclusive a
  pseudo-NMIs, com o PSCI dizendo que ele está ligado. Ele fica preso acima do EL1, no firmware.
  Sem solução no lado do Linux, por isso o porte seguiu para o kernel downstream.
