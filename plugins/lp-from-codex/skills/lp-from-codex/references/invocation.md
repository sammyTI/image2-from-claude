# Codex MCP 呼び出しテンプレ（LP版）

`mcp__codex__codex` で gpt-image-2 を使ってスマホLPを生成するときのプロンプトテンプレ集。

## ツール呼び出しパラメータ（推奨デフォルト）

```
mcp__codex__codex
  prompt: <下記プロンプトテンプレ>
  sandbox: workspace-write
  approval-policy: never
  model: gpt-5.5  または gpt-5.2-codex
  cwd: <output_dir の親ディレクトリ>
```

`sandbox: read-only` だと Codex 側が画像を保存できない。
`approval-policy: never` を入れないと、ユーザー承認待ちで止まる。

## 画像とコーディングの境界（全テンプレ共通・必ず読む）

LP は「画像で作るもの」と「コードで作るもの」を明確に分ける。
Codex が抜け穴で SVG / CSS / canvas に逃げないよう、以下を全プロンプトの先頭に含める。

### 画像で作る（gpt-image-2 で PNG 生成）

各セクションスライス（FV / 証明 / ベネフィット / こんな人 / 流れ / 登壇者 / 最終CTA絵柄）の本体。
ビジュアル・見出し文字・サブ文字・装飾・アイコン・イラストはすべて **画像内に焼き込む**。

**厳禁**（これに違反したら全部やり直し）:
- セクション本体の見出し・本文テキストを HTML / CSS / SVG / canvas で描くこと
- インラインSVG（`<svg>` 要素）で文字や装飾を組み立てること
- CSS background-image / linear-gradient / box-shadow だけでセクション本体を構成すること
- Pillow / PIL / 任意の Python 画像ライブラリでテキスト合成
- HTML→PNG レンダリング（puppeteer / playwright / wkhtmltopdf / Pageres 含む）

### コードで作る（HTML / CSS 実装）

- CTAボタン本体（`<a class="cta">予約する</a>` などクリック可能なリンク）
- 画像の上に重ねる透明クリックエリア（`position: absolute; opacity: 0;`）
- レイアウトラッパー（`width: min(100%, 430px);` の縦並びコンテナ）
- スライス画像を読み込む `<img>` タグ（必ず `alt` 属性付き）
- スクロール / フェードイン等の軽量JS（任意）

つまり「セクションのビジュアル本体は焼き込み画像、機能（CTAリンク・レイアウト）はコード」が原則。

### 完了報告で証跡を要求

Codex の応答に必ず含めさせる:
- 各PNGのファイルパス＋ファイルサイズ（KB単位、明示的に）
- gpt-image-2 generated_images uuid（呼び出し証跡）
- 「セクション本体を SVG / CSS / canvas で描いていないこと」の明示宣言

## プロンプトテンプレ A — 基本（構成と参考デザイン渡す）

Claude Code 側のヒアリングで集めた値を埋めて投げる:

