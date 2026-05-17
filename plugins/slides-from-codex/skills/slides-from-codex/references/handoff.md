# Claude Code ↔ Codex MCP の入出力プロトコル（スライド版）

## 入力ハンドオフ

### 必須

| 項目 | 形式 | 例 |
|------|------|------|
| 出力先 | 絶対パス | `/Applications/MAMP/htdocs/extrahans_compony/slides-out/seminar-2026-05/` |
| 枚数 | 整数 | 10 |
| 各スライドのコピー | 構造化テキスト | references/invocation.md のテンプレ参照 |
| デザイントーン | 文字列 | 「白背景＋ネイビーアクセント、ビジネスカジュアル」 |

### 任意

- ブランド配色（HEX）
- フォント指定
- 参考デザインのパス
- ロゴ画像
- 用途（プレゼン / カルーセル / 提案書）

### Codex MCP 呼び出し

```
mcp__codex__codex(
  prompt: <invocation.md テンプレ展開後>,
  sandbox: "workspace-write",
  approval-policy: "never",
  cwd: <output_dir の親>,
  model: "gpt-5.5"
)
```

## 出力ハンドオフ

### Codex 側で生成されるべき構造

```
{output_dir}/assets/
├── 01-cover.png          ← 表紙
├── 02-agenda.png         ← アジェンダ
├── 03-...png             ← 本文
├── ...
└── NN-closing.png        ← 締め
```

各PNG:
- 用途別にサイズ選択（references/invocation.md 参照）
- 1枚あたり 1MB 前後（Image 2.0）
- 30〜100KB ならHTMLフォールバック → 修正プロンプトで再投

### Claude Code 側の検証手順

#### 事前検証フローを使う場合（5枚以上推奨）

Phase 1（1枚目のみ生成）完了直後:

1. `stat -f %z {output_dir}/assets/01-cover.png` でファイルサイズ取得
2. 500KB以上 → ゲート通過 → Phase 2 へ進む
3. 30〜100KB → HTMLフォールバック疑い → `invocation.md` テンプレDの再投プロンプトで Phase 1 を再投
4. 10KB未満 → エラー → ユーザーに報告して中断

Phase 2 完了後:

1. 全スライドファイル数確認（指定枚数と一致するか）
2. 各ファイルサイズが Image 2.0 由来か（>500KB目安）
3. 連番抜けがないか
4. 表紙・締めが配置されているか

#### 一括生成の場合

1. 全スライドファイル数確認（指定枚数と一致するか）
2. 各ファイルサイズが Image 2.0 由来か（>500KB目安）
3. 連番抜けがないか
4. 表紙・締めが配置されているか

### ロギング

`.company/marketing/content-plan/` または `pm/projects/` に1ファイル記録:

```markdown
---
type: slides-output
date: YYYY-MM-DD
slug: {output-slug}
output_dir: {absolute-path}
slides_count: {N}
purpose: {seminar | carousel | proposal | ...}
generator: slides-from-codex (Claude Code) + gpt-image-2 (Codex)
status: draft | reviewed | published
---

# {デッキタイトル}

## 経緯
- {何のためのスライドか}

## 入力
- 枚数: {N}
- トーン: {tone}
- 主要メッセージ: {key messages}

## 出力
- スライド: {N}枚
- ビューア: {index.html path}

## 次のアクション
- [ ] レビュー
- [ ] 修正
- [ ] PDFエクスポート
- [ ] 配布
```

## トラブル時のフォールバック

1. **直接 Codex CLI**: `codex chat` で直接プロンプトを投げる
2. **手動分割生成**: 1枚ずつ別プロンプトで生成して連結
3. **HTMLビューア無し**: 画像連番だけで提供して、ユーザー側で keynote 等にインポート
