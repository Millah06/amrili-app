// ─────────────────────────────────────────────────────────────────────────────
// _worker.js  — Cloudflare Pages advanced-mode worker (Phase 3, go-live build)
//
// Handles every request to amril.app:
//   • /.well-known/apple-app-site-association → real bytes, forced application/json
//   • /store/:id, /product/:id, /post/:id     → fetch /web/* and inject OG/SEO
//   • everything else                          → static asset, with an explicit
//                                                 SPA fallback so client routes
//                                                 (e.g. /u/:handle, /scan) resolve
//
// FAIL-OPEN everywhere: any error serves the plain SPA. A share preview must
// never block the page.
// ─────────────────────────────────────────────────────────────────────────────

// Backend origin serving the optional-auth /web/* reads.
// Until the api.amril.app cutover this is the Render URL. After cutover, flip to
// "https://api.amril.app" (keep in lockstep with ApiConstants.baseUrl).
const API_BASE = "https://api.amril.app";

const SITE = "https://amril.app";
const DEFAULT_OG_IMAGE = `${SITE}/icons/og-default.png`;

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const path = url.pathname;

    // 1) iOS Universal Links file: no extension -> Pages serves octet-stream.
    //    Apple requires application/json with no redirect. Serve real bytes,
    //    force the content-type.
    if (path === "/.well-known/apple-app-site-association") {
      const assetResp = await env.ASSETS.fetch(request);
      return new Response(assetResp.body, {
        status: assetResp.status,
        headers: {
          "content-type": "application/json",
          "cache-control": "public, max-age=3600",
        },
      });
    }

    // 2) Enrich the three shareable HTML routes with route-specific meta.
    const enrich = request.method === "GET" ? matchDeepLink(path) : null;
    if (enrich) {
      try {
        const apiResp = await fetch(`${API_BASE}${enrich.apiPath}`, {
          headers: { accept: "application/json" },
          cf: { cacheTtl: 60, cacheEverything: true },
        });
        if (apiResp.ok) {
          const data = await apiResp.json();
          const meta = enrich.buildMeta(data, url);
          if (meta) {
            const baseHtml = await loadIndex(env, url);
            return html(injectMeta(baseHtml, meta), 120);
          }
        }
      } catch (_) {
        // fall through to plain SPA
      }
      return spa(env, url);
    }

    // 3) Everything else: serve the real asset. If it's a navigation (a route
    //    with no matching file) and the asset server 404s, serve the SPA shell
    //    so GoRouter can take over client-side.
    const assetResp = await env.ASSETS.fetch(request);
    if (assetResp.status === 404 && isNavigation(request)) {
      return spa(env, url);
    }
    return assetResp;
  },
};

// -- SPA helpers --------------------------------------------------------------
function isNavigation(request) {
  const dest = request.headers.get("sec-fetch-dest");
  const accept = request.headers.get("accept") || "";
  return dest === "document" || accept.includes("text/html");
}

async function loadIndex(env, url) {
  const resp = await env.ASSETS.fetch(new URL("/index.html", url.origin));
  return resp.text();
}

async function spa(env, url) {
  const body = await loadIndex(env, url);
  return html(body, 0);
}

function html(body, maxAge) {
  return new Response(body, {
    status: 200,
    headers: {
      "content-type": "text/html; charset=UTF-8",
      "cache-control": maxAge > 0 ? `public, max-age=${maxAge}` : "no-store",
    },
  });
}

// -- Route matching (response shapes per BUILD_STATE.md) ----------------------
function matchDeepLink(path) {
  let m = path.match(/^\/store\/([^/]+)\/?$/); // not /store/:id/table/:tid
  if (m) {
    const id = decodeURIComponent(m[1]);
    return {
      apiPath: `/web/store/${encodeURIComponent(id)}`,
      buildMeta: (d, url) => {
        if (!d || !d.id) return null;
        return {
          title: `${d.name} on Amril`,
          description: clamp(d.description || `Order from ${d.name} on Amril.`, 200),
          image: d.coverPhoto || d.logo || DEFAULT_OG_IMAGE,
          canonical: url.href,
        };
      },
    };
  }

  m = path.match(/^\/product\/([^/]+)\/?$/);
  if (m) {
    const id = decodeURIComponent(m[1]);
    return {
      apiPath: `/web/product/${encodeURIComponent(id)}`,
      buildMeta: (d, url) => {
        if (!d || !d.id) return null;
        const price = typeof d.price === "number" ? ` \u2014 \u20a6${formatNaira(d.price)}` : "";
        return {
          title: `${d.name}${price} | ${d.vendorName || "Amril"}`,
          description: clamp(d.description || `${d.name} from ${d.vendorName || "a merchant"} on Amril.`, 200),
          image: (Array.isArray(d.images) && d.images[0]) || d.vendorLogo || DEFAULT_OG_IMAGE,
          canonical: url.href,
        };
      },
    };
  }

  m = path.match(/^\/post\/([^/]+)\/?$/);
  if (m) {
    const id = decodeURIComponent(m[1]);
    return {
      apiPath: `/web/post/${encodeURIComponent(id)}`,
      buildMeta: (d, url) => {
        const post = d && d.post ? d.post : null;
        if (!post || !post.postId) return null;
        return {
          title: `${post.userName || "Someone"} on Amril`,
          description: clamp(post.text || "View this post on Amril.", 200),
          image: (Array.isArray(post.images) && post.images[0]) || post.userAvatar || DEFAULT_OG_IMAGE,
          canonical: url.href,
        };
      },
    };
  }

  return null;
}

// -- head rewriting -----------------------------------------------------------
function injectMeta(htmlStr, meta) {
  let out = htmlStr
    .replace(/<title>[\s\S]*?<\/title>/i, "")
    .replace(/<meta\s+property="og:[^"]*"[^>]*>\s*/gi, "")
    .replace(/<meta\s+name="twitter:[^"]*"[^>]*>\s*/gi, "")
    .replace(/<meta\s+name="description"[^>]*>\s*/gi, "");

  const t = esc(meta.title);
  const d = esc(meta.description);
  const img = esc(meta.image);
  const canonical = esc(meta.canonical);

  const tags = `
    <title>${t}</title>
    <meta name="description" content="${d}">
    <link rel="canonical" href="${canonical}">
    <meta property="og:type" content="website">
    <meta property="og:site_name" content="Amril">
    <meta property="og:title" content="${t}">
    <meta property="og:description" content="${d}">
    <meta property="og:image" content="${img}">
    <meta property="og:url" content="${canonical}">
    <meta name="twitter:card" content="summary_large_image">
    <meta name="twitter:title" content="${t}">
    <meta name="twitter:description" content="${d}">
    <meta name="twitter:image" content="${img}">
  `;

  return out.replace(/<head([^>]*)>/i, `<head$1>${tags}`);
}

// -- helpers ------------------------------------------------------------------
function esc(s) {
  return String(s == null ? "" : s)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}
function clamp(s, n) {
  const str = String(s || "").replace(/\s+/g, " ").trim();
  return str.length > n ? `${str.slice(0, n - 1)}\u2026` : str;
}
function formatNaira(n) {
  try {
    return Number(n).toLocaleString("en-NG", { maximumFractionDigits: 2 });
  } catch (_) {
    return String(n);
  }
}