```text
gpt-image-2 (Image 2.0) で 縦長スマホLP のセクション別スライス画像を {N}枚 生成し、
HTML/CSS/JS で組み上げて1本のLPに仕上げてください。

【画像とコーディングの境界・厳守】

セクション本体（FV / 証明 / ベネフィット 等）の見出し・本文・装飾は全て gpt-image-2 で生成した PNG に焼き込むこと。
以下は厳禁:
- セクション本体のテキスト・見出しを HTML/CSS/SVG/canvas で描くこと
- インラインSVG・CSS background-image / gradient のみで構成すること
- Pillow / PIL / HTML→PNG レンダリング（puppeteer / playwright 等）

逆に以下は HTML/CSS で実装すること:
- CTAボタン本体（クリック可能な `<a>` タグ）
- 画像の上に重ねる透明クリックエリア
- レイアウトラッパー（width: min(100%, 430px) 縦並び）
- `<img>` タグでのスライス画像読み込み

【LPの目的】
{goal}（例: 無料LIVE予約 / LINE登録 / 商品購入 / 資料請求 / ウェビナー申込）

【ターゲット】
{audience}

【参考デザイン】
{reference_image_path}

このアイキャッチ/キービジュアルからトンマナ（配色・余白・見出しの強さ・全体の雰囲気）を引き継いでください。
レイアウトは固定模写ではなく、スマホLP として読みやすい形に再構成してOK。

【出力】
- 各スライス: 1024×1536 PNG（縦長2:3、スマホLP最適）
- {output_dir}/assets/01-{kind}.png 〜 {N}-{kind}.png に保存
- {output_dir}/index.html, style.css, script.js を作成
- index.html はスマホ最大幅 430px の縦並びレイアウト、各スライスを上から順に表示

【全スライス共通のデザインシステム】
- 配色: 参考デザインから抽出 or {主配色を指定}
- 雰囲気: {ビジネス／カジュアル／ポップ／ミニマル}
- フォント: 日本語サンセリフ、見出しは太字
- 余白: 多め。要素は左右に最低40pxのセーフマージン
- 1セクション1メッセージ
- 必ず縦長キャンバス全体を使い切ること

【セクション構成】
1. ファーストビュー
   - 見出し: {fv_headline}
   - サブ: {fv_sub}
   - CTA: {fv_cta_label}
2. 証明 / 動画 / 信頼
   - 入れたい要素: {proof_elements}
3. ベネフィット / 得られるもの
   - 箇条書き: {benefits}
4. こんな人におすすめ
   - 箇条書き: {target_list}
5. 流れ / ワークフロー / 違い
   - ステップ: {workflow_steps}
6. 登壇者 / 商品 / サービス紹介
   - 名前: {speaker_name}
   - 肩書き: {speaker_title}
   - プロフィール: {speaker_bio}
7. 最終CTA
   - CTA: {final_cta_label}
   - 注記: {final_notes}

【リンク先】
- CTA1 (ファーストビュー): {cta1_url}
- CTA2 (最終): {cta2_url}
- 動画: {video_url}
- フォーム: {form_url}

URL未確定のものは placeholder modal で構わない。

【HTML 仕様】
- `width: min(100%, 430px)` でスマホ最大幅指定
- 各スライス画像の上に CTA ボタン（透明オーバーレイ）を配置可能にする
- アクセシビリティ: `alt` 属性を必ず付ける（セクション内容を簡潔に）

【完了報告に含めてほしいもの】
- 生成した縦長画像スライスのファイルパス全部
- index.html のフルパス
- 検証スクショ (preview-mobile-390.png / preview-mobile-430.png / preview-desktop.png) のパス
- gpt-image-2 で生成したことの証跡（generated_images uuid）
- 1枚あたりのファイルサイズ（1MB以上＝Image 2.0、30〜100KB＝HTMLフォールバック）
- もしエラーが出たらエラー全文
```

## プロンプトテンプレ B — 簡易（ヒアリングはCodex側に任せる）

ユーザーが「とりあえずざっくり LP 作って」と言った場合:

```text
gpt-image-2 (Image 2.0) で 縦長スマホLP を作ってください。
HTML→PNG レンダリング禁止。

参考デザイン: {reference_image_path}
出力先: {output_dir}

LP構成はデフォルト（FV/証明/ベネフィット/こんな人/流れ/登壇者/最終CTA）でOKです。
各セクションに入れるコピーは、参考デザインから推測して埋めてください。
迷ったら明らかに仮のサンプルテキストを入れて、後で差し替えやすくしてください。

各スライス 1024×1536 PNG、最大幅430pxのスマホLP HTML、で組み上げ。
完了したら生成物のパス全部とスクショパスを報告してください。
```

## プロンプトテンプレ D — 事前検証フロー（推奨デフォルト）

LPは通常6〜8スライス。全部まとめて生成して「全部HTMLフォールバック」だった、を避けるために
**ファーストビューだけ先に生成 → サイズ確認 → OKなら残りを一気に生成**、の2段階で投げる。

### Phase 1: ファーストビューだけ先行生成

