-- ============================================================
-- practice-portal seed.sql
-- 初回 admin 用招待コード
-- schema.sql 実行後に Supabase SQL Editor で実行してください
-- ============================================================

-- 初回 admin 用招待コード（role_to_grant = 'admin'）
-- コードは運用前に変更してください
INSERT INTO invite_codes (code, role_to_grant, max_uses)
VALUES ('ADMIN-INIT-2024', 'admin', 1);

-- 一般メンバー用招待コード（サンプル）
INSERT INTO invite_codes (code, role_to_grant, max_uses)
VALUES
  ('MEMBER-INVITE-001', 'member', 5),
  ('MEMBER-INVITE-002', 'member', 5);
