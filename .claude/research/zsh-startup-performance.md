# ZSH 起動パフォーマンス Research

## Summary

対話シェルの起動に実測 **約 2.1〜3.1 秒(中央値 ~2.5 秒)** かかっている。`zprof` による計測で、起動時間の **92%(約 1.9 秒)が `compinit` に消費されている** ことが判明した。根本原因は「compinit が 3 箇所から呼ばれ、うち 2 つが同じ dump ファイル(`~/.zcompdump`)を異なる fpath 状態で書き合うため、補完キャッシュが毎回無効化され、毎起動でフル再生成(`compdump` ×3、`compdef` ×2457)が走る」こと。これを単一の compinit に統合し dump を安定させれば、起動時間は **~0.6〜0.8 秒** まで短縮できる見込み。機能・挙動はほぼ変えずに達成可能。

## 実測データ

### 起動時間(`zsh -i -c exit`、5 回)

| run | 時間 |
| --- | --- |
| 1 | 3125 ms |
| 2 | 2530 ms |
| 3 | 2086 ms |
| 4 | 2703 ms |
| 5 | 2322 ms |

※ サンドボックス環境下の計測のため `gitstatus failed to initialize` / `can't change option: monitor` のノイズを含むが、支配的コストは下記 zprof で裏付けられる。

### zprof プロファイル(主要項目)

| 順位 | 関数 | 呼び出し回数 | total | 割合 |
| --- | --- | --- | --- | --- |
| 1 | `compinit` | **3 回** | 1862.85 ms | 92.59% |
| 2 | `compdump`(dump 再生成) | **3 回** | 479.95 ms | 23.86% |
| 3 | `compdef` | **2457 回** | 422.48 ms | 21.00% |
| 4 | `_omz_source`(OMZ lib/plugin 読込 25 件) | 25 回 | 100.33 ms | 4.99% |
| 5 | `compaudit`(セキュリティ検査) | 6 回 | 69.41 ms | 3.45% |
| 6 | `zrecompile` | 1 回 | 18.16 ms | 0.90% |
| 7 | powerlevel10k 初期化 ほか | - | ~40 ms | ~2% |

※ `compdump` / `compdef` / `compaudit` の時間は `compinit` の total に含まれる(children)。

### 個別コスト(単体計測)

| 処理 | コスト | 備考 |
| --- | --- | --- |
| `config_files=($DOTFILES/**/*.zsh)` 再帰 glob | **93 ms**(36 ファイル) | `user-app/npm/npm-global/lib/node_modules`(238+ ディレクトリ)まで走査するため |
| 深さ制限 glob(`*/*.zsh` + `*/*/*.zsh` + `*/*/*/*.zsh`) | 1.6 ms | 同じファイル集合を 1/60 のコストで列挙できる |
| `eval "$(pyenv init - --no-rehash)"` | 113 ms | サブプロセス起動 |
| `eval "$(brew shellenv)"` | 69 ms | サブプロセス起動 |
| gcloud `path.zsh.inc` | 0.3 ms | 無視できる |

## Architecture Overview

起動フロー(`zsh/zshrc.symlink`):

```
~/.zshrc (symlink)
├── Kiro CLI pre block
├── p10k instant prompt(キャッシュあり: ~/.cache/p10k-instant-prompt-*.zsh)
├── ~/.localrc(現在は空)
├── config_files=($DOTFILES/**/*.zsh)          ← 再帰 glob 93ms
├── [phase 1] **/path.zsh を source
│     └── user-app-work/google-cloud-sdk/path.zsh
│           └── completion.zsh.inc → ★compinit #1(dump: ~/.zcompdump、fpath が小さい状態)
├── [phase 2] path/completion 以外を source(辞書順)
│     ├── user-app/ohmyzsh/config.zsh
│     │     └── oh-my-zsh.sh → ★compinit #2(dump: $ZSH_COMPDUMP = ~/.zcompdump-<host>-<ver>)
│     ├── zsh/config.zsh   ← fpath+=functions(OMZ compinit の後!)
│     └── zsh/fpath.zsh    ← 全 topic dir を fpath に追加(これも OMZ compinit の後)
├── ★compinit #3(zshrc.symlink:45、dump: ~/.zcompdump、fpath が成長済み)
├── [phase 3] **/completion.zsh を source
├── ~/.p10k.zsh
├── Rancher Desktop PATH
├── /opt/homebrew/share/google-cloud-sdk/{path,completion}.zsh.inc ← gcloud の二重ロード
└── Kiro CLI post block
```

