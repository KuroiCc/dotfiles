# ZSH 起動高速化 実装プラン(TDD)

対応する Research: `.claude/research/zsh-startup-performance.md`

## ゴール

- 対話シェルの起動時間を **~2.5 秒 → 0.6〜0.8 秒** に短縮する。
- 機能は変えない。挙動もできるだけ変えない(alias / 関数 / PATH / fpath / 補完登録は同値を維持)。

> **実装結果(2026-07-07)**: 全 8 テスト PASS。サンドボックス実測で median **~700ms**(warm dump、gitstatus リトライのノイズ込み)。環境スナップショット(PATH / aliases / functions / fpath / `_comps` / options)は最適化前の baseline と完全一致。

## 方針(Research の結論)

1. **compinit を 3 回 → 1 回に統合**し、dump キャッシュの「ピンポン無効化」を止める(最大の効果 ~1.6 秒)。
   - gcloud の completion ロードを path フェーズから completion フェーズへ移す。
   - fpath 構築(topic dirs + `functions/`)を oh-my-zsh ロードより前(path フェーズ)へ移す。
   - `zsh/zshrc.symlink:45` の素の `compinit` を `(( $+functions[compdef] )) || compinit` ガードに置き換え、oh-my-zsh の compinit を唯一の実行点にする。
2. `ZSH_DISABLE_COMPFIX=true` で oh-my-zsh 独自の insecurity 監査をスキップ。
   - 挙動差: insecure directory(fpath 上の group/world-writable なディレクトリ)が存在しない限り**完全に同一挙動**。実測で `compaudit` は現在何も検出していない(exit 0)。存在した場合のみ「警告表示+該当ディレクトリの補完スキップ(`compinit -i`)」→「警告なしで読み込み(`compinit -u`)」に変わる。独立コミットにするので単独 revert 可能。
   - **実装時の発見**: `compinit` 内部の `compaudit`(`compinit:454-457`)は `-u` でも実行される。これを消すには `compinit -C` が必要だが、dump の鮮度検知(新しい補完ファイルの検出)まで無効になるため不採用。効果は oh-my-zsh の監査 1 回分(~10〜40ms)にとどまる。テストは「compaudit 実行がちょうど 1 回(compinit 内部のみ)」を固定する。
3. 実 HOME に散乱した古い `.zcompdump*` を一回限り掃除する(キャッシュ安定化)。

見送り(ユーザー判断・挙動リスクにより今回やらない): **`$DOTFILES/**/*.zsh` 再帰 glob の深さ制限化(~90 ms、ユーザー判断で見送り)**、pyenv の lazy 化、`brew shellenv` の静的化、`git/completion.zsh` 等のデッドコード修正。

## テスト基盤

既存テストはないため `test/` を新設する。すべて zsh スクリプトで、失敗時に非ゼロ終了する。

**重要(実装時に発見)**: テストファイルは **`.zsh` 拡張子を使ってはならない**。`zshrc.symlink` は `$DOTFILES/**/*.zsh` を全て起動時に source するため、`*.zsh` のテストは新しいシェルを開くたびに実行され、テスト自身が対話シェルを起動するため**無限再帰(フォーク爆弾)になる**。テスト本体は拡張子なし(`*_test`)、source 用ヘルパーは `.zsh.inc` とする。

```
test/
├── run                          # すべての *_test を順に実行するランナー
├── harness_test / *_test        # テスト本体(拡張子なし・実行可能)
├── helpers/
│   ├── common.zsh.inc           # assert_eq / fail / make_zdotdir / trace_startup など
│   └── snapshot-env             # PATH / aliases / functions / fpath / ${(ok)_comps} / options をダンプ
└── snapshots/                   # baseline スナップショット置き場(gitignore 済み)
```

隔離の仕組み: `ZDOTDIR=$(mktemp -d)` に「`export DOTFILES=<repo>` → `source <repo>/zsh/zshrc.symlink`」だけの `.zshrc` を置いて `zsh -i` を起動する。`compinit` も oh-my-zsh も dump パスに `${ZDOTDIR:-$HOME}` を使うため、**実 HOME の dump を汚さずに毎回クリーンな状態でテストできる**。

注意事項:

