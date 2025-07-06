#!/bin/bash
# Git Worktree管理スクリプト
# Claudeエージェント用の分離作業環境を作成・管理

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKTREE_ROOT="$PROJECT_ROOT/../worktrees"
LOG_FILE="$PROJECT_ROOT/docs/logs/worktree.log"

# ログ関数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "\033[32m✅ $1\033[0m" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "\033[31m❌ $1\033[0m" | tee -a "$LOG_FILE"
}

log_info() {
    echo -e "\033[34mℹ️ $1\033[0m" | tee -a "$LOG_FILE"
}

# Worktree作成
create_worktree() {
    local agent_name="$1"
    local base_branch="${2:-main}"
    
    if [ -z "$agent_name" ]; then
        log_error "エージェント名が指定されていません"
        return 1
    fi
    
    log_info "Worktree作成開始: $agent_name (ベース: $base_branch)"
    
    # Worktreeディレクトリ作成
    mkdir -p "$WORKTREE_ROOT"
    
    local worktree_path="$WORKTREE_ROOT/$agent_name"
    local branch_name="refactor/$agent_name/$(date +%Y%m%d_%H%M%S)"
    
    # 既存のWorktreeをチェック
    if [ -d "$worktree_path" ]; then
        log_info "既存のWorktreeを削除: $worktree_path"
        remove_worktree "$agent_name"
    fi
    
    # ベースブランチの存在確認
    if ! git rev-parse --verify "$base_branch" &>/dev/null; then
        log_error "ベースブランチが存在しません: $base_branch"
        return 1
    fi
    
    # Worktree作成
    if git worktree add -b "$branch_name" "$worktree_path" "$base_branch"; then
        log_success "Worktree作成成功: $worktree_path"
        
        # Worktree情報の記録
        record_worktree_info "$agent_name" "$worktree_path" "$branch_name" "$base_branch"
        
        # 初期設定
        setup_worktree_environment "$worktree_path" "$agent_name"
        
        echo "$worktree_path"
        return 0
    else
        log_error "Worktree作成失敗: $agent_name"
        return 1
    fi
}

# Worktree情報記録
record_worktree_info() {
    local agent_name="$1"
    local worktree_path="$2"
    local branch_name="$3"
    local base_branch="$4"
    
    local info_file="$PROJECT_ROOT/docs/logs/worktree_info.json"
    
    # JSON形式で情報を記録
    cat > "$info_file" << EOF
{
    "agent_name": "$agent_name",
    "worktree_path": "$worktree_path",
    "branch_name": "$branch_name",
    "base_branch": "$base_branch",
    "created_at": "$(date -Iseconds)",
    "status": "active"
}
EOF
    
    log_info "Worktree情報記録: $info_file"
}

# Worktree環境設定
setup_worktree_environment() {
    local worktree_path="$1"
    local agent_name="$2"
    
    log_info "Worktree環境設定: $agent_name"
    
    cd "$worktree_path"
    
    # エージェント固有の設定ファイル作成
    cat > ".claude_agent" << EOF
AGENT_NAME=$agent_name
WORKTREE_PATH=$worktree_path
CREATED_AT=$(date -Iseconds)
EOF
    
    # Gitconfig設定
    git config user.name "Claude Agent $agent_name"
    git config user.email "claude-$agent_name@refactoring.local"
    
    # リモート追跡設定
    local main_remote=$(git remote | head -1)
    if [ -n "$main_remote" ]; then
        git branch --set-upstream-to="$main_remote/main"
    fi
    
    log_success "Worktree環境設定完了: $agent_name"
}

