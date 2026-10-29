#!/usr/bin/env bash
# =============================================================================
# 海信 E5S Pro (VIDAA_TV, Android 14 / SDK 34, arm64)  默认桌面切换/还原 核心脚本
# Hisense E5S Pro default-launcher switch & restore (core script)
# -----------------------------------------------------------------------------
# 作用 / Purpose:
#   在 "海信自带桌面" 和 "当贝桌面" 之间切换系统默认 HOME(桌面)。
#   不停用、不卸载任何桌面;自带桌面始终保留,可随时一键还原。
#   Switch the system default HOME between the stock Hisense launcher and the
#   Dangbei launcher. NOTHING is disabled/uninstalled; the stock launcher stays
#   installed & enabled and can be restored in one step.
#
# 原理 / How it works:
#   这台海信(VIDAA)开机和 HOME 键用的是它自己的私有属性 persist.vt.use_home_pkg,
#   而不是 Android 标准的 RoleManager HOME 角色。实测:只有改这个属性才真正生效。
#     setprop persist.vt.use_home_pkg <包名>     # 关键!persist 持久化,重启保留
#   同时也设 Android 标准默认(双保险,不改动任何 App、完全可逆):
#     cmd package set-home-activity <组件>
#     cmd role    add-role-holder android.app.role.HOME <包名>
#
# 关键组件 / Key components (本机实测值):
#   海信自带桌面 STOCK  : com.jamdeo.tv.vod/com.ju.main.launcher.LauncherActivity
#   当贝桌面     DANGBEI : com.dangbei.tvlauncher/com.dangbei.launcher.ui.main.MainActivity
#
# 前置条件 / Prerequisites:
#   1) 电视已开: 开发者模式 + USB/ADB 调试。
#      (设置→系统→关于→"版本号"连点7次;再到开发者选项打开 USB 调试)
#   2) 电脑有 adb(本目录上级的 platform-tools 即可),电视与电脑同一网络。
#   3) 首次连接电视会弹"允许调试",用遥控器选"一律允许"。
#
# 用法 / Usage:
#   ./switch_launcher.sh dangbei  [电视IP]   # 默认桌面 -> 当贝
#   ./switch_launcher.sh restore  [电视IP]   # 一键还原 -> 海信自带桌面
#   ./switch_launcher.sh status   [电视IP]   # 查看当前默认桌面
#   电视IP 省略时用下面默认值;换网络后 IP 可能变,可作第2参数传入或改这里。
#   (在电视上查 IP: 设置→网络→当前连接→详情)
# =============================================================================
set -u

# ---- 配置 / Config (如有变化在此修改) --------------------------------------
TV_IP_DEFAULT="172.20.10.2"
STOCK="com.jamdeo.tv.vod/com.ju.main.launcher.LauncherActivity"
DANGBEI="com.dangbei.tvlauncher/com.dangbei.launcher.ui.main.MainActivity"
STOCK_PKG="com.jamdeo.tv.vod"
DANGBEI_PKG="com.dangbei.tvlauncher"
# ---------------------------------------------------------------------------

ACTION="${1:-status}"
TV_IP="${2:-$TV_IP_DEFAULT}"
TARGET="$TV_IP:5555"

# 定位 adb:依次找 脚本同目录/adb、同目录/platform-tools/adb、上级/platform-tools/adb、系统 adb
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if   [ -x "$SCRIPT_DIR/adb" ];                     then ADB="$SCRIPT_DIR/adb"
elif [ -x "$SCRIPT_DIR/platform-tools/adb" ];      then ADB="$SCRIPT_DIR/platform-tools/adb"
elif [ -x "$SCRIPT_DIR/../platform-tools/adb" ];   then ADB="$SCRIPT_DIR/../platform-tools/adb"
elif command -v adb >/dev/null 2>&1;               then ADB="adb"
else
  echo "[错误] 找不到 adb。请把 adb 放到本脚本同目录,或安装 Android platform-tools。" >&2
  exit 1
fi

connect() {
  "$ADB" connect "$TARGET" >/dev/null 2>&1
  sleep 1
  state="$("$ADB" devices | awk -v t="$TARGET" '$1==t{print $2}')"
  if [ "$state" = "unauthorized" ]; then
    echo "[提示] 电视上出现"允许调试"弹窗,请用遥控器选"一律允许"后重试。" >&2
    exit 2
  fi
  if [ "$state" != "device" ]; then
    echo "[错误] 连不上电视 $TARGET (状态: ${state:-无})。" >&2
    echo "       请确认: 电视已开 ADB 调试、与本机同网、IP 正确(可作第2参数传入)。" >&2
    exit 3
  fi
}

sh_() { "$ADB" -s "$TARGET" shell "$@" 2>&1 | tr -d '\r'; }

# 判断某包是否已安装(已安装返回 0)。pm path 已安装会输出 package:/.../base.apk
pkg_installed() { sh_ "pm path $1" | grep -q '^package:'; }

set_home() { # $1=组件  $2=包名
  # 【关键】海信 VIDAA 开机与 HOME 键都看这个私有属性;persist 持久化,重启保留。
  #  这才是这台海信真正决定默认桌面的开关(Android 的 HOME 角色它开机时不认)。
  sh_ "setprop persist.vt.use_home_pkg $2" >/dev/null 2>&1
  # Android 标准机制,作为双保险。
  sh_ "cmd package set-home-activity $1" >/dev/null 2>&1
  sh_ "cmd role add-role-holder android.app.role.HOME $2" >/dev/null 2>&1
}

show_status() {
  prop="$(sh_ "getprop persist.vt.use_home_pkg")"
  role="$(sh_ "cmd role get-role-holders android.app.role.HOME")"
  echo "海信开机桌面属性 persist.vt.use_home_pkg: ${prop:-未知}"
  echo "Android HOME 角色:                        ${role:-未知}"
  case "$prop" in
    *dangbei*) echo "=> 当前默认桌面: 当贝桌面" ;;
    *jamdeo*)  echo "=> 当前默认桌面: 海信自带桌面" ;;
    *)         echo "=> 其它/未知" ;;
  esac
}

case "$ACTION" in
  dangbei)
    connect
    # 安全保险:当贝未安装时绝不设置,避免把开机桌面指向不存在的应用导致黑屏/无桌面。
    if ! pkg_installed "$DANGBEI_PKG"; then
      echo "[已中止] 未检测到当贝桌面 ($DANGBEI_PKG) 已安装!" >&2
      echo "         为避免把默认桌面指向不存在的应用(可能导致开机黑屏/无桌面)," >&2
      echo "         本次【未做任何修改】。请先安装当贝桌面,再运行本命令。" >&2
      exit 4
    fi
    echo "设置默认桌面为【当贝桌面】..."
    set_home "$DANGBEI" "$DANGBEI_PKG"
    show_status
    echo "完成。按遥控器 HOME 或重启电视即进入当贝。"
    ;;
  restore)
    connect
    echo "一键还原默认桌面为【海信自带桌面】..."
    set_home "$STOCK" "$STOCK_PKG"
    show_status
    echo "完成。已恢复海信原桌面。"
    ;;
  status)
    connect
    show_status
    ;;
  *)
    echo "用法: $0 {dangbei|restore|status} [电视IP]"
    exit 1
    ;;
esac
