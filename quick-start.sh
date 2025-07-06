#!/bin/bash
# 🚀 リファクタリングエージェント簡易起動スクリプト
# 認証チェックをスキップして即座に画面表示

set -e

echo "🔧 リファクタリングエージェント簡易起動"
echo "======================================"
echo ""

# 色付きログ関数
log_info() {
    echo -e "\033[1;32m[INFO]\033[0m $1"
}

log_success() {
    echo -e "\033[1;34m[SUCCESS]\033[0m $1"
}

# STEP 1: 既存セッションをクリーンアップ
log_info "既存セッションをクリーンアップ中..."
tmux kill-server 2>/dev/null || true
sleep 1

# 完了ファイルクリア
mkdir -p ./tmp
rm -f ./tmp/worker*_done.txt 2>/dev/null

log_success "クリーンアップ完了"
echo ""

# STEP 2: refactoring_teamセッション作成
log_info "refactoring_teamセッション作成中..."

# セッション作成
tmux new-session -d -s refactoring_team -n "Managers"

# マウスモードを有効化
tmux set -g mouse on

# Window 1: 管理系エージェント（4ペイン垂直並び）
tmux rename-window -t refactoring_team:0 "Managers"

# refactor_pm（最上段）
tmux send-keys -t "refactoring_team:0.0" "cd $(pwd)/roles/refactor_pm" C-m

# code_analyst（2段目）
tmux split-window -t refactoring_team:0 -v
tmux send-keys -t "refactoring_team:0.1" "cd $(pwd)/roles/code_analyst" C-m

# architect（3段目）
tmux split-window -t refactoring_team:0.1 -v
tmux send-keys -t "refactoring_team:0.2" "cd $(pwd)/roles/architect" C-m

# code_reviewer（4段目）
tmux split-window -t refactoring_team:0.2 -v
tmux send-keys -t "refactoring_team:0.3" "cd $(pwd)/roles/code_reviewer" C-m

# レイアウトを均等に調整
tmux select-layout -t refactoring_team:0 even-vertical

# Window 2: 実装系エージェント（4ペイン垂直並び）
tmux new-window -t refactoring_team -n "Implementers"

# test_designer（最上段）
tmux send-keys -t "refactoring_team:1.0" "cd $(pwd)/roles/test_designer" C-m

# test_writer（2段目）
tmux split-window -t refactoring_team:1 -v
tmux send-keys -t "refactoring_team:1.1" "cd $(pwd)/roles/test_writer" C-m

# tester（3段目）
tmux split-window -t refactoring_team:1.1 -v
tmux send-keys -t "refactoring_team:1.2" "cd $(pwd)/roles/tester" C-m

# refactorer（4段目）
tmux split-window -t refactoring_team:1.2 -v
tmux send-keys -t "refactoring_team:1.3" "cd $(pwd)/roles/refactorer" C-m

# レイアウトを均等に調整
tmux select-layout -t refactoring_team:1 even-vertical

# 最初のウィンドウに戻る
tmux select-window -t refactoring_team:0

# ペイン設定（Window1: 管理系）
MANAGERS=("refactor_pm" "code_analyst" "architect" "code_reviewer")
MANAGER_COLORS=("1;31m" "1;32m" "1;33m" "1;35m")

for i in {0..3}; do
    tmux select-pane -t "refactoring_team:0.$i" -T "${MANAGERS[$i]}"
    tmux send-keys -t "refactoring_team:0.$i" "export PS1='(\[\033[${MANAGER_COLORS[$i]}]${MANAGERS[$i]}\[\033[0m\]) \[\033[1;32m\]\w\[\033[0m\]\$ '" C-m
    tmux send-keys -t "refactoring_team:0.$i" "clear" C-m
    tmux send-keys -t "refactoring_team:0.$i" "echo '=== ${MANAGERS[$i]} エージェント ==='" C-m
done

# ペイン設定（Window2: 実装系）
IMPLEMENTERS=("test_designer" "test_writer" "tester" "refactorer")
IMPLEMENTER_COLORS=("1;34m" "1;34m" "1;34m" "1;33m")

for i in {0..3}; do
    tmux select-pane -t "refactoring_team:1.$i" -T "${IMPLEMENTERS[$i]}"
    tmux send-keys -t "refactoring_team:1.$i" "export PS1='(\[\033[${IMPLEMENTER_COLORS[$i]}]${IMPLEMENTERS[$i]}\[\033[0m\]) \[\033[1;32m\]\w\[\033[0m\]\$ '" C-m
    tmux send-keys -t "refactoring_team:1.$i" "clear" C-m
    tmux send-keys -t "refactoring_team:1.$i" "echo '=== ${IMPLEMENTERS[$i]} エージェント ==='" C-m
done

