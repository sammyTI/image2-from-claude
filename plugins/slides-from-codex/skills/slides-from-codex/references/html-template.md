# HTML ビューア雛形

Codex が生成したスライド画像を、ブラウザで前後遷移できる簡易ビューアにする雛形。
Claude Code 側で組み立てる。Codex に投げる必要なし。

## 構成

```
{output_dir}/
├── index.html
├── style.css
├── script.js
└── assets/
    ├── 01-cover.png
    ├── 02-...png
    └── NN-closing.png
```

## index.html

```html
<!doctype html>
<html lang="ja">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{デッキタイトル}</title>
  <link rel="stylesheet" href="./style.css">
</head>
<body>
  <main class="deck" data-deck>
    <!-- Codex 生成スライドを連番で並べる。order は assets/ の連番に従う -->
    <section class="slide" data-index="1">
      <img src="./assets/01-cover.png" alt="表紙">
    </section>
    <section class="slide" data-index="2" hidden>
      <img src="./assets/02-agenda.png" alt="アジェンダ">
    </section>
    <!-- ... 続く ... -->
  </main>

  <nav class="controls" aria-label="スライド操作">
    <button data-prev aria-label="前へ">←</button>
    <span class="counter"><span data-current>1</span> / <span data-total>10</span></span>
    <button data-next aria-label="次へ">→</button>
    <button data-thumb aria-label="サムネ一覧" class="thumb-toggle">⊞</button>
    <button data-fullscreen aria-label="全画面">⛶</button>
  </nav>

  <aside class="thumbs" data-thumbs hidden>
    <!-- 全スライドのサムネをグリッドで表示。クリックでジャンプ -->
  </aside>

  <script src="./script.js"></script>
</body>
</html>
```

## style.css の要点

```css
:root {
  color-scheme: dark;
  --bg: #0f172a;
  --fg: #ffffff;
  --accent: #f97316;
}

* { box-sizing: border-box; }
html, body { margin: 0; height: 100%; background: var(--bg); color: var(--fg); }

.deck {
  display: grid;
  place-items: center;
  height: calc(100vh - 64px);
  padding: 16px;
}

.slide {
  width: 100%;
  max-width: 1280px;
  aspect-ratio: 16 / 9;
}

.slide img {
  width: 100%;
  height: 100%;
  object-fit: contain;
  display: block;
}

.controls {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 12px;
  padding: 12px;
  background: rgba(15, 23, 42, 0.85);
  backdrop-filter: blur(8px);
}

.controls button {
  border: 1px solid rgba(255,255,255,0.2);
  background: transparent;
  color: var(--fg);
  border-radius: 999px;
  width: 40px;
  height: 40px;
  cursor: pointer;
}

.thumbs {
  position: fixed;
  inset: 0;
  background: rgba(15, 23, 42, 0.95);
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
  gap: 16px;
  padding: 24px;
  overflow-y: auto;
}

.thumbs img {
  width: 100%;
  border-radius: 8px;
  cursor: pointer;
}
```

## script.js の要点

```js
const slides = document.querySelectorAll(".slide");
const total = slides.length;
const counter = document.querySelector("[data-current]");
const totalEl = document.querySelector("[data-total]");
totalEl.textContent = total;

let current = 1;

function show(n) {
  if (n < 1 || n > total) return;
  slides.forEach((s, i) => { s.hidden = (i + 1) !== n; });
  counter.textContent = n;
  current = n;
  history.replaceState(null, "", `#${n}`);
}

document.querySelector("[data-prev]").addEventListener("click", () => show(current - 1));
document.querySelector("[data-next]").addEventListener("click", () => show(current + 1));
document.addEventListener("keydown", (e) => {
  if (e.key === "ArrowLeft" || e.key === "PageUp") show(current - 1);
  if (e.key === "ArrowRight" || e.key === "PageDown" || e.key === " ") show(current + 1);
  if (e.key === "Home") show(1);
  if (e.key === "End") show(total);
  if (e.key === "f") document.documentElement.requestFullscreen();
});

// サムネ一覧
const thumbs = document.querySelector("[data-thumbs]");
slides.forEach((s, i) => {
  const img = s.querySelector("img").cloneNode(true);
  img.addEventListener("click", () => { show(i + 1); thumbs.hidden = true; });
  thumbs.appendChild(img);
});

document.querySelector("[data-thumb]").addEventListener("click", () => {
  thumbs.hidden = !thumbs.hidden;
});

document.querySelector("[data-fullscreen]").addEventListener("click", () => {
  document.documentElement.requestFullscreen();
});

// URL #で初期スライド指定
const initial = parseInt(location.hash.slice(1)) || 1;
show(initial);
```

## キーボードショートカット

- `←` / `PageUp`: 前のスライド
- `→` / `PageDown` / `Space`: 次のスライド
- `Home`: 最初へ
- `End`: 最後へ
- `f`: 全画面トグル

## PDF エクスポート

ブラウザの印刷ダイアログ（Cmd+P）→ 「PDFとして保存」 → 1スライド1ページで出力可能（margin 0、用紙サイズ A4横）

完璧な PDF 出力にしたい場合は、Playwright MCP に PDF 生成を委譲する選択肢もあり。
