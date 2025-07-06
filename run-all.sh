#!/bin/bash

# 🚀 リファクタリングエージェント完全自動起動スクリプト
# 1コマンドですべてのリファクタリングエージェントが動作状態になります

set -e  # エラー時に停止

# 色付きログ関数
log_info() {
    echo -e "\033[1;32m[INFO]\033[0m $1"
}

log_success() {
    echo -e "\033[1;34m[SUCCESS]\033[0m $1"
}

log_warning() {
    echo -e "\033[1;33m[WARNING]\033[0m $1"
}

echo "🔧 リファクタリングエージェント完全自動起動"
echo "=============================================="
echo ""

# STEP 1: 既存セッションをクリーンアップ
log_info "既存セッションをクリーンアップ中..."
tmux kill-server 2>/dev/null || true
sleep 1

# 完了ファイルクリア
mkdir -p ./tmp
rm -f ./tmp/worker*_done.txt 2>/dev/null

log_success "クリーンアップ完了"
echo ""

# STEP 2: refactoring_teamセッション作成（8ペイン）
log_info "refactoring_teamセッション作成中（8ペイン - リファクタリングチーム）..."

# 最初のセッション作成
tmux new-session -d -s refactoring_team -n "refactor_agents"

# マウスモードを有効化（セッション作成後）
tmux set -g mouse on

# ペインサイズ自動調整設定
tmux set-window-option -g automatic-rename off
tmux set-window-option -g allow-rename off
tmux set-option -g status-keys vi
tmux set-option -g mode-keys vi

# ペインリサイズ時の自動等分設定（エラー対策でコメントアウト）
# tmux bind-key -n M-= select-layout even-vertical
# tmux bind-key -n M-| select-layout even-horizontal

# ウィンドウサイズを最大化
tmux resize-window -t refactoring_team -x 200 -y 50 2>/dev/null || true

# 8つのペイン作成（2つのウィンドウに分割）
# Window 1: 管理系エージェント（4ペイン垂直並び）
tmux rename-window -t refactoring_team:0 "Managers"

# refactor_pm（最上段）
tmux send-keys -t "refactoring_team:0.0" "cd $(pwd)/roles/refactor_pm" C-m
tmux send-keys -t "refactoring_team:0.0" "source .claude_auto_start 2>/dev/null || true" C-m

# code_analyst（2段目）
tmux split-window -t refactoring_team:0 -v
tmux send-keys -t "refactoring_team:0.1" "cd $(pwd)/roles/code_analyst" C-m
tmux send-keys -t "refactoring_team:0.1" "source .claude_auto_start 2>/dev/null || true" C-m

# architect（3段目）
tmux split-window -t refactoring_team:0.1 -v
tmux send-keys -t "refactoring_team:0.2" "cd $(pwd)/roles/architect" C-m
tmux send-keys -t "refactoring_team:0.2" "source .claude_auto_start 2>/dev/null || true" C-m

# code_reviewer（4段目）
tmux split-window -t refactoring_team:0.2 -v
tmux send-keys -t "refactoring_team:0.3" "cd $(pwd)/roles/code_reviewer" C-m
tmux send-keys -t "refactoring_team:0.3" "source .claude_auto_start 2>/dev/null || true" C-m

# レイアウトを均等に調整
tmux select-layout -t refactoring_team:0 even-vertical

# Window 2: 実装系エージェント（4ペイン垂直並び）
tmux new-window -t refactoring_team -n "Implementers"

# test_designer（最上段）
tmux send-keys -t "refactoring_team:1.0" "cd $(pwd)/roles/test_designer" C-m
tmux send-keys -t "refactoring_team:1.0" "source .claude_auto_start 2>/dev/null || true" C-m

# test_writer（2段目）
tmux split-window -t refactoring_team:1 -v
tmux send-keys -t "refactoring_team:1.1" "cd $(pwd)/roles/test_writer" C-m
tmux send-keys -t "refactoring_team:1.1" "source .claude_auto_start 2>/dev/null || true" C-m

# tester（3段目）
tmux split-window -t refactoring_team:1.1 -v
tmux send-keys -t "refactoring_team:1.2" "cd $(pwd)/roles/tester" C-m
tmux send-keys -t "refactoring_team:1.2" "source .claude_auto_start 2>/dev/null || true" C-m

