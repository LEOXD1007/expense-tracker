# 简记

本地优先的个人记账应用。一套 Flutter 代码同时面向 iOS 和 Android，界面为简体中文，默认货币为人民币（¥）。账本、分类和预算都保存在设备上的 SQLite 数据库里，不需要账号，也不会上传数据。

## 功能（v1）

- 记一笔收入或支出：金额、分类、日期、可选备注，可以修改和删除。
- 内置分类（餐饮、交通、购物、娱乐、居住、医疗、教育、通讯、日用、工资、奖金等）。内置分类可以改名、换图标和颜色；也可以新建、编辑、删除自定义分类。已被记录使用的分类不能删除。
- 按月查看收入、支出和结余，用饼图看分类占比，用折线看每天的趋势。
- 为本月设置总预算，也可以按支出分类单独设置。达到 80% 时提醒，超出时警告。应用内会显示横幅；在 iOS / Android 上，第一次跨过阈值时还会发一条本地通知（需要允许通知权限）。
- 把本月或全部记录导出为 CSV（带 UTF-8 BOM，方便 Excel 打开中文）或 Excel `.xlsx`，并通过系统分享面板发送。

## 还没做，但结构已经留好（v2）

- **云同步**：`SyncService`（现在是 `DisabledSyncService`）。记录、分类、预算都带 `updatedAt`，以后可以换成远程实现，界面不用重写。
- **语音记账**：`VoiceEntryParser`（现在是 `UnsupportedVoiceEntryParser`）。记一笔页面上的麦克风会调用它；识别成功后可以把金额、分类和备注填进表单。

数据访问都走 `CategoryRepository`、`EntryRepository`、`BudgetRepository`。当前实现是 `lib/data/local` 里的 SQLite。换后端时实现同样的接口即可。

## 环境

- Flutter 3.47 或更新的 stable（本仓库用 Dart 3.13 开发）
- iOS：Xcode，并打开一次 `ios/` 让 CocoaPods 安装依赖
- Android：Android Studio 或命令行 SDK。通知依赖 Java 11+ 的 core library desugaring，工程里已经打开
- 运行单元测试的桌面环境需要本机 SQLite（Ubuntu：`sudo apt install libsqlite3-dev`）

### 安装 Flutter

1. 按官方文档安装 SDK：<https://docs.flutter.dev/get-started/install>
2. 把 `flutter/bin` 加进 `PATH`
3. 检查环境：

```bash
flutter doctor
```

## 运行

```bash
flutter pub get
flutter run
```

手机会出现在 `flutter devices` 里。指定设备：

```bash
flutter devices
flutter run -d <device-id>
```

Android 模拟器可以用 Android Studio 的 Device Manager 启动，iOS 模拟器在 Mac 上用：

```bash
open -a Simulator
flutter run
```

Linux 桌面也能跑同一套界面，方便在没有手机时看效果：

```bash
flutter run -d linux
```

加载一份示例账本（只在你加上这个参数时才会写入）：

```bash
flutter run --dart-define=SEED_DEMO=true --dart-define=DEMO_TODAY=2026-11-18
```

`DEMO_TODAY` 把“今天”固定成某一天，示例数据会落在那一天所在的月份、并且不超过这一天。

## 检查

```bash
flutter analyze
flutter test
```

`flutter test` 覆盖金额换算、月度统计、预算阈值、CSV / Excel 导出，以及 SQLite 仓库的增删改查。另有一个界面测试：记一笔、切换统计 / 预算 / 我的，并导出 CSV。

## 目录

```text
lib/
  main.dart                 启动
  bootstrap.dart            打开数据库、可选示例数据、装好依赖
  core/                     金额（分）和日期
  domain/
    models/                 记录、分类、预算、统计结果
    repositories/           数据接口
    services/               统计、预算进度、提醒文案（纯函数，方便测试）
    sync/                   v2 云同步接口
    voice/                  v2 语音解析接口
  data/
    local/                  SQLite 和内置分类
    export/                 CSV、Excel、系统分享
    notifications/          预算阈值去重和本地通知
    demo/                   示例数据
  state/app_controller.dart 界面用的状态
  ui/                       Material 3 界面
test/                       单元测试和界面测试
```

数据库文件名是 `jizhang.db`，放在应用支持目录里。金额以「分」保存，避免浮点误差。日期存成本地的 `yyyyMMdd`，不受时区把记账日拨到前一天的影响。

## 预算提醒

- 未满 80%：不提醒
- 达到 80% 且未超出：黄色提醒
- 花费大于等于预算：红色超支
- 同一档位只发一次系统通知。把记录删掉、花费回到阈值以下之后，如果再次超过，会再提醒一次
- 桌面端没有移动通知渠道时，仍然会显示应用内横幅

## 局限

- 没有账号、没有云备份。卸载或清数据会丢掉账本，请先导出。
- 语音按钮会说明功能尚未开放，不会录音。
- 云同步入口同样只是占位。
- Linux 上的系统分享可能不可用；导出失败时会提示临时文件路径。手机上走系统分享面板。
- 一个设备一本账，没有多账本、周期账单或报销流转。
