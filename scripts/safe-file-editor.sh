#!/bin/bash
# Safe File Editor - 自動バックアップ付きファイル修正システム
# 使用方法: source ~/workspace/cc-knowledge/scripts/safe-file-editor.sh

# セッション管理スクリプトの読み込み
source ~/workspace/cc-knowledge/scripts/session-manager.sh

# =============================================================================
# バックアップ管理機能
# =============================================================================

# 安全なファイルバックアップ作成
create_safe_backup() {
    local file_path=$1
    local reason=${2:-"修正前自動バックアップ"}
    
    if [[ ! -f "$file_path" ]]; then
        echo "❌ エラー: ファイルが存在しません - $file_path"
        return 1
    fi
    
    # タイムスタンプ付きバックアップファイル名生成
    local timestamp=$(TZ=Asia/Tokyo date '+%Y%m%d-%H%M%S')
    local backup_name=$(basename "$file_path")
    local backup_path="${file_path}.bak.${timestamp}"
    
    # バックアップ作成
    cp "$file_path" "$backup_path"
    if [[ $? -eq 0 ]]; then
        echo "✅ バックアップ作成: $(basename "$backup_path")"
        echo "📝 理由: $reason"
        echo "📁 場所: $backup_path"
        
        # セッション管理統合: バックアップログ記録
        log_backup_to_session "$file_path" "$backup_path" "$reason"
        
        return 0
    else
        echo "❌ エラー: バックアップ作成失敗 - $file_path"
        return 1
    fi
}

# セッション管理統合: バックアップログ記録
log_backup_to_session() {
    local original_file=$1
    local backup_file=$2
    local reason=$3
    local current_ticket=$(get_ticket_number)
    
    # 現在のセッションディレクトリ取得（出力を変数に格納）
    local session_output=$(get_or_create_session "$current_ticket" 2>/dev/null)
    local session_dir=$(echo "$session_output" | tail -1)
    local backup_log="$session_dir/backup-log.md"
    
    # 初回作成時のヘッダー
    if [[ ! -f "$backup_log" ]]; then
        cat > "$backup_log" <<EOF
# ファイルバックアップログ

## セッション情報
- **チケット**: $current_ticket
- **開始日時**: $(TZ=Asia/Tokyo date '+%Y-%m-%d %H:%M:%S')

## バックアップ履歴
EOF
    fi
    
    # バックアップエントリ追加
    cat >> "$backup_log" <<EOF

### $(TZ=Asia/Tokyo date '+%H:%M:%S') - $(basename "$original_file")
- **元ファイル**: $original_file
- **バックアップ**: $backup_file  
- **理由**: $reason
- **サイズ**: $(du -h "$backup_file" | cut -f1)
EOF
    
    echo "📋 バックアップログ更新: $backup_log"
}

# =============================================================================
# 安全な修正実行機能
# =============================================================================

# 安全なファイル修正（Edit機能統合）
safe_edit_file() {
    local file_path=$1
    local old_string=$2
    local new_string=$3
    local replace_all=${4:-false}
    
    echo "🔧 安全なファイル修正開始: $(basename "$file_path")"
    
    # Step 1: バックアップ作成
    if ! create_safe_backup "$file_path" "Edit修正前"; then
        echo "❌ 修正中止: バックアップ作成失敗"
        return 1
    fi
    
    # Step 2: 修正内容の事前検証
    if ! grep -q "$old_string" "$file_path"; then
        echo "⚠️  警告: 対象文字列が見つかりません"
        echo "🔍 検索対象: $old_string"
        list_recent_backups "$file_path"
        return 1
    fi
    
    # Step 3: 修正実行
    echo "🔄 修正実行中..."
    local temp_file="${file_path}.tmp.$(TZ=Asia/Tokyo date '+%Y%m%d-%H%M%S')"
    
    if [[ "$replace_all" == "true" ]]; then
        sed "s|${old_string}|${new_string}|g" "$file_path" > "$temp_file"
    else
        # 最初の1件のみ置換
        sed "0,/${old_string}/s/${old_string}/${new_string}/" "$file_path" > "$temp_file"
    fi
    
    # Step 4: 修正結果検証
    if verify_edit_success "$file_path" "$temp_file" "$old_string" "$new_string"; then
        mv "$temp_file" "$file_path"
        echo "✅ 修正完了: $(basename "$file_path")"
        
        # 正常終了時の処理
        handle_successful_edit "$file_path"
        return 0
    else
        rm -f "$temp_file"
        echo "❌ 修正失敗: 変更を破棄しました"
        return 1
    fi
}