### 遅さの因果構造(ピンポン無効化)

1. **compinit #1**(gcloud、path フェーズ)が fpath の小さい状態で `~/.zcompdump` を検証 → 前回起動の #3 が書いた「fpath 大」の dump と不一致 → **再生成**
2. **compinit #2**(oh-my-zsh)は別ファイル `$ZSH_COMPDUMP` を使うが、fpath の状態が起動内で変化するため毎回検証コスト+再生成が発生
3. **compinit #3**(zshrc.symlink)が fpath の大きい状態で `~/.zcompdump` を再検証 → #1 が書いた「fpath 小」の dump と不一致 → **再生成**
4. 次回起動で 1 に戻る(永久に収束しない)

つまり **dump キャッシュが恒久的に機能していない**。加えて dump を source するたびに `compdef` が 2457 回実行される(×複数回)。

## Key Files

| ファイル | 役割 / 問題点 |
| --- | --- |
| `zsh/zshrc.symlink:29` | `$DOTFILES/**/*.zsh` の再帰 glob(node_modules 走査で 93ms) |
| `zsh/zshrc.symlink:44-45` | compinit #3。fpath 構築完了後に呼ぶ必要があるため現構造では削除不可 |
| `zsh/zshrc.symlink:71-75` | gcloud の path/completion を再度 source(topic 側と二重) |
| `user-app-work/google-cloud-sdk/path.zsh:3` | **path フェーズで completion.zsh.inc を source → compinit #1 の原因** |
| `user-app/ohmyzsh/config.zsh:87` | `oh-my-zsh.sh` を source → compinit #2(`oh-my-zsh.sh:127/132`) |
| `zsh/fpath.zsh` | 全 topic dir を fpath に追加。**OMZ ロード後に実行される**ため compinit #2 に反映されない |
| `zsh/config.zsh:1` | `$DOTFILES/functions` を fpath に追加(同上の順序問題) |
| `functions/_brew` `_c` `_boom` `_git-rm` | 自作補完関数。fpath 構築順の制約の根拠 |
| `~/.zcompdump*`(10+ ファイル) | 散乱した dump。`~/.zcompdump-L15298-5.9.zwc` は **2024-03 の read-only な化石**。`.zcompdump.L15298.<pid>` は書き込み中断の残骸 |

### compinit の呼び出し元(`zsh -x` トレースで確認済み)

1. `/opt/homebrew/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc:4`(`user-app-work/google-cloud-sdk/path.zsh` 経由。ガードは `(( $+functions[compdef] ))` — path フェーズでは `compdef` 未定義なので毎回発火)
2. `~/.oh-my-zsh/oh-my-zsh.sh:127/132`(`compinit -i/-u -d $ZSH_COMPDUMP`)
3. `zsh/zshrc.symlink:45`(素の `compinit`)

なお `zshrc.symlink:75` の `/opt/homebrew/share/.../completion.zsh.inc` も同じガード付き compinit を持つが、この時点では `compdef` 定義済みのため発火しない(ただし補完関数定義自体は二重ロードされている)。

## Patterns & Conventions

- topic-based 構成: 各ディレクトリが 1 topic。`path.zsh` → その他 → `compinit` → `completion.zsh` の 4 段階ロード(holman/dotfiles 由来)。
- **設計上の前提**: 「fpath への追加は compinit より前」「補完登録(compdef 使用)は compinit より後」。gcloud topic の `path.zsh` はこの前提を破っている(completion を path フェーズに置いている)。
- phase 2 のロード順は glob の辞書順: `git/ < homebrew/ < macos/ < system/ < user-app-work/ < user-app/ < zsh/`(ASCII で `-` < `/` のため `user-app-work` が `user-app/` より先)。`zsh/` が最後なので fpath 設定が OMZ より後になっている。