# refactorer（4段目）
tmux split-window -t refactoring_team:1.2 -v
tmux send-keys -t "refactoring_team:1.3" "cd $(pwd)/roles/refactorer" C-m
tmux send-keys -t "refactoring_team:1.3" "source .claude_auto_start 2>/dev/null || true" C-m

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
tmux send-keys -t president 'claude code --dangerously-skip-permissions' C-m

# PRESIDENT用の自動ロール設定（30秒後）
(sleep 30 && tmux send-keys -t president C-c && sleep 1 && \
 tmux send-keys -t president "あなたはpresidentです。リファクタリングプロジェクトの統括責任者として、refactor_pmに指示を出してプロジェクトを開始してください。instructions/president.mdの指示に従ってください。" C-m) &

sleep 1

# refactoring_teamの各ペインで起動（Window1: 管理系）
MANAGER_AGENTS=("refactor_pm" "code_analyst" "architect" "code_reviewer")
for i in {0..3}; do
    agent="${MANAGER_AGENTS[$i]}"
    tmux send-keys -t "refactoring_team:0.$i" 'claude code --dangerously-skip-permissions' C-m
    
    # Claude起動後、自動でロールメッセージを送信（30秒後）
    (sleep 30 && tmux send-keys -t "refactoring_team:0.$i" C-c && sleep 1 && \
     tmux send-keys -t "refactoring_team:0.$i" "あなたは${agent}です。instructions/${agent}.mdの指示に従ってください。チームの準備が完了しました。" C-m) &
    
    sleep 0.5
done

# refactoring_teamの各ペインで起動（Window2: 実装系）
IMPLEMENTER_AGENTS=("test_designer" "test_writer" "tester" "refactorer")
for i in {0..3}; do
    agent="${IMPLEMENTER_AGENTS[$i]}"
    tmux send-keys -t "refactoring_team:1.$i" 'claude code --dangerously-skip-permissions' C-m
    
    # Claude起動後、自動でロールメッセージを送信（30秒後）
    (sleep 30 && tmux send-keys -t "refactoring_team:1.$i" C-c && sleep 1 && \
     tmux send-keys -t "refactoring_team:1.$i" "あなたは${agent}です。instructions/${agent}.mdの指示に従ってください。チームの準備が完了しました。" C-m) &
    
    sleep 0.5
done

log_success "Claude起動コマンド送信完了"
echo ""

# STEP 5: 各エージェントに役割を自動送信
log_info "各エージェントのClaude起動を待機中..."

# Claude起動完了を待つ関数
wait_for_claude() {
    local target=$1
    local name=$2
    local timeout=120
    local count=0
    
    echo -n "  [$name] Claude起動待機中"
    while [ $count -lt $timeout ]; do
        # ペインの内容を確認
        content=$(tmux capture-pane -t "$target" -p 2>/dev/null | tail -10)
        
        # Claudeプロンプトが表示されているかチェック
        if echo "$content" | grep -q "claude>" || echo "$content" | grep -q "How can I help" || echo "$content" | grep -q "Bypassing Permissions" || echo "$content" | grep -q "Try \"" || echo "$content" | grep -q "Preview" || echo "$content" | grep -q "console.log" || echo "$content" | grep -q "function"; then
            echo " ✅"
            return 0
        fi
        
        # 認証URLが表示されているかチェック
        if echo "$content" | grep -q "https://.*auth" || echo "$content" | grep -q "Open.*browser"; then
            echo " 🔐 認証が必要です"
            echo ""
            echo "    認証URL: $(echo "$content" | grep -o 'https://[^[:space:]]*' | tail -1)"
            echo "    上記URLをブラウザで開いて認証してください"
            echo ""
            echo "    📺 認証画面を表示します..."
            sleep 2
            
            # 認証が必要な画面を表示
            if [[ "$target" == "president" ]]; then
                tmux attach-session -t president
            else
                tmux attach-session -t multiagent
            fi
            return 0
        fi
        
        echo -n "."
        sleep 1
        count=$((count + 1))
        
        # 30秒後に画面を自動表示
        if [ $count -eq 30 ]; then
            echo ""
            echo "    📺 30秒経過：認証画面を自動表示します..."
            sleep 2
            if [[ "$target" == "president" ]]; then
                tmux attach-session -t president
            else
                tmux attach-session -t multiagent
            fi
            return 0
        fi
        
        # 60秒ごとに画面表示の提案
        if [ $((count % 60)) -eq 0 ] && [ $count -gt 30 ] && [ $count -lt $timeout ]; then
            echo ""
            echo "    💡 認証画面を確認するには:"
            echo "       tmux attach-session -t $(echo $target | cut -d: -f1)"
            echo -n "    [$name] 認証待機継続中"
        fi
    done
    
    echo " ⚠️ タイムアウト"
    echo "    認証が必要な場合は以下で画面を確認してください:"
    echo "    tmux attach-session -t $(echo $target | cut -d: -f1)"
    return 1
}

