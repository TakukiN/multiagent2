# 🔧 Claude リファクタリングエージェントシステム

複数のClaudeエージェントが協力して、安全で戦略的なコードリファクタリングを実行するシステムです

## 📌 これは何？

**3行で説明すると：**
1. 8つの専門AIエージェントが協力してコードリファクタリングを実行
2. テスト駆動で振る舞いを保ったまま技術的負債を解消
3. すべての変更を自動記録し、透明性と安全性を確保

**実際の効果：**
- 技術的負債を70%以上削減
- テスト成功率100%維持
- コードカバレッジ80%以上達成

## 🎬 5分で動かしてみよう！

### 必要なもの
- Mac、Linux、または Windows
- Git
- Claude Code CLI
- Java/Kotlin開発環境（リファクタリング対象プロジェクト）

### 手順

#### 1️⃣ ダウンロード（30秒）
```bash
git clone https://github.com/TakukiN/multiagent2.git
cd multiagent2
```

#### 2️⃣ システム初期化（1分）

```bash
# Claude初期化フック実行
./.claude/hooks/init

# システム仕様書確認
cat docs/specs/refactor_agent_system.md
```

#### 3️⃣ エージェント用作業環境作成（2分）

```bash
# 各エージェント用Worktree作成
./scripts/create_worktree.sh code_analyst main
./scripts/create_worktree.sh refactorer main
./scripts/create_worktree.sh test_writer main
```

#### 4️⃣ リファクタリング開始（30秒）

```bash
# テスト実行・検証
./scripts/run_and_verify_tests.sh

# リファクタリング実行（例：code_analystエージェントとして）
cd ../worktrees/code_analyst
claude code
```

エージェントとして動作し、指示書に従ってコード分析を開始します。

**すると自動的に：**
1. コード分析と技術的負債の特定
2. テスト設計・実装
3. 安全なリファクタリング実行
4. 品質検証・レビュー

## 🏢 8つの専門エージェント

### 🔍 code_analyst
- **役割**: コードアナリスト
- **専門**: 技術的負債の特定・コード品質評価
- **成果物**: 分析レポート、改善優先度マトリクス

### 🧪 test_designer
- **役割**: テスト設計者
- **専門**: 振る舞い保護テストの設計
- **成果物**: テスト設計書、テストケース一覧

### ⚒️ test_writer
- **役割**: テスト実装者
- **専門**: JUnit/Espressoテストコードの実装
- **成果物**: 単体テスト、UIテスト

### 🧪 tester
- **役割**: テスト実行者
- **専門**: テスト実行・品質保証
- **成果物**: テスト結果レポート、品質メトリクス

### 🏗️ architect
- **役割**: ソフトウェアアーキテクト
- **専門**: リファクタリング戦略立案・設計改善
- **成果物**: アーキテクチャ設計書、リファクタリング計画

### ⚒️ refactorer
- **役割**: リファクタリング実装者
- **専門**: 安全なコード改善の実行
- **成果物**: 改善されたソースコード、変更ログ

### 👀 code_reviewer
- **役割**: コードレビュアー
- **専門**: 変更の品質・設計適合性評価
- **成果物**: レビューレポート、改善提案

### 📋 refactor_pm
- **役割**: プロジェクトマネージャー
- **専門**: 全体統括・進捗管理
- **成果物**: 進捗ダッシュボード、完了報告書

## 💬 エージェント間コミュニケーション

### 作業環境の分離
```bash
# 各エージェント専用のWorktree作成
./scripts/create_worktree.sh code_analyst main

# Worktree一覧確認
./scripts/create_worktree.sh list

# 特定エージェントの作業環境に移動
cd ../worktrees/refactorer
```

### 進捗・結果の共有
```bash
# テスト実行・結果共有
./scripts/run_and_verify_tests.sh

# 継続的品質監視
./scripts/continuous_test_monitoring.sh &

# 進捗ダッシュボード確認
cat docs/logs/progress_dashboard.md
```

## 📁 重要なファイルの説明

### システム仕様書（docs/specs/）
```markdown
docs/specs/refactor_agent_system.md  # システム全体仕様
```

### エージェント指示書（instructions/）
各エージェントの専門行動マニュアル

