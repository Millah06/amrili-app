# amril-web — the Amril public site (landing + legal)

This folder is a **static website**. It is served by **Cloudflare Pages** at
`amril.app`. Nothing here runs on your Node backend.

```
amril-web/
├── index.html          landing page          → amril.app/
├── get.html            smart store redirect   → amril.app/get  (the QR target)
├── 404.html            not-found page
├── favicon.svg
├── robots.txt
├── sitemap.xml
├── _redirects          routing (SPA + deep links)
├── landing.css
├── landing.js          ← put your real store URLs here (3 lines, marked)
├── assets/
│   ├── amril_lockup.svg
│   └── qr_get.svg      QR encoding https://amril.app/get
└── legal/
    ├── legal.css
    ├── privacy.html · terms.html · cookies.html
    ├── acceptable-use.html · coins.html · vendor-agreement.html
```

## 1. Before it goes live — replace 3 placeholders

Open **landing.js** and **get.html** and set the same three values in both:

```
play:  'https://play.google.com/store/apps/details?id=YOUR.APP.ID'
apple: 'https://apps.apple.com/app/amril/idYOURID'
web:   '/app'   ← leave as-is
```

Until you do, the store buttons and the QR safely fall back to the web app, so
nothing is broken if you ship early.

## 2. Deploy to Cloudflare Pages

Two ways:

**A. Connect a Git repo (recommended)**
1. Put this `amril-web/` folder in a Git repo (its own repo, or a subfolder).
2. Cloudflare dashboard → **Workers & Pages → Create → Pages → Connect to Git**.
3. Build settings: **Framework preset = None**, **Build command = (empty)**,
   **Build output directory = /** (or the path to this folder if it's a subfolder).
4. Deploy, then add the custom domain **amril.app** under the project's
   **Custom domains** tab.

**B. Direct upload**
   Workers & Pages → Create → Pages → **Upload assets** → drag this folder in.

Clean URLs work automatically: `/legal/privacy` serves `legal/privacy.html`,
`/get` serves `get.html`. No extra config.

## 3. The Flutter web app at /app  (deferred to the web-routing chat)

The "Use on web" button and deep links expect the Flutter SPA under `/app`:

```
flutter build web --base-href /app/
# then copy build/web/* into amril-web/app/
```

The `_redirects` file already routes `/app/*` and the social/commerce deep links
(`/store`, `/post`, `/u`, …) to the SPA. Finishing the deep-link Open-Graph tags
and the base-href details is the separate web-routing pass we deferred — the
landing and legal pages here are fully live without it.

## 4. After you swap the icon master to a real logo (optional)

`favicon.svg` is the rounded Amril mark. `assets/amril_lockup.svg` is the
horizontal logo used in the nav and footer. Swap both if your final designer
mark differs.