- `user-app-work/` は gitignore 対象で worktree には存在しない。**実装とテスト実行は実 checkout(`~/.dotfiles`)上のブランチで行うこと**(compinit #1 は user-app-work 経由でしか再現しないため)。
- サンドボックス実行では gitstatus の初期化エラーが stderr に出る。テストの assert は stderr のノイズを無視する。
- 時間系テスト(Step 8)は環境負荷でぶれるので、median を取り閾値に余裕を持たせる。

## TDD ステップ(各ステップが 1 回の Red→Green)

### Step 1: テストハーネス有効化 — `DOTFILES` を上書き可能にする

現状 `zshrc.symlink:11` が `export DOTFILES=$HOME/.dotfiles` と固定しており、repo-under-test を差し替えられない。

- テストファイル: `test/harness_test.zsh`
- テスト名: `should load zshrc from the repo under test when DOTFILES is preset`
- Arrange: 一時 ZDOTDIR に `DOTFILES=<repo root>` を export してから `zsh/zshrc.symlink` を source する `.zshrc` を作る / Act: `zsh -i -c 'print -r -- $DOTFILES'` / Assert: 出力が `<repo root>` に一致する。
- Green にする最小変更: `zsh/zshrc.symlink:11` を `export DOTFILES=${DOTFILES:-$HOME/.dotfiles}` に変更(未設定時の挙動は完全に同一)。
- 同時に `test/run` と `test/helpers/common.zsh` / `test/helpers/run-interactive.zsh` を作成する(インフラなので Red→Green の対象外)。

### Step 2: 環境スナップショットの characterization test(安全網)

- テストファイル: `test/equivalence_test.zsh`
- テスト名: `should preserve interactive environment snapshot against baseline`
- Arrange: **一切の変更前に** `test/helpers/snapshot-env.zsh` で baseline を `test/snapshots/baseline.txt` に保存(PATH、sorted aliases、function 名一覧、fpath の集合、`${(ok)_comps}`、setopt) / Act: 現在のコードで同じスナップショットを取る / Assert: baseline と一致(fpath は「集合として一致」、それ以外は完全一致。差分が出た場合は既知差分リストに理由を明記して許容する)。
- このテストは書いた時点で Green(characterization)。**以降の全ステップの後に必ず再実行**し、挙動同値を担保する。
- 既知の許容差分(あらかじめ想定されるもの): fpath 内の順序(topic dirs が前方に移動)、`_comps` のエントリ数増(gcloud 補完の二重登録が一回に整理される場合)。

### Step 3: gcloud completion を path フェーズから追い出す(compinit #1 の除去)

- テストファイル: `test/compinit_phase_test.zsh`
- テスト名: `should not run compinit before oh-my-zsh loads`
- Arrange: `zsh -x -i -c exit` のトレースを取得 / Act: トレース中の compinit 実行マーカー(`+compinit:133>` 行)と `oh-my-zsh.sh` の source 行の初出位置を比較 / Assert: oh-my-zsh より前に compinit 実行が存在しない。
- Green にする最小変更(**実 checkout 上で実施。gitignore 対象なので PR には含まれない — PR 説明と `docs`/コミットメッセージに手動適用手順を明記**):
  - `user-app-work/google-cloud-sdk/path.zsh` から `source "${HOMEBREW_PREFIX}/Caskroom/.../completion.zsh.inc"` の行を削除。
  - 新規 `user-app-work/google-cloud-sdk/completion.zsh` に同じ source 行を移す(completion フェーズでは `compdef` 定義済みのため、inc 内のガードにより compinit は発火しない)。

### Step 4: fpath 構築を oh-my-zsh ロード前(path フェーズ)へ移す

- テストファイル: `test/fpath_order_test.zsh`
- テスト名: `should build dotfiles fpath before oh-my-zsh loads`
- Arrange: `zsh -x -i -c exit` のトレースを取得 / Act: `zsh/path.zsh`(新設)の source 行と `oh-my-zsh.sh` の source 行の初出位置を比較 / Assert: `zsh/path.zsh` が先、かつ `zsh/fpath.zsh` はもはや source されない。
- Green にする最小変更:
  - 新規 `zsh/path.zsh` を作成し、以下を集約:
    - `zsh/fpath.zsh` の内容(topic dirs を fpath へ追加するループ)
    - `zsh/config.zsh:1` の `fpath=($DOTFILES/functions $fpath)`
  - `zsh/fpath.zsh` を削除、`zsh/config.zsh` から fpath 行を削除(`autoload -U $DOTFILES/functions/*(:t)` は config.zsh に残す — path フェーズが先に走るので fpath は構築済み)。

### Step 5: compinit を 1 回に統合

- 5a. テストファイル: `test/compinit_count_test.zsh`
  - テスト名: `should run compinit exactly once during interactive startup`
  - Arrange: `zsh -x -i -c exit` のトレースを取得 / Act: `+compinit:133>`(`_comp_dumpfile` の typeset 実行マーカー)の出現回数を数える / Assert: ちょうど 1 回(現状 2 回なので Red)。
  - Green にする最小変更: `zsh/zshrc.symlink:44-45` を以下に置き換え:

    ```zsh
    # oh-my-zsh (user-app/ohmyzsh/config.zsh) has already run compinit with all
    # fpath entries in place; only run it here if oh-my-zsh was not loaded.
    autoload -U compinit
    (( $+functions[compdef] )) || compinit
    ```

- 5b. テストファイル: `test/compinit_count_test.zsh`(同ファイルに追加)
  - テスト名: `should register custom completion for c command after startup`
  - Arrange: 隔離起動 / Act: `zsh -i -c 'print -r -- ${+_comps[c]}'` / Assert: `1`(`functions/_c` が唯一の compinit = oh-my-zsh の compinit に拾われていることの確認。Step 4 が正しくないとここで落ちる)。

### Step 6: dump キャッシュの安定化(受け入れテスト)

- テストファイル: `test/compdump_stability_test.zsh`
- テスト名: `should not rewrite completion dump on second consecutive startup`
- Arrange: 隔離 ZDOTDIR で 1 回起動して dump を生成し、`.zcompdump*` のチェックサムを記録 / Act: 同じ ZDOTDIR でもう一度起動 / Assert: チェックサムが不変、かつ `.zcompdump.<pid>` 形式の残骸が増えていない。
- 期待: Step 3〜5 が正しければこの時点で Green(fpath が起動内で不変になり、dump 検証が毎回成功するため)。Red の場合は fpath に起動ごとに変わる要素が残っている合図なので、トレースで `compdump` の呼び出し元を特定して潰す。

### Step 7: compaudit のスキップ

- テストファイル: `test/compaudit_test.zsh`
- テスト名: `should not run compaudit during interactive startup`
- Arrange: `zsh -x -i -c exit` のトレースを取得 / Act: `+compaudit:` 行を検索 / Assert: 出現 0 回(現状 6 回呼ばれているので Red)。
- Green にする最小変更: `user-app/ohmyzsh/config.zsh` の `source $ZSH/oh-my-zsh.sh`(87 行目)の直前に `ZSH_DISABLE_COMPFIX=true` を追加。
- 挙動差の詳細: oh-my-zsh が `compaudit` 検査 + `compinit -i` の代わりに `compinit -u` を使うようになる。insecure directory(group/world-writable な fpath ディレクトリ)が存在しない限り挙動は完全に同一(実測で現在 `compaudit` は何も検出していない)。存在した場合のみ「警告+補完スキップ」→「警告なしで読み込み」に変わる。

### Step 8: 起動時間の回帰テスト(全体の受け入れ)

- テストファイル: `test/startup_time_test.zsh`
- テスト名: `should start interactive shell within 900 ms at median of 5 runs`
- Arrange: 隔離 ZDOTDIR で 1 回ウォームアップ起動(dump 生成)/ Act: `zsh -i -c exit` を 5 回計測し median を取る / Assert: 900 ms 未満(リサーチ時点の実測 median ~2.5 秒に対する回帰防止線。実端末では 0.6〜0.8 秒を期待)。
- このステップに固有の production 変更はない(Step 3〜7 の総和で Green になることを確認する)。

### Step 9: 最終検証と後始末

1. `test/run` で全テスト Green を確認。
2. `test/equivalence_test.zsh` を再実行し、baseline との差分が「既知の許容差分」のみであることを確認。
3. 一回限りの掃除(実 HOME、テストではなく運用手順):

   ```zsh
   rm -f ~/.zcompdump*   # 2024 年からの化石 .zwc(read-only)と .<pid> 残骸を含めて全消し
   exec zsh              # 新しい dump が 1 つだけ再生成されることを確認
   ls ~/.zcompdump*      # → ~/.zcompdump-<host>-<ver> 系のみになるはず
   ```

4. 手動スモークテスト(新しいターミナルで): p10k プロンプト表示 / `c <TAB>`(自作補完)/ `git st` 等の alias / `gcloud <TAB>` / `poetry` 補完 / wakatime プラグインのロード / `echo $PATH` が従来と一致。
5. コミット(規約: Conventional Commits + `Co-Authored-By`)、push、draft PR 作成。PR 本文に **gitignore 対象 `user-app-work/google-cloud-sdk/` の手動適用手順(Step 3)** を必ず記載する。

## コミット分割の目安

各 Step = 1 コミット(テスト + 最小 production 変更を同一コミットに):

1. `feat: allow DOTFILES override and add test harness`
2. `test: add environment snapshot characterization test`
3. `fix: load gcloud completion in completion phase, not path phase`(実 checkout のみ、PR には手順記載)
4. `refactor: build fpath in path phase before oh-my-zsh loads`
5. `fix: run compinit only once during startup`
6. `test: assert completion dump stays stable across startups`
7. `perf: skip compaudit via ZSH_DISABLE_COMPFIX`
8. `test: add startup time regression test`

## リスクと緩和

| リスク | 緩和策 |
| --- | --- |
| fpath 移動により補完が欠ける | Step 5b の `_comps[c]` 検査 + Step 2 の `${(ok)_comps}` スナップショット比較 |
| oh-my-zsh を外した(将来の)構成で compinit が走らない | ガードを `(( $+functions[compdef] )) || compinit` にしているため、OMZ 不在時は従来どおり zshrc が compinit する |
| 他マシン(work 以外)への影響 | 変更はすべて「未設定時は従来値」のフォールバック付き。`user-app-work/` はそもそも work マシンにしか存在しない |
| compaudit スキップによる警告喪失 | 個人マシン運用のため許容。気になる場合は Step 7 のみ revert 可能(独立コミット) |
