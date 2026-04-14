# Supabase セットアップ手順

## 1. Supabase プロジェクト作成

1. [supabase.com](https://supabase.com) でアカウント作成
2. 「New project」でプロジェクト作成
3. Project URL と Anon Key をメモ

## 2. 接続情報を設定

```bash
cp assets/js/supabase-init.example.js assets/js/supabase-init.js
```

`supabase-init.js` を開いて、メモした URL と Anon Key を入力:

```javascript
window.SUPABASE_URL = 'https://YOUR_PROJECT.supabase.co';
window.SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY';
```

## 3. スキーマ適用

Supabase ダッシュボード → SQL Editor で以下の順に実行:

1. `supabase/schema.sql`（テーブル・関数・RLS）
2. `supabase/seed.sql`（初期招待コード）
3. `supabase/import.sql`（タスク・クイズ初期データ）

## 4. 認証設定

Supabase ダッシュボード → Authentication → Settings:

- **Email confirmation**: 有効化
- **Redirect URLs**: `http://localhost:5500` を追加（本番は本番 URL も追加）

## 5. ローカル開発

VSCode の Live Server 拡張機能等でポート 5500 で起動:

```
http://localhost:5500
```

## 6. 初回 admin 作成

1. ブラウザで `http://localhost:5500` にアクセス
2. メールアドレスを入力して Magic Link を送信
3. メール内のリンクをクリック
4. 初回セットアップ画面で招待コード `ADMIN-INIT-2024` と表示名を入力
5. ダッシュボードへ遷移すれば完了

> **注意**: `ADMIN-INIT-2024` は `seed.sql` に記載の初期コードです。使用後は `invite_codes` テーブルで確認してください。
