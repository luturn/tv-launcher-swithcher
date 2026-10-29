#!/system/bin/sh
# 【电视本机版】把默认桌面设为【当贝桌面】  (海信 E5S Pro / VIDAA / Android 14)
# 运行(在电脑上): adb -s <电视IP>:5555 shell sh /sdcard/hisense-launcher/set_dangbei.sh
# 本脚本直接在电视本机执行命令,不含 adb connect(连接是电脑端的事)。
DANGBEI=com.dangbei.tvlauncher
DANGBEI_COMP=com.dangbei.tvlauncher/com.dangbei.launcher.ui.main.MainActivity

# 安全保险:当贝未安装绝不设置,避免把开机桌面指向不存在的应用导致开机黑屏。
if ! pm path "$DANGBEI" | grep -q '^package:'; then
  echo "[已中止] 未检测到当贝($DANGBEI)已安装,未做任何修改。"
  exit 1
fi

setprop persist.vt.use_home_pkg "$DANGBEI"                    # 关键:海信开机/HOME键读这个
cmd package set-home-activity "$DANGBEI_COMP"                  # Android 标准默认(双保险)
cmd role add-role-holder android.app.role.HOME "$DANGBEI"     # HOME 角色(双保险)
echo "完成: 默认桌面 -> 当贝"
echo -n "persist.vt.use_home_pkg = "; getprop persist.vt.use_home_pkg