# 修正結果の検証
verify_edit_success() {
    local original_file=$1
    local modified_file=$2
    local old_string=$3
    local new_string=$4
    
    # 基本的な検証: ファイルが空でないか
    if [[ ! -s "$modified_file" ]]; then
        echo "❌ 検証失敗: 修正後ファイルが空です"
        return 1
    fi
    
    # 変更内容の検証: 新しい文字列が含まれているか
    if ! grep -q "$new_string" "$modified_file"; then
        echo "❌ 検証失敗: 新しい文字列が見つかりません"
        return 1
    fi
    
    # ファイルサイズの妥当性確認（極端に小さくなっていないか）
    local original_size=$(stat -f%z "$original_file")
    local modified_size=$(stat -f%z "$modified_file")
    local size_ratio=$((modified_size * 100 / original_size))
    
    if [[ $size_ratio -lt 10 ]]; then
        echo "⚠️  警告: ファイルサイズが大幅に減少 ($size_ratio%)"
        echo "🔍 確認してください: 元=${original_size}bytes → 修正後=${modified_size}bytes"
        return 1
    fi
    
    return 0
}

# 正常終了時の処理
handle_successful_edit() {
    local file_path=$1
    echo "🎉 修正処理正常完了"
    
    # 修正成功をセッションログに記録
    local current_ticket=$(get_ticket_number)
    local session_output=$(get_or_create_session "$current_ticket" 2>/dev/null)
    local session_dir=$(echo "$session_output" | tail -1)
    
    echo "- ✅ $(TZ=Asia/Tokyo date '+%H:%M:%S') - $(basename "$file_path") 修正完了" >> "$session_dir/session-summary.md"
}

# =============================================================================
# バックアップ管理・復旧機能
# =============================================================================

# 最近のバックアップ一覧表示
list_recent_backups() {
    local file_path=$1
    local file_pattern=$(basename "$file_path")
    local dir_path=$(dirname "$file_path")
    
    echo ""
    echo "📋 最近のバックアップファイル ($file_pattern):"
    find "$dir_path" -name "${file_pattern}.bak.*" -mtime -1 2>/dev/null | sort -r | head -5 | while read backup; do
        local timestamp=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$backup")
        local size=$(du -h "$backup" | cut -f1)
        echo "  📄 $(basename "$backup") ($size, $timestamp)"
    done
    echo ""
}

# 安全な復旧機能
restore_from_backup() {
    local file_path=$1
    local backup_pattern=${2:-"latest"}
    
    echo "🔄 ファイル復旧開始: $(basename "$file_path")"
    
    local file_pattern=$(basename "$file_path")
    local dir_path=$(dirname "$file_path")
    local backup_file
    
    if [[ "$backup_pattern" == "latest" ]]; then
        # 最新のバックアップを選択
        backup_file=$(find "$dir_path" -name "${file_pattern}.bak.*" -mtime -7 2>/dev/null | sort -r | head -1)
    else
        # 指定されたパターンで検索
        backup_file=$(find "$dir_path" -name "${file_pattern}.bak.*${backup_pattern}*" 2>/dev/null | head -1)
    fi
    
    if [[ -z "$backup_file" ]]; then
        echo "❌ エラー: 復旧可能なバックアップが見つかりません"
        list_recent_backups "$file_path"
        return 1
    fi
    
    echo "📁 復旧元: $(basename "$backup_file")"
    
    # 現在のファイルもバックアップしてから復旧
    if [[ -f "$file_path" ]]; then
        create_safe_backup "$file_path" "復旧前のバックアップ"
    fi
    
    # 復旧実行
    cp "$backup_file" "$file_path"
    if [[ $? -eq 0 ]]; then
        echo "✅ 復旧完了: $(basename "$file_path")"
        echo "📝 復旧元: $(basename "$backup_file")"
        return 0
    else
        echo "❌ エラー: 復旧失敗"
        return 1
    fi
}

# =============================================================================
# trash管理機能
# =============================================================================

# セッション完了時のtrash移動
move_backups_to_trash() {
    local session_completed=${1:-false}
    local current_ticket=$(get_ticket_number)
    local session_dir=$(get_or_create_session "$current_ticket")
    
    if [[ "$session_completed" == "true" ]]; then
        echo "🗑️ セッション完了: バックアップをtrashに移動"
        
        # trash ディレクトリ作成
        local trash_dir="${session_dir}/../trash/$(basename $session_dir)"
        mkdir -p "$trash_dir"
        
        # .bak ファイルをtrashに移動
        local moved_count=0
        find "$(dirname $session_dir)" -name "*.bak.*" -mtime -1 2>/dev/null | while read backup_file; do
            mv "$backup_file" "$trash_dir/"
            moved_count=$((moved_count + 1))
        done
        
        echo "📦 移動完了: ${moved_count}個のバックアップファイルをtrashに移動"
        echo "📁 移動先: $trash_dir"
        
        # trash移動ログ
        echo "## trash移動完了: $(TZ=Asia/Tokyo date '+%Y-%m-%d %H:%M:%S')" >> "$session_dir/session-summary.md"
        echo "- 移動先: $trash_dir" >> "$session_dir/session-summary.md"
        echo "- 移動ファイル数: ${moved_count}個" >> "$session_dir/session-summary.md"
    fi
}

