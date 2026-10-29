# 海信 E5S Pro 默认桌面切换/还原 (当贝 ⇄ 海信自带)

本目录用于一键切换或还原海信 E5S Pro 默认桌面。

## 这是什么
在**不停用、不卸载**任何桌面的前提下,切换电视的系统默认桌面(HOME):
- `set_dangbei.sh`    一键把默认桌面设为 **当贝桌面**
- `restore_default.sh` 一键还原为 **海信自带桌面**
- `switch_launcher.sh` 核心脚本(上面两个都是它的包装);还支持 `status` 查看当前桌面

海信自带桌面始终保留、随时可还原。

## 设备信息(本机实测)
- 机型: 海信 E5S Pro,系统 VIDAA_TV,Android 14 (SDK 34),arm64
- 海信自带桌面: `com.jamdeo.tv.vod/com.ju.main.launcher.LauncherActivity`
- 当贝桌面:     `com.dangbei.tvlauncher/com.dangbei.launcher.ui.main.MainActivity`

## 原理(重要)
这台海信 VIDAA **开机和 HOME 键用的是它自己的私有属性**,不是 Android 标准的
RoleManager HOME 角色。**实测:只有改这个属性才真正生效**:
```
persist.vt.use_home_pkg = <桌面包名>   # 海信开机/HOME键 实际读取的开关(persist,重启保留)
```
脚本据此执行(并额外设置 Android 标准默认作双保险,完全可逆、不改动任何 App):
```
setprop persist.vt.use_home_pkg <包名>                      # 关键
cmd package set-home-activity <组件>                        # 双保险
cmd role    add-role-holder android.app.role.HOME <包名>    # 双保险
```

## 前置条件
1. 电视开启:开发者模式 + USB/ADB 调试
   (本机开启方法较特殊、不是常规的"版本号连点";见文末 **"附:本机开启开发者模式/ADB 的实测步骤"**)
2. 电脑有 adb(本仓库上级目录的 `platform-tools/adb` 即可),电视与电脑同一网络
3. 首次连接电视会弹"允许调试",用遥控器选"一律允许"

## 用法
```bash
# 设为当贝(默认用脚本内置的电视IP)
./set_dangbei.sh
# 一键还原海信自带桌面
./restore_default.sh
# 查看当前默认桌面
./switch_launcher.sh status

# 换了网络、电视IP变了?把新IP作为参数传入:
./set_dangbei.sh 192.168.1.23
./restore_default.sh 192.168.1.23
```
电视 IP 查看:设置→网络→当前连接→详情。也可在 `switch_launcher.sh` 顶部改 `TV_IP_DEFAULT`。

## 纯手动还原(万一脚本丢失,记住这几条即可)
电脑连上电视 adb 后执行(把默认桌面设回海信自带):
```
adb connect <电视IP>:5555
adb -s <电视IP>:5555 shell setprop persist.vt.use_home_pkg com.jamdeo.tv.vod
adb -s <电视IP>:5555 shell cmd package set-home-activity com.jamdeo.tv.vod/com.ju.main.launcher.LauncherActivity
```
设回当贝就把上面两处包名/组件换成:
`com.dangbei.tvlauncher` 和 `com.dangbei.tvlauncher/com.dangbei.launcher.ui.main.MainActivity`
改完按 HOME 或重启即生效。

## 说明
- 不需要 root。所有命令 adb shell 普通权限即可执行(本机已验证)。
- 不会删除/禁用任何桌面;自带桌面随时能用。
- **安全保险**:`set_dangbei` 执行前会先检查当贝是否已安装;**未安装则直接中止、不做任何修改**,
  以免把开机桌面(`persist.vt.use_home_pkg`)指向一个不存在的应用而导致开机黑屏/无桌面。
  (`restore` 的目标是系统自带桌面,必定存在,永远安全。)
- 万一真的把默认桌面指向了不存在的应用导致无桌面:用 `restore_default.sh` 或本文件
  "纯手动还原"里的命令,把属性/默认设回海信自带桌面即可恢复(只要 adb 能连上)。

## 附:本机开启开发者模式/ADB 的实测步骤(海信 E5S Pro)

这台海信的开发者选项藏在"安卓原生设置"里,常规"版本号连点"进不去,需先进工厂菜单打开入口。
以下为实测可用步骤:

1. `设置 → 声音 → 专业音响设置`(需**先关闭"杜比全景声"**才会出现)`→ 声音平衡`
2. 停在"**声音平衡**"界面,用遥控器**交替按 OK 键 和 菜单键 3~4 次**,直到屏幕出现 **"M" 和雪花屏**
3. 此时**按菜单键** → 进入**工厂菜单** → 进 `选项(Options)`
4. 把 **`To Fac` 参数改为 `M`**,然后**重启电视**
5. 重启后:`设置 → 关于 → 本机信息`,**连续按菜单键 4~5 次** → 进入**安卓原生设置菜单**
6. (用鼠标)进入 `关于手机`,**连续点击"版本号" 7~8 次**,提示已进入开发者模式
7. 返回上一级 → 进入 `系统` 菜单 → 就能看到 **开发者选项**,进去打开 **USB 调试**

注意事项:
- 第 6 步的**安卓原生设置菜单在本机需要鼠标操作**(遥控器焦点不好使),所以**务必保证 USB 鼠标可用**。
  (鼠标识别可用 `adb shell dumpsys input` 查:出现 CURSOR 类设备即已识别。)
- 开启后首次电脑连接会弹"允许调试",用遥控器或鼠标选"一律允许"。
- 如需退出该工厂模式:回到第 3~4 步的工厂菜单,把 `To Fac` 改回原值即可(非必须,不影响日常使用)。
