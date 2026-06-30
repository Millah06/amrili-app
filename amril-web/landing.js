/* ============================================================================
   Amril landing — behaviour
   • Detects the visitor's device and shows the right download options
   • Mobile nav, scroll-reveal, current year
   ========================================================================== */

/* ┌─────────────────────────────────────────────────────────────────────────┐
   │  REPLACE THESE THREE when the apps are live. They're the ONLY values to  │
   │  change here. Until then they point to safe fallbacks.                   │
   └─────────────────────────────────────────────────────────────────────────┘ */
const STORE = {
  // Google Play — replace with your real listing URL, e.g.
  //   https://play.google.com/store/apps/details?id=com.amrili.amril
  play:  'PLAY_STORE_URL_PLACEHOLDER',
  // Apple App Store — replace with your real listing URL, e.g.
  //   https://apps.apple.com/app/amril/id000000000
  apple: 'APP_STORE_URL_PLACEHOLDER',
  // The web app (Flutter) entry. Lives at /app once the SPA is deployed there.
  web:   '/app/',
};

/* ── Device detection ─────────────────────────────────────────────────────── */
function detectOS() {
  const ua = navigator.userAgent || '';
  if (/android/i.test(ua)) return 'android';
  // iPadOS 13+ reports as Mac; the touch check catches it.
  if (/iPad|iPhone|iPod/.test(ua) || (/Macintosh/.test(ua) && navigator.maxTouchPoints > 1)) return 'ios';
  return 'desktop';
}

function applyPlatform() {
  const os = detectOS();
  document.body.classList.add('is-' + os);

  // Point every store badge at its real URL.
  document.querySelectorAll('.store[data-store]').forEach((el) => {
    const url = STORE[el.dataset.store];
    if (url && !url.includes('PLACEHOLDER')) {
      el.setAttribute('href', url);
    } else {
      // Placeholder still in place: keep it from navigating nowhere.
      el.setAttribute('href', STORE.web);
      el.setAttribute('title', 'Store link coming soon — replace the placeholder in landing.js');
    }
  });

  // Tailor the supporting copy per device.
  const note = document.getElementById('cta-note');
  const dlSub = document.getElementById('dl-sub');
  if (os === 'android' && note) note.textContent = '// free on Google Play — or use the web app';
  if (os === 'ios' && note)     note.textContent = '// free on the App Store — or use the web app';
  if (os === 'desktop') {
    if (note) note.textContent = '// scan the code below to install on your phone';
    if (dlSub) dlSub.textContent = 'Scan the QR with your phone to install, or use Amril right here in your browser.';
  }
}

/* ── Mobile nav ───────────────────────────────────────────────────────────── */
function initNav() {
  const toggle = document.getElementById('navToggle');
  const sheet = document.getElementById('navSheet');
  if (!toggle || !sheet) return;
  const close = () => { sheet.classList.remove('open'); toggle.setAttribute('aria-expanded', 'false'); };
  toggle.addEventListener('click', () => {
    const open = sheet.classList.toggle('open');
    toggle.setAttribute('aria-expanded', String(open));
  });
  sheet.querySelectorAll('a').forEach((a) => a.addEventListener('click', close));
}

/* ── Scroll reveal ────────────────────────────────────────────────────────── */
function initReveal() {
  const items = document.querySelectorAll('.reveal');
  if (!('IntersectionObserver' in window) || window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
    items.forEach((el) => el.classList.add('in'));
    return;
  }
  const io = new IntersectionObserver((entries) => {
    entries.forEach((e) => {
      if (e.isIntersecting) { e.target.classList.add('in'); io.unobserve(e.target); }
    });
  }, { threshold: 0.14, rootMargin: '0px 0px -8% 0px' });
  items.forEach((el) => io.observe(el));
}

document.addEventListener('DOMContentLoaded', () => {
  applyPlatform();
  initNav();
  initReveal();
  const yr = document.getElementById('yr');
  if (yr) yr.textContent = new Date().getFullYear();
});