## Gotchas & Constraints

- **`functions/` の自作補完**(`_c` `_brew` 等)があるため、「zshrc.symlink の compinit #3 を単純に消す」と補完が壊れる。先に fpath 構築を path フェーズへ移す必要がある。
- **phase 2 のロード順序は挙動に影響する**(alias の上書き、OMZ の位置)。glob を深さ制限に変える場合は結合後に `${(o)...}` でソートし、従来の完全辞書順を維持すること。
- `user-app/npm/npm-global/path.zsh` は**深さ 4** にある(`*/*/*/*.zsh` まで必要)。深さ 2+3 だけだと 1 ファイル漏れる(実測 35 vs 36)。
- **`/user-app-work` は gitignore 対象**(`.gitignore:13`)。`user-app-work/google-cloud-sdk/path.zsh` の修正は PR に含められない — 実機の checkout 上で直接適用する必要がある(Plan に手順を明記)。
- `git/completion.zsh` と `user-app-work/nodebrew/completion.zsh` は `completion='$(brew --prefix)/...'` と**シングルクォートのため展開されず、`test -f` が常に偽 = 実質デッドコード**。現状何もロードしていない(`_git` は fpath の site-functions から解決されている)。修正すると挙動が変わるため、本タスクでは触らない(別課題)。
- `~/.zcompdump-L15298-5.9.zwc`(2024-03、read-only 444)が残存。dump 掃除の際に一緒に消すこと(read-only なので `rm -f` が必要)。
- p10k instant prompt は有効(キャッシュ存在確認済み)なので**体感**は一部マスクされているが、コマンド受付可能になるまでの実時間は 2.5 秒のまま。また起動中にエラー出力があると instant prompt が警告を出す。
- サンドボックス内計測では gitstatus 初期化エラーが出る(`monitor` オプション不可のため)。実端末では発生しない。テストはこのノイズを許容する必要がある。
- OMZ の compinit は `ZSH_DISABLE_COMPFIX=true` で `compaudit`(69ms)をスキップできる(`compinit -u` になる)。single-user Mac では実害なし。

## Similar Implementations

- gcloud 自身の `completion.zsh.inc` が使う `(( $+functions[compdef] )) || compinit` ガードは、`zshrc.symlink:45` の compinit #3 をそのまま安全に無効化するのに流用できるイディオム。
- oh-my-zsh の compinit は dump 指定(`-d $ZSH_COMPDUMP`)+ `zrecompile`(.zwc 生成)+ compaudit 制御を既に備えており、「唯一の compinit」として最適。自前 compinit を温存するより OMZ に寄せる方が挙動維持に有利。

## Relevant Tests

- 既存のテストは存在しない(`script/bootstrap` 等のセットアップスクリプトのみ)。
- 検証は Plan 側で新設する `test/` 配下の zsh スクリプト(トレースベースの compinit 回数検査、環境スナップショット同値検査、起動時間計測)で行う。→ `.claude/plan/zsh-startup-speedup.md`

## 改善余地の総括(期待効果)

| 施策 | 期待削減 | 挙動リスク |
| --- | --- | --- |
| compinit 統合(3→1)+ dump 安定化 | **~1.6 秒** | 低(fpath 順序を正しく移せば同値) |
| `ZSH_DISABLE_COMPFIX=true` で compaudit スキップ | ~70 ms | 低(insecure dir が存在しない限り同一挙動。実測で compaudit の検出はゼロ) |
| 古い `.zcompdump*` の掃除(一回限り) | 安定化に寄与 | なし |
| (今回見送り・ユーザー判断)glob 深さ制限 + ソート | ~90 ms | 低(ファイル集合・順序同一を担保できるが見送り) |
| (任意・今回見送り)pyenv lazy 化 | ~110 ms | 中(初回 pyenv 実行の挙動が変わる) |
| (任意・今回見送り)brew shellenv の静的化 | ~70 ms | 中(brew 更新時に追従しない) |

採用施策の合計で **~2.5 秒 → 0.6〜0.8 秒** を見込む。
