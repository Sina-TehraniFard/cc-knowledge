#!/bin/bash
# 通知システム - Claude Code 自動保存システム
# 用途: ドキュメント保存完了通知とビューアー連携
# 作成者: Claude Code Auto-Save System

# デバッグフラグ
DEBUG_NOTIFIER=${DEBUG_NOTIFIER:-false}

# ログ関数
log_notifier() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    if [[ "$DEBUG_NOTIFIER" == "true" ]]; then
        echo "[$timestamp] [$level] [notifier] $message" >&2
    fi
    
    # 詳細ログファイルにも記録
    local log_file="$HOME/.claude/logs/auto-save.log"
    mkdir -p "$(dirname "$log_file")"
    echo "[$timestamp] [$level] [notifier] $message" >> "$log_file"
}

# 設定読み込み
load_notifier_config() {
    # デフォルト設定
    MACOS_NOTIFICATIONS=true
    VIEWER_INTEGRATION=true
    VIEWER_PORT=3333
    VIEWER_HOST="localhost"
    SOUND_ENABLED=false
    
    # 設定ファイルから読み込み（オプション）
    local config_file="$HOME/.claude-config.yml"
    if [[ -f "$config_file" ]]; then
        log_notifier "INFO" "設定ファイル読み込み: $config_file"
        
        if grep -q "notifications:[[:space:]]*false" "$config_file"; then
            MACOS_NOTIFICATIONS=false
        fi
        
        if grep -q "viewer_integration:[[:space:]]*false" "$config_file"; then
            VIEWER_INTEGRATION=false
        fi
        
        local viewer_port=$(grep "viewer_port:" "$config_file" | sed 's/.*viewer_port:[[:space:]]*\([0-9]*\)$/\1/')
        if [[ -n "$viewer_port" && "$viewer_port" =~ ^[0-9]+$ ]]; then
            VIEWER_PORT="$viewer_port"
        fi
    fi
    
    log_notifier "DEBUG" "設定: MACOS_NOTIFICATIONS=$MACOS_NOTIFICATIONS, VIEWER_INTEGRATION=$VIEWER_INTEGRATION"
}

# macOS通知の送信
send_macos_notification() {
    local title="$1"
    local message="$2"
    local sound="${3:-default}"
    
    if [[ "$MACOS_NOTIFICATIONS" != "true" ]]; then
        log_notifier "DEBUG" "macOS通知が無効のためスキップ"
        return 0
    fi
    
    # macOS環境チェック
    if ! command -v osascript >/dev/null 2>&1; then
        log_notifier "WARN" "osascript が利用できません（非macOS環境）"
        return 1
    fi
    
    # 通知内容のサニタイズ
    title=$(echo "$title" | sed 's/"/\\"/g')
    message=$(echo "$message" | sed 's/"/\\"/g')
    
    # AppleScriptで通知送信
    local script="display notification \"$message\" with title \"$title\""
    
    if [[ "$SOUND_ENABLED" == "true" && -n "$sound" ]]; then
        script="$script sound name \"$sound\""
    fi
    
    osascript -e "$script" 2>/dev/null
    
    if [[ $? -eq 0 ]]; then
        log_notifier "INFO" "macOS通知送信完了: $title"
        return 0
    else
        log_notifier "ERROR" "macOS通知送信に失敗: $title"
        return 1
    fi
}

# Claude Outputs Viewerの稼働状況確認
is_viewer_running() {
    local port="$1"
    
    # ポート指定がない場合はデフォルトを使用
    if [[ -z "$port" ]]; then
        port="$VIEWER_PORT"
    fi
    
    # lsofでポート使用状況を確認
    if command -v lsof >/dev/null 2>&1; then
        lsof -i ":$port" >/dev/null 2>&1
        return $?
    fi
    
    # netstatでの確認（fallback）
    if command -v netstat >/dev/null 2>&1; then
        netstat -an | grep ":$port " | grep -q "LISTEN"
        return $?
    fi
    
    log_notifier "WARN" "ポート確認ツールが利用できません"
    return 1
}

