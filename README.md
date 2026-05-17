# image2-from-claude

> Claude Code から Codex 経由で Image 2.0、スライドもLPもこれ1本。

Claude Code 内で Codex MCP を踏み台にして gpt-image-2（Image 2.0）を呼び出し、
**横長16:9スライド**と**縦長スマホLP**を ChatGPT サブスク枠で量産するための2スキル同梱キット。

- `slides-from-codex` — 横長16:9スライドを5〜30枚一気に生成。Instagram / X カルーセル対応
- `lp-from-codex` — 縦長スマホLPをセクション別スライス＋HTMLで一発組立

API課金なし。Claude Code を抜けずに、Codex の Image 2.0 だけ拝借する設計です。

---

## インストール（30秒）

Claude Code を起動して、以下を実行:

```
/plugin marketplace add sammyTI/image2-from-claude
/plugin install lp-from-codex@image2-from-claude
/plugin install slides-from-codex@image2-from-claude
```

これで `~/.claude/skills/` に2スキルが配置され、すぐ使えます。

---

## 必要なもの

- **ChatGPT Plus / Pro** — Image 2.0 をサブスク枠で動かすため
- **Claude Code** — このスキルの起動環境
- **Codex CLI** — Image 2.0 を呼ぶための踏み台

Codex CLI を入れて ChatGPT ログイン:

```bash
brew install openai/tap/codex   # または npm install -g @openai/codex
codex login                      # ChatGPT アカウントでログイン
```

Codex MCP を Claude Code に接続（`~/.claude.json` または `.mcp.json`）:

```json
{
  "mcpServers": {
    "codex": {
      "command": "npx",
      "args": ["@openai/codex", "mcp-server"]
    }
  }
}
```

Claude Code を再起動して `mcp__codex__codex` ツールが見えれば疎通OK。

---

## 使い方

Claude Code に話しかけるだけ。

```
スライド作って
→ slides-from-codex が起動

LP作って
→ lp-from-codex が起動
```

それぞれヒアリング → Codex MCP に投げる → 結果の引き取り、まで自動で進みます。

---

## 出力イメージ

```
slides-out/<slug>/
├── index.html              ← HTML ビューア
├── style.css / script.js
└── assets/
    ├── 01-cover.png        ← 表紙
    ├── 02-agenda.png       ← アジェンダ
    └── NN-closing.png      ← 締め

lp-out/<slug>/
├── index.html              ← LP本体
├── style.css / script.js
├── assets/
│   ├── 01-fv.png           ← ファーストビュー
│   ├── 02-proof.png        ← 証明
│   └── 07-cta.png          ← 最終CTA
└── preview/
    ├── mobile-390.png
    └── desktop.png
```

---

## トラブルシュート

| 症状 | 対処 |
|------|------|
| `mcp__codex__codex` が見えない | Claude Code を再起動 / `.mcp.json` のパス確認 |
| 画像生成で API 課金が走る | `codex login` で ChatGPT アカウントを選び直す |
| Image 2.0 がレートリミット | サブスク枠の上限。時間を置く |
| 生成画像が30〜100KB しかない | HTMLフォールバック。プロンプトに「Pillow禁止 / gpt-image-2 必須」を明示 |

---

## 手動インストール（プラグイン仕組みを使わない場合）

```bash
git clone https://github.com/sammyTI/image2-from-claude.git
cd image2-from-claude
./scripts/install.sh
```

または既存ディレクトリを `~/.claude/skills/` にコピーするだけでも動きます:

```bash
cp -R skills/lp-from-codex ~/.claude/skills/
cp -R skills/slides-from-codex ~/.claude/skills/
```

---

## ライセンス

MIT License. © 2026 Sammy Okamura

---

## 制作

岡村さみー（[@sammyTI](https://x.com/sammyTI)）

- note: [@sammyo_official](https://note.com/bold_daisy957)
- Substack: [@dxai1](https://substack.com/@dxai1)