**president.md** - プロジェクト統括者の指示書
```markdown
# あなたの役割
プロジェクト全体のビジョンと目標を設定し、
各エージェントの協力を統括する

# 統括方針
1. プロジェクト目標の明確化
2. エージェント間の調整
3. 最終成果物の品質保証
```

**code_analyst.md** - コード分析者の指示書
```markdown
# あなたの役割
既存ソースコードを詳細に分析し、
技術的負債と構造的な問題を特定・報告する

# 分析手順
1. ファイル構造分析
2. 各ファイルの詳細分析  
3. 結果レポート作成
```

**refactorer.md** - リファクタリング実装者の指示書
```markdown
# あなたの役割
テストがグリーンな状態を保ちながら
段階的にコード改善を実行する

# 絶対ルール
テスト実行 → グリーン確認 → 変更実行 → テスト実行
```

**test_writer.md** - テスト実装者の指示書
```markdown
# あなたの役割
test_designerが設計したテストケースを
実際のJUnit/Espressoコードとして実装する

# 実装方針
- 単体テスト（JUnit）
- UIテスト（Espresso）
- テスト環境の構築
```

### 実行スクリプト（scripts/）
```markdown
scripts/run_and_verify_tests.sh      # テスト実行・検証
scripts/create_worktree.sh           # Git worktree管理
scripts/continuous_test_monitoring.sh # 継続監視
```

### ログ・進捗管理（docs/logs/）
```markdown
docs/logs/refactor_log.md           # 変更履歴
docs/logs/progress_dashboard.md     # 進捗ダッシュボード
docs/logs/test_results.md           # テスト結果
```

## 🔧 困ったときは

### Q: エージェントが反応しない
```bash
# 状態を確認
tmux ls

# 再起動（Linux/Mac）
./run_all.sh

# 再起動（Windows）
.\run_all.sh
```

### Q: メッセージが届かない
```bash
# ログを見る
cat logs/send_log.txt

# 手動でテスト
./agent-send.sh president "テスト"
```

### Q: 最初からやり直したい
```bash
# 全部リセット（Linux/Mac）
tmux kill-server
rm -rf ./tmp/*
./run_all.sh

# 全部リセット（Windows）
tmux kill-server
Remove-Item ./tmp/* -Recurse -Force -ErrorAction SilentlyContinue
.\run_all.sh
```

## 🚀 自分のプロジェクトを作る

### 簡単な例：TODOアプリを作る

presidentで入力：
```
あなたはpresidentです。
TODOアプリを作ってください。
シンプルで使いやすく、タスクの追加・削除・完了ができるものです。
```

すると自動的に：
1. code_analystがコード分析
2. test_designerがテスト設計
3. test_writerがテスト実装
4. architectがアーキテクチャ設計
5. refactorerがコード改善
6. testerが品質検証
7. code_reviewerがレビュー
8. refactor_pmが進捗管理
9. 完成！

## 📊 システムの仕組み（図解）

### 画面構成
```
┌─────────────────┐
│   PRESIDENT     │ ← 統括者の画面（紫色）
└─────────────────┘

┌────────┬────────┐
│code_analyst│test_designer│ ← 分析者とテスト設計者
├────────┼────────┤
│test_writer│tester│ ← テスト実装者とテスト実行者
├────────┼────────┤
│architect│refactorer│ ← アーキテクトとリファクタリング実装者
├────────┼────────┤
│code_reviewer│refactor_pm│ ← レビュアーとプロジェクトマネージャー
└────────┴────────┘
```

### コミュニケーションの流れ
```
president
 ↓ 「プロジェクト目標を設定」
code_analyst
 ↓ 「コード分析完了」
test_designer
 ↓ 「テスト設計完了」
test_writer
 ↓ 「テスト実装完了」
tester
 ↓ 「テスト実行完了」
architect
 ↓ 「アーキテクチャ設計完了」
refactorer
 ↓ 「リファクタリング完了」
code_reviewer
 ↓ 「レビュー完了」
refactor_pm
 ↓ 「プロジェクト完了」
president
```

