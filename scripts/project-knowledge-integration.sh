#!/bin/bash
# プロジェクト固有ナレッジ蓄積促進スクリプト
# Claude Codeの作業完了時に自動実行されるナレッジ統合システム

set -e

# パス設定
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
KNOWLEDGE_SCRIPT="$PROJECT_ROOT/.claude/scripts/auto-knowledge.sh"

# カラー設定
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[ナレッジ統合]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[保存完了]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[注意]${NC} $1"
}

log_error() {
    echo -e "${RED}[エラー]${NC} $1"
}

# ナレッジスクリプトの読み込み
if [[ -f "$KNOWLEDGE_SCRIPT" ]]; then
    source "$KNOWLEDGE_SCRIPT"
else
    log_error "auto-knowledge.shが見つかりません: $KNOWLEDGE_SCRIPT"
    exit 1
fi

# 作業ログからナレッジを抽出・保存
extract_and_save_work_knowledge() {
    local work_log="$1"
    local work_context="$2"
    
    log_info "作業ログからナレッジを抽出中..."
    
    # 作業タイプの推定
    local work_type="analysis"
    if echo "$work_log" | grep -qi -E "(implement|code|function|class|method)"; then
        work_type="implementation"
    elif echo "$work_log" | grep -qi -E "(debug|fix|error|bug|problem)"; then
        work_type="debugging"
    elif echo "$work_log" | grep -qi -E "(config|setting|setup|install)"; then
        work_type="configuration"
    elif echo "$work_log" | grep -qi -E "(test|spec|verify)"; then
        work_type="testing"
    fi
    
    # 作業対象の抽出
    local work_target="project-work"
    if [[ -n "$work_context" ]]; then
        work_target="$work_context"
    fi
    
    # 自動ナレッジ保存実行
    auto_save_work_knowledge "$work_type" "$work_target" "$work_log" "作業完了" "$work_context"
    log_success "作業ナレッジを保存しました"
}

# 問題解決ログからパターンを抽出
extract_problem_solution_pattern() {
    local problem_description="$1"
    local solution_description="$2"
    local context="$3"
    
    if [[ -n "$problem_description" && -n "$solution_description" ]]; then
        log_info "問題解決パターンを抽出中..."
        auto_save_problem_solution "$problem_description" "$solution_description" "$context" ""
        log_success "問題解決パターンを保存しました"
    fi
}

# 実装パターンの抽出・保存
extract_implementation_pattern() {
    local pattern_description="$1"
    local use_case="$2"
    local implementation_details="$3"
    
    if [[ -n "$pattern_description" && -n "$implementation_details" ]]; then
        log_info "実装パターンを抽出中..."
        
        # パターン名の生成
        local pattern_name=$(echo "$pattern_description" | head -c 30 | sed 's/[^a-zA-Z0-9 ]//g' | tr ' ' '-')
        
        auto_save_implementation_pattern "$pattern_name" "$use_case" "$implementation_details" "プロジェクト固有の実装パターン" "プロジェクト依存の実装"
        log_success "実装パターンを保存しました: $pattern_name"
    fi
}

# ファイル変更履歴からナレッジを推測
analyze_file_changes() {
    local changed_files="$1"
    
    if [[ -z "$changed_files" ]]; then
        return 0
    fi
    
    log_info "ファイル変更からナレッジパターンを分析中..."
    
    # ファイルタイプ別の分析
    local config_changes=""
    local code_changes=""
    local test_changes=""
    
    for file in $changed_files; do
        if echo "$file" | grep -qi -E "\.(json|yaml|yml|properties|env|config)$"; then
            config_changes="$config_changes $file"
        elif echo "$file" | grep -qi -E "\.(test|spec)\.|test/|spec/"; then
            test_changes="$test_changes $file"
        elif echo "$file" | grep -qi -E "\.(js|ts|py|java|go|rs|cpp|c)$"; then
            code_changes="$code_changes $file"
        fi
    done
    
    # 設定変更パターンの保存
    if [[ -n "$config_changes" ]]; then
        auto_save_work_knowledge "configuration" "config-files" "設定ファイルの変更: $config_changes" "設定更新完了" "$config_changes"
    fi
    
    # コード変更パターンの保存
    if [[ -n "$code_changes" ]]; then
        auto_save_work_knowledge "implementation" "source-code" "ソースコード変更: $code_changes" "実装完了" "$code_changes"
    fi
    
    # テスト変更パターンの保存
    if [[ -n "$test_changes" ]]; then
        auto_save_work_knowledge "testing" "test-code" "テストコード変更: $test_changes" "テスト更新完了" "$test_changes"
    fi
}

# プロジェクト固有のナレッジ統計表示
show_knowledge_stats() {
    log_info "プロジェクト固有ナレッジ統計"
    
    local patterns_dir="$PROJECT_ROOT/.claude/knowledge/patterns"
    local lessons_dir="$PROJECT_ROOT/.claude/knowledge/lessons"
    
    if [[ -d "$patterns_dir" ]]; then
        local pattern_count=$(find "$patterns_dir" -name "*.md" -type f | wc -l)
        echo "  パターン数: $pattern_count"
        
        # 最近の追加
        local recent_patterns=$(find "$patterns_dir" -name "*.md" -type f -mtime -1 | wc -l)
        echo "  24時間以内の追加: $recent_patterns"
    fi
    
    if [[ -d "$lessons_dir" ]]; then
        local lesson_count=$(find "$lessons_dir" -name "*.md" -type f | wc -l)
        echo "  学習記録数: $lesson_count"
    fi
}

# 統合実行モード
integrate_work_session() {
    local work_summary="$1"
    local changed_files="$2"
    local problem_context="$3"
    local solution_context="$4"
    
    log_info "作業セッションのナレッジ統合を開始"
    
    # 1. 作業サマリからナレッジ抽出
    if [[ -n "$work_summary" ]]; then
        extract_and_save_work_knowledge "$work_summary" "$changed_files"
    fi
    
    # 2. ファイル変更の分析
    if [[ -n "$changed_files" ]]; then
        analyze_file_changes "$changed_files"
    fi
    
    # 3. 問題解決パターンの抽出
    if [[ -n "$problem_context" && -n "$solution_context" ]]; then
        extract_problem_solution_pattern "$problem_context" "$solution_context" "プロジェクト作業中"
    fi
    
    # 4. 統計表示
    show_knowledge_stats
    
    log_success "ナレッジ統合が完了しました"
}

# メイン実行
main() {
    case "${1:-help}" in
        "work")
            extract_and_save_work_knowledge "$2" "$3"
            ;;
        "problem")
            extract_problem_solution_pattern "$2" "$3" "$4"
            ;;
        "pattern")
            extract_implementation_pattern "$2" "$3" "$4"
            ;;
        "files")
            analyze_file_changes "$2"
            ;;
        "session")
            integrate_work_session "$2" "$3" "$4" "$5"
            ;;
        "stats")
            show_knowledge_stats
            ;;
        *)
            echo "プロジェクト固有ナレッジ蓄積システム"
            echo ""
            echo "使用方法:"
            echo "  $0 work <作業内容> [関連ファイル]     # 作業ナレッジ保存"
            echo "  $0 problem <問題> <解決法> [文脈]     # 問題解決パターン保存"
            echo "  $0 pattern <パターン> <用途> <実装>   # 実装パターン保存" 
            echo "  $0 files <変更ファイル一覧>           # ファイル変更分析"
            echo "  $0 session <サマリ> <ファイル> <問題> <解決> # 統合実行"
            echo "  $0 stats                              # ナレッジ統計表示"
            ;;
    esac
}

main "$@"