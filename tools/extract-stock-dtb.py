#!/usr/bin/env python3
"""Extract the DTB section from the stock Samsung boot.img (header v2).
usage: extract-stock-dtb.py boot.img stock-dtb.img
The result holds the concatenated SoC dtbs; board overlays stay in the DTBO partition."""
import struct, sys
d = open(sys.argv[1], "rb").read()
assert d[:8] == b"ANDROID!", "not an Android boot image"
ks, ka, rs, ra, ss, sa, ta, ps = struct.unpack_from("<8I", d, 8)
hdr_ver = struct.unpack_from("<I", d, 40)[0]
assert hdr_ver == 2, "expected boot image header v2, got %d" % hdr_ver
rdo_size, rdo_off, hs, ds, da = struct.unpack_from("<IQIIQ", d, 1632)
pages = lambda n: (n + ps - 1) // ps
off = ps * (1 + pages(ks) + pages(rs) + pages(ss) + pages(rdo_size))
open(sys.argv[2], "wb").write(d[off:off + ds])
print("dtb: %d bytes" % ds)