# 各エージェントの起動を順番に待つ
echo ""
echo "💡 認証が必要な場合は、以下のコマンドで各画面を確認できます:"
echo "   tmux attach-session -t president         # PRESIDENT画面"
echo "   tmux attach-session -t refactoring_team  # リファクタリングチーム画面"
echo ""

# 認証が必要かどうか事前チェック
auth_needed=false
echo "🔍 認証状況をチェック中..."

agents=(
    "president:PRESIDENT"
    "refactoring_team:0.0:refactor_pm"
    "refactoring_team:0.1:code_analyst"
    "refactoring_team:0.2:architect"
    "refactoring_team:0.3:code_reviewer"
    "refactoring_team:1.0:test_designer"
    "refactoring_team:1.1:test_writer"
    "refactoring_team:1.2:tester"
    "refactoring_team:1.3:refactorer"
)

for agent in "${agents[@]}"; do
    IFS=':' read -r target name <<< "$agent"
    content=$(tmux capture-pane -t "$target" -p 2>/dev/null | tail -10)
    
    if echo "$content" | grep -q "https://.*auth" || echo "$content" | grep -q "https://claude.ai"; then
        if [ "$auth_needed" = false ]; then
            echo ""
            echo "🔐 認証が必要なエージェントが見つかりました:"
            echo "=================================================="
            auth_needed=true
        fi
        
        url=$(echo "$content" | grep -o 'https://[^[:space:]]*' | tail -1)
        echo ""
        echo "[$name] 認証URL:"
        echo "$url"
        echo "  ↑ このURLをブラウザで開いて認証してください"
    fi
done

if [ "$auth_needed" = true ]; then
    echo ""
    echo "=================================================="
    echo "💡 上記のURLをすべてブラウザで開いて認証を完了してください"
    echo ""
    echo "📺 3秒後に認証画面を表示します..."
    echo "   （Ctrl+Cでキャンセル可能）"
    
    # カウントダウン
    for i in 3 2 1; do
        echo -n "$i... "
        sleep 1
    done
    echo ""
    
    # 認証画面を表示（最初にrefactoring_teamを表示）
    echo "refactoring_team画面を表示中（認証後、Ctrl+b → s でPRESIDENTに切り替え可能）"
    tmux attach-session -t refactoring_team
    exit 0
else
    echo "✅ 認証済みまたは認証不要です"
    echo ""
    echo "📺 認証確認のため画面を表示します..."
    echo "   （認証が必要な場合は各ペインで認証してください）"
    
    # カウントダウン
    for i in 3 2 1; do
        echo -n "$i... "
        sleep 1
    done
    echo ""
    
    # 認証画面を表示
    echo "refactoring_team画面を表示中（Ctrl+b → s でPRESIDENTに切り替え可能）"
    tmux attach-session -t refactoring_team
    exit 0
fi
echo ""

wait_for_claude "president" "PRESIDENT"
wait_for_claude "refactoring_team:0.0" "refactor_pm"
wait_for_claude "refactoring_team:0.1" "code_analyst"
wait_for_claude "refactoring_team:0.2" "architect"
wait_for_claude "refactoring_team:0.3" "code_reviewer"
wait_for_claude "refactoring_team:1.0" "test_designer"
wait_for_claude "refactoring_team:1.1" "test_writer"
wait_for_claude "refactoring_team:1.2" "tester"
wait_for_claude "refactoring_team:1.3" "refactorer"

