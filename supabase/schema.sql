-- ============================================================
-- practice-portal schema.sql
-- Supabase SQL Editor で実行してください
-- ============================================================

-- ============================================================
-- 1. プロフィール
-- ============================================================
CREATE TABLE profiles (
  id           UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT NOT NULL DEFAULT '',
  role         TEXT NOT NULL DEFAULT 'member'
                 CHECK (role IN ('member', 'admin')),
  avatar       JSONB,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- 2. EXP / レベル
-- ============================================================
CREATE TABLE user_stats (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  total_exp  INTEGER NOT NULL DEFAULT 0,
  level      INTEGER NOT NULL DEFAULT 1,
  badges     JSONB NOT NULL DEFAULT '[0,0,0,0,0]',
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id)
);

-- ============================================================
-- 3. EXP 付与ログ（二重付与防止）
-- ============================================================
CREATE TABLE exp_transactions (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  source_type TEXT NOT NULL CHECK (source_type IN ('task_approval', 'quiz_complete', 'manual')),
  source_id   UUID NOT NULL,
  exp_amount  INTEGER NOT NULL,
  note        TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, source_type, source_id)
);

-- ============================================================
-- 4. 招待コード
-- ============================================================
CREATE TABLE invite_codes (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code         TEXT NOT NULL UNIQUE,
  role_to_grant TEXT NOT NULL DEFAULT 'member' CHECK (role_to_grant IN ('member', 'admin')),
  max_uses     INTEGER NOT NULL DEFAULT 1,
  used_count   INTEGER NOT NULL DEFAULT 0,
  expires_at   TIMESTAMPTZ,
  created_by   UUID REFERENCES profiles(id),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- 5. 招待コード使用履歴
-- ============================================================
CREATE TABLE invite_code_redemptions (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invite_code_id UUID NOT NULL REFERENCES invite_codes(id) ON DELETE CASCADE,
  user_id        UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  redeemed_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (invite_code_id, user_id),
  UNIQUE (user_id)
);

-- ============================================================
-- 6. タスクマスタ
-- ============================================================
CREATE TABLE tasks (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title        TEXT NOT NULL,
  clear_exp    INTEGER NOT NULL DEFAULT 0,
  deadline_bonus INTEGER NOT NULL DEFAULT 0,
  repeat_type  TEXT NOT NULL DEFAULT 'none'
                 CHECK (repeat_type IN ('none', 'daily', 'weekly', 'custom')),
  repeat_count INTEGER,
  repeat_exp   INTEGER NOT NULL DEFAULT 0,
  is_active    BOOLEAN NOT NULL DEFAULT true,
  created_by   UUID REFERENCES profiles(id),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- 7. サブタスク
-- ============================================================
CREATE TABLE subtasks (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id    UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  title      TEXT NOT NULL,
  exp        INTEGER NOT NULL DEFAULT 0,
  sort_order INTEGER NOT NULL DEFAULT 0
);

-- ============================================================
-- 8. 条件項目
-- ============================================================
CREATE TABLE conditions (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subtask_id UUID NOT NULL REFERENCES subtasks(id) ON DELETE CASCADE,
  text       TEXT NOT NULL,
  exp        INTEGER NOT NULL DEFAULT 0,
  sort_order INTEGER NOT NULL DEFAULT 0
);

-- ============================================================
-- 9. ユーザーごとのタスク進捗
-- ============================================================
CREATE TABLE user_task_progress (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  task_id          UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  status           TEXT NOT NULL DEFAULT 'not_started'
                     CHECK (status IN ('not_started', 'in_progress', 'requested', 'approved')),
  deadline         DATE,
  completed_count  INTEGER NOT NULL DEFAULT 0,
  approved_at      TIMESTAMPTZ,
  approved_by      UUID REFERENCES profiles(id),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, task_id)
);

-- ============================================================
-- 10. ユーザーごとの条件進捗
-- ============================================================
CREATE TABLE user_condition_progress (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  condition_id    UUID NOT NULL REFERENCES conditions(id) ON DELETE CASCADE,
  completed       BOOLEAN NOT NULL DEFAULT false,
  approval_status TEXT NOT NULL DEFAULT 'none'
                    CHECK (approval_status IN ('none', 'requested', 'approved')),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, condition_id)
);

