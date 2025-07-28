#!/bin/bash
# Claude Code 自動保存システム - コア統合スクリプト
# 用途: 各カスタムコマンドから呼び出される統合エントリーポイント
# 作成者: Claude Code Auto-Save System

# スクリプトディレクトリの取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 依存スクリプトの読み込み
source "$SCRIPT_DIR/file-classifier.sh" || {
    echo "エラー: file-classifier.sh が読み込めません" >&2
    exit 1
}

source "$SCRIPT_DIR/document-saver.sh" || {
    echo "エラー: document-saver.sh が読み込めません" >&2
    exit 1
}

source "$SCRIPT_DIR/notifier.sh" || {
    echo "エラー: notifier.sh が読み込めません" >&2
    exit 1
}

# デバッグフラグ
DEBUG_AUTO_SAVE=${DEBUG_AUTO_SAVE:-false}

# ログ関数
log_auto_save() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    if [[ "$DEBUG_AUTO_SAVE" == "true" ]]; then
        echo "[$timestamp] [$level] [auto-save-core] $message" >&2
    fi
    
    # 統合ログファイルにも記録
    local log_file="$HOME/.claude/logs/auto-save.log"
    mkdir -p "$(dirname "$log_file")"
    echo "[$timestamp] [$level] [auto-save-core] $message" >> "$log_file"
}

# システム初期化チェック
check_system_requirements() {
    local errors=0
    
    log_auto_save "INFO" "システム要件チェック開始"
    
    # 必要なディレクトリの存在確認
    local required_dirs=(
        "$HOME/Documents/claude-outputs"
        "$HOME/.claude/logs"
        "$HOME/.claude/stats"
    )
    
    for dir in "${required_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir" 2>/dev/null
            if [[ $? -eq 0 ]]; then
                log_auto_save "INFO" "ディレクトリ作成: $dir"
            else
                log_auto_save "ERROR" "ディレクトリ作成に失敗: $dir"
                ((errors++))
            fi
        fi
    done
    
    # ファイル書き込み権限の確認
    local test_file="$HOME/Documents/claude-outputs/.write-test"
    echo "test" > "$test_file" 2>/dev/null
    if [[ $? -eq 0 ]]; then
        rm -f "$test_file"
        log_auto_save "DEBUG" "書き込み権限OK"
    else
        log_auto_save "ERROR" "書き込み権限がありません: $HOME/Documents/claude-outputs/"
        ((errors++))
    fi
    
    # 依存コマンドの確認
    local required_commands=("date" "mkdir" "basename" "dirname")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            log_auto_save "ERROR" "必要なコマンドが見つかりません: $cmd"
            ((errors++))
        fi
    done
    
    if [[ $errors -eq 0 ]]; then
        log_auto_save "INFO" "システム要件チェック完了（問題なし）"
        return 0
    else
        log_auto_save "ERROR" "システム要件チェック失敗（$errors 個のエラー）"
        return 1
    fi
}

# 設定の初期化
initialize_auto_save_config() {
    local config_file="$HOME/.claude-config.yml"
    
    # 設定ファイルが存在しない場合のデフォルト作成
    if [[ ! -f "$config_file" ]]; then
        log_auto_save "INFO" "デフォルト設定ファイル作成: $config_file"
        
        cat > "$config_file" << 'EOF'
# Claude Code 自動保存システム設定ファイル
auto_save:
  enabled: true
  documents_path: "~/Documents/claude-outputs"
  session_integration: true
  notifications: true
  viewer_integration: true
  
  classification:
    knowledge_keywords: ["pattern", "technique", "guide", "best-practice"]
    document_keywords: ["design", "investigation", "report", "specification"]
    command_defaults:
      design: "document"
      implement: "knowledge"
      fix-test: "knowledge"
      next-steps: "document"
      pr: "document"

# 通知設定
notifications:
  macos_notifications: true
  sound_enabled: false
  
# ビューアー連携設定
viewer:
  enabled: true
  host: "localhost"
  port: 3333
  
# 保持期間設定
retention:
  document_days: 30
  log_days: 7
  stats_days: 90
EOF
    fi
}

