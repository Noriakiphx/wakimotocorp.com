# WAKIMOTO CORP Static Site

WAKIMOTO CORP公式WebサイトのNetlify公開用静的サイトです。ビルド工程は不要で、`wakimotocorp-site` ディレクトリを公開ディレクトリとして配信します。

## Files

- `index.html`: 企業サイト本体、Netlify Forms対応のお問い合わせフォーム
- `thanks.html`: フォーム送信完了ページ
- `404.html`: カスタム404ページ
- `privacy.html`: プライバシーポリシー
- `robots.txt`: クロール設定とsitemap参照
- `sitemap.xml`: 公開URL一覧
- `_redirects`: 旧WordPress URLから現行静的サイトへの301リダイレクト
- `netlify.toml`: publish設定とセキュリティヘッダ

## Netlify

Netlifyのサイト設定では以下を指定します。

- Base directory: `wakimotocorp-site`
- Build command: 空
- Publish directory: `.`

お問い合わせフォームは `index.html` の `name="contact"` フォームで `data-netlify="true"` を指定しています。Netlifyへのデプロイ後、管理画面の Forms で受信を確認できます。

## Domain

本番URLは `https://wakimotocorp.com/` を前提に、canonical、robots.txt、sitemap.xml、OGP URLを設定しています。

## Site Facts

- 会社サイト上の主表記: `WAKIMOTO CORP`
- 併記: `脇本商会 / SoundAssist`
- 所在地: `〒367-0041 埼玉県本庄市駅南2-1-25 ふらわあビル3-A`
- 電話番号: `0495-37-4806`
- メール: `info@wakimotocorp.com`
- ブランド表記: `DAS Audio 日本総代理店`
