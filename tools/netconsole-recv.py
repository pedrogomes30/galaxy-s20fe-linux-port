#!/usr/bin/env python3
"""Receive r8q netconsole UDP packets and append them, timestamped, to a log file."""
import socket
import sys
import time

path = sys.argv[1] if len(sys.argv) > 1 else "netconsole.log"
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
sock.bind(("0.0.0.0", 6666))
with open(path, "a", buffering=1) as log:
    log.write(f"--- listener started {time.strftime('%F %T')} ---\n")
    while True:
        data, _ = sock.recvfrom(65535)
        text = data.decode("utf-8", "replace")
        log.write(f"{time.strftime('%T')} {text}" if text.endswith("\n") else f"{time.strftime('%T')} {text}\n")
