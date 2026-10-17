#!/usr/bin/env python3
# Run a command on the r8q over the USB ACM root console (macOS); prints output.
# Needs /etc/r8q/usb-serial-debug on the phone (serial console is off by default).
import os, sys, termios, time, glob, select, re
cmd = sys.argv[1]; timeout = float(sys.argv[2]) if len(sys.argv) > 2 else 30
dev = sorted(glob.glob('/dev/cu.usbmodem*'))[0]
fd = os.open(dev, os.O_RDWR | os.O_NOCTTY | os.O_NONBLOCK)
a = termios.tcgetattr(fd)
a[0] = 0; a[1] = 0; a[3] = 0; a[2] |= termios.CLOCAL | termios.CREAD
a[4] = a[5] = termios.B115200
termios.tcsetattr(fd, termios.TCSANOW, a)
def rd(t):
    buf = b''; end = time.time() + t
    while time.time() < end:
        r, _, _ = select.select([fd], [], [], 0.2)
        if r:
            try: buf += os.read(fd, 65536)
            except BlockingIOError: pass
    return buf
os.write(fd, b'\x03\n'); rd(1.0)
os.write(fd, b'stty -echo cols 250 2>/dev/null; export PAGER=cat SYSTEMD_PAGER=cat TERM=dumb\n'); rd(0.8)
tag = 'END%d' % time.time()
os.write(fd, (cmd + '; echo ' + tag + '\n').encode())
out = b''; end = time.time() + timeout
while time.time() < end:
    out += rd(0.5)
    if (tag + '\r').encode() in out or (tag + '\n').encode() in out: break
s = out.decode('utf-8', 'replace').replace('\r', '')
s = re.sub(r'\x1b\[[0-9;?]*[A-Za-z]', '', s)
s = s.split('\n' + tag)[0] if ('\n' + tag) in s else s
print(s.strip('\n'))
