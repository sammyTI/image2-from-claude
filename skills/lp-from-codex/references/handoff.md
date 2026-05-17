# Claude Code ↔ Codex MCP の入出力プロトコル（LP版）

このスキルは Claude Code と Codex MCP の間でファイルベース＋プロンプトベースのハンドオフを行う。
取り違え・パス迷子を防ぐためのチェックリスト。

## 入力ハンドオフ（Claude Code → Codex MCP）

### 必須入力

| 項目 | 形式 | 例 |
|------|------|------|
| 参考デザインのパス | 絶対パス | `/path/to/reference.png` |
| 出力先ディレクトリ | 絶対パス | `/path/to/lp-out/seminar-2026-06/` |
| LPの目的 | 文字列 | `LINE登録誘導` |
| セクション構成＋コピー | 構造化テキスト | `references/invocation.md` のテンプレ参照 |

### 任意入力

- リンク先URL（CTA / 動画 / フォーム）— 未指定なら placeholder modal
- ブランド配色（HEX）— 未指定なら参考デザインから推測
- フォント指定 — 未指定なら参考デザインから推測

### Codex MCP 呼び出し時の引数

```
mcp__codex__codex(
  prompt: <invocation.md のテンプレに値を埋めたもの>,
  sandbox: "workspace-write",
  approval-policy: "never",
  cwd: <output_dir の親ディレクトリ>,
  model: "gpt-5.5"
)
```

## 出力ハンドオフ（Codex MCP → Claude Code）

### Codex 側で生成されるべき構造

```
{output_dir}/
├── index.html                ← LP本体
├── style.css                 ← 任意（inline でも可）
├── script.js                 ← 任意（inline でも可）
├── assets/
│   ├── 01-fv.png            ← ファーストビュー
│   ├── 02-proof.png         ← 証明
│   ├── 03-benefit.png       ← ベネフィット
│   ├── 04-target.png        ← こんな人
│   ├── 05-flow.png          ← 流れ
│   ├── 06-speaker.png       ← 登壇者
│   └── 07-cta.png           ← 最終CTA
└── preview/
    ├── mobile-390.png
    ├── mobile-430.png
    └── desktop.png
```

### Claude Code 側の検証手順

1. `index.html` の存在を Read で確認
2. `assets/` 配下のスライス枚数が想定通りか
3. 各PNGのファイルサイズが Image 2.0 由来か（>500KB目安、30〜100KB なら HTMLフォールバック）
4. `preview/` のスクショがあれば内容を Read で表示確認
5. `index.html` を grep して以下を確認:
   - `width: min(100%, 430px)` 等のスマホ最大幅指定があるか
   - 透明CTAボタンが存在するか（`position: absolute` + `opacity: 0` または背景なし）
   - `alt` 属性がスライス画像に付いているか
6. CSS / JS が分離されているか inline か確認

### 期待しない応答（要再投）

- 画像生成エラー（Codex 側のレートリミット）
- HTML が `<html>` だけ
- assets/ が空
- 参考デザインを完全模写しただけ（LPになってない）
- PNG ファイルサイズが30〜100KB（HTMLフォールバック疑い）

→ 修正プロンプト（`references/invocation.md` テンプレC）を追投する。

## トラブル時のフォールバック

Codex MCP 経由でうまく動かない場合:

1. **直接 Codex CLI を起動**: `codex chat` で同じプロンプトを貼る。Claude Code のセッションは中断
2. **1スライスずつ生成**: 全部まとめてではなく、`invocation.md` のテンプレを使って1セクションずつ生成 → 最後に index.html を Claude Code 側で組み立て
3. **デバッグログ**: `~/.codex/logs_2.sqlite` を `sqlite3` で開いて直近のエラー確認
