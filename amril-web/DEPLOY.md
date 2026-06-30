
# DEPLOY — Amril (Cloudflare Pages, one project: "amril")

You keep using **wrangler**, like you do today. The only change: the folder you
deploy is now `amril-web` (landing + legal at root) with the Flutter app inside
it at `amril-web\app`.

Put the folder here once:
  C:\Users\HP\PersonalProjects\amril-app\amril-web
This folder IS your deploy directory now (it replaces deploying build\web).

================================================================================
A. UPDATE THE APP  (run from C:\Users\HP\PersonalProjects\amril-app)
================================================================================
  flutter build web --release --base-href /app/
  Remove-Item -Recurse -Force amril-web\app -ErrorAction SilentlyContinue
  New-Item -ItemType Directory -Force amril-web\app | Out-Null
  Copy-Item -Recurse -Force build\web\* amril-web\app
  Copy-Item -Recurse -Force web\.well-known amril-web\.well-known
  wrangler pages deploy amril-web --project-name amril

  • "build\web\*" = copy the CONTENTS of build\web INTO amril-web\app.
    Result: amril-web\app\index.html, amril-web\app\main.dart.js, ...
  • --base-href /app/ is required so the app's assets resolve under /app/.

================================================================================
B. UPDATE ONLY LANDING / LEGAL  (no Flutter rebuild needed)
================================================================================
  wrangler pages deploy amril-web --project-name amril

================================================================================
MANUAL vs AUTOMATIC
================================================================================
  • wrangler (above) = MANUAL: run the deploy line each time (one command).
  • GitHub = AUTOMATIC: `git push` auto-deploys, BUT you must commit the built
    amril-web\app output (Pages can't run flutter build), and you'd create a new
    Pages project + move the amril.app domain to it. More setup; not recommended
    unless you really want push-to-deploy.

================================================================================
NOT READY TO MOVE THE APP TO /app YET?  (ship legal only, zero risk)
================================================================================
Keep the app at root as it is now, and just publish the legal pages:
  Copy-Item -Recurse -Force amril-web\legal build\web\legal
  Copy-Item -Recurse -Force web\.well-known build\web\.well-known
  wrangler pages deploy build\web --project-name amril
→ amril.app/legal/privacy (etc.) go live; the app stays untouched at root.
Do the full landing + /app split later in the web-routing pass.