# Worktree削除
remove_worktree() {
    local agent_name="$1"
    
    if [ -z "$agent_name" ]; then
        log_error "エージェント名が指定されていません"
        return 1
    fi
    
    local worktree_path="$WORKTREE_ROOT/$agent_name"
    
    log_info "Worktree削除開始: $agent_name"
    
    if [ ! -d "$worktree_path" ]; then
        log_info "Worktreeが存在しません: $worktree_path"
        return 0
    fi
    
    # Worktree削除前の状態確認
    cd "$worktree_path"
    
    # 未コミットの変更をチェック
    if ! git diff --quiet || ! git diff --cached --quiet; then
        log_info "未コミットの変更を検出。スタッシュに保存中..."
        git stash push -m "Auto-stash before worktree removal"
    fi
    
    # ブランチ名取得
    local branch_name=$(git branch --show-current)
    
    cd "$PROJECT_ROOT"
    
    # Worktree削除
    if git worktree remove "$worktree_path" --force; then
        log_success "Worktree削除成功: $worktree_path"
        
        # ブランチも削除（確認後）
        if [ -n "$branch_name" ] && [[ "$branch_name" == refactor/* ]]; then
            git branch -D "$branch_name" 2>/dev/null || true
            log_info "ブランチ削除: $branch_name"
        fi
        
        return 0
    else
        log_error "Worktree削除失敗: $agent_name"
        return 1
    fi
}

# Worktree一覧表示
list_worktrees() {
    log_info "Worktree一覧表示"
    
    echo "📋 アクティブなWorktree:"
    git worktree list
    
    echo ""
    echo "📁 エージェント別Worktree:"
    if [ -d "$WORKTREE_ROOT" ]; then
        for dir in "$WORKTREE_ROOT"/*; do
            if [ -d "$dir" ]; then
                local agent_name=$(basename "$dir")
                local branch_name=""
                if [ -f "$dir/.git" ]; then
                    cd "$dir"
                    branch_name=$(git branch --show-current 2>/dev/null || echo "不明")
                    cd "$PROJECT_ROOT"
                fi
                echo "  - $agent_name: $dir (ブランチ: $branch_name)"
            fi
        done
    else
        echo "  Worktreeディレクトリが存在しません"
    fi
}

# Worktree同期
sync_worktree() {
    local agent_name="$1"
    local worktree_path="$WORKTREE_ROOT/$agent_name"
    
    if [ ! -d "$worktree_path" ]; then
        log_error "Worktreeが存在しません: $agent_name"
        return 1
    fi
    
    log_info "Worktree同期開始: $agent_name"
    
    cd "$worktree_path"
    
    # 現在のブランチ確認
    local current_branch=$(git branch --show-current)
    
    # リモートから最新を取得
    git fetch origin
    
    # mainブランチとの差分確認
    local behind_commits=$(git rev-list --count "$current_branch..origin/main" 2>/dev/null || echo "0")
    local ahead_commits=$(git rev-list --count "origin/main..$current_branch" 2>/dev/null || echo "0")
    
    log_info "$agent_name: $behind_commits commits behind, $ahead_commits commits ahead"
    
    # 必要に応じてリベース
    if [ "$behind_commits" -gt 0 ]; then
        log_info "リベース実行中..."
        if git rebase origin/main; then
            log_success "リベース成功"
        else
            log_error "リベース失敗。手動解決が必要です"
            return 1
        fi
    fi
    
    cd "$PROJECT_ROOT"
    log_success "Worktree同期完了: $agent_name"
}

# 全Worktreeのクリーンアップ
cleanup_all_worktrees() {
    log_info "全Worktreeクリーンアップ開始"
    
    if [ ! -d "$WORKTREE_ROOT" ]; then
        log_info "Worktreeディレクトリが存在しません"
        return 0
    fi
    
    for dir in "$WORKTREE_ROOT"/*; do
        if [ -d "$dir" ]; then
            local agent_name=$(basename "$dir")
            log_info "Worktreeクリーンアップ: $agent_name"
            remove_worktree "$agent_name"
        fi
    done
    
    # Worktreeディレクトリも削除
    rmdir "$WORKTREE_ROOT" 2>/dev/null || true
    
    log_success "全Worktreeクリーンアップ完了"
}

# 使用方法表示
show_usage() {
    cat << EOF
Git Worktree管理スクリプト

使用法:
  $0 create <agent_name> [base_branch]    # Worktree作成
  $0 remove <agent_name>                  # Worktree削除
  $0 list                                 # Worktree一覧表示
  $0 sync <agent_name>                    # Worktree同期
  $0 cleanup                              # 全Worktreeクリーンアップ

例:
  $0 create code_analyst main             # code_analyst用Worktree作成
  $0 remove refactorer                    # refactorer用Worktree削除
  $0 sync test_writer                     # test_writer用Worktree同期
  $0 list                                 # 全Worktree一覧
  $0 cleanup                              # 全Worktreeクリーンアップ

注意:
  - Worktreeは $WORKTREE_ROOT に作成されます
  - エージェント名は英数字とアンダースコアのみ使用可能
  - 作業中の変更は自動的にスタッシュされます
EOF
}

# メイン処理
main() {
    local command="$1"
    local agent_name="$2"
    local base_branch="$3"
    
    # ログディレクトリ作成
    mkdir -p "$(dirname "$LOG_FILE")"
    
    case "$command" in
        "create")
            if [ -z "$agent_name" ]; then
                log_error "エージェント名を指定してください"
                show_usage
                exit 1
            fi
            create_worktree "$agent_name" "$base_branch"
            ;;
        "remove")
            if [ -z "$agent_name" ]; then
                log_error "エージェント名を指定してください"
                show_usage
                exit 1
            fi
            remove_worktree "$agent_name"
            ;;
        "list")
            list_worktrees
            ;;
        "sync")
            if [ -z "$agent_name" ]; then
                log_error "エージェント名を指定してください"
                show_usage
                exit 1
            fi
            sync_worktree "$agent_name"
            ;;
        "cleanup")
            echo "全Worktreeをクリーンアップしますか？ (y/N)"
            read -r response
            if [[ "$response" =~ ^[Yy]$ ]]; then
                cleanup_all_worktrees
            else
                log_info "クリーンアップをキャンセルしました"
            fi
            ;;
        "help"|"--help"|"-h"|"")
            show_usage
            ;;
        *)
            log_error "不明なコマンド: $command"
            show_usage
            exit 1
            ;;
    esac
}

# スクリプト実行
cd "$PROJECT_ROOT"
main "$@"