<div align="center">

# tmux-scroll-revamped

<strong>將滑鼠滾輪交給能自行捲動的應用程式，其他情況下進入 tmux 複製模式。</strong>

[English](README.md) &nbsp;|&nbsp; [日本語](README.ja.md) &nbsp;|&nbsp; [简体中文](README.zh-Hans.md) &nbsp;|&nbsp; 繁體中文（香港）

[![Tests](https://github.com/tmux-revamped/tmux-scroll-revamped/actions/workflows/tests.yml/badge.svg)](https://github.com/tmux-revamped/tmux-scroll-revamped/actions/workflows/tests.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-3.0.0-blue.svg)](CHANGELOG.md)

<p align="center">
  <a href="#what-it-does">功能</a> &nbsp;|&nbsp;
  <a href="#installation">安裝</a> &nbsp;|&nbsp;
  <a href="#usage">用法</a> &nbsp;|&nbsp;
  <a href="#configuration">設定</a> &nbsp;|&nbsp;
  <a href="#key-bindings">按鍵綁定</a> &nbsp;|&nbsp;
  <a href="#how-it-works">運作原理</a>
</p>

</div>

**在 tmux 2.0 或以上，每次滾輪捲動衍生 0 個進程。需要設定的應用程式名稱為 0 個。13 個選項。已在 macOS 及 Linux 上測試。**

---

<a id="what-it-does"></a>

## 功能

運行在替代螢幕上的全螢幕應用程式，例如 vim、less、htop 或 Claude Code，會收到滾輪事件。開啟了滑鼠報告的應用程式亦一樣。在 shell 提示字元上，滾輪會進入複製模式並捲動 tmux 紀錄。判斷只讀取兩個 tmux 格式 `#{alternate_on}` 及 `#{mouse_any_flag}`，所以無需列出任何應用程式名稱。

選用設定可以調整複製模式下的捲動：每次捲動的行數、按半頁或整頁捲動、到底部時離開複製模式、閃現捲動位置，以及把滑鼠選取範圍複製到系統剪貼簿。

## 系統要求

| 項目 | 版本或說明 |
|:------------|:----------------|
| tmux | 3.2 或以上。藉着[運作原理](#how-it-works)中的後備方式，綁定亦能在 tmux 1.9 至 3.1 上建立 |
| bash | 3.2 或以上，因此 macOS 內置的 `/bin/bash` 可以使用 |
| 作業系統 | Apple Silicon 及 Intel 上的 macOS，x86_64 及 arm64 上的 Linux |
| 核心工具 | BSD、GNU 或 uutils coreutils |
| 剪貼簿工具 | 選用，用於 `@scroll_revamped_drag_copy`：macOS 上為 `pbcopy`，Linux 上為 `wl-copy`、`xclip` 或 `xsel` |

<a id="installation"></a>

## 安裝

使用 [TPM](https://github.com/tmux-plugins/tpm) 時，把插件加入 `~/.tmux.conf`，開啟滾輪分流，然後按 `prefix + I`：

```tmux
set -g @plugin 'tmux-revamped/tmux-scroll-revamped'
set -g @scroll_revamped_wheel 'on'
```

不使用 TPM 時，複製儲存庫，並在 `~/.tmux.conf` 中執行入口腳本：

```sh
git clone https://github.com/tmux-revamped/tmux-scroll-revamped ~/.tmux/plugins/tmux-scroll-revamped
```

```tmux
run-shell ~/.tmux/plugins/tmux-scroll-revamped/scroll-revamped.tmux
```

<a id="usage"></a>

## 用法

開啟 `@scroll_revamped_wheel` 後直接捲動即可。在 vim、less、htop 或全螢幕 TUI 上，滾輪捲動應用程式本身。在 shell 提示字元上，它捲動 tmux 紀錄。無需按任何鍵。

插件在載入時亦會開啟 tmux 的 `mouse` 選項。如要自行管理這個選項，把 `@scroll_revamped_mouse` 設為 `off`。

每次捲動 3 行並在到底部時離開複製模式的設定：

```tmux
set -g @scroll_revamped_wheel 'on'
set -g @scroll_revamped_speed '3'
set -g @scroll_revamped_auto_exit 'on'
```

<a id="configuration"></a>

## 設定

在插件載入之前於 `~/.tmux.conf` 中設定選項。

| 選項 | 預設值 | 含義 |
|:-------|:--------|:--------|
| `@scroll_revamped_wheel` | `off` | `on` 綁定根表中用於分流滾輪的 `WheelUpPane` 及 `WheelDownPane`。`off` 保留 tmux 內置的滾輪綁定 |
| `@scroll_revamped_passthrough_alternate` | `on` | 把滾輪交給替代螢幕上的應用程式。`off` 令這些窗格進入複製模式 |
| `@scroll_revamped_passthrough_mouse` | `on` | 把滾輪交給開啟了滑鼠報告的應用程式。`off` 忽略應用程式的滑鼠模式 |
| `@scroll_revamped_skip_empty` | `off` | `on` 時，沒有回捲內容的窗格不會因滾輪進入複製模式 |
| `@scroll_revamped_select_pane` | `off` | `on` 時，捲動前先選取指標下方的窗格 |
| `@scroll_revamped_alt_keys` | 未設定 | `arrow` 或 `page` 會把滾輪轉換為方向鍵或翻頁鍵，送給關閉了滑鼠報告的替代螢幕應用程式，例如 less、man 或 vi。arrow 模式每次送出 `@scroll_revamped_speed` 個按鍵，未設定時為 3 個，最多 20 個 |
| `@scroll_revamped_mouse` | `on` | `off` 時插件不會設定 tmux 的 `mouse` 選項 |
| `@scroll_revamped_speed` | 未設定 | 正整數，設定複製模式下每次滾輪捲動的行數 |
| `@scroll_revamped_granularity` | `line` | 複製模式下每次捲動的距離：`line`、`halfpage` 或 `page` |
| `@scroll_revamped_auto_exit` | `off` | `on` 時，已經在底部時再向下捲動一次會離開複製模式 |
| `@scroll_revamped_indicator` | `off` | `on` 時，複製模式下每次捲動都會閃現捲動位置，例如 `scroll 120/4000` |
| `@scroll_revamped_drag_copy` | `off` | `on` 時，把複製模式中的滑鼠選取範圍複製到系統剪貼簿 |
| `@scroll_revamped_status_wheel` | `off` | `on` 時，在狀態列上捲動滾輪會切換視窗 |

兩個 passthrough 選項都關閉時，滾輪總會進入複製模式。

### 內部狀態

以下選項由插件自行管理，請勿設定。

| 選項 | 內容 |
|:-------|:------|
| `@scroll_revamped_cache_key` | tmux 1.9 檢查指令最近一次判斷時的窗格、替代螢幕、滑鼠及回捲狀態 |
| `@scroll_revamped_cache_val` | 那次判斷的結果：`0` 把滾輪交給應用程式，`1` 進入複製模式 |

<a id="key-bindings"></a>

## 按鍵綁定

插件不綁定任何前綴鍵。它的綁定都是滑鼠事件，每一個都要等到對應選項設定後才綁定。

| 按鍵 | 表 | 綁定條件 |
|:----|:------|:-----------|
| `WheelUpPane`、`WheelDownPane` | root | `@scroll_revamped_wheel` 為 `on` |
| `WheelUpPane`、`WheelDownPane` | `copy-mode`、`copy-mode-vi` | 設定了 `@scroll_revamped_speed`，或 `@scroll_revamped_granularity` 不是 `line`，或 `@scroll_revamped_auto_exit` 或 `@scroll_revamped_indicator` 為 `on` |
| `MouseDragEnd1Pane` | `copy-mode`、`copy-mode-vi` | `@scroll_revamped_drag_copy` 為 `on` 並找到剪貼簿工具 |
| `WheelUpStatus`、`WheelDownStatus` | root | `@scroll_revamped_status_wheel` 為 `on` |

在 tmux-revamped 家族中，根表由用戶自行選擇啟用，因此由 3.0.0 起滾輪綁定要等 `@scroll_revamped_wheel` 開啟。無論滾輪分流是否開啟，複製模式綁定都能運作。

<a id="how-it-works"></a>

## 運作原理

**分流。** `WheelUpPane` 檢查一個條件：窗格處於替代螢幕，或其應用程式開啟了滑鼠報告，或窗格已經處於某種模式。條件成立時，滾輪事件用 `send-keys -M` 送給窗格。條件不成立時，tmux 用 `copy-mode -e` 進入複製模式，捲回底部時這個模式會自動離開。`WheelDownPane` 總會轉發事件，因此它捲動應用程式或已開啟的複製模式。

**每次捲動不衍生進程。** 條件是放在 `if-shell -F` 中的 tmux 格式，由 tmux 自己求值。

| tmux | 分流方式 |
|:-----|:--------|
| 3.1 或以上 | `#{\|\|:}` 及 `#{&&:}` 格式運算子 |
| 2.0 至 3.0 | 用嵌套的 `#{?}` 建立同樣的條件 |
| 1.9 | 每次捲動都執行 [`src/scroll.sh`](src/scroll.sh) 的 `check`，其結果按窗格狀態快取 |

**複製模式調整。** 速度、粒度、自動離開及位置提示會在 tmux 2.4 或以上重新綁定 `copy-mode` 及 `copy-mode-vi` 表中的滾輪。位置提示需要 tmux 3.2，這是 `display-message` 首個接受 `-d` 的版本。狀態列滾輪需要 tmux 2.1。

## 開發

| 指令 | 作用 |
|:--------|:-------------|
| `make test` | 執行 bats 測試套件 |
| `make lint` | 對所有 shell 檔案執行 shellcheck |
| `make coverage` | 用 kcov 量度行覆蓋率，低於 95% 時失敗，在 Linux 上執行 |

綁定在 [`src/lib/scroll/routing.sh`](src/lib/scroll/routing.sh) 中透過一個發出所有 tmux 指令的函數建立，因此測試無需運行中的 tmux 伺服器就能檢查每個綁定。

## 授權條款

[MIT](LICENSE)

<!-- family:begin -->

## tmux-revamped 插件家族

本插件是 tmux-revamped 插件家族的成員。每個成員都帶有 [`FAMILY.md`](FAMILY.md) 中的同一份約定、`family/` 下的同一套工具和同一個共用程式庫，並由校驗和清單確保逐位元組一致。這些成員可以一併安裝：任何成員都不會佔用其他成員使用的按鍵或 tmux 選項。

在一個成員中發現的缺陷，要在全部成員中排查後才算修正完成。這項責任寫在約定之中，而不是依靠記憶，`family/bin/sweep` 負責執行。

| 成員 | 功能 |
|---|---|
| [`tmux-autoreload-revamped`](https://github.com/tmux-revamped/tmux-autoreload-revamped) | 編輯並儲存 tmux 設定後，它會自動重新載入，毋須按鍵，也毋須指令 |
| [`tmux-battery-revamped`](https://github.com/tmux-revamped/tmux-battery-revamped) | 在 tmux 狀態列顯示電池狀態，從不阻塞狀態列繪製 |
| [`tmux-bluetooth-revamped`](https://github.com/tmux-revamped/tmux-bluetooth-revamped) | 在 tmux 狀態列顯示每部已連接的藍牙裝置及其電量，不阻塞繪製 |
| [`tmux-cpu-revamped`](https://github.com/tmux-revamped/tmux-cpu-revamped) | 在 tmux 狀態列顯示 CPU 負載、溫度及頻率，從不阻塞繪製 |
| [`tmux-disk-revamped`](https://github.com/tmux-revamped/tmux-disk-revamped) | 在 tmux 狀態列顯示磁碟用量，從不阻塞狀態列繪製 |
| [`tmux-extract-revamped`](https://github.com/tmux-revamped/tmux-extract-revamped) | 用 fzf 從畫面上揀選 URL、路徑、雜湊值或任何其他字詞，並輸入到游標位置，全部以純 shell 實現 |
| [`tmux-fzf-revamped`](https://github.com/tmux-revamped/tmux-fzf-revamped) | 在彈出視窗的 fzf 選擇器中切換、關閉、重新命名或建立 tmux 工作階段、視窗和窗格 |
| [`tmux-git-revamped`](https://github.com/tmux-revamped/tmux-git-revamped) | 在 tmux 狀態列顯示當前窗格的 git 分支、改動和託管平台數目，而不會阻塞顯示 |
| [`tmux-gpu-revamped`](https://github.com/tmux-revamped/tmux-gpu-revamped) | 在 tmux 狀態列顯示 NVIDIA、AMD、Intel 及 Apple GPU 的負載、溫度、時脈、功耗及記憶體 |
| [`tmux-kube-revamped`](https://github.com/tmux-revamped/tmux-kube-revamped) | 在 tmux 狀態列顯示目前的 Kubernetes 上下文及命名空間，毋須 kubectl，直接解析 kubeconfig |
| [`tmux-launcher-revamped`](https://github.com/tmux-revamped/tmux-launcher-revamped) | 在彈出視窗或新視窗中啟動任何 TUI 應用程式，從目前窗格的目錄開始，每個應用程式可設定一個按鍵 |
| [`tmux-logging-revamped`](https://github.com/tmux-revamped/tmux-logging-revamped) | 將任何窗格儲存到檔案：即時記錄、完整捲動緩衝區或一次性截圖 |
| [`tmux-music-revamped`](https://github.com/tmux-revamped/tmux-music-revamped) | 在 tmux 狀態列顯示正在播放的歌曲，從不阻塞狀態列的繪製 |
| [`tmux-network-revamped`](https://github.com/tmux-revamped/tmux-network-revamped) | 在 tmux 狀態列顯示網絡傳輸量，從不阻塞繪製 |
| [`tmux-pain-control-revamped`](https://github.com/tmux-revamped/tmux-pain-control-revamped) | tmux 的窗格和視窗管理按鍵，配合 tmux 版本，與 vim 相容，每個 prefix 按鍵都可停用 |
| [`tmux-persist-revamped`](https://github.com/tmux-revamped/tmux-persist-revamped) | 儲存 tmux 的所有工作階段、視窗及窗格，按計時器自動儲存，並在重新開機後全部還原 |
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | tmux-revamped 插件的起點：共用程式庫、bats 測試框架、CI 和系列工具 |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | tmux 狀態列中的番茄鐘計時器，所有狀態都儲存在 tmux 選項中，不使用暫存檔 |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | 在 tmux 狀態列顯示記憶體、交換空間及記憶體壓力，在背景取樣，繪製從不等待 |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | 用滑鼠在 tmux 狀態列上拖動視窗標籤來移動該視窗 |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | **本插件**，將滑鼠滾輪交給能自行捲動的應用程式，其他情況下進入 tmux 複製模式 |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | 按 tmux 版本和終端機區分的合理預設設定，不會改動你自己設定的選項 |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | tmux 的平鋪視窗管理：八種版面，包括 BSP dwindle 和 spiral，並支援復原版面 |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | 狀態列中的本地時鐘和世界時鐘，按一天中的時段著色，並提供倒數和夏令時間提示 |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | 在背景從 wttr.in 取得天氣並顯示在狀態列，狀態列毋須等待 |

### 檢查安裝

所有成員都在磁碟上時，一個指令即可報告它們之間的任何衝突：

```sh
family/bin/doctor --live
```

它讀取每個成員和正在運行的 tmux 伺服器，報告重複的按鍵、重複的狀態佔位符、不符合命名規則的選項，以及約定版本落後的成員。

<!-- family:end -->
