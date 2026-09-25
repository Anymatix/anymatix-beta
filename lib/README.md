# libfuse.so.2 — what it is and why it is here

AppImages mount themselves with FUSE 2 (`libfuse.so.2`). Ubuntu 22.04 and later
no longer install it by default, so the Anymatix AppImage would not start on a
stock desktop. `install.sh` uses the copy here **only when the system has no
`libfuse.so.2` of its own**, and only for the Anymatix launcher it writes
(`LD_LIBRARY_PATH` set for that one process). Nothing is installed system-wide
and no root is needed; the mount helper (`fusermount`) is the system's own.

| file | from | sha256 |
|---|---|---|
| `linux-x86_64/libfuse.so.2` | Ubuntu 22.04 `libfuse2_2.9.9-5ubuntu3_amd64.deb` (archive.ubuntu.com) | `0c2b629ecbb29c36a8089e15fa69216869494850a7d00710ebe7707dc1b3b828` |
| `linux-aarch64/libfuse.so.2` | Ubuntu 22.04 `libfuse2_2.9.9-5ubuntu3_arm64.deb` (ports.ubuntu.com) | `01734bd23c8f6f3b5ac7a662c7a5cf6156cdfd1239c0c1cbf44c30cb6d7a3200` |

Unmodified binaries. Both need glibc 2.34 or later (Ubuntu 22.04+, Debian 12+,
Fedora 35+); older systems still ship `libfuse2` themselves.

**Licence.** libfuse is free software under the GNU LGPL v2.1 (library) — full
terms and authors in `libfuse2-copyright`, as shipped by Debian/Ubuntu. Source:
the `fuse` 2.9.9-5ubuntu3 source package,
https://launchpad.net/ubuntu/+source/fuse/2.9.9-5ubuntu3 , and upstream
https://github.com/libfuse/libfuse (tag `fuse-2.9.9`).
