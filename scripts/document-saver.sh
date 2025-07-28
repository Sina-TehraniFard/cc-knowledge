#!/bin/bash
# ドキュメント保存システム - Claude Code 自動保存システム
# 用途: 分類されたドキュメントファイルの自動保存とセッション統合
# 作成者: Claude Code Auto-Save System

# 依存関係の読み込み
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/session-manager.sh" 2>/dev/null || {
    echo "警告: session-manager.sh が読み込めません" >&2
}

# デバッグフラグ
DEBUG_SAVER=${DEBUG_SAVER:-false}

# ログ関数
log_saver() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    if [[ "$DEBUG_SAVER" == "true" ]]; then
        echo "[$timestamp] [$level] [document-saver] $message" >&2
    fi
    
    # 詳細ログファイルにも記録
    local log_file="$HOME/.claude/logs/auto-save.log"
    mkdir -p "$(dirname "$log_file")"
    echo "[$timestamp] [$level] [document-saver] $message" >> "$log_file"
}

# 設定読み込み
load_saver_config() {
    # デフォルト設定
    CLAUDE_OUTPUTS_BASE="$HOME/Documents/claude-outputs"
    SESSION_INTEGRATION=true
    BACKUP_ENABLED=true
    NOTIFICATION_ENABLED=true
    
    # 設定ファイルから読み込み（オプション）
    local config_file="$HOME/.claude-config.yml"
    if [[ -f "$config_file" ]]; then
        log_saver "INFO" "設定ファイル読み込み: $config_file"
        
        # 簡易YAML解析（grepベース）
        local documents_path=$(grep "documents_path:" "$config_file" | sed 's/.*documents_path:[[:space:]]*["'\'']*\([^"'\'']*\)["'\'']*$/\1/')
        if [[ -n "$documents_path" ]]; then
            CLAUDE_OUTPUTS_BASE=$(eval echo "$documents_path")
        fi
        
        if grep -q "session_integration:[[:space:]]*false" "$config_file"; then
            SESSION_INTEGRATION=false
        fi
        
        if grep -q "notifications:[[:space:]]*false" "$config_file"; then
            NOTIFICATION_ENABLED=false
        fi
    fi
    
    log_saver "INFO" "設定: CLAUDE_OUTPUTS_BASE=$CLAUDE_OUTPUTS_BASE"
    log_saver "DEBUG" "設定: SESSION_INTEGRATION=$SESSION_INTEGRATION, BACKUP_ENABLED=$BACKUP_ENABLED"
}

# ディレクトリ構造の作成
ensure_directories() {
    local base_dir="$1"
    local session_dir="$2"
    
    # Claude Outputs ディレクトリ
    mkdir -p "$base_dir"
    if [[ $? -ne 0 ]]; then
        log_saver "ERROR" "Claude Outputsディレクトリの作成に失敗: $base_dir"
        return 1
    fi
    
    # セッションディレクトリ（SESSION_INTEGRATION が有効な場合）
    if [[ "$SESSION_INTEGRATION" == "true" && -n "$session_dir" ]]; then
        mkdir -p "$session_dir/reports"
        if [[ $? -ne 0 ]]; then
            log_saver "WARN" "セッションディレクトリの作成に失敗: $session_dir/reports"
        fi
    fi
    
    return 0
}

# ファイルのバックアップ作成
create_backup() {
    local file_path="$1"
    
    if [[ "$BACKUP_ENABLED" != "true" || ! -f "$file_path" ]]; then
        return 0
    fi
    
    local backup_path="${file_path}.backup.$(date '+%Y%m%d_%H%M%S')"
    cp "$file_path" "$backup_path" 2>/dev/null
    
    if [[ $? -eq 0 ]]; then
        log_saver "INFO" "バックアップ作成完了: $backup_path"
    else
        log_saver "WARN" "バックアップ作成に失敗: $file_path"
    fi
}

# メタデータの生成
generate_metadata() {
    local file_path="$1"
    local command_context="$2"
    local original_path="$3"
    
    cat << EOF
{
  "saved_at": "$(date -Iseconds)",
  "original_path": "$original_path",
  "command_context": "$command_context",
  "file_size": $(wc -c < "$file_path" 2>/dev/null || echo "0"),
  "claude_code_version": "auto-save-v1.0"
}
EOF
}

# メインの保存関数
save_document() {
    local file_path="$1"
    local content="$2"
    local metadata="$3"
    local command_context="$4"
    
    log_saver "INFO" "ドキュメント保存開始: $(basename "$file_path")"
    
    # 引数チェック
    if [[ -z "$file_path" || -z "$content" ]]; then
        log_saver "ERROR" "必須引数が不足: file_path=$file_path, content_length=${#content}"
        return 1
    fi
    
    # 設定読み込み
    load_saver_config
    
    # チケット番号とセッション情報の取得
    local ticket_number=""
    local session_dir=""
    
    if command -v get_ticket_number >/dev/null 2>&1; then
        ticket_number=$(get_ticket_number)
        log_saver "DEBUG" "チケット番号取得: $ticket_number"
        
        if command -v get_or_create_session >/dev/null 2>&1; then
            session_dir=$(get_or_create_session "$ticket_number" 2>/dev/null | tail -1)
            log_saver "DEBUG" "セッションディレクトリ: $session_dir"
        fi
    else
        log_saver "WARN" "セッション管理システムが利用できません"
        ticket_number="UNKNOWN"
    fi
    
    # 保存先パスの決定
    local today=$(date '+%Y-%m-%d')
    local claude_outputs_dir="$CLAUDE_OUTPUTS_BASE/$today"
    local filename=$(basename "$file_path")
    local claude_outputs_path="$claude_outputs_dir/$filename"
    
    # ディレクトリ作成
    if ! ensure_directories "$claude_outputs_dir" "$session_dir"; then
        return 1
    fi
    
    # Claude Outputs への保存
    create_backup "$claude_outputs_path"
    echo "$content" > "$claude_outputs_path"
    
    if [[ $? -eq 0 ]]; then
        log_saver "INFO" "Claude Outputs保存完了: $claude_outputs_path"
        
        # メタデータファイルの作成
        local metadata_path="${claude_outputs_path}.meta"
        generate_metadata "$claude_outputs_path" "$command_context" "$file_path" > "$metadata_path"
        
        # インデックスファイルの更新
        update_index "$claude_outputs_dir" "$filename" "$command_context"
        
    else
        log_saver "ERROR" "Claude Outputs保存に失敗: $claude_outputs_path"
        return 1
    fi
    
    # セッション管理システムとの統合
    if [[ "$SESSION_INTEGRATION" == "true" && -n "$session_dir" ]]; then
        local session_reports_path="$session_dir/reports/$filename"
        echo "$content" > "$session_reports_path"
        
        if [[ $? -eq 0 ]]; then
            log_saver "INFO" "セッション統合完了: $session_reports_path"
            
            # セッションサマリーの更新
            update_session_summary "$session_dir" "$filename" "$command_context"
        else
            log_saver "WARN" "セッション統合に失敗: $session_reports_path"
        fi
    fi
    
    # 保存完了後の処理
    post_save_processing "$claude_outputs_path" "$command_context"
    
    return 0
}

# インデックスファイルの更新
update_index() {
    local output_dir="$1"
    local filename="$2"  
    local command_context="$3"
    
    local index_file="$output_dir/.index"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "$timestamp: $filename ($command_context)" >> "$index_file"
    log_saver "DEBUG" "インデックス更新: $index_file"
}

# セッションサマリーの更新
update_session_summary() {
    local session_dir="$1"
    local filename="$2"
    local command_context="$3"
    
    local summary_file="$session_dir/session-summary.md"
    
    if [[ -f "$summary_file" ]]; then
        # 生成ファイルセクションを更新
        if ! grep -q "## 生成ファイル" "$summary_file"; then
            echo "" >> "$summary_file"
            echo "## 生成ファイル" >> "$summary_file"
        fi
        
        echo "- **$filename** ($command_context) - $(date '+%H:%M')" >> "$summary_file"
        log_saver "DEBUG" "セッションサマリー更新: $summary_file"
    fi
}

# 保存後処理
post_save_processing() {
    local saved_path="$1"
    local command_context="$2"
    
    # 通知システムの呼び出し（利用可能な場合）
    if [[ "$NOTIFICATION_ENABLED" == "true" ]] && command -v notify_document_saved >/dev/null 2>&1; then
        notify_document_saved "$saved_path" "$command_context"
    fi
    
    # 統計情報の更新
    update_save_statistics "$saved_path" "$command_context"
}

# 保存統計の更新
update_save_statistics() {
    local saved_path="$1"
    local command_context="$2"
    
    local stats_file="$HOME/.claude/stats/document-save-stats.log"
    mkdir -p "$(dirname "$stats_file")"
    
    local file_size=$(wc -c < "$saved_path" 2>/dev/null || echo "0")
    echo "$(date -Iseconds),$command_context,$(basename "$saved_path"),$file_size" >> "$stats_file"
}

# 保存先パスの取得（他のスクリプトから使用）
get_document_save_path() {
    local filename="$1"
    local today=$(date '+%Y-%m-%d')
    
    load_saver_config
    
    echo "$CLAUDE_OUTPUTS_BASE/$today/$filename"
}

# 最近の保存ファイル一覧
list_recent_documents() {
    local days=${1:-7}
    local today=$(date '+%Y-%m-%d')
    
    load_saver_config
    
    echo "=== 最近 $days 日間の保存ドキュメント ==="
    
    # 過去N日分のディレクトリを検索
    for i in $(seq 0 $((days-1))); do
        local check_date=$(date -d "$today -$i days" '+%Y-%m-%d' 2>/dev/null || date -v-${i}d '+%Y-%m-%d')
        local check_dir="$CLAUDE_OUTPUTS_BASE/$check_date"
        
        if [[ -d "$check_dir" ]]; then
            echo ""
            echo "## $check_date"
            find "$check_dir" -name "*.md" -type f | head -10 | while read file; do
                local size=$(wc -c < "$file" 2>/dev/null || echo "0")
                echo "- $(basename "$file") (${size} bytes)"
            done
        fi
    done
}

# クリーンアップ機能
cleanup_old_documents() {
    local retain_days=${1:-30}
    
    load_saver_config
    
    log_saver "INFO" "古いドキュメントのクリーンアップ開始 (${retain_days}日以前)"
    
    local cutoff_date=$(date -d "$(date '+%Y-%m-%d') -$retain_days days" '+%Y-%m-%d' 2>/dev/null || 
                       date -v-${retain_days}d '+%Y-%m-%d')
    
    find "$CLAUDE_OUTPUTS_BASE" -name "????-??-??" -type d | while read dir; do
        local dir_date=$(basename "$dir")
        
        if [[ "$dir_date" < "$cutoff_date" ]]; then
            local file_count=$(find "$dir" -type f | wc -l)
            log_saver "INFO" "削除対象: $dir ($file_count ファイル)"
            
            # 安全のため、実際の削除はコメントアウト
            # rm -rf "$dir"
            echo "削除対象ディレクトリ: $dir ($file_count ファイル)"
        fi
    done
}

# テスト用関数
test_document_saver() {
    echo "=== ドキュメント保存システムテスト ==="
    
    DEBUG_SAVER=true
    
    # テスト用コンテンツ
    local test_content="# テストドキュメント
これはテスト用のドキュメントです。
作成日時: $(date)"
    
    # テスト実行
    save_document "test-document.md" "$test_content" "" "test"
    
    echo "テスト完了"
    echo "保存先確認: $(get_document_save_path "test-document.md")"
}

# スクリプトが直接実行された場合
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-test}" in
        "test")
            test_document_saver
            ;;
        "list")
            list_recent_documents "${2:-7}"
            ;;
        "cleanup")
            cleanup_old_documents "${2:-30}"
            ;;
        "stats")
            if [[ -f "$HOME/.claude/stats/document-save-stats.log" ]]; then
                echo "=== ドキュメント保存統計 ==="
                tail -20 "$HOME/.claude/stats/document-save-stats.log"
            else
                echo "統計データが存在しません"
            fi
            ;;
        *)
            echo "使用方法: $0 {test|list [日数]|cleanup [保持日数]|stats}"
            ;;
    esac
fi

log_saver "INFO" "ドキュメント保存システム読み込み完了"