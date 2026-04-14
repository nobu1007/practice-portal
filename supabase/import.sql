-- ============================================================
-- practice-portal import.sql
-- タスク定義 / クイズ問題の初期データ投入
-- 実際のデータに書き換えてから実行してください
-- ============================================================

-- ============================================================
-- タスク定義サンプル
-- ============================================================
INSERT INTO tasks (title, clear_exp, deadline_bonus, repeat_type, repeat_exp)
VALUES
  ('三連梯子 基礎訓練', 100, 20, 'none', 0),
  ('ロープ結索 初級', 50, 10, 'weekly', 15),
  ('資機材点検', 30, 0, 'weekly', 10);

-- サブタスクサンプル（三連梯子）
WITH task_id AS (SELECT id FROM tasks WHERE title = '三連梯子 基礎訓練' LIMIT 1)
INSERT INTO subtasks (task_id, title, exp, sort_order)
VALUES
  ((SELECT id FROM task_id), '準備', 20, 1),
  ((SELECT id FROM task_id), '設置', 40, 2),
  ((SELECT id FROM task_id), '登はん', 40, 3);

-- ============================================================
-- クイズ問題サンプル
-- ============================================================
INSERT INTO quiz_problems (title, description, level)
VALUES
  ('ロープ結索 基礎', '基本的なロープ結索の知識を確認します', 'beginner'),
  ('資機材 基礎知識', '消防資機材の種類と使い方', 'beginner'),
  ('三連梯子 操作', '三連梯子の展張手順', 'intermediate'),
  ('救助技術 応用', '救助活動の応用知識', 'advanced');

-- クイズ質問サンプル（ロープ結索 基礎）
WITH p AS (SELECT id FROM quiz_problems WHERE title = 'ロープ結索 基礎' LIMIT 1)
INSERT INTO quiz_questions (problem_id, question_text, options, correct_answer, explanation, sort_order)
VALUES
  (
    (SELECT id FROM p),
    '本結びに使用する結び方はどれか',
    '["もやい結び", "本結び", "巻き結び", "8の字結び"]',
    1,
    '本結びは基本的な結び方で、ロープ同士を繋ぐのに使用します',
    1
  ),
  (
    (SELECT id FROM p),
    'もやい結びの特徴として正しいものはどれか',
    ["ほどけやすい", "輪が固定される", "強度が低い", "摩擦で固定される"],
    1,
    'もやい結びは輪の大きさが変わらないため、人命救助など安全が求められる場面に使用されます',
    2
  );