# メイン自動保存処理関数
auto_save_generated_file() {
    local file_path="$1"
    local content="$2"
    local command_context="$3"
    local additional_metadata="$4"
    
    log_auto_save "INFO" "自動保存処理開始: $(basename "$file_path") (command: $command_context)"
    
    # 引数チェック
    if [[ -z "$file_path" || -z "$content" ]]; then
        log_auto_save "ERROR" "必須引数が不足: file_path=$file_path, content_length=${#content}"
        return 1
    fi
    
    # システム要件チェック
    if ! check_system_requirements; then
        log_auto_save "ERROR" "システム要件チェックに失敗しました"
        return 1
    fi
    
    # 統計データの記録開始
    local start_time=$(date +%s)
    
    # ファイル分類の実行
    log_auto_save "DEBUG" "ファイル分類開始"
    local classification=$(classify_file "$file_path" "$content" "$command_context")
    
    if [[ $? -ne 0 || -z "$classification" ]]; then
        log_auto_save "ERROR" "ファイル分類に失敗しました"
        return 1
    fi
    
    log_auto_save "INFO" "分類結果: $classification"
    
    # 分類に基づく処理の分岐
    case "$classification" in
        "knowledge")
            handle_knowledge_file "$file_path" "$content" "$command_context" "$additional_metadata"
            ;;
        "document")
            handle_document_file "$file_path" "$content" "$command_context" "$additional_metadata"
            ;;
        *)
            log_auto_save "WARN" "未知の分類: $classification - ドキュメントとして処理します"
            handle_document_file "$file_path" "$content" "$command_context" "$additional_metadata"
            ;;
    esac
    
    local save_result=$?
    
    # 統計データの記録
    local end_time=$(date +%s)
    local processing_time=$((end_time - start_time))
    record_processing_stats "$file_path" "$classification" "$command_context" "$processing_time" "$save_result"
    
    if [[ $save_result -eq 0 ]]; then
        log_auto_save "INFO" "自動保存処理完了: $(basename "$file_path") (${processing_time}秒)"
    else
        log_auto_save "ERROR" "自動保存処理に失敗: $(basename "$file_path")"
    fi
    
    return $save_result
}

# ナレッジファイルの処理
handle_knowledge_file() {
    local file_path="$1"
    local content="$2"
    local command_context="$3"
    local additional_metadata="$4"
    
    log_auto_save "INFO" "ナレッジファイル処理: $(basename "$file_path")"
    
    # 既存のナレッジ管理システムに委譲
    # 注意: 実際の実装では既存のナレッジ保存ロジックを呼び出す
    local knowledge_dir="$HOME/workspace/cc-knowledge/docs/knowledge"
    
    if [[ -d "$knowledge_dir" ]]; then
        # ナレッジファイルとして保存
        local knowledge_file="$knowledge_dir/$(basename "$file_path")"
        echo "$content" > "$knowledge_file"
        
        if [[ $? -eq 0 ]]; then
            log_auto_save "INFO" "ナレッジファイル保存完了: $knowledge_file"
            
            # INDEXファイルの更新（簡易版）
            update_knowledge_index "$knowledge_file" "$command_context"
            
            return 0
        else
            log_auto_save "ERROR" "ナレッジファイル保存に失敗: $knowledge_file"
            return 1
        fi
    else
        log_auto_save "WARN" "ナレッジディレクトリが存在しません: $knowledge_dir"
        # ドキュメントファイルとして処理
        handle_document_file "$file_path" "$content" "$command_context" "$additional_metadata"
        return $?
    fi
}

# ドキュメントファイルの処理
handle_document_file() {
    local file_path="$1"
    local content="$2"
    local command_context="$3"
    local additional_metadata="$4"
    
    log_auto_save "INFO" "ドキュメントファイル処理: $(basename "$file_path")"
    
    # ドキュメント保存システムの呼び出し
    save_document "$file_path" "$content" "$additional_metadata" "$command_context"
    
    return $?
}

# ナレッジINDEXの更新
update_knowledge_index() {
    local knowledge_file="$1"
    local command_context="$2"
    
    local index_file="$HOME/workspace/cc-knowledge/docs/knowledge/INDEX.md"
    local filename=$(basename "$knowledge_file")
    
    if [[ -f "$index_file" ]] && ! grep -q "$filename" "$index_file"; then
        echo "- [$filename]($filename) - $(date '+%Y-%m-%d') 追加" >> "$index_file"
        log_auto_save "DEBUG" "ナレッジINDEX更新完了"
    fi
}

# 処理統計の記録
record_processing_stats() {
    local file_path="$1"
    local classification="$2"
    local command_context="$3"
    local processing_time="$4"
    local result="$5"
    
    local stats_file="$HOME/.claude/stats/auto-save-stats.log"
    local timestamp=$(date -Iseconds)
    local filename=$(basename "$file_path")
    local file_size=$(echo -n "$content" | wc -c 2>/dev/null || echo "0")
    
    echo "$timestamp,$command_context,$classification,$filename,$file_size,$processing_time,$result" >> "$stats_file"
}

