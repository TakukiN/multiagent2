#!/bin/bash

# 🚀 AIエージェント一括起動・準備完了スクリプト
# 1コマンドで全エージェントを起動し、動作準備を完了させる

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

log_error() {
    echo -e "\033[1;31m[ERROR]\033[0m $1"
}

echo "🤖 AIエージェント一括起動・準備完了"
echo "===================================="
echo ""

# 環境チェック
check_environment() {
    log_info "環境チェック中..."
    
    # tmux確認
    if ! command -v tmux &> /dev/null; then
        log_error "tmuxがインストールされていません"
        echo "インストール方法: brew install tmux (Mac) または sudo apt install tmux (Ubuntu)"
        exit 1
    fi
    
    # claude確認
    if ! command -v claude &> /dev/null; then
        log_error "Claude Code CLIがインストールされていません"
        echo "インストール方法: https://docs.anthropic.com/ja/docs/claude-code/overview"
        exit 1
    fi
    
    log_success "環境チェック完了"
}

# セッション作成（存在しない場合）
setup_sessions() {
    log_info "セッション確認・作成中..."
    
    # 既存セッションクリーンアップ
    tmux kill-session -t multiagent 2>/dev/null && log_info "既存のmultiagentセッションを削除" || log_info "multiagentセッションは存在しませんでした"
    tmux kill-session -t president 2>/dev/null && log_info "既存のpresidentセッションを削除" || log_info "presidentセッションは存在しませんでした"
    
    # 完了ファイルクリア
    mkdir -p ./tmp
    rm -f ./tmp/worker*_done.txt 2>/dev/null
    
    # multiagentセッション作成（4ペイン）
    log_info "multiagentセッション作成中..."
    tmux new-session -d -s multiagent -n "agents"
    
    # 2x2グリッド作成
    tmux split-window -h -t "multiagent:0"
    tmux select-pane -t "multiagent:0.0"
    tmux split-window -v
    tmux select-pane -t "multiagent:0.2"
    tmux split-window -v
    
    # ペイン設定
    PANE_TITLES=("boss1" "worker1" "worker2" "worker3")
    for i in {0..3}; do
        tmux select-pane -t "multiagent:0.$i" -T "${PANE_TITLES[$i]}"
        tmux send-keys -t "multiagent:0.$i" "cd $(pwd)" C-m
        
        # カラープロンプト設定
        if [ $i -eq 0 ]; then
            tmux send-keys -t "multiagent:0.$i" "export PS1='(\[\033[1;31m\]${PANE_TITLES[$i]}\[\033[0m\]) \[\033[1;32m\]\w\[\033[0m\]\$ '" C-m
        else
            tmux send-keys -t "multiagent:0.$i" "export PS1='(\[\033[1;34m\]${PANE_TITLES[$i]}\[\033[0m\]) \[\033[1;32m\]\w\[\033[0m\]\$ '" C-m
        fi
        
        tmux send-keys -t "multiagent:0.$i" "echo '=== ${PANE_TITLES[$i]} エージェント ==='" C-m
    done
    
    # presidentセッション作成
    log_info "presidentセッション作成中..."
    tmux new-session -d -s president
    tmux send-keys -t president "cd $(pwd)" C-m
    tmux send-keys -t president "export PS1='(\[\033[1;35m\]PRESIDENT\[\033[0m\]) \[\033[1;32m\]\w\[\033[0m\]\$ '" C-m
    tmux send-keys -t president "echo '=== PRESIDENT セッション ==='" C-m
    tmux send-keys -t president "echo 'プロジェクト統括責任者'" C-m
    
    log_success "セッション作成完了"
}

