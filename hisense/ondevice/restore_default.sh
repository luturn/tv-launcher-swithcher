#!/system/bin/sh
# 【电视本机版】一键还原默认桌面为【海信自带桌面】 (海信 E5S Pro / VIDAA / Android 14)
# 运行(在电脑上): adb -s <电视IP>:5555 shell sh /sdcard/hisense-launcher/restore_default.sh
# 本脚本直接在电视本机执行命令,不含 adb connect。
STOCK=com.jamdeo.tv.vod
STOCK_COMP=com.jamdeo.tv.vod/com.ju.main.launcher.LauncherActivity

setprop persist.vt.use_home_pkg "$STOCK"                      # 关键:海信开机/HOME键读这个
cmd package set-home-activity "$STOCK_COMP"                    # Android 标准默认(双保险)
cmd role add-role-holder android.app.role.HOME "$STOCK"       # HOME 角色(双保险)
echo "完成: 默认桌面 -> 海信自带"
echo -n "persist.vt.use_home_pkg = "; getprop persist.vt.use_home_pkg