# ペインタイトルとボーダー設定
tmux set-option -t refactoring_team -g pane-border-status top
tmux set-option -t refactoring_team -g pane-border-format "#{pane_title}"

log_success "refactoring_teamセッション作成完了"

# STEP 3: presidentセッション作成
log_info "presidentセッション作成中..."

tmux new-session -d -s president
tmux send-keys -t president "cd $(pwd)" C-m
tmux send-keys -t president "export PS1='(\[\033[1;35m\]PRESIDENT\[\033[0m\]) \[\033[1;32m\]\w\[\033[0m\]\$ '" C-m
tmux send-keys -t president "clear" C-m
tmux send-keys -t president "echo '=== PRESIDENT セッション ==='" C-m
tmux send-keys -t president "echo 'プロジェクト統括責任者'" C-m
tmux send-keys -t president "echo '========================'" C-m

log_success "presidentセッション作成完了"
echo ""

# STEP 4: 全エージェントでClaude起動
log_info "全エージェントでClaude起動中..."

# PRESIDENT起動
tmux send-keys -t president 'claude code' C-m

# PRESIDENT用の自動ロール設定（30秒後）
(sleep 30 && tmux send-keys -t president C-c && sleep 1 && \
 tmux send-keys -t president "あなたはpresidentです。リファクタリングプロジェクトの統括責任者として、refactor_pmに指示を出してプロジェクトを開始してください。instructions/president.mdの指示に従ってください。" C-m) &

sleep 1

# refactoring_teamの各ペインで起動（Window1: 管理系）
MANAGER_AGENTS=("refactor_pm" "code_analyst" "architect" "code_reviewer")
for i in {0..3}; do
    agent="${MANAGER_AGENTS[$i]}"
    tmux send-keys -t "refactoring_team:0.$i" 'claude code' C-m
    
    # Claude起動後、自動でロールメッセージを送信（30秒後）
    (sleep 30 && tmux send-keys -t "refactoring_team:0.$i" C-c && sleep 1 && \
     tmux send-keys -t "refactoring_team:0.$i" "あなたは${agent}です。instructions/${agent}.mdの指示に従ってください。チームの準備が完了しました。" C-m) &
    
    sleep 0.5
done

# refactoring_teamの各ペインで起動（Window2: 実装系）
IMPLEMENTER_AGENTS=("test_designer" "test_writer" "tester" "refactorer")
for i in {0..3}; do
    agent="${IMPLEMENTER_AGENTS[$i]}"
    tmux send-keys -t "refactoring_team:1.$i" 'claude code' C-m
    
    # Claude起動後、自動でロールメッセージを送信（30秒後）
    (sleep 30 && tmux send-keys -t "refactoring_team:1.$i" C-c && sleep 1 && \
     tmux send-keys -t "refactoring_team:1.$i" "あなたは${agent}です。instructions/${agent}.mdの指示に従ってください。チームの準備が完了しました。" C-m) &
    
    sleep 0.5
done

log_success "Claude起動コマンド送信完了"
echo ""

# STEP 5: 即座に画面表示
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_success "🔧 リファクタリングエージェントチーム起動完了！"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 現在の状態:"
echo "  ✅ refactoring_teamセッション（2ウィンドウ・8エージェント）:"
echo "     【Window1: Managers（管理系）】"
echo "     • refactor_pm - プロジェクトマネージャー"
echo "     • code_analyst - コード分析者"
echo "     • architect - ソフトウェアアーキテクト"
echo "     • code_reviewer - コードレビュアー"
echo "     【Window2: Implementers（実装系）】"
echo "     • test_designer - テスト設計者"
echo "     • test_writer - テスト実装者"
echo "     • tester - テスト実行者"
echo "     • refactorer - リファクタリング実装者"
echo "  ✅ presidentセッション: 統括責任者"
echo "  ✅ 全員Claude起動済み"
echo "  ✅ 30秒後に自動で各エージェントのロールが設定されます"
echo ""
echo "💡 操作方法:"
echo "  画面切り替え: Ctrl+b → s"
echo "  ウィンドウ切り替え: Ctrl+b → 0/1"
echo "  ペイン移動: Ctrl+b → 矢印キー"
echo "  デタッチ: Ctrl+b → d"
echo ""
echo "🚀 リファクタリング開始方法:"
echo "  1. 各ペインでClaude認証を完了（必要に応じて）"
echo "  2. 30秒後に自動でロールが設定されます"
echo "  3. PRESIDENTから refactor_pm に指示を出してプロジェクトを開始"
echo ""
echo "📺 refactoring_team画面を表示中..."
echo "   （Ctrl+b → s でPRESIDENTに切り替え可能）"

# refactoring_teamセッションにアタッチ
tmux attach-session -t refactoring_team