-- ============================================================
-- 11. クイズ問題セット
-- ============================================================
CREATE TABLE quiz_problems (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title       TEXT NOT NULL,
  description TEXT,
  level       TEXT NOT NULL CHECK (level IN ('beginner', 'intermediate', 'advanced')),
  is_active   BOOLEAN NOT NULL DEFAULT true,
  created_by  UUID REFERENCES profiles(id),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- 12. クイズ質問
-- ============================================================
CREATE TABLE quiz_questions (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  problem_id     UUID NOT NULL REFERENCES quiz_problems(id) ON DELETE CASCADE,
  question_text  TEXT NOT NULL,
  options        JSONB NOT NULL DEFAULT '[]',
  correct_answer INTEGER NOT NULL,
  explanation    TEXT,
  points         INTEGER NOT NULL DEFAULT 10,
  sort_order     INTEGER NOT NULL DEFAULT 0
);

-- ============================================================
-- 13. クイズ進捗（忘却曲線対応）
-- ============================================================
CREATE TABLE user_quiz_progress (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id        UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  problem_id     UUID NOT NULL REFERENCES quiz_problems(id) ON DELETE CASCADE,
  score          INTEGER,
  best_score     INTEGER,
  completed      BOOLEAN NOT NULL DEFAULT false,
  completed_at   TIMESTAMPTZ,
  attempt_count  INTEGER NOT NULL DEFAULT 0,
  next_review_at TIMESTAMPTZ,
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, problem_id)
);