# Claude Outputs Viewerとの連携
update_viewer_index() {
    local file_path="$1"
    local command_context="$2"
    
    if [[ "$VIEWER_INTEGRATION" != "true" ]]; then
        log_notifier "DEBUG" "ビューアー連携が無効のためスキップ"
        return 0
    fi
    
    local viewer_dir=$(dirname "$file_path")
    local filename=$(basename "$file_path")
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # 簡易的なインデックスファイル更新
    local index_file="$viewer_dir/.index"
    echo "$timestamp: $filename ($command_context)" >> "$index_file"
    log_notifier "DEBUG" "ビューアーインデックス更新: $index_file"
    
    # 将来のWebSocket実装準備
    try_notify_viewer_api "$file_path" "$command_context"
}

# Viewer HTTP API通知の試行
try_notify_viewer_api() {
    local file_path="$1"
    local command_context="$2"
    
    if ! command -v curl >/dev/null 2>&1; then
        log_notifier "DEBUG" "curl が利用できないためAPI通知をスキップ"
        return 1
    fi
    
    if ! is_viewer_running "$VIEWER_PORT"; then
        log_notifier "DEBUG" "Claude Outputs Viewer が動作していません (port $VIEWER_PORT)"
        return 1
    fi
    
    # API エンドポイントに通知を試行
    local api_url="http://$VIEWER_HOST:$VIEWER_PORT/api/notify"
    local payload="{\"file\": \"$file_path\", \"timestamp\": \"$(date -Iseconds)\", \"command\": \"$command_context\"}"
    
    local response=$(curl -s -X POST "$api_url" \
                     -H "Content-Type: application/json" \
                     -d "$payload" \
                     --connect-timeout 2 \
                     --max-time 5 2>/dev/null)
    
    if [[ $? -eq 0 && -n "$response" ]]; then
        log_notifier "INFO" "ビューアーAPI通知成功: $file_path"
        return 0
    else
        log_notifier "DEBUG" "ビューアーAPI通知失敗（API未実装の可能性）"
        return 1
    fi
}

# ビューアーの自動起動（オプション）
start_viewer_if_needed() {
    local viewer_command="$1"
    
    # ビューアーが既に動作している場合はスキップ
    if is_viewer_running "$VIEWER_PORT"; then
        log_notifier "DEBUG" "ビューアーは既に動作中"
        return 0
    fi
    
    # 自動起動は無効（ユーザーの明示的な操作を推奨）
    log_notifier "INFO" "Claude Outputs Viewer が動作していません。手動で起動してください。"
    return 1
}

# メイン通知関数
notify_document_saved() {
    local file_path="$1"
    local command_context="${2:-unknown}"
    
    log_notifier "INFO" "ドキュメント保存通知開始: $(basename "$file_path")"
    
    # 引数チェック
    if [[ -z "$file_path" ]]; then
        log_notifier "ERROR" "file_path が指定されていません"
        return 1
    fi
    
    # 設定読み込み
    load_notifier_config
    
    local filename=$(basename "$file_path")
    local file_size="不明"
    
    # ファイルサイズ取得
    if [[ -f "$file_path" ]]; then
        file_size=$(wc -c < "$file_path" 2>/dev/null || echo "不明")
        if [[ "$file_size" =~ ^[0-9]+$ ]]; then
            if [[ $file_size -gt 1024 ]]; then
                file_size="$((file_size / 1024))KB"
            else
                file_size="${file_size}B"
            fi
        fi
    fi
    
    # macOS通知の送信
    local notification_title="Claude Code Auto-Save"
    local notification_message="新しいドキュメント: $filename ($file_size)"
    
    send_macos_notification "$notification_title" "$notification_message"
    
    # ビューアー連携の実行
    update_viewer_index "$file_path" "$command_context"
    
    # 通知統計の更新
    update_notification_stats "$file_path" "$command_context"
    
    log_notifier "INFO" "ドキュメント保存通知完了: $filename"
    return 0
}

