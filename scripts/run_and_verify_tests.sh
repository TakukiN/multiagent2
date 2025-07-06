#!/bin/bash
# テスト実行・検証スクリプト
# リファクタリング時の安全性を保証するための統合テスト実行

set -e  # エラー時即座に終了

# 設定
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="$PROJECT_ROOT/docs/logs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
TEST_LOG="$LOG_DIR/test_execution_$TIMESTAMP.log"

# ログディレクトリ作成
mkdir -p "$LOG_DIR"

# ログ関数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$TEST_LOG"
}

log_success() {
    echo -e "\033[32m✅ $1\033[0m" | tee -a "$TEST_LOG"
}

log_error() {
    echo -e "\033[31m❌ $1\033[0m" | tee -a "$TEST_LOG"
}

log_warning() {
    echo -e "\033[33m⚠️ $1\033[0m" | tee -a "$TEST_LOG"
}

log_info() {
    echo -e "\033[34mℹ️ $1\033[0m" | tee -a "$TEST_LOG"
}

# テスト実行前の環境チェック
check_environment() {
    log_info "環境チェック開始"
    
    # Gradleの存在確認
    if ! command -v ./gradlew &> /dev/null; then
        log_error "gradlewが見つかりません"
        return 1
    fi
    
    # Android SDKの確認
    if [ -z "$ANDROID_HOME" ]; then
        log_warning "ANDROID_HOME環境変数が設定されていません"
    fi
    
    # プロジェクトファイルの確認
    if [ ! -f "build.gradle" ] && [ ! -f "build.gradle.kts" ]; then
        log_error "Gradleプロジェクトファイルが見つかりません"
        return 1
    fi
    
    log_success "環境チェック完了"
    return 0
}

# 単体テスト実行
run_unit_tests() {
    log_info "単体テスト実行開始"
    
    # Gradleキャッシュクリア（必要に応じて）
    if [ "$1" == "--clean" ]; then
        log_info "Gradleキャッシュクリア中..."
        ./gradlew clean
    fi
    
    # 単体テスト実行
    log_info "JUnitテスト実行中..."
    if ./gradlew test --no-daemon --stacktrace 2>&1 | tee -a "$TEST_LOG"; then
        log_success "単体テスト実行成功"
        
        # テスト結果の解析
        analyze_unit_test_results
        return 0
    else
        log_error "単体テスト実行失敗"
        return 1
    fi
}

# 単体テスト結果解析
analyze_unit_test_results() {
    log_info "単体テスト結果解析中..."
    
    # JUnit XML結果ファイルを検索
    RESULT_FILES=$(find build -name "TEST-*.xml" 2>/dev/null || true)
    
    if [ -z "$RESULT_FILES" ]; then
        log_warning "テスト結果ファイルが見つかりません"
        return
    fi
    
    # テスト統計の計算
    TOTAL_TESTS=0
    TOTAL_FAILURES=0
    TOTAL_ERRORS=0
    
    for file in $RESULT_FILES; do
        if [ -f "$file" ]; then
            TESTS=$(grep -o 'tests="[0-9]*"' "$file" | cut -d'"' -f2 || echo "0")
            FAILURES=$(grep -o 'failures="[0-9]*"' "$file" | cut -d'"' -f2 || echo "0")
            ERRORS=$(grep -o 'errors="[0-9]*"' "$file" | cut -d'"' -f2 || echo "0")
            
            TOTAL_TESTS=$((TOTAL_TESTS + TESTS))
            TOTAL_FAILURES=$((TOTAL_FAILURES + FAILURES))
            TOTAL_ERRORS=$((TOTAL_ERRORS + ERRORS))
        fi
    done
    
    log_info "単体テスト結果: 実行数=${TOTAL_TESTS}, 失敗=${TOTAL_FAILURES}, エラー=${TOTAL_ERRORS}"
    
    # 結果をJSONで保存
    cat > "$LOG_DIR/unit_test_results_$TIMESTAMP.json" << EOF
{
    "timestamp": "$TIMESTAMP",
    "total_tests": $TOTAL_TESTS,
    "failures": $TOTAL_FAILURES,
    "errors": $TOTAL_ERRORS,
    "success_rate": $(echo "scale=2; ($TOTAL_TESTS - $TOTAL_FAILURES - $TOTAL_ERRORS) * 100 / $TOTAL_TESTS" | bc -l 2>/dev/null || echo "0")
}
EOF
}

