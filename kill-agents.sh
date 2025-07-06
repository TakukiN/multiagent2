#!/bin/bash

# 🛑 AIエージェント終了スクリプト

echo "🛑 AIエージェントセッションを終了します"
echo "========================================"
echo ""

# 現在のセッション一覧表示
echo "📋 現在のtmuxセッション:"
tmux ls 2>/dev/null || echo "  （セッションなし）"
echo ""

# 確認
read -p "本当に全てのエージェントセッションを終了しますか？ (y/N): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "キャンセルしました"
    exit 0
fi

echo ""
echo "🔧 セッションを終了中..."

# 各セッションを終了
if tmux has-session -t multiagent 2>/dev/null; then
    tmux kill-session -t multiagent
    echo "  ✅ multiagentセッション終了"
else
    echo "  ⏭️  multiagentセッションは存在しません"
fi

if tmux has-session -t president 2>/dev/null; then
    tmux kill-session -t president
    echo "  ✅ presidentセッション終了"
else
    echo "  ⏭️  presidentセッションは存在しません"
fi

# 完了ファイルもクリア
rm -f ./tmp/worker*_done.txt 2>/dev/null
echo "  ✅ 完了ファイルをクリア"

echo ""
echo "✅ 全てのエージェントセッションを終了しました"

# その他のセッションも確認
echo ""
echo "📋 残っているセッション:"
remaining_sessions=$(tmux ls 2>/dev/null)
if [ -n "$remaining_sessions" ]; then
    echo "$remaining_sessions"
    echo ""
    read -p "他のセッションも全て終了しますか？ (y/N): " kill_all
    if [[ "$kill_all" =~ ^[Yy]$ ]]; then
        tmux kill-server
        echo "✅ 全てのtmuxセッションを終了しました"
    fi
else
    echo "  （セッションなし）"
fi