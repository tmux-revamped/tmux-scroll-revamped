<div align="center">

# tmux-scroll-revamped

<strong>自分でスクロールできるアプリにはマウスホイールを渡し、それ以外ではtmuxのコピーモードに入ります。</strong>

[English](README.md) &nbsp;|&nbsp; 日本語 &nbsp;|&nbsp; [简体中文](README.zh-Hans.md) &nbsp;|&nbsp; [繁體中文（香港）](README.zh-HK.md)

[![Tests](https://github.com/tmux-revamped/tmux-scroll-revamped/actions/workflows/tests.yml/badge.svg)](https://github.com/tmux-revamped/tmux-scroll-revamped/actions/workflows/tests.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-3.0.0-blue.svg)](CHANGELOG.md)

<p align="center">
  <a href="#what-it-does">概要</a> &nbsp;|&nbsp;
  <a href="#installation">インストール</a> &nbsp;|&nbsp;
  <a href="#usage">使い方</a> &nbsp;|&nbsp;
  <a href="#configuration">設定</a> &nbsp;|&nbsp;
  <a href="#key-bindings">キーバインド</a> &nbsp;|&nbsp;
  <a href="#how-it-works">仕組み</a>
</p>

</div>

**tmux 2.0以降では、ホイールを1回回すごとに起動するプロセスは0個です。設定するアプリ名は0個です。オプションは13個です。macOSとLinuxでテストしています。**

---

<a id="what-it-does"></a>

## 概要

vim、less、htop、Claude Codeのように代替画面で動く全画面のアプリはホイールを受け取ります。マウスレポートを有効にしたアプリも同じです。シェルのプロンプトの上では、ホイールでコピーモードに入り、tmuxの履歴をスクロールします。判定は`#{alternate_on}`と`#{mouse_any_flag}`という2つのtmuxの書式を読むだけなので、アプリの名前を指定する必要はありません。

任意の設定でコピーモードのスクロールを調整できます。1回あたりの行数、半ページやページ単位の移動、末尾でのコピーモードの終了、スクロール位置の表示、マウスで選択した範囲のシステムクリップボードへのコピーです。

## 必要なもの

| 項目 | バージョンや補足 |
|:------------|:----------------|
| tmux | 3.2以降。[仕組み](#how-it-works)にある代替手段により、バインドはtmux 1.9から3.1でも組み立てられます |
| bash | 3.2以降。macOS標準の`/bin/bash`で動きます |
| OS | Apple SiliconとIntelのmacOS、x86_64とarm64のLinux |
| 基本コマンド | BSD、GNU、uutilsのいずれのcoreutilsでも動きます |
| クリップボードのツール | 任意。`@scroll_revamped_drag_copy`に使います。macOSでは`pbcopy`、Linuxでは`wl-copy`、`xclip`、`xsel`のいずれかです |

<a id="installation"></a>

## インストール

[TPM](https://github.com/tmux-plugins/tpm)を使う場合は、`~/.tmux.conf`にプラグインを追加し、ホイールの振り分けを有効にして`prefix + I`を押します。

```tmux
set -g @plugin 'tmux-revamped/tmux-scroll-revamped'
set -g @scroll_revamped_wheel 'on'
```

TPMを使わない場合は、リポジトリをクローンし、`~/.tmux.conf`からエントリーポイントを実行します。

```sh
git clone https://github.com/tmux-revamped/tmux-scroll-revamped ~/.tmux/plugins/tmux-scroll-revamped
```

```tmux
run-shell ~/.tmux/plugins/tmux-scroll-revamped/scroll-revamped.tmux
```

<a id="usage"></a>

## 使い方

`@scroll_revamped_wheel`を有効にしたら、あとはスクロールするだけです。vim、less、htop、全画面のTUIの上では、ホイールはアプリをスクロールします。シェルのプロンプトの上では、tmuxの履歴をスクロールします。押すキーはありません。

プラグインは読み込み時にtmuxの`mouse`オプションも有効にします。このオプションを自分で管理するには、`@scroll_revamped_mouse`を`off`にします。

1回で3行スクロールし、末尾でコピーモードを抜ける設定の例です。

```tmux
set -g @scroll_revamped_wheel 'on'
set -g @scroll_revamped_speed '3'
set -g @scroll_revamped_auto_exit 'on'
```

<a id="configuration"></a>

## 設定

オプションはプラグインを読み込む前に`~/.tmux.conf`で設定します。

| オプション | 既定値 | 意味 |
|:-------|:--------|:--------|
| `@scroll_revamped_wheel` | `off` | `on`でホイールを振り分けるルートテーブルの`WheelUpPane`と`WheelDownPane`を割り当てます。`off`ではtmux自身のホイールのバインドがそのまま残ります |
| `@scroll_revamped_passthrough_alternate` | `on` | 代替画面のアプリにホイールを渡します。`off`にすると、そのペインはコピーモードに入ります |
| `@scroll_revamped_passthrough_mouse` | `on` | マウスレポートを有効にしたアプリにホイールを渡します。`off`にするとアプリのマウスモードを無視します |
| `@scroll_revamped_skip_empty` | `off` | `on`にすると、スクロールバックのないペインではホイールでコピーモードに入りません |
| `@scroll_revamped_select_pane` | `off` | `on`にすると、スクロールの前にポインターの下のペインを選択します |
| `@scroll_revamped_alt_keys` | 未設定 | `arrow`または`page`にすると、less、man、viのようにマウスレポートを無効にした代替画面のアプリに対して、ホイールを矢印キーまたはページキーに変えます。arrowでは1回につき`@scroll_revamped_speed`個のキーを送ります。未設定なら3個で、最大20個です |
| `@scroll_revamped_mouse` | `on` | `off`にすると、プラグインはtmuxの`mouse`オプションを設定しません |
| `@scroll_revamped_speed` | 未設定 | 正の整数で、コピーモードのホイール1回でスクロールする行数を決めます |
| `@scroll_revamped_granularity` | `line` | コピーモードのホイール1回で進む量です。`line`、`halfpage`、`page`のいずれかです |
| `@scroll_revamped_auto_exit` | `off` | `on`にすると、すでに末尾にいるときの下向きの1回でコピーモードを抜けます |
| `@scroll_revamped_indicator` | `off` | `on`にすると、コピーモードでのホイール1回ごとに`scroll 120/4000`のようなスクロール位置を一瞬表示します |
| `@scroll_revamped_drag_copy` | `off` | `on`にすると、コピーモードでマウスで選択した範囲をシステムクリップボードにコピーします |
| `@scroll_revamped_status_wheel` | `off` | `on`にすると、ステータス行の上でホイールを回してウィンドウを切り替えます |

2つのpassthroughオプションを両方とも無効にすると、ホイールは常にコピーモードに入ります。

### 内部状態

以下のオプションはプラグインが自分で管理します。設定しないでください。

| オプション | 内容 |
|:-------|:------|
| `@scroll_revamped_cache_key` | tmux 1.9の確認コマンドが最後に判定したときの、ペイン、代替画面、マウス、スクロールバックの状態です |
| `@scroll_revamped_cache_val` | その判定です。`0`はアプリにホイールを渡し、`1`はコピーモードに入ります |

<a id="key-bindings"></a>

## キーバインド

プラグインはプレフィックスキーを割り当てません。バインドはマウスのイベントで、それぞれオプションが設定されるまで割り当てません。

| キー | テーブル | 割り当てる条件 |
|:----|:------|:-----------|
| `WheelUpPane`、`WheelDownPane` | root | `@scroll_revamped_wheel`が`on`のとき |
| `WheelUpPane`、`WheelDownPane` | `copy-mode`、`copy-mode-vi` | `@scroll_revamped_speed`が設定されているか、`@scroll_revamped_granularity`が`line`以外か、`@scroll_revamped_auto_exit`または`@scroll_revamped_indicator`が`on`のとき |
| `MouseDragEnd1Pane` | `copy-mode`、`copy-mode-vi` | `@scroll_revamped_drag_copy`が`on`で、クリップボードのツールが見つかったとき |
| `WheelUpStatus`、`WheelDownStatus` | root | `@scroll_revamped_status_wheel`が`on`のとき |

tmux-revampedファミリーではルートテーブルは利用者が選んで使うものなので、3.0.0からホイールのバインドは`@scroll_revamped_wheel`を待ちます。コピーモードのバインドは、ホイールの振り分けが有効かどうかに関係なく働きます。

<a id="how-it-works"></a>

## 仕組み

**振り分け。** `WheelUpPane`は1つの条件を確かめます。ペインが代替画面にあるか、アプリがマウスレポートを有効にしているか、ペインがすでにモードに入っているかです。真なら、ホイールのイベントは`send-keys -M`でペインに送られます。偽なら、tmuxは`copy-mode -e`でコピーモードに入ります。このモードは末尾までスクロールして戻ると終了します。`WheelDownPane`は常にイベントを転送するので、アプリか開いているコピーモードをスクロールします。

**1回ごとのフォークなし。** 条件は`if-shell -F`の中のtmuxの書式で、tmux自身が評価します。

| tmux | 振り分け |
|:-----|:--------|
| 3.1以降 | `#{\|\|:}`と`#{&&:}`の書式演算子 |
| 2.0から3.0 | 同じ条件を入れ子の`#{?}`で組み立てます |
| 1.9 | [`src/scroll.sh`](src/scroll.sh)の`check`が1回ごとに実行され、その答えをペインの状態ごとにキャッシュします |

**コピーモードの調整。** 速度、粒度、自動終了、位置の表示は、tmux 2.4以降で`copy-mode`と`copy-mode-vi`のテーブルのホイールを割り当て直します。位置の表示には、`display-message`が`-d`を受け付ける最初のリリースであるtmux 3.2が必要です。ステータス行のホイールにはtmux 2.1が必要です。

## 開発

| コマンド | 内容 |
|:--------|:-------------|
| `make test` | batsのテストスイートを実行します |
| `make lint` | すべてのシェルファイルにshellcheckを実行します |
| `make coverage` | kcovで行カバレッジを測り、95パーセント未満なら失敗します。Linuxで動きます |

バインドは[`src/lib/scroll/routing.sh`](src/lib/scroll/routing.sh)で、すべてのtmuxコマンドを発行する1つの関数を通して組み立てられるので、テストは稼働中のtmuxサーバーなしで各バインドを確認できます。

## ライセンス

[MIT](LICENSE)

<!-- family:begin -->

## tmux-revamped ファミリー

このプラグインは tmux-revamped ファミリーの一員です。すべてのメンバーが [`FAMILY.md`](FAMILY.md) の同じ規約、`family/` 配下の同じツール、同じ共有ライブラリを持ち、チェックサムの一覧によってバイト単位で同一に保たれています。メンバーは一緒にインストールする前提で作られており、ほかのメンバーが使うキーや tmux オプションを使うメンバーはありません。

あるメンバーで見つかった不具合は、修正完了とする前に全メンバーで同じ不具合を探します。この義務は記憶に頼らず規約に書かれており、`family/bin/sweep` がその作業を行います。

| メンバー | 機能 |
|---|---|
| [`tmux-autoreload-revamped`](https://github.com/tmux-revamped/tmux-autoreload-revamped) | tmuxの設定を編集して保存するだけで、キーもコマンドも使わずに自動で再読み込みされます |
| [`tmux-battery-revamped`](https://github.com/tmux-revamped/tmux-battery-revamped) | tmuxのステータスバーに電池の状態を表示し、ステータスの描画を一切止めません |
| [`tmux-bluetooth-revamped`](https://github.com/tmux-revamped/tmux-bluetooth-revamped) | 接続中のすべてのBluetooth機器とその電池残量をtmuxのステータスバーに表示し、描画を止めません |
| [`tmux-cpu-revamped`](https://github.com/tmux-revamped/tmux-cpu-revamped) | CPUの負荷、温度、周波数をtmuxのステータスバーに表示し、描画を一切止めません |
| [`tmux-disk-revamped`](https://github.com/tmux-revamped/tmux-disk-revamped) | tmuxのステータスバーにディスク使用量を表示し、ステータスの描画を一切止めません |
| [`tmux-extract-revamped`](https://github.com/tmux-revamped/tmux-extract-revamped) | 画面上の URL、パス、ハッシュなどのトークンを fzf で選び、カーソル位置に入力します。純粋なシェルだけで動きます |
| [`tmux-fzf-revamped`](https://github.com/tmux-revamped/tmux-fzf-revamped) | ポップアップ内の fzf ピッカーから、tmux のセッション、ウィンドウ、ペインの切り替え、終了、名前変更、作成を行います |
| [`tmux-git-revamped`](https://github.com/tmux-revamped/tmux-git-revamped) | アクティブなペインのgitブランチ、変更、プロバイダーの件数を、描画を止めずにtmuxのステータスバーに表示します |
| [`tmux-gpu-revamped`](https://github.com/tmux-revamped/tmux-gpu-revamped) | NVIDIA、AMD、Intel、Apple の GPU の負荷、温度、クロック、電力、メモリを tmux のステータスバーに表示します |
| [`tmux-kube-revamped`](https://github.com/tmux-revamped/tmux-kube-revamped) | 現在の Kubernetes コンテキストと名前空間を、kubectl を使わずに kubeconfig から解析して tmux のステータスバーに表示します |
| [`tmux-launcher-revamped`](https://github.com/tmux-revamped/tmux-launcher-revamped) | 任意の TUI アプリを、現在のペインのディレクトリでポップアップまたはウィンドウとして起動します。アプリごとにキーを設定できます |
| [`tmux-logging-revamped`](https://github.com/tmux-revamped/tmux-logging-revamped) | 任意のペインをファイルに保存します。ライブのログ記録、スクロールバック全体、1 回限りのスクリーンショットに対応します |
| [`tmux-music-revamped`](https://github.com/tmux-revamped/tmux-music-revamped) | 再生中の曲をステータスバーに表示し、ステータスの描画を止めません |
| [`tmux-network-revamped`](https://github.com/tmux-revamped/tmux-network-revamped) | ネットワークのスループットをステータスバーに表示し、描画を止めません |
| [`tmux-pain-control-revamped`](https://github.com/tmux-revamped/tmux-pain-control-revamped) | tmux のペインとウィンドウの操作キー。tmux のバージョンに対応し、vim と共存でき、どの prefix キーも無効にできます |
| [`tmux-persist-revamped`](https://github.com/tmux-revamped/tmux-persist-revamped) | tmuxのすべてのセッション、ウィンドウ、ペインを保存し、タイマーで自動保存して、再起動後にすべて復元します |
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | tmux-revampedプラグインの出発点です。共有ライブラリ、batsハーネス、CI、ファミリーのツールを含みます |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | すべての状態をtmuxオプションに保持し、一時ファイルを使わない、tmuxステータスバーのポモドーロタイマーです |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | RAM、スワップ、メモリプレッシャーをtmuxのステータスバーに表示します。計測はバックグラウンドで行うため描画を待たせません |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | tmuxのステータスバー上でウィンドウのタブをマウスでドラッグして、そのウィンドウを移動します |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | **このプラグイン**、自分でスクロールできるアプリにはマウスホイールを渡し、それ以外ではtmuxのコピーモードに入ります |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | tmuxのバージョンと端末に合わせて適用され、ユーザーが設定したオプションには触れない、妥当な初期設定です |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | tmuxのタイル型ウィンドウ管理です。BSPのdwindleとspiralを含む8つのレイアウトと、レイアウトの取り消しがあります |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | ステータスバーにローカル時計と世界時計を時間帯ごとの色で表示し、カウントダウンと夏時間の警告も出します |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | wttr.inの天気をバックグラウンドで取得し、ステータスバーを待たせずに表示します |

### インストールの確認

全メンバーがディスク上にあれば、1 つのコマンドでメンバー間の衝突を報告できます。

```sh
family/bin/doctor --live
```

各メンバーと実行中の tmux サーバーを読み取り、重複したキー、重複したステータスのプレースホルダー、命名規則に合わないオプション、規約のバージョンが古いメンバーを報告します。

<!-- family:end -->
