#!/bin/bash

# 🚀 AIエージェント完全自動起動スクリプト
# 1コマンドですべてのエージェントが動作状態になります

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

echo "🤖 AIエージェント完全自動起動"
echo "=============================="
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

# STEP 2: multiagentセッション作成（4ペイン）
log_info "multiagentセッション作成中（4ペイン - 垂直配置）..."

# 最初のセッション作成
tmux new-session -d -s multiagent -n "agents"

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

# 4つの垂直ペイン作成（縦一列）
tmux split-window -v -t "multiagent:0"      # 2分割
tmux split-window -v -t "multiagent:0.0"    # 上を分割 → 3つ
tmux split-window -v -t "multiagent:0.2"    # 下端を分割 → 4つ

# レイアウトを均等に調整
tmux select-layout -t multiagent even-vertical

# ウィンドウリサイズ時の自動等分設定
tmux set-hook -t multiagent:agents window-layout-changed 'select-layout even-vertical'

# ペイン設定
PANE_TITLES=("boss1" "worker1" "worker2" "worker3")
for i in {0..3}; do
    tmux select-pane -t "multiagent:0.$i" -T "${PANE_TITLES[$i]}"
    tmux send-keys -t "multiagent:0.$i" "cd $(pwd)" C-m
    
    # カラープロンプト設定
    if [ $i -eq 0 ]; then
        # boss1: 赤色
        tmux send-keys -t "multiagent:0.$i" "export PS1='(\[\033[1;31m\]${PANE_TITLES[$i]}\[\033[0m\]) \[\033[1;32m\]\w\[\033[0m\]\$ '" C-m
    else
        # workers: 青色
        tmux send-keys -t "multiagent:0.$i" "export PS1='(\[\033[1;34m\]${PANE_TITLES[$i]}\[\033[0m\]) \[\033[1;32m\]\w\[\033[0m\]\$ '" C-m
    fi
    
    tmux send-keys -t "multiagent:0.$i" "clear" C-m
    tmux send-keys -t "multiagent:0.$i" "echo '=== ${PANE_TITLES[$i]} エージェント ==='" C-m
done

log_success "multiagentセッション作成完了"

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
tmux send-keys -t president 'claude --dangerously-skip-permissions' C-m
sleep 1

# multiagentの各ペインで起動
for i in {0..3}; do
    tmux send-keys -t "multiagent:0.$i" 'claude --dangerously-skip-permissions' C-m
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
echo "   tmux attach-session -t president    # PRESIDENT画面"
echo "   tmux attach-session -t multiagent   # boss1, worker1-3画面"
echo ""

# 認証が必要かどうか事前チェック
auth_needed=false
echo "🔍 認証状況をチェック中..."

agents=("president:PRESIDENT" "multiagent:0.0:boss1" "multiagent:0.1:worker1" "multiagent:0.2:worker2" "multiagent:0.3:worker3")

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
    
    # 認証画面を表示（最初にmultiagentを表示）
    echo "multiagent画面を表示中（認証後、Ctrl+b → s でPRESIDENTに切り替え可能）"
    tmux attach-session -t multiagent
    exit 0
else
    echo "✅ 認証済みまたは認証不要です"
fi
echo ""

wait_for_claude "president" "PRESIDENT"
wait_for_claude "multiagent:0.0" "boss1"
wait_for_claude "multiagent:0.1" "worker1"
wait_for_claude "multiagent:0.2" "worker2"
wait_for_claude "multiagent:0.3" "worker3"

echo ""
log_info "全エージェントに役割を自動送信中..."

# PRESIDENTに役割送信
log_info "PRESIDENTに役割を送信..."
tmux send-keys -t president "あなたはpresidentです。instructions/president.mdの指示に従ってください。" C-m
sleep 2

# boss1に役割送信
log_info "boss1に役割を送信..."
tmux send-keys -t "multiagent:0.0" "あなたはboss1です。instructions/boss.mdの指示に従ってください。" C-m
sleep 2

# worker1に役割送信
log_info "worker1に役割を送信..."
tmux send-keys -t "multiagent:0.1" "あなたはworker1です。instructions/worker.mdの指示に従ってください。" C-m
sleep 2

# worker2に役割送信
log_info "worker2に役割を送信..."
tmux send-keys -t "multiagent:0.2" "あなたはworker2です。instructions/worker.mdの指示に従ってください。" C-m
sleep 2

# worker3に役割送信
log_info "worker3に役割を送信..."
tmux send-keys -t "multiagent:0.3" "あなたはworker3です。instructions/worker.mdの指示に従ってください。" C-m

log_success "役割設定完了 - 全員準備完了！"
echo ""

# STEP 6: PRESIDENTに起動完了メッセージを送信
log_info "PRESIDENTに起動完了メッセージを送信中..."
tmux send-keys -t president "" C-m
tmux send-keys -t president "echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'" C-m
tmux send-keys -t president "echo '🎉 全AIエージェント起動完了！'" C-m
tmux send-keys -t president "echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'" C-m
tmux send-keys -t president "echo ''" C-m
tmux send-keys -t president "echo '📋 システム状況:'" C-m
tmux send-keys -t president "echo '  ✅ PRESIDENT: 準備完了'" C-m
tmux send-keys -t president "echo '  ✅ boss1: 準備完了'" C-m
tmux send-keys -t president "echo '  ✅ worker1: 準備完了'" C-m
tmux send-keys -t president "echo '  ✅ worker2: 準備完了'" C-m
tmux send-keys -t president "echo '  ✅ worker3: 準備完了'" C-m
tmux send-keys -t president "echo ''" C-m
tmux send-keys -t president "echo '🚀 プロジェクト開始準備完了！'" C-m
tmux send-keys -t president "echo '以下のような指示でプロジェクトを開始できます:'" C-m
tmux send-keys -t president "echo ''" C-m
tmux send-keys -t president "echo '例: おしゃれな充実したIT企業のホームページを作成して。'" C-m
tmux send-keys -t president "echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'" C-m

sleep 2

# STEP 7: 最終メッセージ
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_success "🎉 全エージェント起動完了！"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 現在の状態:"
echo "  ✅ multiagentセッション（4ペイン垂直配置）: boss1, worker1-3"
echo "  ✅ presidentセッション: 統括責任者"
echo "  ✅ 全員Claude起動済み"
echo "  ✅ 役割自動設定済み（エンター不要）"
echo "  ✅ PRESIDENT画面に起動完了メッセージ表示済み"
echo ""
echo "💡 操作方法:"
echo "  画面切り替え: Ctrl+b → s"
echo "  ペイン移動: Ctrl+b → 矢印キー"
echo "  デタッチ: Ctrl+b → d"
echo "  URLコピー: マウスでドラッグ選択（マウスモード有効済み）"
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