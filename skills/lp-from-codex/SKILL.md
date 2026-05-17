---
name: lp-from-codex
description: Claude Code から Codex MCP 経由で gpt-image-2 (Image 2.0) を使い、縦長スマホLP（セクション別スライス画像 + HTML/CSS/JS）を生成する薄いブリッジ。Claude Code 側で構成・コピー整理、Codex 側でスライス画像生成と HTML 組立を担当する。slides-from-codex の姉妹スキル。トリガー: 「LP作って」「ランディング作って」「セミナー告知ページ作って」と言われたとき、または Claude Code 主軸の人が Codex を直叩きせずスマホLPを作りたいとき。
---

# lp-from-codex

Claude Code から **Codex MCP** 経由で gpt-image-2 (Image 2.0) を呼び出し、**縦長スマホLP**（セクション別スライス画像 + HTML/CSS/JS）を生成するためのブリッジスキル。

姉妹スキル `slides-from-codex`（横長16:9スライド）と同じ薄いブリッジ思想で、Codex 側の Image 2.0 を Claude Code から呼び出す形。

## 設計思想

Codex 経由で Image 2.0 を使うと、サブスク枠で実質コストゼロ・高品質なLPスライス画像が量産できる。
このスキルは「Claude Code 主軸の人が、Codex に切り替えずに同じ恩恵を受ける」ためのブリッジ。

役割分担:

| 担当 | やること |
|------|---------|
| Claude Code（このスキル） | ヒアリング、構成・コピーまとめ、成果物管理、Playwright QA、SNS配布物の下書き |
| Codex MCP（gpt-image-2） | 各セクションのスライス画像（縦長スマホ）を Image 2.0 で生成、HTML/CSS/JS の組立 |

## 前提条件

→ Codex CLI が動く（`which codex`）
→ Codex MCP が Claude Code に接続済み（`.mcp.json` に `codex` エントリ）
→ ChatGPT サブスクで `codex login` 済み（Image 2.0 をサブスク枠で動かすため）

詳細は `references/codex-setup.md` 参照。

## いつ使うか

- 「LP作って」「ランディング作って」「セミナー告知ページ」と言われたとき
- 既に LP 構成・参考デザインが固まっていて、スマホLPに落としたいとき
- Claude Code を抜けたくない、でもLP制作はしたいとき

逆に **使わない**:

- LP の戦略・コピー・オファー設計から相談したいとき → 先に構成を固める
- LP 構成が未確定 → 確定させてから呼ぶ
- インタラクティブな動的要素が多い → 別ツール（React/Vue 系）

## ワークフロー

### Step 0: 前提チェック

```
□ codex コマンドが PATH にある
□ Claude Code から mcp__codex__codex ツールが見える
□ ~/.codex/auth.json に ChatGPT サブスクのログインがある
```

欠けがある場合の案内は `references/codex-setup.md` を参照。

### Step 1: 入力収集（Claude Code 側で完結）

`AskUserQuestion` で以下を埋める:

- **LP の目的**: 予約 / LINE登録 / 購入 / 資料請求 / ウェビナー / 動画視聴 / その他
- **ターゲット**: 誰に見せるLPか
- **参考デザイン**: アイキャッチ / キービジュアル / 過去LP / デザインスクショのファイルパス
- **セクション構成**: ファーストビュー〜最終CTAまで（4〜8セクション目安）
- **コピー**: 各セクションの見出し・本文・CTA文言
- **リンク先URL**: CTA / 動画 / フォーム（未確定なら placeholder で OK）
- **出力先**: デフォルト `lp-out/<slug>/`

### Step 2: Codex MCP に投げる（2段階推奨）

`mcp__codex__codex` を `sandbox: workspace-write` / `approval-policy: never` で呼ぶ。プロンプトテンプレは `references/invocation.md` 参照。

**推奨フロー: ファーストビューだけ先行生成 → サイズゲート → 残りスライス＋HTML を生成**

LPは通常6〜8スライス。全部まとめて生成して「全部HTMLフォールバック」だった、を避けるため `invocation.md` のテンプレD（事前検証フロー）を使う:

1. **Phase 1**: 01-fv.png だけ Codex に投げて生成
2. **Claude Code 側でサイズ確認**: 500KB以上なら gpt-image-2 由来確定、30〜100KBならフォールバック疑いで再投
3. **Phase 2**: ゲート通過後に残りスライス（02-07）＋ HTML/CSS/JS を一気に生成

要点:

→ 各スライスは **1024×1536** PNG（縦長2:3、スマホLP最適）で gpt-image-2 生成
→ 全スライスで同じデザインシステム（配色・余白・タイポ）
→ 参考デザインがあればそのトンマナを引き継ぐ（固定模写ではなく再構成）
→ Pillow / HTML→PNG レンダーは禁止（gpt-image-2 直接生成固定）
→ index.html はスマホ最大幅 430px の縦並びレイアウト、各スライスを順に表示

### Step 2.5: 1枚目のサイズゲート

`stat -f %z {output_dir}/assets/01-fv.png` で容量確認:

| サイズ | 判定 | アクション |
|--------|------|----------|
| 500KB 以上 | gpt-image-2 由来確定 | Phase 2 へ進む |
| 30〜100KB | HTMLフォールバック疑い | Phase 1 を修正プロンプトで再投 |
| 10KB 未満 | 生成失敗 | エラー報告 |

### Step 3: 結果の引き取り

Codex MCP の応答から以下を抽出して Claude Code 側で確認する:

- 生成画像スライス（`{output_dir}/assets/`）
- `index.html`
- プレビュースクショ（あれば）

抽出したパスを Read で開いて存在確認。

### Step 4: Claude Code 側の追加処理（任意）

ユーザーが追加で求めたら以下を実施。デフォルトでは聞いてから:

- **追加QA（Playwright MCP）**: 390px / 430px / 1280px の3幅でスクショ取り直し、横スクロール検知
- **配布物下書き**: SNS用テキスト（X / IG / note）の下書きを生成
- **デプロイ**: Netlify / Cloudflare Pages など

## 出力規約

LP 1本につき以下の構造を維持する:

```
{output_dir}/
├── index.html
├── style.css                 (inline でも可)
├── script.js                 (inline でも可)
├── assets/
│   ├── 01-fv.png             ← ファーストビュー
│   ├── 02-proof.png          ← 証明 / 動画 / 信頼
│   ├── 03-benefit.png        ← ベネフィット
│   ├── 04-target.png         ← こんな人におすすめ
│   ├── 05-flow.png           ← 流れ / ワークフロー
│   ├── 06-speaker.png        ← 登壇者 / 商品紹介
│   └── 07-cta.png            ← 最終CTA
└── preview/
    ├── mobile-390.png
    ├── mobile-430.png
    └── desktop.png
```

スライス命名は `NN-purpose.png` 形式。

## 関連ファイル

- `references/codex-setup.md` — Codex CLI セットアップ手順
- `references/invocation.md` — Codex MCP プロンプトテンプレ
- `references/handoff.md` — 入出力プロトコル

## 姉妹スキル

- `slides-from-codex` — 横長16:9スライド用のブリッジ（同じ Image 2.0 経由）