-- ============================================================
-- 14. マインドマップ
-- ============================================================
CREATE TABLE mindmaps (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title       TEXT NOT NULL DEFAULT '新規マインドマップ',
  description TEXT,
  user_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- 15. ノード
-- ============================================================
CREATE TABLE mindmap_nodes (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  mindmap_id  UUID NOT NULL REFERENCES mindmaps(id) ON DELETE CASCADE,
  title       TEXT NOT NULL DEFAULT '',
  comment     TEXT,
  position_x  NUMERIC NOT NULL DEFAULT 100,
  position_y  NUMERIC NOT NULL DEFAULT 100,
  width       NUMERIC,
  height      NUMERIC,
  is_central  BOOLEAN NOT NULL DEFAULT false,
  parent_id   UUID REFERENCES mindmap_nodes(id) ON DELETE SET NULL,
  image_url   TEXT,
  sort_order  INTEGER NOT NULL DEFAULT 0,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- 16. updated_at 自動更新トリガー関数
-- ============================================================
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_user_stats_updated_at
  BEFORE UPDATE ON user_stats
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_tasks_updated_at
  BEFORE UPDATE ON tasks
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_user_task_progress_updated_at
  BEFORE UPDATE ON user_task_progress
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_user_condition_progress_updated_at
  BEFORE UPDATE ON user_condition_progress
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_user_quiz_progress_updated_at
  BEFORE UPDATE ON user_quiz_progress
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_mindmaps_updated_at
  BEFORE UPDATE ON mindmaps
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_mindmap_nodes_updated_at
  BEFORE UPDATE ON mindmap_nodes
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================
-- 17. レベル計算関数
-- ============================================================
CREATE OR REPLACE FUNCTION calculate_level(total_exp INTEGER)
RETURNS INTEGER AS $$
BEGIN
  -- レベル計算式: Lv N に必要な累計 EXP = N * (N-1) / 2 * 100
  -- Lv1=0, Lv2=100, Lv3=300, Lv4=600, Lv5=1000 ...
  RETURN GREATEST(1, FLOOR((1 + SQRT(1 + 8.0 * total_exp / 100)) / 2)::INTEGER);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION recalculate_user_level(target_user_id UUID)
RETURNS VOID AS $$
DECLARE
  v_total_exp INTEGER;
  v_new_level INTEGER;
BEGIN
  SELECT total_exp INTO v_total_exp FROM user_stats WHERE user_id = target_user_id;
  v_new_level := calculate_level(v_total_exp);
  UPDATE user_stats SET level = v_new_level WHERE user_id = target_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 18. bootstrap_user 関数
-- ============================================================
CREATE OR REPLACE FUNCTION bootstrap_user(
  p_invite_code  TEXT,
  p_display_name TEXT
)
RETURNS JSONB AS $$
DECLARE
  v_code_row   invite_codes%ROWTYPE;
  v_user_id    UUID := auth.uid();
BEGIN
  -- 未ログインチェック
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', '認証が必要です');
  END IF;

  -- すでに bootstrap 済みチェック
  IF EXISTS (SELECT 1 FROM profiles WHERE id = v_user_id) THEN
    RETURN jsonb_build_object('success', false, 'error', 'すでに登録済みです');
  END IF;

  -- 招待コード検証
  SELECT * INTO v_code_row FROM invite_codes WHERE code = p_invite_code;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', '招待コードが無効です');
  END IF;

  IF v_code_row.expires_at IS NOT NULL AND v_code_row.expires_at < now() THEN
    RETURN jsonb_build_object('success', false, 'error', '招待コードの有効期限が切れています');
  END IF;

  IF v_code_row.used_count >= v_code_row.max_uses THEN
    RETURN jsonb_build_object('success', false, 'error', '招待コードの使用回数上限に達しています');
  END IF;

  -- profiles 作成
  INSERT INTO profiles (id, display_name, role)
  VALUES (v_user_id, p_display_name, v_code_row.role_to_grant);

  -- user_stats 作成
  INSERT INTO user_stats (user_id) VALUES (v_user_id);

  -- 使用履歴記録
  INSERT INTO invite_code_redemptions (invite_code_id, user_id)
  VALUES (v_code_row.id, v_user_id);

  -- 使用カウント加算
  UPDATE invite_codes SET used_count = used_count + 1 WHERE id = v_code_row.id;

  RETURN jsonb_build_object('success', true, 'role', v_code_row.role_to_grant);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 19. approve_task 関数（EXP二重付与防止）
-- ============================================================
CREATE OR REPLACE FUNCTION approve_task(p_progress_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_approver_id    UUID := auth.uid();
  v_approver_role  TEXT;
  v_progress       user_task_progress%ROWTYPE;
  v_task           tasks%ROWTYPE;
  v_exp_amount     INTEGER;
BEGIN
  -- admin チェック
  SELECT role INTO v_approver_role FROM profiles WHERE id = v_approver_id;
  IF v_approver_role != 'admin' THEN
    RETURN jsonb_build_object('success', false, 'error', '管理者権限が必要です');
  END IF;

  -- 進捗取得
  SELECT * INTO v_progress FROM user_task_progress WHERE id = p_progress_id;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', '進捗が見つかりません');
  END IF;

  IF v_progress.status != 'requested' THEN
    RETURN jsonb_build_object('success', false, 'error', '承認申請中のタスクのみ承認できます');
  END IF;

  -- タスク取得（EXP計算）
  SELECT * INTO v_task FROM tasks WHERE id = v_progress.task_id;
  v_exp_amount := v_task.clear_exp;

  -- 期限内ボーナス
  IF v_progress.deadline IS NOT NULL AND v_progress.deadline >= CURRENT_DATE THEN
    v_exp_amount := v_exp_amount + v_task.deadline_bonus;
  END IF;

  -- 進捗を approved に更新
  UPDATE user_task_progress
  SET status = 'approved', approved_at = now(), approved_by = v_approver_id
  WHERE id = p_progress_id;

  -- EXP トランザクション記録（UNIQUE制約で二重防止）
  BEGIN
    INSERT INTO exp_transactions (user_id, source_type, source_id, exp_amount, note)
    VALUES (v_progress.user_id, 'task_approval', p_progress_id, v_exp_amount, v_task.title);
  EXCEPTION WHEN unique_violation THEN
    RETURN jsonb_build_object('success', false, 'error', 'EXPは既に付与されています');
  END;

  -- EXP 加算
  UPDATE user_stats
  SET total_exp = total_exp + v_exp_amount
  WHERE user_id = v_progress.user_id;

  -- レベル再計算
  PERFORM recalculate_user_level(v_progress.user_id);

  RETURN jsonb_build_object('success', true, 'exp_granted', v_exp_amount);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 20. Row Level Security
-- ============================================================
ALTER TABLE profiles                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_stats                ENABLE ROW LEVEL SECURITY;
ALTER TABLE exp_transactions          ENABLE ROW LEVEL SECURITY;
ALTER TABLE invite_codes              ENABLE ROW LEVEL SECURITY;
ALTER TABLE invite_code_redemptions   ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks                     ENABLE ROW LEVEL SECURITY;
ALTER TABLE subtasks                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE conditions                ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_task_progress        ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_condition_progress   ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_problems             ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_questions            ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_quiz_progress        ENABLE ROW LEVEL SECURITY;
ALTER TABLE mindmaps                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE mindmap_nodes             ENABLE ROW LEVEL SECURITY;

-- profiles
CREATE POLICY "profiles_select_all"    ON profiles FOR SELECT USING (true);
CREATE POLICY "profiles_update_self"   ON profiles FOR UPDATE USING (auth.uid() = id);

-- user_stats
CREATE POLICY "user_stats_select_self" ON user_stats FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "user_stats_select_admin" ON user_stats FOR SELECT
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

-- exp_transactions
CREATE POLICY "exp_tx_select_self"  ON exp_transactions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "exp_tx_select_admin" ON exp_transactions FOR SELECT
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

-- invite_codes（admin のみ）
CREATE POLICY "invite_codes_admin" ON invite_codes FOR ALL
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

-- invite_code_redemptions
CREATE POLICY "icr_select_self" ON invite_code_redemptions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "icr_select_admin" ON invite_code_redemptions FOR SELECT
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

-- tasks（全ユーザー読み取り可、管理者のみ書き込み）
CREATE POLICY "tasks_select_auth" ON tasks FOR SELECT
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid()));
CREATE POLICY "tasks_write_admin" ON tasks FOR ALL
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

-- subtasks / conditions（tasks と同様）
CREATE POLICY "subtasks_select_auth" ON subtasks FOR SELECT
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid()));
CREATE POLICY "subtasks_write_admin" ON subtasks FOR ALL
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