echo ""
log_info "全エージェントに役割を自動送信中..."

# PRESIDENTに役割送信
log_info "PRESIDENTに役割を送信..."
tmux send-keys -t president "あなたはpresidentです。リファクタリングプロジェクトの統括責任者として、refactor_pmに指示を出してください。" C-m
sleep 2

# Window1（管理系）に役割送信
MANAGER_AGENTS=("refactor_pm" "code_analyst" "architect" "code_reviewer")
for i in {0..3}; do
    agent="${MANAGER_AGENTS[$i]}"
    log_info "${agent}に役割を送信..."
    tmux send-keys -t "refactoring_team:0.$i" "あなたは${agent}です。instructions/${agent}.mdの指示に従ってください。" C-m
    sleep 1
done

# Window2（実装系）に役割送信
IMPLEMENTER_AGENTS=("test_designer" "test_writer" "tester" "refactorer")
for i in {0..3}; do
    agent="${IMPLEMENTER_AGENTS[$i]}"
    log_info "${agent}に役割を送信..."
    tmux send-keys -t "refactoring_team:1.$i" "あなたは${agent}です。instructions/${agent}.mdの指示に従ってください。" C-m
    sleep 1
done

log_success "役割設定完了 - 全員準備完了！"
echo ""

# STEP 6: PRESIDENTに起動完了メッセージを送信
log_info "PRESIDENTに起動完了メッセージを送信中..."
tmux send-keys -t president "" C-m
tmux send-keys -t president "echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'" C-m
tmux send-keys -t president "echo '🔧 リファクタリングエージェントチーム起動完了！'" C-m
tmux send-keys -t president "echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'" C-m
tmux send-keys -t president "echo ''" C-m
tmux send-keys -t president "echo '📋 システム状況:'" C-m
tmux send-keys -t president "echo '  ✅ PRESIDENT: 準備完了'" C-m
tmux send-keys -t president "echo '  ✅ refactor_pm: 準備完了'" C-m
tmux send-keys -t president "echo '  ✅ code_analyst: 準備完了'" C-m
tmux send-keys -t president "echo '  ✅ architect: 準備完了'" C-m
tmux send-keys -t president "echo '  ✅ test_designer: 準備完了'" C-m
tmux send-keys -t president "echo '  ✅ test_writer: 準備完了'" C-m
tmux send-keys -t president "echo '  ✅ tester: 準備完了'" C-m
tmux send-keys -t president "echo '  ✅ refactorer: 準備完了'" C-m
tmux send-keys -t president "echo '  ✅ code_reviewer: 準備完了'" C-m
tmux send-keys -t president "echo ''" C-m
tmux send-keys -t president "echo '🚀 リファクタリングプロジェクト開始準備完了！'" C-m
tmux send-keys -t president "echo '以下のような指示でプロジェクトを開始できます:'" C-m
tmux send-keys -t president "echo ''" C-m
tmux send-keys -t president "echo '例: 技術的負債を解消するリファクタリングプロジェクトを開始してください。'" C-m
tmux send-keys -t president "echo '    対象: [プロジェクトパス] 目標: 技術的負債70%削減'" C-m
tmux send-keys -t president "echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'" C-m

sleep 2

# STEP 7: 最終メッセージ
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
echo "  ✅ 役割自動設定済み"
echo ""
echo "💡 操作方法:"
echo "  画面切り替え: Ctrl+b → s"
echo "  ペイン移動: Ctrl+b → 矢印キー"
echo "  デタッチ: Ctrl+b → d"
echo "  URLコピー: マウスでドラッグ選択（マウスモード有効済み）"
echo ""
echo "🚀 リファクタリング開始方法:"
echo "  PRESIDENTから refactor_pm に指示を出してプロジェクトを開始"
echo ""
echo "📺 3秒後に自動的にPRESIDENT画面を表示します..."
echo "  （Ctrl+Cでキャンセル可能）"

# カウントダウン
for i in 3 2 1; do
    echo -n "$i... "
    sleep 1
done
echo ""

# PRESIDENTセッションにアタッチ
log_info "PRESIDENT画面を表示中..."
tmux attach-session -t president