```text
gpt-image-2 (Image 2.0) で 縦長スマホLP の「ファーストビュー」スライスだけを1枚生成してください。
HTML→PNG レンダリング・Pillow 変換は厳禁。gpt-image-2 直接生成のみ。

【出力】
- {output_dir}/assets/01-fv.png（1024×1536 PNG、縦長2:3）

【スライス内容】
- 見出し: {fv_headline}
- サブ: {fv_sub}
- CTA: {fv_cta_label}
- 参考デザイン: {reference_image_path}（トンマナのみ引き継ぎ）
- デザイントーン: {tone}

【完了報告に必ず含める】
- ファイルパス
- ファイルサイズ（バイト単位 or KB単位、明示的に）
- gpt-image-2 generated_images uuid
```

### Phase 1 後、Claude Code 側でゲート

応答からファイルパスを抽出し、サイズを確認:

```bash
stat -f %z {output_dir}/assets/01-fv.png
# Linux なら stat -c %s
```

判定:

| サイズ | 判定 | 次のアクション |
|--------|------|--------------|
| 500KB 以上 | gpt-image-2 由来確定 | Phase 2 へ進む |
| 100〜500KB | グレー | ユーザーに見せて判断仰ぐ |
| 30〜100KB | HTML/Pillow フォールバック疑い | Phase 1 を修正プロンプトで再投 |
| 10KB 未満 | 生成失敗 | エラー報告 → 再投 |

### Phase 1 再投プロンプト（フォールバック検知時）

```text
直前に生成した {output_dir}/assets/01-fv.png はファイルサイズが小さすぎます（{actual_size}KB）。
これは HTML→PNG レンダリングまたは Pillow 変換に切り替わったことを意味します。

**改めて厳守してください**:
- gpt-image-2 (Image 2.0) を直接呼び出すこと
- Pillow / HTML レンダリング / PIL / 任意の Python 画像ライブラリは使用禁止
- 出力は必ず Image 2.0 由来（1MB前後）

同じ仕様で 01-fv.png を再生成してください。
完了報告にファイルサイズと generated_images uuid を含めること。
```

### Phase 2: 残りスライス + HTML 組立

Phase 1 が通ったら、テンプレA または B と同じ要領で残りスライス（02-proof.png 〜 07-cta.png）と HTML/CSS/JS を1ターンで投げる。
プロンプトの末尾に「1枚目（01-fv.png）と同じデザインシステム・配色・トーンで揃えること」を必ず入れる。

## プロンプトテンプレ C — 修正フェーズ

初回生成後にユーザーが「FVをもう少し強く」「色を寒色に」みたいに言ってきたら:

```text
前回生成した {output_dir}/assets/ のうち、以下のスライスを修正してください。

【対象】
- {target_slices}（例: 01-fv.png, 03-benefit.png）

【修正指示】
{修正内容を具体的に}

【他のスライスへの波及】
他のスライスとデザインシステム（配色・トーン）が揃うように、必要なら他のスライスも合わせて再生成してください。
HTML側のレイアウトは保つこと。

修正後、変更したスライスとスクショの再生成を報告してください。
```

## サイズの選び方

| 用途 | 推奨サイズ | アスペクト比 |
|------|----------|-----------|
| スマホLP（標準） | 1024×1536 | 2:3 |
| スマホLP（縦長強調） | 1024×1792 | ≒4:7 |
| 横長LP（PC優先） | 1792×1024 | 16:9 |

gpt-image-2 がサポートする生成サイズに合わせて、近い比率で生成 → 必要なら `sips` 等でリサイズ。

## 応答パース

Codex MCP の応答（content フィールド）から以下を取り出す:

- 画像スライスパス（`assets/01-fv.png` など）
- HTML パス
- スクショパス
- エラーがあれば error フィールド

応答が JSON 構造化されていない場合、プレーンテキストから正規表現で抽出する:

```regex
/(\/[^\s`'"]+\.(png|html|jpg|webp))/g
```

抽出後、Read で実在を確認。ファイルサイズが1MB前後なら Image 2.0、30〜100KB ならHTMLフォールバック → 修正プロンプトで再投。

## タイムアウト目安

- スライス4枚 + HTML: 3〜6分
- スライス7枚 + HTML + スクショ: 6〜12分

10分以上応答がない場合、Codex 側でレートリミットに当たっている可能性。`mcp__codex__codex-reply` で続報を待つか、新しいセッションで再投。
