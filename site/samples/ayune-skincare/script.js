document.addEventListener("DOMContentLoaded", () => {
  const form = document.querySelector("#sample-form form");

  form?.addEventListener("submit", (event) => {
    event.preventDefault();
    alert("ご請求ありがとうございます（デモ）");
    form.reset();
  });
});