# trash ディレクトリのクリーンアップ
cleanup_old_trash() {
    local days_old=${1:-7}
    local current_ticket=$(get_ticket_number)
    local base_dir="$HOME/workspace/tasks/$current_ticket"
    
    if [[ -d "$base_dir/trash" ]]; then
        echo "🧹 古いtrashファイルのクリーンアップ開始 (${days_old}日以上前)"
        
        local cleaned_count=0
        find "$base_dir/trash" -type f -mtime +$days_old 2>/dev/null | while read old_file; do
            rm -f "$old_file"
            cleaned_count=$((cleaned_count + 1))
        done
        
        # 空のディレクトリも削除
        find "$base_dir/trash" -type d -empty -delete 2>/dev/null
        
        echo "✅ クリーンアップ完了: ${cleaned_count}個のファイルを削除"
    fi
}

# =============================================================================
# 便利機能・ユーティリティ
# =============================================================================

# バックアップシステムの状態表示
show_backup_status() {
    local current_ticket=$(get_ticket_number)
    local session_dir=$(get_or_create_session "$current_ticket")
    
    echo "## 🛡️ バックアップシステム状態"
    echo ""
    echo "### 基本情報"
    echo "- **チケット**: $current_ticket"
    echo "- **セッション**: $(basename "$session_dir")"
    echo ""
    
    # 最近のバックアップファイル統計
    local backup_count=$(find "$(dirname $session_dir)" -name "*.bak.*" -mtime -1 2>/dev/null | wc -l)
    local total_size=$(find "$(dirname $session_dir)" -name "*.bak.*" -mtime -1 -exec du -ch {} + 2>/dev/null | tail -1 | cut -f1)
    
    echo "### バックアップ統計"
    echo "- **24時間以内のバックアップ数**: ${backup_count}個"
    echo "- **合計サイズ**: ${total_size:-0B}"
    echo ""
    
    # trash状態
    local trash_dir="${session_dir}/../trash"
    if [[ -d "$trash_dir" ]]; then
        local trash_count=$(find "$trash_dir" -type f 2>/dev/null | wc -l)
        local trash_size=$(du -sh "$trash_dir" 2>/dev/null | cut -f1)
        echo "### Trash状態"  
        echo "- **Trashファイル数**: ${trash_count}個"
        echo "- **Trashサイズ**: ${trash_size:-0B}"
    else
        echo "### Trash状態"
        echo "- **Trashディレクトリ**: 未作成"
    fi
}

# 機能テスト
test_backup_system() {
    echo "🧪 バックアップシステム機能テスト開始..."
    
    # テストファイル作成
    local test_file="/tmp/backup_test_$(TZ=Asia/Tokyo date '+%Y%m%d_%H%M%S').txt"
    echo "テスト用ファイル - 作成時刻: $(TZ=Asia/Tokyo date)" > "$test_file"
    
    echo ""
    echo "1. バックアップ作成テスト:"
    if create_safe_backup "$test_file" "機能テスト"; then
        echo "✅ バックアップ作成: 成功"
    else
        echo "❌ バックアップ作成: 失敗"
    fi
    
    echo ""
    echo "2. 安全な修正テスト:"
    if safe_edit_file "$test_file" "作成時刻" "修正時刻"; then
        echo "✅ 安全な修正: 成功"
    else
        echo "❌ 安全な修正: 失敗" 
    fi
    
    echo ""
    echo "3. バックアップ一覧テスト:"
    list_recent_backups "$test_file"
    
    # テストファイル削除
    rm -f "$test_file" "${test_file}.bak."* 2>/dev/null
    
    echo "🎉 バックアップシステム機能テスト完了"
}

# ヘルプ表示
show_backup_help() {
    echo "## 🛡️ Safe File Editor - 使用方法"
    echo ""
    echo "### 基本機能"
    echo "- \`create_safe_backup <file>\` - 安全なバックアップ作成"
    echo "- \`safe_edit_file <file> <old> <new>\` - 自動バックアップ付きファイル修正"
    echo "- \`restore_from_backup <file>\` - 最新バックアップから復旧"
    echo "- \`list_recent_backups <file>\` - 最近のバックアップ一覧"
    echo ""
    echo "### 管理機能"
    echo "- \`move_backups_to_trash true\` - セッション完了時のtrash移動"
    echo "- \`cleanup_old_trash 7\` - 7日以上前のtrashファイル削除"
    echo "- \`show_backup_status\` - バックアップシステム状態表示"
    echo ""
    echo "### テスト・ヘルプ"
    echo "- \`test_backup_system\` - 機能テスト実行"
    echo "- \`show_backup_help\` - このヘルプ表示"
}

echo "🛡️ Safe File Editor システム読み込み完了"
echo "💡 使用方法: show_backup_help"