// ============================================================
// nav.js — 共通ナビゲーション / モバイルメニュー
// ============================================================

const Nav = (() => {
  // 現在のページに合わせてアクティブリンクをマーク
  function setActiveLink() {
    const path = window.location.pathname.split('/').pop() || 'index.html';
    document.querySelectorAll('.nav-links a, .nav-mobile-menu a').forEach(a => {
      const href = a.getAttribute('href')?.split('/').pop();
      if (href === path) a.classList.add('active');
    });
  }

  // ハンバーガーメニュー制御
  function initToggle() {
    const toggle = document.getElementById('nav-toggle');
    const menu = document.getElementById('nav-mobile-menu');
    if (!toggle || !menu) return;

    toggle.addEventListener('click', () => {
      menu.classList.toggle('open');
    });

    // メニュー外クリックで閉じる
    document.addEventListener('click', e => {
      if (!toggle.contains(e.target) && !menu.contains(e.target)) {
        menu.classList.remove('open');
      }
    });
  }

  // ユーザー名をナビに表示
  function setUserName(name) {
    document.querySelectorAll('.nav-user-name').forEach(el => {
      el.textContent = name;
    });
  }

  // ログアウトボタンにイベント登録
  function initLogout() {
    document.querySelectorAll('.nav-logout-btn').forEach(btn => {
      btn.addEventListener('click', () => Auth.signOut());
    });
  }

  // ナビ全体初期化
  async function init() {
    setActiveLink();
    initToggle();
    initLogout();
  }

  return { init, setUserName };
})();
