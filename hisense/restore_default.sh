#!/usr/bin/env bash
# 一键:还原默认桌面为【海信自带桌面】 / One-click: restore stock Hisense launcher
# 海信 E5S Pro 专用。详细说明见 README.md 与 switch_launcher.sh。
# 可选:把电视IP作为第1个参数传入(换网络后IP会变),例: ./restore_default.sh 192.168.1.23
exec "$(cd "$(dirname "$0")" && pwd)/switch_launcher.sh" restore "$@"