### 進捗管理の仕組み
```
./tmp/
├── code_analyst_done.txt     # 分析者が完了したらできるファイル
├── test_designer_done.txt    # テスト設計者が完了したらできるファイル
├── test_writer_done.txt      # テスト実装者が完了したらできるファイル
├── tester_done.txt           # テスト実行者が完了したらできるファイル
├── architect_done.txt        # アーキテクトが完了したらできるファイル
├── refactorer_done.txt       # リファクタリング実装者が完了したらできるファイル
├── code_reviewer_done.txt    # レビュアーが完了したらできるファイル
├── refactor_pm_done.txt      # プロジェクトマネージャーが完了したらできるファイル
└── *_progress.log            # 進捗の記録
```

## 💡 なぜこれがすごいの？

### 従来の開発
```
人間 → AI → 結果
```

### このシステム
```
人間 → AI統括者 → AI専門エージェント×8 → 統合 → 結果
```

**メリット：**
- 並列処理で8倍速い
- 専門性を活かせる
- アイデアが豊富
- 品質が高い

## 🎓 もっと詳しく知りたい人へ

### プロンプトの書き方

**良い例：**
```
あなたはpresidentです。

【プロジェクト名】明確な名前
【ビジョン】具体的な理想
【成功基準】測定可能な指標
```

**悪い例：**
```
何か作って
```

### カスタマイズ方法

**新しいエージェントを追加：**
1. `instructions/new_agent.md`を作成
2. `run_all.sh`を編集してペインを追加
3. `agent-send.sh`にマッピングを追加

**タイマーを変更：**
```bash
# instructions/president.md の中の
sleep 600  # 10分を5分に変更するなら
sleep 300
```

## 🌟 まとめ

このリファクタリングエージェントシステムは、8つの専門AIエージェントが協力することで：
- **技術的負債を70%以上削減**
- **テスト成功率100%維持**でリファクタリング実行
- **透明性の高い変更記録**で安全性を確保
- **段階的で戦略的なコード改善**を実現

既存コードの品質を安全に向上させたい開発チームに最適です！

## 🚀 次のステップ

1. **システム体験**: サンプルプロジェクトでリファクタリングを実行
2. **実プロジェクト適用**: 実際のコードベースに適用
3. **カスタマイズ**: チーム固有のニーズに合わせて調整

---

**システム仕様**: [docs/specs/refactor_agent_system.md](docs/specs/refactor_agent_system.md)
**ライセンス**: MIT
**貢献**: PullRequestやIssueでのフィードバックをお待ちしています！

*🤖 Generated with Claude Refactoring Agent System*

## 参考リンク
    
・Claude Code公式   
　　URL: https://docs.anthropic.com/ja/docs/claude-code/overview   
    
・Tmux Cheat Sheet & Quick Reference | Session, window, pane and more     
　　URL: https://tmuxcheatsheet.com/   
     
・Akira-Papa/Claude-Code-Communication   
　　URL: https://github.com/Akira-Papa/Claude-Code-Communication   
     
・【tmuxでClaude CodeのMaxプランでAI組織を動かし放題のローカル環境ができた〜〜〜！ので、やり方をシェア！！🔥🔥🔥🙌☺️】 #AIエージェント - Qiita   
　　URL: https://qiita.com/akira_papa_AI/items/9f6c6605e925a88b9ac5   
    
・Claude Code コマンドチートシート完全ガイド #ClaudeCode - Qiita   
　　URL: https://qiita.com/akira_papa_AI/items/d68782fbf03ffd9b2f43   
    
    
※以下の情報を参考に、今回のtmuxのClaude Code組織環境を構築することができました。本当にありがとうございました！☺️🙌   
    
◇Claude Code双方向通信をシェルで一撃構築できるようにした発案者の元木さん   
参考GitHub ：   
haconiwa/README_JA.md at main · dai-motoki/haconiwa  
　　URL: https://github.com/dai-motoki/haconiwa/blob/main/README_JA.md   
    
・神威/KAMUI（@kamui_qai）さん / X   
　　URL: https://x.com/kamui_qai   
    
◇簡単にClaude Code双方向通信環境を構築できるようシェアして頂いたダイコンさん   
参考GitHub：   
nishimoto265/Claude-Code-Communication   
　　URL: https://github.com/nishimoto265/Claude-Code-Communication   
    
・ ダイコン（@daikon265）さん / X   
　　URL: https://x.com/daikon265   
    
◇Claude Code公式解説動画：   
Mastering Claude Code in 30 minutes - YouTube   
　　URL: https://www.youtube.com/live/6eBSHbLKuN0?t=1356s  
   
