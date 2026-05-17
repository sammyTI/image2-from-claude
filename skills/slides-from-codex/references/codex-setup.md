# Codex 側のセットアップ手順

このスキルを動かすには Codex CLI が動作し、Claude Code から MCP 経由で叩ける状態が必要。
`lp-from-codex` のセットアップと共通。

## 1. Codex CLI のインストール

```bash
brew install openai/tap/codex
# または
npm install -g @openai/codex
```

## 2. ChatGPT アカウントでログイン

API key ではなく ChatGPT アカウントでログインする（Image 2.0 をサブスク枠で動かすため）:

```bash
codex login
```

ブラウザが開くので、ChatGPT Plus / Pro 契約のアカウントで「Sign in with ChatGPT」を選ぶ。

確認:

```bash
cat ~/.codex/auth.json | head -3
```

## 3. Claude Code に Codex MCP を接続

プロジェクトの `.mcp.json` または `~/.claude.json` に追加:

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

Claude Code を再起動して `mcp__codex__codex` ツールが見えれば OK。

## 4. 動作確認

Claude Code から:

```
mcp__codex__codex を呼んで、「テスト用の横長16:9 PNG を1枚 gpt-image-2 で生成して、`/tmp/test.png` に保存してください」
```

実行後、`/tmp/test.png` が 1024×576 程度のPNGとして存在し、ファイルサイズが1MB前後あれば疎通OK。

## トラブルシュート

| 症状 | 対処 |
|------|------|
| `mcp__codex__codex` が見えない | Claude Code を再起動 / `.mcp.json` のパス確認 |
| 画像生成で API 課金が走る | `codex login` で ChatGPT アカウントを選び直す |
| Image 2.0 がレートリミット | サブスク枠の上限に達してる。時間を置く |
| 生成画像が30〜100KB しかない（フラット） | Codex が HTML→PNG にフォールバックしてる。プロンプトに「Pillow禁止 / gpt-image-2 必須」を明示 |
