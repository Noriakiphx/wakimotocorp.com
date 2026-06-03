# 脇本商会 — 静的サイト デプロイ一式

WordPress を外して GitHub + Netlify で運用するための、デプロイ可能な雛形です。

## 含まれるもの
- `index.html` / `thanks.html`（送信完了）/ `404.html`
- `netlify.toml`（ビルド不要・セキュリティヘッダ）
- `_redirects`（旧→新URLの301。**要編集**）
- `robots.txt` / `images/`（ロゴ配置先）

## 自動化済み / 手動が必要な箇所
- ✅ **デプロイ一式（このフォルダ）= ドラッグ&ドロップで即公開できる状態**
- 🟡 ① GitHub への push（生成環境が外部ネット遮断のため、ここだけ手動）
- 🟡 ② DNS 切替（レジストラ操作＋稼働中メール保護のため手動。値は下記C）

---

## A. 最速で公開（Git不要・Netlify Drop）
1. https://app.netlify.com/drop を開く
2. `wakimotocorp-site.zip`（またはフォルダ）をブラウザにドラッグ&ドロップ
3. 数十秒で `https://<ランダム>.netlify.app` が公開 → 動作確認

## B. 推奨運用（GitHub + 自動デプロイ）
```bash
cd wakimotocorp-site
git init && git add -A && git commit -m "init: static site"
git branch -M main
git remote add origin https://github.com/<あなた>/wakimotocorp-site.git
git push -u origin main
```
Netlify → Add new site → Import from Git → リポジトリ選択 → **Build command 空 / Publish ディレクトリ `.`** → Deploy。
以後 `main` への push で自動再デプロイ。

## C. 独自ドメイン（wakimotocorp.com）
**メール（info@wakimotocorp.com）を守るため、DNSはレジストラに残し A/CNAME だけ向けます。**
レジストラ（お名前.com 等）の設定:
- A レコード: `@`（wakimotocorp.com） → `75.2.60.5`（Netlifyロードバランサ。**実値はNetlifyのドメイン設定に表示されるものを正とする**）
- CNAME: `www` → `<あなたのサイト>.netlify.app`
- **MX / SPF / TXT（メール系）は変更せず温存**

Netlify 側で primary domain を設定 → SSL（Let's Encrypt）自動発行 → **"Force HTTPS" を ON**。

## D. 本番切替の順番（重要）
1. レジストラで該当レコードの TTL を 300秒 に下げる
2. netlify.app で全ページを最終確認
3. A / CNAME を Netlify の値に変更
4. 反映と伝播を確認するまで **WordPress は止めない**（フォールバック）
5. 問題なければ WordPress を解約

## E. 公開後のTODO
- `_redirects` を Search Console の全URLで完成させる（SEO維持の肝）
- `sitemap.xml` を生成し `robots.txt` のパスに配置
- `images/` にロゴ（`logo.png` / `og.png`）を配置
- 会社概要の住所など本文を実情報に更新
- Netlify 管理画面 → Forms で受信確認＋通知メール設定