CREATE POLICY "conditions_select_auth" ON conditions FOR SELECT
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid()));
CREATE POLICY "conditions_write_admin" ON conditions FOR ALL
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

-- user_task_progress
CREATE POLICY "utp_self" ON user_task_progress FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "utp_admin_select" ON user_task_progress FOR SELECT
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));
CREATE POLICY "utp_admin_update" ON user_task_progress FOR UPDATE
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

-- user_condition_progress
CREATE POLICY "ucp_self" ON user_condition_progress FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "ucp_admin_select" ON user_condition_progress FOR SELECT
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

-- quiz_problems / quiz_questions
CREATE POLICY "qp_select_auth" ON quiz_problems FOR SELECT
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid()));
CREATE POLICY "qp_write_admin" ON quiz_problems FOR ALL
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

CREATE POLICY "qq_select_auth" ON quiz_questions FOR SELECT
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid()));
CREATE POLICY "qq_write_admin" ON quiz_questions FOR ALL
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

-- user_quiz_progress
CREATE POLICY "uqp_self" ON user_quiz_progress FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "uqp_admin_select" ON user_quiz_progress FOR SELECT
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

-- mindmaps / mindmap_nodes（所有者のみ）
CREATE POLICY "mindmaps_owner" ON mindmaps FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "mindmap_nodes_owner" ON mindmap_nodes FOR ALL
  USING (EXISTS (SELECT 1 FROM mindmaps WHERE id = mindmap_id AND user_id = auth.uid()));