# 通知統計の更新
update_notification_stats() {
    local file_path="$1"
    local command_context="$2"
    
    local stats_file="$HOME/.claude/stats/notification-stats.log"
    mkdir -p "$(dirname "$stats_file")"
    
    local notification_time=$(date -Iseconds)
    echo "$notification_time,$command_context,$(basename "$file_path")" >> "$stats_file"
}

# 複数ファイルの一括通知
notify_multiple_documents() {
    local file_count="$1"
    shift
    local files=("$@")
    
    log_notifier "INFO" "複数ドキュメント通知: $file_count ファイル"
    
    load_notifier_config
    
    # 要約通知の送信
    local notification_title="Claude Code Auto-Save"
    local notification_message="$file_count 個のドキュメントを保存しました"
    
    send_macos_notification "$notification_title" "$notification_message"
    
    # 各ファイルのビューアー連携
    for file_path in "${files[@]}"; do
        update_viewer_index "$file_path" "batch"
    done
}

# エラー通知
notify_error() {
    local error_message="$1"
    local context="${2:-general}"
    
    log_notifier "ERROR" "エラー通知: $error_message"
    
    load_notifier_config
    
    local notification_title="Claude Code Auto-Save Error"
    send_macos_notification "$notification_title" "$error_message" "Basso"
}

# 通知テスト
test_notifications() {
    echo "=== 通知システムテスト ==="
    
    DEBUG_NOTIFIER=true
    load_notifier_config
    
    echo "1. macOS環境チェック"
    if command -v osascript >/dev/null 2>&1; then
        echo "   ✅ osascript 利用可能"
    else
        echo "   ❌ osascript 利用不可（非macOS環境）"
    fi
    
    echo "2. ビューアー稼働状況"
    if is_viewer_running "$VIEWER_PORT"; then
        echo "   ✅ Claude Outputs Viewer 動作中 (port $VIEWER_PORT)"
    else
        echo "   ❌ Claude Outputs Viewer 停止中 (port $VIEWER_PORT)"
    fi
    
    echo "3. テスト通知送信"
    notify_document_saved "/tmp/test-document.md" "test"
    
    echo "4. エラー通知テスト"
    notify_error "これはテスト用のエラー通知です" "test"
    
    echo "テスト完了"
}

# 通知統計の表示
show_notification_stats() {
    local stats_file="$HOME/.claude/stats/notification-stats.log"
    
    if [[ ! -f "$stats_file" ]]; then
        echo "通知統計データが存在しません"
        return 1
    fi
    
    echo "=== 通知統計 ==="
    echo "総通知数: $(wc -l < "$stats_file")"
    echo ""
    echo "最近の通知:"
    tail -10 "$stats_file" | while IFS=',' read timestamp command filename; do
        echo "  $(date -d "$timestamp" '+%m/%d %H:%M' 2>/dev/null || echo "$timestamp") $command $filename"
    done
    
    echo ""
    echo "コマンド別統計:"
    cut -d',' -f2 "$stats_file" | sort | uniq -c | sort -nr
}

# スクリプトが直接実行された場合
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-test}" in
        "test")
            test_notifications
            ;;
        "stats")
            show_notification_stats
            ;;
        "notify")
            if [[ -n "$2" ]]; then
                notify_document_saved "$2" "${3:-manual}"
            else
                echo "使用方法: $0 notify <file_path> [command_context]"
            fi
            ;;
        "error")
            notify_error "${2:-テストエラー}" "${3:-test}"
            ;;
        *)
            echo "使用方法: $0 {test|stats|notify <file>|error <message>}"
            ;;
    esac
fi

log_notifier "INFO" "通知システム読み込み完了"