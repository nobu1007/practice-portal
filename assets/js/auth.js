// ============================================================
// auth.js — Magic Link 認証 / セッション監視 / 権限制御
// ============================================================

const Auth = (() => {
  // -----------------------------------------------------------
  // Supabase client（supabase-init.js で window.SUPABASE_URL 等が設定済み前提）
  // -----------------------------------------------------------
  let _client = null;

  function getClient() {
    if (!_client) {
      _client = window.supabase.createClient(
        window.SUPABASE_URL,
        window.SUPABASE_ANON_KEY,
        {
          auth: {
            autoRefreshToken: true,
            persistSession: true,
            detectSessionInUrl: true,
          },
        }
      );
    }
    return _client;
  }

  // -----------------------------------------------------------
  // Magic Link 送信
  // -----------------------------------------------------------
  async function sendMagicLink(email) {
    const { error } = await getClient().auth.signInWithOtp({
      email,
      options: {
        emailRedirectTo: 'http://localhost:5500/index.html',
      },
    });
    if (error) throw error;
  }

  // -----------------------------------------------------------
  // ログアウト
  // -----------------------------------------------------------
  async function signOut() {
    await getClient().auth.signOut();
    window.location.href = '/index.html';
  }

  // -----------------------------------------------------------
  // 現在のセッション取得
  // -----------------------------------------------------------
  async function getSession() {
    const { data } = await getClient().auth.getSession();
    return data.session;
  }

  // -----------------------------------------------------------
  // 現在のユーザー取得
  // -----------------------------------------------------------
  async function getUser() {
    const { data } = await getClient().auth.getUser();
    return data.user;
  }

  // -----------------------------------------------------------
  // profiles 取得
  // -----------------------------------------------------------
  async function getProfile(userId) {
    const { data, error } = await getClient()
      .from('profiles')
      .select('*')
      .eq('id', userId)
      .single();
    if (error) return null;
    return data;
  }

  // -----------------------------------------------------------
  // bootstrap_user RPC
  // -----------------------------------------------------------
  async function bootstrapUser(inviteCode, displayName) {
    const { data, error } = await getClient().rpc('bootstrap_user', {
      p_invite_code: inviteCode,
      p_display_name: displayName,
    });
    if (error) throw error;
    if (!data.success) throw new Error(data.error);
    return data;
  }

  // -----------------------------------------------------------
  // 認証ガード（未ログイン or profiles 未作成なら index.html へ）
  // -----------------------------------------------------------
  async function requireAuth() {
    const session = await getSession();
    if (!session) {
      window.location.href = '/index.html';
      return null;
    }
    const profile = await getProfile(session.user.id);
    if (!profile) {
      // profiles 未作成 → 初回セットアップへ
      window.location.href = '/index.html?setup=1';
      return null;
    }
    return { session, profile };
  }

  // -----------------------------------------------------------
  // admin 専用ガード
  // -----------------------------------------------------------
  async function requireAdmin() {
    const auth = await requireAuth();
    if (!auth) return null;
    if (auth.profile.role !== 'admin') {
      window.location.href = '/dashboard.html';
      return null;
    }
    return auth;
  }

  // -----------------------------------------------------------
  // セッション変化リスナー
  // -----------------------------------------------------------
  function onAuthStateChange(callback) {
    return getClient().auth.onAuthStateChange((event, session) => {
      callback(event, session);
    });
  }

  return {
    getClient,
    sendMagicLink,
    signOut,
    getSession,
    getUser,
    getProfile,
    bootstrapUser,
    requireAuth,
    requireAdmin,
    onAuthStateChange,
  };
})();
