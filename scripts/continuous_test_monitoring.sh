#!/bin/bash
# 継続的テスト監視スクリプト
# リファクタリング中の品質を継続的に監視

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="$PROJECT_ROOT/docs/logs"
MONITORING_LOG="$LOG_DIR/monitoring.log"

# 監視間隔（秒）
INTERVAL=${1:-300}  # デフォルト5分

# ログ関数
log_monitor() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [MONITOR] $1" | tee -a "$MONITORING_LOG"
}

# Git変更監視
monitor_git_changes() {
    local last_commit_file="$LOG_DIR/.last_commit"
    local current_commit=$(git rev-parse HEAD 2>/dev/null || echo "")
    
    if [ ! -f "$last_commit_file" ]; then
        echo "$current_commit" > "$last_commit_file"
        return 0
    fi
    
    local last_commit=$(cat "$last_commit_file")
    
    if [ "$current_commit" != "$last_commit" ]; then
        log_monitor "新しいコミット検出: $current_commit"
        echo "$current_commit" > "$last_commit_file"
        return 1  # 変更あり
    fi
    
    return 0  # 変更なし
}

# ファイル変更監視
monitor_file_changes() {
    local watch_file="$LOG_DIR/.file_watch"
    local current_hash=$(find . -name "*.kt" -o -name "*.java" | sort | xargs ls -la | md5sum | cut -d' ' -f1 2>/dev/null || echo "")
    
    if [ ! -f "$watch_file" ]; then
        echo "$current_hash" > "$watch_file"
        return 0
    fi
    
    local last_hash=$(cat "$watch_file")
    
    if [ "$current_hash" != "$last_hash" ]; then
        log_monitor "ソースファイル変更検出"
        echo "$current_hash" > "$watch_file"
        return 1  # 変更あり
    fi
    
    return 0  # 変更なし
}

# 自動テスト実行
auto_run_tests() {
    log_monitor "自動テスト実行開始"
    
    if ./scripts/run_and_verify_tests.sh --no-ui --no-performance; then
        log_monitor "自動テスト実行成功"
        return 0
    else
        log_monitor "自動テスト実行失敗"
        return 1
    fi
}

# アラート送信
send_alert() {
    local message="$1"
    local severity="$2"
    
    log_monitor "アラート: [$severity] $message"
    
    # refactor_pmにアラート送信
    # ./agent-send.sh refactor_pm "【自動監視アラート】$message"
    
    # メール通知（設定されている場合）
    if [ -n "$ALERT_EMAIL" ]; then
        echo "$message" | mail -s "リファクタリング監視アラート" "$ALERT_EMAIL" 2>/dev/null || true
    fi
}

# 品質メトリクス監視
monitor_quality_metrics() {
    log_monitor "品質メトリクス監視開始"
    
    # 最新のテスト結果ファイルを取得
    local latest_test_result=$(ls -t "$LOG_DIR"/unit_test_results_*.json 2>/dev/null | head -1)
    
    if [ -f "$latest_test_result" ]; then
        local success_rate=$(jq -r '.success_rate' "$latest_test_result" 2>/dev/null || echo "0")
        
        log_monitor "現在のテスト成功率: ${success_rate}%"
        
        # 成功率が100%未満の場合アラート
        if (( $(echo "$success_rate < 100" | bc -l 2>/dev/null || echo "1") )); then
            send_alert "テスト成功率低下: ${success_rate}%" "HIGH"
        fi
    fi
}

# ヘルスチェック
health_check() {
    log_monitor "ヘルスチェック実行"
    
    local health_score=100
    
    # プロジェクト構造チェック
    if [ ! -f "build.gradle" ] && [ ! -f "build.gradle.kts" ]; then
        health_score=$((health_score - 20))
        log_monitor "警告: Gradleプロジェクトファイルが見つかりません"
    fi
    
    # Git状態チェック
    if ! git status &>/dev/null; then
        health_score=$((health_score - 10))
        log_monitor "警告: Gitリポジトリに問題があります"
    fi
    
    # ディスク容量チェック
    local disk_usage=$(df . | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "$disk_usage" -gt 90 ]; then
        health_score=$((health_score - 15))
        log_monitor "警告: ディスク使用率が高い: ${disk_usage}%"
    fi
    
    log_monitor "プロジェクトヘルススコア: ${health_score}/100"
    
    if [ "$health_score" -lt 80 ]; then
        send_alert "プロジェクトヘルススコア低下: ${health_score}/100" "MEDIUM"
    fi
}

# メイン監視ループ
main_monitoring_loop() {
    log_monitor "継続的監視開始（間隔: ${INTERVAL}秒）"
    
    while true; do
        # Git変更監視
        if monitor_git_changes; then
            # 変更なし
            :
        else
            # 変更あり - 自動テスト実行
            if ! auto_run_tests; then
                send_alert "Gitコミット後のテスト失敗" "CRITICAL"
            fi
        fi
        
        # ファイル変更監視（Git外の変更）
        if monitor_file_changes; then
            # 変更なし
            :
        else
            # ファイル変更あり
            log_monitor "作業中のファイル変更を検出"
        fi
        
        # 品質メトリクス監視
        monitor_quality_metrics
        
        # ヘルスチェック（1時間に1回）
        local current_minute=$(date +%M)
        if [ "$current_minute" -eq "00" ]; then
            health_check
        fi
        
        # 待機
        sleep "$INTERVAL"
    done
}

# シグナルハンドラ
cleanup() {
    log_monitor "監視終了"
    exit 0
}

trap cleanup SIGTERM SIGINT

# 使用方法表示
show_usage() {
    echo "使用法: $0 [監視間隔（秒）]"
    echo ""
    echo "例:"
    echo "  $0 300    # 5分間隔で監視"
    echo "  $0 60     # 1分間隔で監視"
    echo ""
    echo "環境変数:"
    echo "  ALERT_EMAIL    アラートメール送信先"
    echo ""
    echo "停止: Ctrl+C"
}

# メイン実行
if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
    show_usage
    exit 0
fi

# ログディレクトリ作成
mkdir -p "$LOG_DIR"

cd "$PROJECT_ROOT"

log_monitor "監視システム起動"
main_monitoring_loop