# 一括処理機能
auto_save_multiple_files() {
    local command_context="$1"
    shift
    local files=("$@")
    
    log_auto_save "INFO" "一括自動保存開始: ${#files[@]} ファイル"
    
    local success_count=0
    local failure_count=0
    local saved_files=()
    
    for file_info in "${files[@]}"; do
        # file_info は "path|content" の形式を想定
        IFS='|' read -r file_path content <<< "$file_info"
        
        if auto_save_generated_file "$file_path" "$content" "$command_context"; then
            ((success_count++))
            saved_files+=("$file_path")
        else
            ((failure_count++))
        fi
    done
    
    log_auto_save "INFO" "一括自動保存完了: 成功 $success_count, 失敗 $failure_count"
    
    # 一括通知
    if [[ ${#saved_files[@]} -gt 1 ]]; then
        notify_multiple_documents "${#saved_files[@]}" "${saved_files[@]}"
    fi
    
    return $failure_count
}

# システム状態の確認
check_auto_save_status() {
    echo "=== Claude Code 自動保存システム状態 ==="
    echo ""
    
    # 設定状況
    echo "## 設定状況"
    local config_file="$HOME/.claude-config.yml"
    if [[ -f "$config_file" ]]; then
        echo "設定ファイル: 存在 ($config_file)"
        if grep -q "enabled: true" "$config_file"; then
            echo "自動保存: 有効"
        else
            echo "自動保存: 無効"
        fi
    else
        echo "設定ファイル: 存在しない"
    fi
    
    echo ""
    
    # ディレクトリ状況
    echo "## ディレクトリ状況"
    local dirs=(
        "Documents/claude-outputs:Claude Outputs"
        "workspace/cc-knowledge/docs/knowledge:ナレッジベース"
        ".claude/logs:ログ"
        ".claude/stats:統計"
    )
    
    for dir_info in "${dirs[@]}"; do
        IFS=':' read -r dir_path dir_name <<< "$dir_info"
        local full_path="$HOME/$dir_path"
        
        if [[ -d "$full_path" ]]; then
            local file_count=$(find "$full_path" -type f | wc -l)
            echo "$dir_name: 存在 ($file_count ファイル)"
        else
            echo "$dir_name: 存在しない"
        fi
    done
    
    echo ""
    
    # 最近のアクティビティ
    echo "## 最近のアクティビティ"
    local stats_file="$HOME/.claude/stats/auto-save-stats.log"
    if [[ -f "$stats_file" ]]; then
        local recent_count=$(tail -n 10 "$stats_file" | wc -l)
        echo "最近の自動保存: $recent_count 件"
        
        echo "最新の保存:"
        tail -n 3 "$stats_file" | while IFS=',' read timestamp command classification filename size time result; do
            local date_part=$(echo "$timestamp" | cut -d'T' -f1)
            local time_part=$(echo "$timestamp" | cut -d'T' -f2 | cut -d'+' -f1)
            echo "  $date_part $time_part: $filename ($command → $classification)"
        done
    else
        echo "統計データなし"
    fi
}

# クリーンアップ処理
cleanup_auto_save_system() {
    local retain_days=${1:-30}
    
    log_auto_save "INFO" "自動保存システムクリーンアップ開始 (${retain_days}日保持)"
    
    # 古いドキュメントファイルのクリーンアップ
    cleanup_old_documents "$retain_days"
    
    # 古いログファイルのクリーンアップ
    local log_dir="$HOME/.claude/logs"
    if [[ -d "$log_dir" ]]; then
        find "$log_dir" -name "*.log" -mtime +7 -delete 2>/dev/null
        log_auto_save "INFO" "古いログファイルを削除しました"
    fi
    
    # 古い統計データのクリーンアップ
    local stats_file="$HOME/.claude/stats/auto-save-stats.log"
    if [[ -f "$stats_file" ]]; then
        local cutoff_date=$(date -d "$(date '+%Y-%m-%d') -90 days" -Iseconds 2>/dev/null)
        if [[ -n "$cutoff_date" ]]; then
            grep "$cutoff_date" "$stats_file" > "${stats_file}.tmp" && mv "${stats_file}.tmp" "$stats_file"
            log_auto_save "INFO" "古い統計データを削除しました"
        fi
    fi
}

# スクリプトが直接実行された場合
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-status}" in
        "status")
            check_auto_save_status
            ;;
        "init")
            initialize_auto_save_config
            check_system_requirements
            ;;
        "test")
            DEBUG_AUTO_SAVE=true
            auto_save_generated_file "test-document.md" "# テスト\nこれはテストです。" "test"
            ;;
        "cleanup")
            cleanup_auto_save_system "${2:-30}"
            ;;
        *)
            echo "使用方法: $0 {status|init|test|cleanup [日数]}"
            ;;
    esac
fi

# 初期化処理
if [[ -z "$AUTO_SAVE_INITIALIZED" ]]; then
    initialize_auto_save_config
    export AUTO_SAVE_INITIALIZED=true
fi

log_auto_save "INFO" "Claude Code 自動保存システム（コア）読み込み完了"