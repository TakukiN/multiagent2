# 📘 Claudeリファクタリングエージェントシステム 仕様書（v1.0）

---

## 🔖 概要

本システムは、Claude AIを活用した**戦略的かつ安全なコードリファクタリング支援システム**である。
ソースコードを解析し、テスト駆動での品質保証を行いながら、段階的な改善を実行するために複数のAIエージェントが役割分担して協調する。

---

## 🎯 目的

* 既存ソースコードにおける設計的・構造的な技術的負債の除去
* リファクタによる品質改善を**振る舞いを保ったまま実現**
* 修正の透明性・説明可能性を担保
* Claudeによる**TDDループの自動化**

---

## 🧩 構成エージェント

| ロール             | 機能概要                        |
| --------------- | --------------------------- |
| `code_analyst`  | 既存コードを解析し、技術的負債と構造課題を報告     |
| `test_designer` | 現在の振る舞いを守るためのテスト設計（正常系・異常系） |
| `test_writer`   | JUnit/Espresso によるテストコードの実装 |
| `tester`        | テストの実行・確認（グリーン保証）           |
| `architect`     | リファクタ設計・構造改善案を立案            |
| `refactorer`    | テスト通過前提で小さなコード改善を実行         |
| `code_reviewer` | 変更のレビュー、設計原則の遵守確認           |
| `refactor_pm`   | 全体戦略・優先順位・フェーズ管理            |

---

## 📁 ディレクトリ構成（Gitプロジェクト構成）

```
.
├── roles/                         ← Claudeロールごとの起動設定
│   ├── code_analyst/.claude_role
│   ├── test_designer/.claude_role
│   ├── test_writer/.claude_role
│   ├── tester/.claude_role
│   ├── architect/.claude_role
│   ├── refactorer/.claude_role
│   ├── code_reviewer/.claude_role
│   └── refactor_pm/.claude_role
├── instructions/                 ← Claudeが読み込むプロンプト指示書
│   ├── code_analyst.md
│   ├── test_designer.md
│   ├── test_writer.md
│   ├── tester.md
│   ├── architect.md
│   ├── refactorer.md
│   ├── code_reviewer.md
│   └── refactor_pm.md
├── tests/                        ← 自動生成されたテスト群
│   ├── unit/
│   └── ui/
├── docs/                         ← 設計・仕様・ログ
│   ├── specs/
│   │   └── refactor_agent_system.md
│   ├── design/
│   ├── tests/
│   └── logs/
│       ├── refactor_log.md
│       ├── progress_dashboard.md
│       └── test_results.md
├── scripts/
│   ├── create_worktree.sh        ← Claude作業分離用
│   ├── run_and_verify_tests.sh   ← テスト実行+判定
│   └── continuous_test_monitoring.sh ← 継続監視
└── .claude/hooks/init            ← 起動時に自動で指示書・仕様読み込み
```

---

## 📋 機能一覧

| 機能カテゴリ | 機能名       | 概要                               |
| ------ | --------- | -------------------------------- |
| 解析     | コード解析     | 長大関数・責務集中・依存密結合などを抽出し報告          |
| テスト設計  | 振る舞いテスト設計 | 正常系・異常系・境界値テストケースの列挙             |
| テスト自動化 | 単体テスト生成   | ViewModelなどのユニットに対応              |
| テスト自動化 | UIテスト生成   | 画面操作・ボタン有効性などをEspressoで検証        |
| 戦略立案   | リファクタ計画策定 | 構造改善の優先順位・段階設計                   |
| リファクタ  | 小規模改善     | 命名、抽出、構造整理など1単位ずつ変更実施            |
| 検証     | テスト結果判定   | すべての変更がグリーンかを確認・ログ記録             |
| 記録     | ログ出力      | `refactor_log.md` に変更内容・理由・影響を記録 |

---

## 🔁 ワークフロー概要

```
┌────────────┐
│code_analyst│─────────────┐
└────────────┘             │
                           ▼
                     ┌──────────────┐
                     │test_designer │────┐
                     └──────────────┘    │
                                          ▼
                     ┌──────────────┐  ┌────────┐
                     │ test_writer  │  │ tester │
                     └──────────────┘  └────────┘
                            ▼               │
                     ┌────────────┐        ▼
                     │ architect  │─────────────┐
                     └────────────┘             ▼
                     ┌────────────┐        ┌────────────┐
                     │refactorer  │───────▶│code_reviewer│
                     └────────────┘        └────────────┘
                            ▼
                    ┌──────────────┐
                    │refactor_log.md│← 自動記録
                    └──────────────┘
```

---

## ✅ Claude動作ルール（統一指針）

* すべての変更は事前にグリーンなテストが存在する状態でのみ実行可
* Claudeは変更理由・前後コード・影響をすべて Markdown で記録
* `refactor_log.md` への追記は Claude が自動で行う（変更ごと）
* ロール間は `tmux + send-keys` または `Claude hooks` を通じて連携

---

## 🔐 セーフティネット

| 手段             | 内容                                     |
| -------------- | -------------------------------------- |
| テスト自動実行        | `run_and_verify_tests.sh` を Claude が実行 |
| テスト失敗時フック      | `refactorer` が修正中止＆PMに通知               |
| Git worktree分離 | Claudeごとのブランチ環境を分離し競合防止                |
| PRレビュー         | `code_reviewer` が設計的妥当性を確認             |

---

## 🧪 成功条件（Definition of Done）

* 🔹 テストグリーンを維持してリファクタが完了
* 🔹 `docs/logs/refactor_log.md` に全変更記録あり
* 🔹 機能振る舞いに変化なし（UI/ユースケース）
* 🔹 設計図（design/）が更新されている
* 🔹 PMがマージ承認できる状態

---

## 🚀 使用方法

### 1. システム起動
```bash
# Claudeエージェント初期化
./.claude/hooks/init

# エージェント用Worktree作成
./scripts/create_worktree.sh code_analyst main
./scripts/create_worktree.sh refactorer main
```

### 2. リファクタリング実行
```bash
# テスト実行・検証
./scripts/run_and_verify_tests.sh

# 継続的監視開始
./scripts/continuous_test_monitoring.sh 300 &
```

### 3. 品質確認
```bash
# 進捗確認
cat docs/logs/progress_dashboard.md

# ログ確認
tail -f docs/logs/refactor_log.md
```

---

## 💡 拡張構想（v2以降）

* Claude API連携でGitHub PRを自動作成
* リファクタ提案を `design/proposal.md` に自動出力
* チームダッシュボードに `refactor_log.md` をリアルタイム表示

---

*🤖 Generated with Claude Refactoring Agent System v1.0*