---
name: slides-from-codex
description: Claude Code から Codex MCP 経由で gpt-image-2 (Image 2.0) を使い、横長16:9のスライドデッキを生成する薄いブリッジ。Claude Code 側で構成・コピー整理、Codex 側でスライド画像生成と簡易HTMLビューア組立を担当する。lp-from-codex の姉妹スキル。トリガー: 「スライド作って」「プレゼン作って」「セミナー資料作って」「SlidesFromCodex」と言われたとき、または Claude Code 主軸の人が Codex を直叩きせずスライド画像を量産したいとき。
---

# slides-from-codex

Claude Code から **Codex MCP** 経由で gpt-image-2 (Image 2.0) を呼び出し、**横長16:9のスライドデッキ**を生成するためのブリッジスキル。

姉妹スキル `lp-from-codex`（縦長スマホLP）と同じ薄いブリッジ思想で、Codex 側の Image 2.0 を Claude Code から呼び出す形。

## 設計思想

Codex 経由で Image 2.0 を使うと、サブスク枠で実質コストゼロ・高品質なスライド画像が量産できる。
このスキルは「Claude Code 主軸の人が、Codex に切り替えずに同じ恩恵を受ける」ためのブリッジ。

役割分担:

| 担当 | やること |
|------|---------|
| Claude Code（このスキル） | ヒアリング、構成・コピーまとめ、成果物管理、HTML ビューア組立 |
| Codex MCP（gpt-image-2） | 各スライド画像（横長16:9）を Image 2.0 で生成 |

## 前提条件

→ Codex CLI が動く（`which codex`）
→ Codex MCP が Claude Code に接続済み（`.mcp.json` に `codex` エントリ）
→ ChatGPT サブスクで `codex login` 済み

詳細は `references/codex-setup.md` 参照。

## いつ使うか

- 「スライド作って」「プレゼン作って」「セミナー資料作って」と言われたとき
- 5〜30枚程度の枚数で構成が固まっているとき
- カルーセル投稿用の連番画像（Instagram / X / LinkedIn）が欲しいとき
- Keynote・PowerPoint じゃなくて 画像連番 + HTML ビューア で十分な用途

逆に **使わない**:

- インタラクティブな動的要素が必要（→ reveal.js などの別ツール）
- 厳密に編集可能な PowerPoint 形式が必要（→ 別ツール）
- 構成が未確定（→ 先にヒアリングで固める）

## ワークフロー

### Step 0: 前提チェック

```
□ codex コマンドが PATH にある
□ Claude Code から mcp__codex__codex ツールが見える
□ ~/.codex/auth.json に ChatGPT サブスクのログインがある
```

### Step 0.5: 競合調査（推奨デフォルト）

スライド制作に入る前に、同ジャンルのデッキを WebSearch / WebFetch で3〜5本収集する。
カルーセル投稿の場合は Instagram / X / LinkedIn の人気投稿、プレゼンの場合は SlideShare / Speaker Deck も対象。

詳細手順は `references/competitive-research.md` 参照。要点:

→ 「{テーマ} スライド」「{テーマ} カルーセル」「{業界} プレゼン」で検索
→ 上位3〜5本のスライド構成・配色・タイポ・1枚目フックを抽出
→ `{output_dir}/_competitive.md` に整理して保存
→ ユーザーに「これらに寄せる / 独自路線 / 一部要素だけ採用」を確認

ユーザーがすでにトーンを決めていて急ぎの場合はスキップしてOK。

### Step 1: 入力収集（Claude Code 側）

`AskUserQuestion` で以下を埋める:

- **デッキの目的**: セミナー / プレゼン / カルーセル投稿 / 説明資料 / 提案書 / その他
- **ターゲット**: 誰に見せるか
- **トーン**: ビジネス / カジュアル / ポップ / モノトーン / 既存ブランド継承
- **競合事例の採用方針**: Step 0.5 の事例から採用する要素（あれば）
- **枚数**: 5〜30枚目安（10前後が標準）
- **各スライドのコピー**: タイトル + サブ + ポイント箇条書き（2〜4個）
- **参考デザイン**: あればパス、なければ言葉でトーン指示
- **出力先**: デフォルト `slides-out/<slug>/`

### Step 2: Codex MCP に投げる（2段階推奨）

`mcp__codex__codex` を `sandbox: workspace-write` / `approval-policy: never` で呼ぶ。プロンプトテンプレは `references/invocation.md` 参照。

**推奨フロー: 1枚目だけ先行生成 → サイズゲート → 残りを生成**

5枚以上のデッキでは `invocation.md` のテンプレD（事前検証フロー）を使う:

1. **Phase 1**: 表紙1枚だけ Codex に投げて生成
2. **Claude Code 側でサイズ確認**: 500KB以上なら gpt-image-2 由来確定、30〜100KBならフォールバック疑いで再投
3. **Phase 2**: ゲート通過後に残りスライスを一気に生成

要点:

→ 各スライドは **1024×576** または **1792×1024** PNG（16:9）で gpt-image-2 生成
→ 全スライドで同じデザインシステム（配色・余白・タイポ）
→ **ヘッダー/フッターの位置を全スライドで完全に揃える**（ブランド名・ページ番号の x/y 座標を固定）
→ Pillow / HTML→PNG レンダーは禁止（gpt-image-2 直接生成固定）
→ 表紙・本文・締め、の3パートでデッキ全体の起承転結を意識

### Step 2.5: 1枚目のサイズゲート

`stat -f %z {output_dir}/assets/01-cover.png` で容量確認:

| サイズ | 判定 | アクション |
|--------|------|----------|
| 500KB 以上 | gpt-image-2 由来確定 | Phase 2 へ進む |
| 30〜100KB | HTMLフォールバック疑い | Phase 1 を修正プロンプトで再投 |
| 10KB 未満 | 生成失敗 | エラー報告 |

### Step 3: 結果の引き取り

Codex MCP の応答からファイルパスを抽出して Read で存在確認。

### Step 4: HTML ビューア組立（任意）

ユーザーが希望すれば、簡易な HTML ビューアを Claude Code 側で組み立てる:

→ 矢印キー / クリック / スワイプで前後遷移
→ サムネ一覧モード
→ 全画面モード
→ PDF エクスポート（印刷ダイアログ経由）

雛形は `references/html-template.md` 参照。

## 出力規約

```
{output_dir}/
├── index.html              ← HTML ビューア（任意）
├── style.css
├── script.js
└── assets/
    ├── 01-cover.png        ← 表紙
    ├── 02-agenda.png       ← アジェンダ
    ├── 03-...png
    └── NN-closing.png      ← 締め
```

スライド命名は `NN-purpose.png` 形式。連番でソート可能に。

## カルーセル投稿モード

Instagram / X カルーセル用の場合は以下の調整:

→ 1枚目に強い「引きフック」を配置（スワイプ動機）
→ 各スライドに番号（1/10、2/10）を控えめに表示
→ 最後の1枚に「保存・シェア」CTA

`references/invocation.md` の「カルーセルプロンプトテンプレ」を使う。

## 関連ファイル

- `references/codex-setup.md` — Codex CLI セットアップ手順
- `references/invocation.md` — Codex MCP プロンプトテンプレ（標準デッキ / カルーセル）
- `references/html-template.md` — HTML ビューア雛形
- `references/handoff.md` — 入出力プロトコル

## 姉妹スキル

- `lp-from-codex` — 縦長スマホLP用のブリッジ（同じ Image 2.0 経由）
