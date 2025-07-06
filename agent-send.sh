#!/bin/bash

# 🚀 リファクタリングエージェント間メッセージ送信スクリプト

# エージェント→tmuxターゲット マッピング
get_agent_target() {
    case "$1" in
        "president") echo "president" ;;
        # Window1: 管理系エージェント
        "refactor_pm") echo "refactoring_team:0.0" ;;
        "code_analyst") echo "refactoring_team:0.1" ;;
        "architect") echo "refactoring_team:0.2" ;;
        "code_reviewer") echo "refactoring_team:0.3" ;;
        # Window2: 実装系エージェント
        "test_designer") echo "refactoring_team:1.0" ;;
        "test_writer") echo "refactoring_team:1.1" ;;
        "tester") echo "refactoring_team:1.2" ;;
        "refactorer") echo "refactoring_team:1.3" ;;
        # 旧エージェント（互換性のため残す）
        "boss1") echo "multiagent:0.0" ;;
        "worker1") echo "multiagent:0.1" ;;
        "worker2") echo "multiagent:0.2" ;;
        "worker3") echo "multiagent:0.3" ;;
        *) echo "" ;;
    esac
}

show_usage() {
    cat << EOF
🔧 リファクタリングエージェント間メッセージ送信

使用方法:
  $0 [エージェント名] [メッセージ]
  $0 --list

リファクタリングエージェント:
  president      - プロジェクト統括責任者
  refactor_pm    - リファクタリングPM
  code_analyst   - コード分析者
  architect      - ソフトウェアアーキテクト
  test_designer  - テスト設計者
  test_writer    - テスト実装者
  tester         - テスト実行者
  refactorer     - リファクタリング実装者
  code_reviewer  - コードレビュアー

使用例:
  $0 refactor_pm "リファクタリングプロジェクトを開始してください"
  $0 code_analyst "技術的負債の分析を開始してください"
  $0 refactorer "コード改善を実行してください"
EOF
}

# エージェント一覧表示
show_agents() {
    echo "📋 利用可能なエージェント:"
    echo "=================================="
    echo "【統括】"
    echo "  president      → president:0          (プロジェクト統括責任者)"
    echo ""
    echo "【リファクタリングチーム - Window1: 管理系】"
    echo "  refactor_pm    → refactoring_team:0.0 (リファクタリングPM)"
    echo "  code_analyst   → refactoring_team:0.1 (コード分析者)"
    echo "  architect      → refactoring_team:0.2 (ソフトウェアアーキテクト)"
    echo "  code_reviewer  → refactoring_team:0.3 (コードレビュアー)"
    echo ""
    echo "【リファクタリングチーム - Window2: 実装系】"
    echo "  test_designer  → refactoring_team:1.0 (テスト設計者)"
    echo "  test_writer    → refactoring_team:1.1 (テスト実装者)"
    echo "  tester         → refactoring_team:1.2 (テスト実行者)"
    echo "  refactorer     → refactoring_team:1.3 (リファクタリング実装者)"
}

# ログ記録
log_send() {
    local agent="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    mkdir -p logs
    echo "[$timestamp] $agent: SENT - \"$message\"" >> logs/send_log.txt
}

# メッセージ送信
send_message() {
    local target="$1"
    local message="$2"
    
    echo "📤 送信中: $target ← '$message'"
    
    # Claude Codeのプロンプトを一度クリア
    tmux send-keys -t "$target" C-c
    sleep 0.3
    
    # メッセージ送信
    tmux send-keys -t "$target" "$message"
    sleep 0.1
    
    # エンター押下
    tmux send-keys -t "$target" C-m
    sleep 0.5
}

# ターゲット存在確認
check_target() {
    local target="$1"
    local session_name="${target%%:*}"
    
    if ! tmux has-session -t "$session_name" 2>/dev/null; then
        echo "❌ セッション '$session_name' が見つかりません"
        return 1
    fi
    
    return 0
}

# メイン処理
main() {
    if [[ $# -eq 0 ]]; then
        show_usage
        exit 1
    fi
    
    # --listオプション
    if [[ "$1" == "--list" ]]; then
        show_agents
        exit 0
    fi
    
    if [[ $# -lt 2 ]]; then
        show_usage
        exit 1
    fi
    
    local agent_name="$1"
    local message="$2"
    
    # エージェントターゲット取得
    local target
    target=$(get_agent_target "$agent_name")
    
    if [[ -z "$target" ]]; then
        echo "❌ エラー: 不明なエージェント '$agent_name'"
        echo "利用可能エージェント: $0 --list"
        exit 1
    fi
    
    # ターゲット確認
    if ! check_target "$target"; then
        exit 1
    fi
    
    # メッセージ送信
    send_message "$target" "$message"
    
    # ログ記録
    log_send "$agent_name" "$message"
    
    echo "✅ 送信完了: $agent_name に '$message'"
    
    return 0
}

main "$@" 