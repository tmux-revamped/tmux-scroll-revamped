<div align="center">

# tmux-scroll-revamped

<strong>将鼠标滚轮交给能自行滚动的应用，其他情况下进入 tmux 复制模式。</strong>

[English](README.md) | [日本語](README.ja.md) | 简体中文 | [繁體中文（香港）](README.zh-HK.md)

[![family](https://img.shields.io/github/actions/workflow/status/tmux-revamped/tmux-scroll-revamped/family.yml?branch=main&style=flat-square&label=family)](https://github.com/tmux-revamped/tmux-scroll-revamped/actions/workflows/family.yml)
[![tests](https://img.shields.io/github/actions/workflow/status/tmux-revamped/tmux-scroll-revamped/tests.yml?branch=main&style=flat-square&label=tests)](https://github.com/tmux-revamped/tmux-scroll-revamped/actions/workflows/tests.yml)
[![release](https://img.shields.io/github/v/release/tmux-revamped/tmux-scroll-revamped?style=flat-square&label=release)](https://github.com/tmux-revamped/tmux-scroll-revamped/releases/latest)
[![openssf scorecard](https://img.shields.io/ossf-scorecard/github.com/tmux-revamped/tmux-scroll-revamped?style=flat-square&label=openssf%20scorecard)](https://scorecard.dev/viewer/?uri=github.com/tmux-revamped/tmux-scroll-revamped)
[![license](https://img.shields.io/github/license/tmux-revamped/tmux-scroll-revamped?style=flat-square&label=license)](LICENSE)

<p align="center">
  <a href="#what-it-does">功能</a> |
  <a href="#installation">安装</a> |
  <a href="#usage">用法</a> |
  <a href="#configuration">配置</a> |
  <a href="#key-bindings">按键绑定</a> |
  <a href="#how-it-works">工作原理</a>
</p>

</div>

**在 tmux 2.0 及更高版本上，每次滚轮滚动派生 0 个进程。需要配置的应用名为 0 个。13 个选项。已在 macOS 和 Linux 上测试。**

---

<a id="what-it-does"></a>

## 功能

运行在备用屏幕上的全屏应用，例如 vim、less、htop 或 Claude Code，会收到滚轮事件。开启了鼠标报告的应用也一样。在 shell 提示符上，滚轮会进入复制模式并滚动 tmux 历史。判断只读取两个 tmux 格式 `#{alternate_on}` 和 `#{mouse_any_flag}`，所以不需要列出任何应用名。

可选设置可以调整复制模式下的滚动：每次滚动的行数、按半页或整页滚动、到底部时退出复制模式、闪现滚动位置，以及把鼠标选区复制到系统剪贴板。

## 环境要求

| 项目 | 版本或说明 |
|:------------|:----------------|
| tmux | 3.2 或更高版本。借助[工作原理](#how-it-works)中的回退方式，绑定也能在 tmux 1.9 到 3.1 上构建 |
| bash | 3.2 或更高版本，因此 macOS 自带的 `/bin/bash` 可以使用 |
| 操作系统 | Apple Silicon 和 Intel 上的 macOS，x86_64 和 arm64 上的 Linux |
| 核心工具 | BSD、GNU 或 uutils coreutils |
| 剪贴板工具 | 可选，用于 `@scroll_revamped_drag_copy`：macOS 上为 `pbcopy`，Linux 上为 `wl-copy`、`xclip` 或 `xsel` |

<a id="installation"></a>

## 安装

使用 [TPM](https://github.com/tmux-plugins/tpm) 时，把插件加入 `~/.tmux.conf`，打开滚轮分流，然后按 `prefix + I`：

```tmux
set -g @plugin 'tmux-revamped/tmux-scroll-revamped'
set -g @scroll_revamped_wheel 'on'
```

不使用 TPM 时，克隆仓库，并在 `~/.tmux.conf` 中运行入口脚本：

```sh
git clone https://github.com/tmux-revamped/tmux-scroll-revamped ~/.tmux/plugins/tmux-scroll-revamped
```

```tmux
run-shell ~/.tmux/plugins/tmux-scroll-revamped/scroll-revamped.tmux
```

<a id="usage"></a>

## 用法

打开 `@scroll_revamped_wheel` 后直接滚动即可。在 vim、less、htop 或全屏 TUI 上，滚轮滚动应用本身。在 shell 提示符上，它滚动 tmux 历史。不需要按任何键。

插件在加载时还会打开 tmux 的 `mouse` 选项。要自己管理这个选项，把 `@scroll_revamped_mouse` 设为 `off`。

每次滚动 3 行并在到底部时退出复制模式的配置：

```tmux
set -g @scroll_revamped_wheel 'on'
set -g @scroll_revamped_speed '3'
set -g @scroll_revamped_auto_exit 'on'
```

<a id="configuration"></a>

## 配置

在插件加载之前于 `~/.tmux.conf` 中设置选项。

| 选项 | 默认值 | 含义 |
|:-------|:--------|:--------|
| `@scroll_revamped_wheel` | `off` | `on` 绑定根表中用于分流滚轮的 `WheelUpPane` 和 `WheelDownPane`。`off` 保留 tmux 自带的滚轮绑定 |
| `@scroll_revamped_passthrough_alternate` | `on` | 把滚轮交给备用屏幕上的应用。`off` 让这些窗格进入复制模式 |
| `@scroll_revamped_passthrough_mouse` | `on` | 把滚轮交给开启了鼠标报告的应用。`off` 忽略应用的鼠标模式 |
| `@scroll_revamped_skip_empty` | `off` | `on` 时，没有回滚内容的窗格不会因滚轮进入复制模式 |
| `@scroll_revamped_select_pane` | `off` | `on` 时，滚动前先选中指针下方的窗格 |
| `@scroll_revamped_alt_keys` | 未设置 | `arrow` 或 `page` 会把滚轮转换为方向键或翻页键，发给关闭了鼠标报告的备用屏幕应用，例如 less、man 或 vi。arrow 模式每次发送 `@scroll_revamped_speed` 个按键，未设置时为 3 个，最多 20 个 |
| `@scroll_revamped_mouse` | `on` | `off` 时插件不设置 tmux 的 `mouse` 选项 |
| `@scroll_revamped_speed` | 未设置 | 正整数，设置复制模式下每次滚轮滚动的行数 |
| `@scroll_revamped_granularity` | `line` | 复制模式下每次滚动的距离：`line`、`halfpage` 或 `page` |
| `@scroll_revamped_auto_exit` | `off` | `on` 时，已经在底部时再向下滚动一次会退出复制模式 |
| `@scroll_revamped_indicator` | `off` | `on` 时，复制模式下每次滚动都会闪现滚动位置，例如 `scroll 120/4000` |
| `@scroll_revamped_drag_copy` | `off` | `on` 时，把复制模式中的鼠标选区复制到系统剪贴板 |
| `@scroll_revamped_status_wheel` | `off` | `on` 时，在状态栏上滚动滚轮会切换窗口 |

两个 passthrough 选项都关闭时，滚轮总是进入复制模式。

### 内部状态

以下选项由插件自行管理，请勿设置。

| 选项 | 内容 |
|:-------|:------|
| `@scroll_revamped_cache_key` | tmux 1.9 检查命令最近一次判断时的窗格、备用屏幕、鼠标和回滚状态 |
| `@scroll_revamped_cache_val` | 那次判断的结果：`0` 把滚轮交给应用，`1` 进入复制模式 |

<a id="key-bindings"></a>

## 按键绑定

插件不绑定任何前缀键。它的绑定都是鼠标事件，每一个都要等到对应选项设置后才绑定。

| 按键 | 表 | 绑定条件 |
|:----|:------|:-----------|
| `WheelUpPane`、`WheelDownPane` | root | `@scroll_revamped_wheel` 为 `on` |
| `WheelUpPane`、`WheelDownPane` | `copy-mode`、`copy-mode-vi` | 设置了 `@scroll_revamped_speed`，或 `@scroll_revamped_granularity` 不是 `line`，或 `@scroll_revamped_auto_exit` 或 `@scroll_revamped_indicator` 为 `on` |
| `MouseDragEnd1Pane` | `copy-mode`、`copy-mode-vi` | `@scroll_revamped_drag_copy` 为 `on` 且找到了剪贴板工具 |
| `WheelUpStatus`、`WheelDownStatus` | root | `@scroll_revamped_status_wheel` 为 `on` |

在 tmux-revamped 家族中，根表由用户自行选择启用，因此从 3.0.0 起滚轮绑定要等 `@scroll_revamped_wheel` 打开。无论滚轮分流是否打开，复制模式绑定都能工作。

<a id="how-it-works"></a>

## 工作原理

**分流。** `WheelUpPane` 检查一个条件：窗格处于备用屏幕，或其应用开启了鼠标报告，或窗格已经处于某种模式。条件为真时，滚轮事件用 `send-keys -M` 发给窗格。条件为假时，tmux 用 `copy-mode -e` 进入复制模式，滚回底部时这个模式会自动退出。`WheelDownPane` 总是转发事件，因此它滚动应用或已打开的复制模式。

**每次滚动不派生进程。** 条件是放在 `if-shell -F` 中的 tmux 格式，由 tmux 自己求值。

| tmux | 分流方式 |
|:-----|:--------|
| 3.1 及更高版本 | `#{\|\|:}` 和 `#{&&:}` 格式运算符 |
| 2.0 到 3.0 | 用嵌套的 `#{?}` 构建同样的条件 |
| 1.9 | 每次滚动都运行 [`src/scroll.sh`](src/scroll.sh) 的 `check`，其结果按窗格状态缓存 |

**复制模式调整。** 速度、粒度、自动退出和位置提示会在 tmux 2.4 及更高版本上重新绑定 `copy-mode` 和 `copy-mode-vi` 表中的滚轮。位置提示需要 tmux 3.2，这是 `display-message` 首个接受 `-d` 的版本。状态栏滚轮需要 tmux 2.1。

## 开发

| 命令 | 作用 |
|:--------|:-------------|
| `make test` | 运行 bats 测试套件 |
| `make lint` | 对所有 shell 文件运行 shellcheck |
| `make coverage` | 用 kcov 测量行覆盖率，低于 95% 时失败，在 Linux 上运行 |

绑定在 [`src/lib/scroll/routing.sh`](src/lib/scroll/routing.sh) 中通过一个发出所有 tmux 命令的函数构建，因此测试无需运行中的 tmux 服务器就能检查每个绑定。

## 许可证

[MIT](LICENSE)

<!-- family:begin -->

## tmux-revamped 插件家族

本插件是 tmux-revamped 插件家族的一员。每个成员都带有 [`FAMILY.md`](FAMILY.md) 中的同一份约定、`family/` 下的同一套工具和同一个共享库，并由校验和清单保证逐字节一致。这些成员可以一起安装：任何成员都不会占用其他成员使用的按键或 tmux 选项。

在一个成员中发现的缺陷，要在全部成员中排查之后才算修复完成。这项义务写在约定里，而不是靠记忆，`family/bin/sweep` 负责执行它。

| 成员 | 功能 |
|---|---|
| [`tmux-autoreload-revamped`](https://github.com/tmux-revamped/tmux-autoreload-revamped) | 编辑并保存 tmux 配置后，它会自动重新加载，无需按键，也无需命令 |
| [`tmux-battery-revamped`](https://github.com/tmux-revamped/tmux-battery-revamped) | 在 tmux 状态栏显示电池状态，从不阻塞状态栏渲染 |
| [`tmux-bluetooth-revamped`](https://github.com/tmux-revamped/tmux-bluetooth-revamped) | 在 tmux 状态栏显示每个已连接的蓝牙设备及其电量，不阻塞渲染 |
| [`tmux-cpu-revamped`](https://github.com/tmux-revamped/tmux-cpu-revamped) | 在 tmux 状态栏显示 CPU 负载、温度和频率，从不阻塞渲染 |
| [`tmux-disk-revamped`](https://github.com/tmux-revamped/tmux-disk-revamped) | 在 tmux 状态栏显示磁盘用量，从不阻塞状态栏渲染 |
| [`tmux-extract-revamped`](https://github.com/tmux-revamped/tmux-extract-revamped) | 用 fzf 从屏幕上挑选 URL、路径、哈希或任意其他词元，并输入到光标处，全部用纯 shell 实现 |
| [`tmux-fzf-revamped`](https://github.com/tmux-revamped/tmux-fzf-revamped) | 在弹出窗口中的 fzf 选择器里切换、关闭、重命名或创建 tmux 会话、窗口和窗格 |
| [`tmux-git-revamped`](https://github.com/tmux-revamped/tmux-git-revamped) | 在 tmux 状态栏中显示活动窗格的 git 分支、改动和托管平台计数，且不阻塞渲染 |
| [`tmux-gpu-revamped`](https://github.com/tmux-revamped/tmux-gpu-revamped) | 在 tmux 状态栏中显示 NVIDIA、AMD、Intel 和 Apple GPU 的负载、温度、频率、功耗和显存 |
| [`tmux-kube-revamped`](https://github.com/tmux-revamped/tmux-kube-revamped) | 在 tmux 状态栏中显示当前的 Kubernetes 上下文和命名空间，不依赖 kubectl，直接解析 kubeconfig |
| [`tmux-launcher-revamped`](https://github.com/tmux-revamped/tmux-launcher-revamped) | 在弹出窗口或新窗口中启动任意 TUI 应用，从当前窗格的目录开始，每个应用可配置一个按键 |
| [`tmux-logging-revamped`](https://github.com/tmux-revamped/tmux-logging-revamped) | 将任意窗格保存到文件：实时日志、完整回滚缓冲区或一次性截图 |
| [`tmux-music-revamped`](https://github.com/tmux-revamped/tmux-music-revamped) | 在 tmux 状态栏显示正在播放的曲目，从不阻塞状态栏渲染 |
| [`tmux-network-revamped`](https://github.com/tmux-revamped/tmux-network-revamped) | 在 tmux 状态栏显示网络吞吐量，从不阻塞渲染 |
| [`tmux-pain-control-revamped`](https://github.com/tmux-revamped/tmux-pain-control-revamped) | tmux 的窗格和窗口管理按键，适配 tmux 版本，兼容 vim，每个 prefix 按键都可禁用 |
| [`tmux-persist-revamped`](https://github.com/tmux-revamped/tmux-persist-revamped) | 保存 tmux 的所有会话、窗口和窗格，按定时器自动保存，并在重启后全部恢复 |
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | tmux-revamped 插件的起点：共享库、bats 测试框架、CI 和系列工具 |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | tmux 状态栏中的番茄钟计时器，所有状态都保存在 tmux 选项中，不使用临时文件 |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | 在 tmux 状态栏显示内存、交换空间和内存压力，在后台采样，渲染从不等待 |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | 用鼠标在 tmux 状态栏上拖动窗口标签来移动该窗口 |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | **本插件**，将鼠标滚轮交给能自行滚动的应用，其他情况下进入 tmux 复制模式 |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | 按 tmux 版本和终端区分的合理默认设置，不改动你自己设置的选项 |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | tmux 的平铺窗口管理：八种布局，包括 BSP dwindle 和 spiral，并支持撤销布局 |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | 状态栏中的本地时钟和世界时钟，按一天中的时段着色，并提供倒计时和夏令时提醒 |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | 在后台从 wttr.in 获取天气并显示在状态栏，状态栏无需等待 |

### 检查安装

所有成员都在磁盘上时，一条命令即可报告它们之间的任何冲突：

```sh
family/bin/doctor --live
```

它读取每个成员和正在运行的 tmux 服务器，报告重复的按键、重复的状态占位符、不符合命名规则的选项，以及约定版本落后的成员。

<!-- family:end -->
