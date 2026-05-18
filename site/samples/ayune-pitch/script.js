(() => {
  const slides = [
    { src: "./assets/01-cover.png",        alt: "表紙: 30代からの肌、立て直す。AYUNE 販売店様向けご提案資料 2026", title: "01 表紙" },
    { src: "./assets/02-brand-story.png",  alt: "ブランドストーリー: ゆらぐ肌に、確かな朝を。AYUNE が生まれた理由",  title: "02 ブランドストーリー" },
    { src: "./assets/03-product.png",      alt: "商品ラインナップ: リニューイング セラム 30mL、希望小売価格4,800円",  title: "03 商品概要" },
    { src: "./assets/04-formula.png",      alt: "3-IN-1 APPROACH + 7つの無添加",                                  title: "04 処方・成分" },
    { src: "./assets/05-target-market.png",alt: "ターゲット顧客と市場機会: 国内エイジングケア美容液 6,300億円市場",   title: "05 顧客・市場" },
    { src: "./assets/06-track-record.png", alt: "実績: 累計15万本、満足度97%、★4.8、@cosme美容液1位",              title: "06 実績" },
    { src: "./assets/07-competitive.png",  alt: "ポジショニング: 価格帯×成分志向マップ",                           title: "07 ポジショニング" },
    { src: "./assets/08-trade-terms.png",  alt: "お取引条件: 卸掛率60%、MOQ30本、リードタイム7営業日",              title: "08 取引条件" },
    { src: "./assets/09-sales-support.png",alt: "販促支援: 什器・POP、サンプリング、接客研修、広告連動",            title: "09 販促支援" },
    { src: "./assets/10-next-steps.png",   alt: "次のステップ: 商談→条件確定→ローンチ。最短6週間で店頭導入",         title: "10 次のステップ" }
  ];

  const $img = document.getElementById("slide-img");
  const $curr = document.getElementById("counter-current");
  const $total = document.getElementById("counter-total");
  const $prev = document.getElementById("prev");
  const $next = document.getElementById("next");
  const $grid = document.getElementById("grid");

  $total.textContent = slides.length;

  let index = 0;
  const render = () => {
    const s = slides[index];
    $img.src = s.src;
    $img.alt = s.alt;
    $curr.textContent = index + 1;
  };

  const go = (delta) => {
    index = (index + delta + slides.length) % slides.length;
    render();
  };

  const jump = (n) => {
    if (n >= 0 && n < slides.length) { index = n; render(); }
  };

  $prev.addEventListener("click", () => go(-1));
  $next.addEventListener("click", () => go(1));

  document.addEventListener("keydown", (e) => {
    if (e.key === "ArrowRight" || e.key === " " || e.key === "PageDown") { e.preventDefault(); go(1); }
    else if (e.key === "ArrowLeft" || e.key === "PageUp") { e.preventDefault(); go(-1); }
    else if (e.key === "Home") { e.preventDefault(); jump(0); }
    else if (e.key === "End") { e.preventDefault(); jump(slides.length - 1); }
    else if (e.key === "g" || e.key === "G") { toggleGrid(); }
    else if (e.key === "f" || e.key === "F") { toggleFullscreen(); }
    else if (e.key === "p" || e.key === "P") { window.print(); }
    else if (/^[1-9]$/.test(e.key)) { jump(parseInt(e.key, 10) - 1); }
    else if (e.key === "0") { jump(9); }
    else if (e.key === "Escape" && !$grid.hidden) { toggleGrid(); }
  });

  document.getElementById("stage").addEventListener("click", () => go(1));

  let touchStartX = 0;
  document.addEventListener("touchstart", (e) => { touchStartX = e.touches[0].clientX; }, { passive: true });
  document.addEventListener("touchend", (e) => {
    const dx = e.changedTouches[0].clientX - touchStartX;
    if (Math.abs(dx) > 60) go(dx < 0 ? 1 : -1);
  }, { passive: true });

  const toggleFullscreen = () => {
    if (!document.fullscreenElement) document.documentElement.requestFullscreen();
    else document.exitFullscreen();
  };

  const buildGrid = () => {
    $grid.innerHTML = slides.map((s, i) => `
      <figure data-i="${i}">
        <img src="${s.src}" alt="${s.alt}">
        <figcaption>${s.title}</figcaption>
      </figure>
    `).join("");
    $grid.querySelectorAll("figure").forEach((el) => {
      el.addEventListener("click", () => {
        jump(parseInt(el.dataset.i, 10));
        toggleGrid();
      });
    });
  };

  const toggleGrid = () => {
    if ($grid.hidden) { buildGrid(); $grid.hidden = false; }
    else $grid.hidden = true;
  };

  render();
})();
