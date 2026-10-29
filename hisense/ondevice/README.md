================================================================================
海信 E5S Pro 默认桌面 切换/还原 —— 电视本机存档
存放位置: /sdcard/hisense-launcher/
================================================================================

【这是什么】
在"海信自带桌面"和"当贝桌面"之间切换系统默认桌面,不停用/不卸载任何桌面。
这是放在电视里的一份备份,万一电脑端脚本丢了,可据此复现或修改。

【设备信息(实测)】
机型: 海信 E5S Pro, 系统 VIDAA_TV, Android 14 (SDK 34), arm64-v8a

【桌面组件】
海信自带: com.jamdeo.tv.vod/com.ju.main.launcher.LauncherActivity
当贝    : com.dangbei.tvlauncher/com.dangbei.launcher.ui.main.MainActivity

【核心原理(重要)】
这台海信开机 / HOME 键读的是它的私有属性 persist.vt.use_home_pkg
(persist 持久、重启保留),不是 Android 标准 HOME 角色。
所以主开关是这个属性,另外再设标准默认作双保险:
  setprop persist.vt.use_home_pkg <包名>
  cmd package set-home-activity <组件>
  cmd role    add-role-holder android.app.role.HOME <包名>

【怎么运行(需要电脑 + adb;电视本身没终端,无法自己点运行)】
1) 电视开启 开发者模式 + USB/ADB 调试(方法见文末),电视与电脑同一网络。
2) 电脑执行:
   adb connect <电视IP>:5555          # 首次会在电视弹"允许调试",选"一律允许"
   adb -s <电视IP>:5555 shell sh /sdcard/hisense-launcher/set_dangbei.sh      # 设为当贝
   adb -s <电视IP>:5555 shell sh /sdcard/hisense-launcher/restore_default.sh  # 还原海信
   查看当前默认桌面:
   adb -s <电视IP>:5555 shell getprop persist.vt.use_home_pkg

【纯手动命令(脚本都丢了也能救)】
还原海信:
  adb -s <IP>:5555 shell setprop persist.vt.use_home_pkg com.jamdeo.tv.vod
  adb -s <IP>:5555 shell cmd package set-home-activity com.jamdeo.tv.vod/com.ju.main.launcher.LauncherActivity
设为当贝:
  adb -s <IP>:5555 shell setprop persist.vt.use_home_pkg com.dangbei.tvlauncher
  adb -s <IP>:5555 shell cmd package set-home-activity com.dangbei.tvlauncher/com.dangbei.launcher.ui.main.MainActivity
改完按 HOME 或重启即生效。

【注意】
- 设当贝前确认当贝已安装(set_dangbei.sh 已内置检查:未装则中止),
  否则把开机桌面指向不存在的应用会导致开机黑屏。
- "恢复出厂设置"会重置该属性回海信、并卸载当贝(= 回默认桌面);也会清空本 /sdcard 目录。
  所以电脑端请务必另存一份备份。
- 已知:当贝在本机"遥控器能移动但焦点/OK 有 bug",需用鼠标操作;若无鼠标易被卡住,
  此时用电脑跑 restore_default.sh 即可切回海信桌面脱困(务必保持 ADB 开启作退路)。

【附:本机开启开发者模式 / ADB 的实测步骤】
1. 设置 → 声音 → 专业音响设置(需先关闭"杜比全景声")→ 声音平衡
2. 在"声音平衡"界面,交替按 OK 键和菜单键 3~4 次,直到出现 "M" 和雪花屏
3. 按菜单键 → 进入工厂菜单 → 选项(Options)
4. 把 "To Fac" 参数改为 "M",然后重启电视
5. 重启后:设置 → 关于 → 本机信息,连续按菜单键 4~5 次 → 进入安卓原生设置菜单
6. (用鼠标)进入"关于手机",连续点击"版本号" 7~8 次(进入开发者模式)
7. 返回上一级 → 进入"系统"菜单 → 看到"开发者选项" → 打开 USB 调试
说明: 第 6 步的原生设置菜单在本机需要鼠标操作;务必保证 USB 鼠标可用。
      退出该模式: 回工厂菜单把 "To Fac" 改回原值即可(非必须)。
================================================================================
