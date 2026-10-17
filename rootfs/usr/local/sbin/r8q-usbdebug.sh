#!/bin/sh
# r8q USB gadget: NCM network (172.16.42.1/24, SSH key-only) independent of Android.
# ACM serial console (root autologin on ttyGS0) ONLY if /etc/r8q/usb-serial-debug exists.
for d in /sys/bus/msm_subsys/devices/*; do echo RELATED > $d/restart_level 2>/dev/null; done
G=/sys/kernel/config/usb_gadget/r8qdbg
mountpoint -q /sys/kernel/config || mount -t configfs none /sys/kernel/config
for g in /sys/kernel/config/usb_gadget/*; do
  [ -e "$g/UDC" ] && [ "$g" != "$G" ] && echo "" > "$g/UDC" 2>/dev/null
done
mkdir -p $G && cd $G || exit 1
echo 0x1d6b > idVendor; echo 0x0104 > idProduct; echo 0x0200 > bcdUSB
echo 0xEF > bDeviceClass; echo 0x02 > bDeviceSubClass; echo 0x01 > bDeviceProtocol
mkdir -p strings/0x409
SERIAL=$(tr " " "\n" < /proc/cmdline | sed -n "s/^androidboot.serialno=//p")
echo "${SERIAL:-r8q}" > strings/0x409/serialnumber
echo Samsung > strings/0x409/manufacturer
echo "r8q Droidian debug" > strings/0x409/product
mkdir -p configs/c.1/strings/0x409
echo "NCM" > configs/c.1/strings/0x409/configuration
echo 500 > configs/c.1/MaxPower
mkdir -p functions/ncm.usb0
echo 02:22:33:44:55:01 > functions/ncm.usb0/host_addr 2>/dev/null
echo 02:22:33:44:55:02 > functions/ncm.usb0/dev_addr 2>/dev/null
if [ -e /etc/r8q/usb-serial-debug ]; then
  mkdir -p functions/acm.gs0
  [ -e configs/c.1/acm.gs0 ] || ln -s functions/acm.gs0 configs/c.1/
  mkdir -p /run/systemd/system/serial-getty@ttyGS0.service.d
  printf "[Service]\nExecStart=\nExecStart=-/sbin/agetty --autologin root --keep-baud 115200,57600,38400,9600 %%I \$TERM\n" \
    > /run/systemd/system/serial-getty@ttyGS0.service.d/autologin.conf
fi
[ -e configs/c.1/ncm.usb0 ] || ln -s functions/ncm.usb0 configs/c.1/
UDC=$(ls /sys/class/udc | head -1)
echo "$UDC" > UDC
sleep 1
IF=$(cat functions/ncm.usb0/ifname 2>/dev/null || echo usb0)
ip link set "$IF" up
ip addr add 172.16.42.1/24 dev "$IF" 2>/dev/null
# netconsole -> Mac 172.16.42.14:6666 over usb0 (DEBUG ONLY: touch /etc/r8q/netconsole)
# Off by default: with the cable unplugged, netpoll on the gadget + loglevel 8
# console spam stalled CPUs -> msm watchdog bark (2026-10-16 21:02).
if [ -e /etc/r8q/netconsole ]; then
  echo 8 > /proc/sys/kernel/printk
  NC=/sys/kernel/config/netconsole/r8q
  if [ -d /sys/kernel/config/netconsole ] && [ ! -d $NC ]; then
    mkdir $NC; echo "$IF" > $NC/dev_name; echo 172.16.42.1 > $NC/local_ip
    echo 172.16.42.14 > $NC/remote_ip; echo 6666 > $NC/remote_port
    echo 02:22:33:44:55:01 > $NC/remote_mac; echo 1 > $NC/enabled
  fi
fi
echo "r8q-usbdebug: udc=$UDC if=$IF"