# UIテスト実行（Espresso）
run_ui_tests() {
    log_info "UIテスト実行開始"
    
    # エミュレータの起動確認
    if ! check_emulator_running; then
        log_warning "エミュレータが起動していません。UIテストをスキップします"
        return 0
    fi
    
    log_info "Espressoテスト実行中..."
    if ./gradlew connectedAndroidTest --no-daemon --stacktrace 2>&1 | tee -a "$TEST_LOG"; then
        log_success "UIテスト実行成功"
        
        # UIテスト結果の解析
        analyze_ui_test_results
        return 0
    else
        log_error "UIテスト実行失敗"
        return 1
    fi
}

# エミュレータ起動確認
check_emulator_running() {
    if adb devices | grep -q "emulator.*device"; then
        return 0
    else
        return 1
    fi
}

# UIテスト結果解析
analyze_ui_test_results() {
    log_info "UIテスト結果解析中..."
    
    # UIテスト結果をadbから取得（簡易版）
    UI_TEST_RESULT=$(adb shell am instrument -w com.app.test/androidx.test.runner.AndroidJUnitRunner 2>/dev/null | grep "Tests run" || echo "Tests run: 0")
    
    log_info "UIテスト結果: $UI_TEST_RESULT"
    
    # 結果をログに記録
    echo "$UI_TEST_RESULT" >> "$LOG_DIR/ui_test_results_$TIMESTAMP.log"
}

# コードカバレッジ測定
measure_code_coverage() {
    log_info "コードカバレッジ測定開始"
    
    # Jacocoレポート生成
    if ./gradlew jacocoTestReport 2>&1 | tee -a "$TEST_LOG"; then
        log_success "カバレッジレポート生成成功"
        
        # カバレッジ結果の解析
        analyze_coverage_results
    else
        log_warning "カバレッジレポート生成失敗"
    fi
}

# カバレッジ結果解析
analyze_coverage_results() {
    log_info "カバレッジ結果解析中..."
    
    # JacocoレポートXMLファイルを検索
    COVERAGE_XML=$(find build -name "jacocoTestReport.xml" | head -1)
    
    if [ -f "$COVERAGE_XML" ]; then
        # カバレッジ率を抽出（簡易版）
        COVERAGE_RATE=$(grep -o 'covered="[0-9.]*"' "$COVERAGE_XML" | head -1 | cut -d'"' -f2 || echo "0")
        log_info "コードカバレッジ: ${COVERAGE_RATE}%"
        
        # しきい値チェック
        THRESHOLD=80
        if (( $(echo "$COVERAGE_RATE >= $THRESHOLD" | bc -l) )); then
            log_success "カバレッジ基準達成: ${COVERAGE_RATE}% >= ${THRESHOLD}%"
        else
            log_warning "カバレッジ基準未達: ${COVERAGE_RATE}% < ${THRESHOLD}%"
        fi
    else
        log_warning "カバレッジレポートファイルが見つかりません"
    fi
}

# 静的解析実行
run_static_analysis() {
    log_info "静的解析実行開始"
    
    # Detekt実行
    if ./gradlew detekt 2>&1 | tee -a "$TEST_LOG"; then
        log_success "静的解析実行成功"
    else
        log_warning "静的解析で問題が検出されました"
    fi
    
    # Lint実行
    if ./gradlew lint 2>&1 | tee -a "$TEST_LOG"; then
        log_success "Lint実行成功"
    else
        log_warning "Lintで問題が検出されました"
    fi
}

# パフォーマンステスト（簡易版）
run_performance_tests() {
    log_info "パフォーマンステスト実行開始"
    
    # ビルド時間測定
    BUILD_START=$(date +%s)
    ./gradlew assembleDebug &>/dev/null
    BUILD_END=$(date +%s)
    BUILD_TIME=$((BUILD_END - BUILD_START))
    
    log_info "ビルド時間: ${BUILD_TIME}秒"
    
    # APKサイズ測定
    APK_PATH=$(find build -name "*.apk" | head -1)
    if [ -f "$APK_PATH" ]; then
        APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
        log_info "APKサイズ: $APK_SIZE"
    fi
}

