// ============================================================
// api.js — Supabase クエリの薄いラッパー
// ============================================================

const API = (() => {
  function db() { return Auth.getClient(); }

  // ============================================================
  // ユーザー統計
  // ============================================================
  async function getUserStats(userId) {
    const { data } = await db().from('user_stats').select('*').eq('user_id', userId).single();
    return data;
  }

  // ============================================================
  // タスク
  // ============================================================
  async function getTasks() {
    const { data } = await db()
      .from('tasks')
      .select('*, subtasks(*, conditions(*))')
      .eq('is_active', true)
      .order('created_at');
    return data || [];
  }

  async function getUserTaskProgress(userId) {
    const { data } = await db()
      .from('user_task_progress')
      .select('*')
      .eq('user_id', userId);
    return data || [];
  }

  async function upsertTaskProgress(userId, taskId, fields) {
    const { data, error } = await db()
      .from('user_task_progress')
      .upsert({ user_id: userId, task_id: taskId, ...fields }, { onConflict: 'user_id,task_id' })
      .select()
      .single();
    if (error) throw error;
    return data;
  }

  async function getUserConditionProgress(userId) {
    const { data } = await db()
      .from('user_condition_progress')
      .select('*')
      .eq('user_id', userId);
    return data || [];
  }

  async function upsertConditionProgress(userId, conditionId, fields) {
    const { data, error } = await db()
      .from('user_condition_progress')
      .upsert({ user_id: userId, condition_id: conditionId, ...fields }, { onConflict: 'user_id,condition_id' })
      .select()
      .single();
    if (error) throw error;
    return data;
  }

  async function approveTask(progressId) {
    const { data, error } = await db().rpc('approve_task', { p_progress_id: progressId });
    if (error) throw error;
    if (!data.success) throw new Error(data.error);
    return data;
  }

  // ============================================================
  // クイズ
  // ============================================================
  async function getQuizProblems(level = null) {
    let q = db().from('quiz_problems').select('*').eq('is_active', true);
    if (level) q = q.eq('level', level);
    const { data } = await q.order('created_at');
    return data || [];
  }

  async function getQuizQuestions(problemId) {
    const { data } = await db()
      .from('quiz_questions')
      .select('*')
      .eq('problem_id', problemId)
      .order('sort_order');
    return data || [];
  }

  async function getUserQuizProgress(userId) {
    const { data } = await db()
      .from('user_quiz_progress')
      .select('*')
      .eq('user_id', userId);
    return data || [];
  }

  async function upsertQuizProgress(userId, problemId, fields) {
    const { data, error } = await db()
      .from('user_quiz_progress')
      .upsert({ user_id: userId, problem_id: problemId, ...fields }, { onConflict: 'user_id,problem_id' })
      .select()
      .single();
    if (error) throw error;
    return data;
  }

  // ============================================================
  // マインドマップ
  // ============================================================
  async function getMindmaps(userId) {
    const { data } = await db()
      .from('mindmaps')
      .select('*')
      .eq('user_id', userId)
      .order('updated_at', { ascending: false });
    return data || [];
  }

  async function getMindmap(id) {
    const { data } = await db()
      .from('mindmaps')
      .select('*, mindmap_nodes(*)')
      .eq('id', id)
      .single();
    return data;
  }

  async function createMindmap(userId, title = '新規マインドマップ') {
    const { data, error } = await db()
      .from('mindmaps')
      .insert({ user_id: userId, title })
      .select()
      .single();
    if (error) throw error;
    return data;
  }

  async function updateMindmapTitle(id, title) {
    const { error } = await db().from('mindmaps').update({ title }).eq('id', id);
    if (error) throw error;
  }

  async function deleteMindmap(id) {
    const { error } = await db().from('mindmaps').delete().eq('id', id);
    if (error) throw error;
  }

  async function upsertNode(node) {
    const { data, error } = await db()
      .from('mindmap_nodes')
      .upsert(node)
      .select()
      .single();
    if (error) throw error;
    return data;
  }

  async function deleteNode(id) {
    const { error } = await db().from('mindmap_nodes').delete().eq('id', id);
    if (error) throw error;
  }

  // ============================================================
  // 管理: メンバー一覧
  // ============================================================
  async function getAllProfiles() {
    const { data } = await db().from('profiles').select('*, user_stats(*)').order('created_at');
    return data || [];
  }

  // ============================================================
  // 管理: 招待コード
  // ============================================================
  async function getInviteCodes() {
    const { data } = await db().from('invite_codes').select('*').order('created_at', { ascending: false });
    return data || [];
  }

  async function createInviteCode(code, roleToGrant, maxUses, expiresAt) {
    const { data, error } = await db()
      .from('invite_codes')
      .insert({ code, role_to_grant: roleToGrant, max_uses: maxUses, expires_at: expiresAt || null })
      .select()
      .single();
    if (error) throw error;
    return data;
  }

  return {
    getUserStats,
    getTasks,
    getUserTaskProgress,
    upsertTaskProgress,
    getUserConditionProgress,
    upsertConditionProgress,
    approveTask,
    getQuizProblems,
    getQuizQuestions,
    getUserQuizProgress,
    upsertQuizProgress,
    getMindmaps,
    getMindmap,
    createMindmap,
    updateMindmapTitle,
    deleteMindmap,
    upsertNode,
    deleteNode,
    getAllProfiles,
    getInviteCodes,
    createInviteCode,
  };
})();