# エージェント起動
launch_agents() {
    log_info "エージェント起動中..."
    
    # 起動順序を制御（認証の競合を避けるため）
    local agents=(
        "president:PRESIDENT"
        "multiagent:0.0:boss1"
        "multiagent:0.1:worker1"
        "multiagent:0.2:worker2"
        "multiagent:0.3:worker3"
    )
    
    for agent in "${agents[@]}"; do
        IFS=':' read -r target name <<< "$agent"
        log_info "$name を起動中..."
        tmux send-keys -t "$target" 'claude --dangerously-skip-permissions' C-m
        sleep 1  # 認証画面の表示を待つ
    done
    
    log_success "全エージェントの起動コマンドを送信完了"
}

# 認証状況確認
check_auth_status() {
    log_info "認証状況確認中..."
    echo ""
    echo "🔐 認証が必要なエージェント:"
    echo "============================="
    
    local agents=(
        "president:PRESIDENT"
        "multiagent:0.0:boss1"
        "multiagent:0.1:worker1"
        "multiagent:0.2:worker2"
        "multiagent:0.3:worker3"
    )
    
    for agent in "${agents[@]}"; do
        IFS=':' read -r target name <<< "$agent"
        echo "  - $name"
    done
    
    echo ""
    echo "💡 各画面でブラウザ認証を完了してください"
    echo "   認証完了後、エージェントは自動的に準備完了状態になります"
}

# 動作確認用のテストメッセージ送信
send_test_messages() {
    log_info "動作確認用メッセージを送信中..."
    
    # 各エージェントに指示書を送信
    sleep 2
    
    # PRESIDENTに指示書送信
    tmux send-keys -t president "cat instructions/president.md" C-m
    sleep 1
    
    # boss1に指示書送信
    tmux send-keys -t "multiagent:0.0" "cat instructions/boss.md" C-m
    sleep 1
    
    # workersに指示書送信
    for i in {1..3}; do
        tmux send-keys -t "multiagent:0.$i" "cat instructions/worker.md" C-m
        sleep 0.5
    done
    
    log_success "指示書送信完了"
}

# 完了メッセージ表示
show_completion_message() {
    echo ""
    log_success "🎉 AIエージェント一括起動・準備完了！"
    echo ""
    echo "📋 システム状況:"
    echo "================="
    echo "✅ セッション作成完了"
    echo "✅ エージェント起動完了"
    echo "✅ 指示書送信完了"
    echo ""
    echo "🎯 次のステップ:"
    echo "==============="
    echo "1. 認証完了確認:"
    echo "   tmux attach-session -t president    # 社長画面確認"
    echo "   tmux attach-session -t multiagent   # 部下たち画面確認"
    echo ""
    echo "2. プロジェクト開始:"
    echo "   # PRESIDENT画面で以下を入力"
    echo "   あなたはpresidentです。おしゃれな充実したIT企業のホームページを作成して。"
    echo ""
    echo "3. 進捗確認:"
    echo "   ./project-status.sh                 # プロジェクト状況確認"
    echo "   ./agent-send.sh --list              # 利用可能エージェント確認"
    echo ""
    echo "🔧 便利なコマンド:"
    echo "================="
    echo "  ./agent-send.sh boss1 \"メッセージ\"     # マネージャーに送信"
    echo "  ./agent-send.sh worker1 \"メッセージ\"   # 作業者1に送信"
    echo "  tmux kill-server                     # 全セッション終了"
    echo ""
    echo "📚 参考資料:"
    echo "==========="
    echo "  README.md                            # 詳細な使用方法"
    echo "  CLAUDE.md                            # システム構成"
    echo "  instructions/                        # 各エージェントの指示書"
}

# メイン処理
main() {
    echo "🚀 AIエージェント一括起動・準備完了プロセスを開始します"
    echo ""
    
    # 環境チェック
    check_environment
    echo ""
    
    # セッション作成
    setup_sessions
    echo ""
    
    # エージェント起動
    launch_agents
    echo ""
    
    # 認証状況確認
    check_auth_status
    echo ""
    
    # 動作確認用メッセージ送信
    send_test_messages
    echo ""
    
    # 完了メッセージ表示
    show_completion_message
}

# 実行
main "$@" 