# 総合レポート生成
generate_comprehensive_report() {
    local exit_code=$1
    
    log_info "総合レポート生成中..."
    
    cat > "$LOG_DIR/test_summary_$TIMESTAMP.md" << EOF
# 📊 テスト実行総合レポート

## 実行情報
- 実行日時: $(date '+%Y-%m-%d %H:%M:%S')
- プロジェクト: $(basename "$PROJECT_ROOT")
- ブランチ: $(git branch --show-current 2>/dev/null || echo "不明")
- コミット: $(git rev-parse --short HEAD 2>/dev/null || echo "不明")

## 実行結果
$([ $exit_code -eq 0 ] && echo "✅ **成功**" || echo "❌ **失敗**")

## テスト詳細
$(cat "$LOG_DIR/unit_test_results_$TIMESTAMP.json" 2>/dev/null | jq -r '"- 単体テスト: " + (.total_tests | tostring) + "件実行, " + (.failures + .errors | tostring) + "件失敗, 成功率" + (.success_rate | tostring) + "%"' 2>/dev/null || echo "- 単体テスト: 結果不明")

$([ -f "$LOG_DIR/ui_test_results_$TIMESTAMP.log" ] && echo "- UIテスト: $(cat "$LOG_DIR/ui_test_results_$TIMESTAMP.log")" || echo "- UIテスト: 実行なし")

## 品質指標
- コードカバレッジ: $(grep "カバレッジ:" "$TEST_LOG" | tail -1 | cut -d':' -f2 || echo "測定なし")
- 静的解析: $(grep -q "静的解析実行成功" "$TEST_LOG" && echo "問題なし" || echo "要確認")
- Lint: $(grep -q "Lint実行成功" "$TEST_LOG" && echo "問題なし" || echo "要確認")

## パフォーマンス
- ビルド時間: $(grep "ビルド時間:" "$TEST_LOG" | tail -1 | cut -d':' -f2 || echo "測定なし")
- APKサイズ: $(grep "APKサイズ:" "$TEST_LOG" | tail -1 | cut -d':' -f2 || echo "測定なし")

## 次のアクション
$([ $exit_code -eq 0 ] && echo "✅ 全テストパス。リファクタリング作業を継続可能。" || echo "❌ テスト失敗。修正が必要です。")

---
詳細ログ: \`$TEST_LOG\`
EOF

    log_success "総合レポート生成完了: $LOG_DIR/test_summary_$TIMESTAMP.md"
}

# メイン実行関数
main() {
    local run_clean=false
    local run_ui=true
    local run_coverage=true
    local run_static=true
    local run_performance=false
    
    # 引数解析
    while [[ $# -gt 0 ]]; do
        case $1 in
            --clean)
                run_clean=true
                shift
                ;;
            --no-ui)
                run_ui=false
                shift
                ;;
            --no-coverage)
                run_coverage=false
                shift
                ;;
            --no-static)
                run_static=false
                shift
                ;;
            --performance)
                run_performance=true
                shift
                ;;
            --help)
                echo "使用法: $0 [オプション]"
                echo "オプション:"
                echo "  --clean        クリーンビルド実行"
                echo "  --no-ui        UIテストスキップ"
                echo "  --no-coverage  カバレッジ測定スキップ"
                echo "  --no-static    静的解析スキップ"
                echo "  --performance  パフォーマンステスト実行"
                echo "  --help         ヘルプ表示"
                exit 0
                ;;
            *)
                log_error "不明なオプション: $1"
                exit 1
                ;;
        esac
    done
    
    log_info "テスト実行開始"
    log_info "設定: clean=$run_clean, ui=$run_ui, coverage=$run_coverage, static=$run_static, performance=$run_performance"
    
    local exit_code=0
    
    # 環境チェック
    if ! check_environment; then
        exit_code=1
    fi
    
    # 単体テスト実行
    if [ $exit_code -eq 0 ]; then
        if ! run_unit_tests $([ "$run_clean" == "true" ] && echo "--clean"); then
            exit_code=1
        fi
    fi
    
    # UIテスト実行
    if [ $exit_code -eq 0 ] && [ "$run_ui" == "true" ]; then
        if ! run_ui_tests; then
            exit_code=1
        fi
    fi
    
    # カバレッジ測定
    if [ "$run_coverage" == "true" ]; then
        measure_code_coverage
    fi
    
    # 静的解析
    if [ "$run_static" == "true" ]; then
        run_static_analysis
    fi
    
    # パフォーマンステスト
    if [ "$run_performance" == "true" ]; then
        run_performance_tests
    fi
    
    # 総合レポート生成
    generate_comprehensive_report $exit_code
    
    if [ $exit_code -eq 0 ]; then
        log_success "全テスト実行完了"
    else
        log_error "テスト実行失敗"
    fi
    
    exit $exit_code
}

# スクリプト実行
cd "$PROJECT_ROOT"
main "$@"