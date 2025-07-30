#!/bin/bash

# Claude Code Knowledge Base Update Script
# 設定変更を自動的に反映するスクリプト

set -e

# 色付きメッセージ用の定数
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ログ関数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 基本パス設定
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="${SCRIPT_DIR}/backups/$(date +%Y%m%d_%H%M%S)"
CONFIG_FILE="${SCRIPT_DIR}/update-config.json"

# ヘルプ表示
show_help() {
    cat << EOF
Claude Code Knowledge Base Update Script

使用方法:
    ./update.sh [オプション] [アクション]

アクション:
    paths           出力先パスの一括更新
    config          設定ファイルの更新
    templates       テンプレートファイルの更新
    sync-git        Git差分のあるファイルを全て更新
    sync-all        cc-workspaceから全ファイルを同期
    sync-project    cc-knowledgeから現在のプロジェクトに同期
    all             全て実行（デフォルト）
    backup          バックアップのみ実行
    restore         最新バックアップから復元

オプション:
    -h, --help      このヘルプを表示
    -n, --dry-run   実際の変更を行わずに確認のみ
    -f, --force     確認なしで実行
    -b, --backup    実行前にバックアップを作成
    -c, --config    設定ファイルを指定
    --old-path      置換元パス（デフォルト: ~/workspace/tasks）
    --new-path      置換先パス（デフォルト: /Users/\$USER/Documents/claude-outputs）

例:
    ./update.sh                                    # 全て実行
    ./update.sh paths --dry-run                   # パス更新の確認のみ
    ./update.sh --old-path "~/old" --new-path "/new" paths
    ./update.sh backup                            # バックアップのみ
    ./update.sh restore                           # 復元

EOF
}

# デフォルト設定
DRY_RUN=false
FORCE=false
CREATE_BACKUP=true
ACTION="all"
OLD_PATH="~/workspace/tasks"
NEW_PATH="/Users/\$(whoami)/Documents/claude-outputs"
CC_WORKSPACE_PATH="../"
CC_KNOWLEDGE_PATH="${CC_KNOWLEDGE_PATH:-~/workspace/cc-knowledge}"

# 引数解析
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -n|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        -b|--backup)
            CREATE_BACKUP=true
            shift
            ;;
        -c|--config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        --old-path)
            OLD_PATH="$2"
            shift 2
            ;;
        --new-path)
            NEW_PATH="$2"
            shift 2
            ;;
        paths|config|templates|sync-git|sync-all|sync-project|all|backup|restore)
            ACTION="$1"
            shift
            ;;
        *)
            log_error "不明なオプション: $1"
            show_help
            exit 1
            ;;
    esac
done

# バックアップ作成
create_backup() {
    log_info "バックアップを作成中..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] バックアップ先: $BACKUP_DIR"
        return 0
    fi

    mkdir -p "$BACKUP_DIR"
    
    # 重要ファイルのバックアップ
    local files_to_backup=(
        "CLAUDE.md"
        ".claude/commands"
        "commands"
        "templates"
        "scripts"
    )
    
    for file in "${files_to_backup[@]}"; do
        if [[ -e "${SCRIPT_DIR}/${file}" ]]; then
            cp -r "${SCRIPT_DIR}/${file}" "$BACKUP_DIR/"
            log_success "バックアップ完了: $file"
        fi
    done
    
    # バックアップ情報を記録
    cat > "${BACKUP_DIR}/backup-info.json" << EOF
{
    "timestamp": "$(date -Iseconds)",
    "old_path": "$OLD_PATH",
    "new_path": "$NEW_PATH",
    "action": "$ACTION",
    "script_version": "1.0.0"
}
EOF
    
    log_success "バックアップ完了: $BACKUP_DIR"
}

# 最新バックアップから復元
restore_backup() {
    local latest_backup=$(find "${SCRIPT_DIR}/backups" -maxdepth 1 -type d -name "20*" | sort -r | head -1)
    
    if [[ -z "$latest_backup" ]]; then
        log_error "復元可能なバックアップが見つかりません"
        exit 1
    fi
    
    log_info "復元中: $latest_backup"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] 復元元: $latest_backup"
        return 0
    fi
    
    if [[ "$FORCE" != "true" ]]; then
        echo -n "バックアップから復元しますか？ (y/N): "
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            log_info "復元をキャンセルしました"
            exit 0
        fi
    fi
    
    # 復元実行
    cp -r "$latest_backup"/* "$SCRIPT_DIR/"
    log_success "復元完了"
}

# パス更新
update_paths() {
    log_info "パス更新を実行中..."
    log_info "置換: '$OLD_PATH' → '$NEW_PATH'"
    
    # 対象ファイルリスト
    local target_files=(
        "CLAUDE.md"
        ".claude/commands/*.md"
        "commands/*.md"
        "templates/**/commands/*.md"
    )
    
    local updated_count=0
    
    for pattern in "${target_files[@]}"; do
        while IFS= read -r -d '' file; do
            if [[ -f "$file" ]]; then
                local matches=$(grep -c "$OLD_PATH" "$file" 2>/dev/null || echo "0")
                
                if [[ "$matches" -gt 0 ]]; then
                    log_info "更新対象: $file ($matches 箇所)"
                    
                    if [[ "$DRY_RUN" != "true" ]]; then
                        # 実際のパス置換を実行
                        sed -i.bak "s|$OLD_PATH|$NEW_PATH|g" "$file"
                        rm -f "${file}.bak"
                        ((updated_count++))
                    fi
                fi
            fi
        done < <(find "$SCRIPT_DIR" -path "*/$pattern" -print0 2>/dev/null)
    done
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] 更新対象ファイル数: $updated_count"
    else
        log_success "パス更新完了: $updated_count ファイルを更新"
    fi
}

# 設定ファイル更新
update_config() {
    log_info "設定ファイルを更新中..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] 設定ファイル更新をシミュレート"
        return 0
    fi
    
    # 設定ファイルが存在しない場合は作成
    if [[ ! -f "$CONFIG_FILE" ]]; then
        cat > "$CONFIG_FILE" << EOF
{
    "version": "1.0.0",
    "last_update": "$(date -Iseconds)",
    "output_path": "$NEW_PATH",
    "backup_enabled": true,
    "auto_japanese_filenames": true
}
EOF
        log_success "設定ファイルを作成: $CONFIG_FILE"
    else
        # 既存設定ファイルを更新
        # jqが利用可能な場合の処理（オプション）
        if command -v jq >/dev/null 2>&1; then
            tmp_file=$(mktemp)
            jq ".last_update = \"$(date -Iseconds)\" | .output_path = \"$NEW_PATH\"" "$CONFIG_FILE" > "$tmp_file"
            mv "$tmp_file" "$CONFIG_FILE"
            log_success "設定ファイルを更新: $CONFIG_FILE"
        else
            log_warning "jqが見つかりません。設定ファイルの更新をスキップ"
        fi
    fi
}

# テンプレート更新
update_templates() {
    log_info "テンプレートファイルを更新中..."
    
    # 日本語ファイル名へのマッピング
    local filename_mapping=(
        "s/{機能名}-design\.md/{機能名}-設計書.md/g"
        "s/implementation-{設計名}-report\.md/実装レポート-{設計名}.md/g"
        "s/generated-pr\.md/PRドキュメント.md/g"
        "s/{テストクラス名}-fix-report\.md/テスト修正レポート.md/g"
    )
    
    local template_files=$(find "$SCRIPT_DIR/templates" -name "*.md" -type f 2>/dev/null | wc -l)
    
    if [[ "$template_files" -eq 0 ]]; then
        log_warning "テンプレートファイルが見つかりません"
        return 0
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] テンプレート更新対象: $template_files ファイル"
        return 0
    fi
    
    # ファイル名の日本語化を適用
    find "$SCRIPT_DIR/templates" -name "*.md" -type f | while read -r file; do
        for mapping in "${filename_mapping[@]}"; do
            sed -i.bak "$mapping" "$file"
        done
        rm -f "${file}.bak"
    done
    
    log_success "テンプレート更新完了: $template_files ファイル"
}

# Git差分のあるファイルを同期（現在のディレクトリが正規版として扱う）
sync_git_changes() {
    log_info "Git差分を検出して変更を適用中..."
    
    # Gitリポジトリかどうか確認
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        log_error "Gitリポジトリではありません"
        return 1
    fi
    
    # ステージングされた変更とワーキングディレクトリの変更を取得
    local changed_files=()
    
    # ステージングされた変更
    while IFS= read -r file; do
        [[ -n "$file" ]] && changed_files+=("$file")
    done < <(git diff --cached --name-only)
    
    # ワーキングディレクトリの変更
    while IFS= read -r file; do
        [[ -n "$file" ]] && changed_files+=("$file")
    done < <(git diff --name-only)
    
    # 追跡されていないファイル
    while IFS= read -r file; do
        [[ -n "$file" ]] && changed_files+=("$file")
    done < <(git ls-files --others --exclude-standard)
    
    if [[ ${#changed_files[@]} -eq 0 ]]; then
        log_info "同期対象の変更ファイルが見つかりません"
        return 0
    fi
    
    log_info "検出された変更ファイル: ${#changed_files[@]} 個"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] 以下のファイルが変更されています:"
        for file in "${changed_files[@]}"; do
            if [[ -f "${SCRIPT_DIR}/${file}" ]]; then
                log_info "  - $file (既存ファイル)"
            else
                log_info "  - $file (新規ファイル)"
            fi
        done
        return 0
    fi
    
    log_success "現在のディレクトリの変更ファイル一覧を表示しました"
    log_info "これらのファイルがGit上で変更として検出されています"
    log_info "変更を適用するには git add および git commit を実行してください"
}

# 外部ディレクトリから全ファイルを同期
sync_all_files() {
    log_info "外部ディレクトリから全ファイルを同期中..."
    
    # 同期元パスの確認（任意設定）
    local source_path="$CC_WORKSPACE_PATH"
    
    # 引数でパスが指定された場合はそれを使用
    if [[ -n "$1" ]]; then
        source_path="$1"
        log_info "指定されたパス: $source_path"
    fi
    
    # パスの展開
    local source_expanded
    source_expanded=$(eval echo "$source_path")
    
    if [[ ! -d "$source_expanded" ]]; then
        log_error "同期元ディレクトリが見つかりません: $source_expanded"
        log_info "使用方法: ./update.sh sync-all [同期元パス]"
        return 1
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        local file_count=$(find "$source_expanded" -type f 2>/dev/null | wc -l)
        log_info "[DRY RUN] 同期対象: $file_count ファイル"
        log_info "[DRY RUN] 同期元: $source_expanded"
        log_info "[DRY RUN] 同期先: $SCRIPT_DIR"
        return 0
    fi
    
    if [[ "$FORCE" != "true" ]]; then
        echo -n "$source_expanded から全ファイルを同期しますか？既存ファイルは上書きされます (y/N): "
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            log_info "同期をキャンセルしました"
            return 0
        fi
    fi
    
    # rsyncが利用可能な場合
    if command -v rsync >/dev/null 2>&1; then
        log_info "rsyncを使用して同期中..."
        if rsync -av --delete --exclude='.git' --exclude='backups' "$source_expanded/" "$SCRIPT_DIR/"; then
            log_success "rsyncによる全ファイル同期完了"
        else
            log_error "rsyncによる同期失敗"
            return 1
        fi
    else
        # cpを使用した同期
        log_info "cpを使用して同期中..."
        if cp -r "$source_expanded/." "$SCRIPT_DIR/"; then
            log_success "全ファイル同期完了"
        else
            log_error "同期失敗"
            return 1
        fi
    fi
}

# cc-knowledgeから現在のプロジェクトに同期
sync_to_project() {
    log_info "cc-knowledgeから現在のプロジェクトに同期中..."
    
    # 現在の作業ディレクトリがcc-knowledgeかどうか確認
    local current_dir="$(pwd)"
    local current_basename=$(basename "$current_dir")
    if [[ "$current_basename" == "cc-knowledge" ]]; then
        log_error "cc-knowledge内でsync-projectは実行できません"
        log_info "別のプロジェクトディレクトリで実行してください"
        return 1
    fi
    
    # cc-knowledgeパスの展開
    local cc_knowledge_expanded
    cc_knowledge_expanded=$(eval echo "$CC_KNOWLEDGE_PATH")
    
    if [[ ! -d "$cc_knowledge_expanded" ]]; then
        log_error "cc-knowledgeディレクトリが見つかりません: $cc_knowledge_expanded"
        log_info "CC_KNOWLEDGE_PATH環境変数で正しいパスを指定してください"
        return 1
    fi
    
    log_info "同期元: $cc_knowledge_expanded"
    log_info "同期先: $current_dir"
    
    # 同期対象のディレクトリとファイル
    local sync_items=(
        ".claude/commands"
        ".claude/agents"
        "commands"
        "templates"
        "docs/guidelines"
        "docs/knowledge"
    )
    
    # 単一ファイルの同期
    local sync_files=(
        "CLAUDE.md"
        "update.sh"
    )
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] 以下を同期します:"
        for item in "${sync_items[@]}"; do
            log_info "  - $item"
        done
        for file in "${sync_files[@]}"; do
            log_info "  - $file"
        done
        return 0
    fi
    
    # 確認プロンプト
    if [[ "$FORCE" != "true" ]]; then
        echo -e "\n以下の内容を同期します:"
        echo -e "  - .claude/commands/ (カスタムコマンド)"
        echo -e "  - .claude/agents/ (エージェント定義)"
        echo -e "  - commands/ (レガシーコマンド)"
        echo -e "  - templates/ (各種テンプレート)"
        echo -e "  - docs/guidelines/ (開発ガイドライン)"
        echo -e "  - docs/knowledge/ (ナレッジベース)"
        echo -e "  - CLAUDE.md (メインガイドライン)"
        echo -e "  - update.sh (このスクリプト)\n"
        
        echo -n "既存のファイルは上書きされます。続行しますか？ (y/N): "
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            log_info "同期をキャンセルしました"
            return 0
        fi
    fi
    
    # 同期実行
    local sync_count=0
    local fail_count=0
    
    # ディレクトリ同期
    for item in "${sync_items[@]}"; do
        local source_path="$cc_knowledge_expanded/$item"
        local target_path="$current_dir/$item"
        
        if [[ -d "$source_path" ]]; then
            log_info "同期中: $item"
            
            # 親ディレクトリを作成
            mkdir -p "$(dirname "$target_path")"
            
            # rsyncまたはcpで同期
            if command -v rsync >/dev/null 2>&1; then
                if rsync -av --delete "$source_path/" "$target_path/"; then
                    ((sync_count++))
                else
                    ((fail_count++))
                    log_error "同期失敗: $item"
                fi
            else
                if cp -r "$source_path/." "$target_path/"; then
                    ((sync_count++))
                else
                    ((fail_count++))
                    log_error "同期失敗: $item"
                fi
            fi
        else
            log_warning "ソースが見つかりません: $source_path"
        fi
    done
    
    # 単一ファイル同期
    for file in "${sync_files[@]}"; do
        local source_file="$cc_knowledge_expanded/$file"
        local target_file="$current_dir/$file"
        
        if [[ -f "$source_file" ]]; then
            log_info "同期中: $file"
            
            if cp "$source_file" "$target_file"; then
                ((sync_count++))
                # update.shに実行権限を付与
                if [[ "$file" == "update.sh" ]]; then
                    chmod +x "$target_file"
                fi
            else
                ((fail_count++))
                log_error "同期失敗: $file"
            fi
        else
            log_warning "ファイルが見つかりません: $source_file"
        fi
    done
    
    # プロジェクト固有の.claudeディレクトリ作成
    if [[ ! -d "$current_dir/.claude" ]]; then
        mkdir -p "$current_dir/.claude"
        log_info ".claudeディレクトリを作成しました"
    fi
    
    # 同期情報ファイルの作成
    cat > "$current_dir/.claude/.sync-info" << EOF
{
    "last_sync": "$(date -Iseconds)",
    "source": "$cc_knowledge_expanded",
    "version": "1.1.0",
    "sync_count": $sync_count,
    "fail_count": $fail_count
}
EOF
    
    if [[ "$fail_count" -eq 0 ]]; then
        log_success "すべての同期が完了しました！($sync_count 項目)"
    else
        log_warning "同期完了: 成功 $sync_count 項目, 失敗 $fail_count 項目"
    fi
    
    log_info "次のステップ:"
    log_info "  1. git add .claude CLAUDE.md update.sh"
    log_info "  2. git commit -m 'chore: cc-knowledgeから設定を同期'"
    log_info "  3. プロジェクト固有の設定は .claude/project/ に追加してください"
}

# 設定検証
validate_configuration() {
    log_info "設定を検証中..."
    
    local errors=0
    
    # 必要ディレクトリの存在確認
    local required_dirs=(".claude/commands" "commands" "templates" "scripts")
    for dir in "${required_dirs[@]}"; do
        if [[ ! -d "${SCRIPT_DIR}/${dir}" ]]; then
            log_error "必須ディレクトリが見つかりません: $dir"
            ((errors++))
        fi
    done
    
    # CLAUDE.mdの存在確認
    if [[ ! -f "${SCRIPT_DIR}/CLAUDE.md" ]]; then
        log_error "CLAUDE.mdが見つかりません"
        ((errors++))
    fi
    
    # 新しいパスの書き込み権限確認
    local output_base_dir
    output_base_dir=$(echo "$NEW_PATH" | sed 's/\$(.*)//' | sed 's|/[^/]*$||')
    
    if [[ ! -d "$output_base_dir" ]]; then
        log_warning "出力先ディレクトリが存在しません: $output_base_dir"
        log_info "必要に応じて手動で作成してください"
    fi
    
    if [[ "$errors" -eq 0 ]]; then
        log_success "設定検証完了: エラーなし"
        return 0
    else
        log_error "設定検証失敗: $errors 個のエラー"
        return 1
    fi
}

# メイン実行
main() {
    log_info "Claude Code Knowledge Base Update Script v1.0.0"
    log_info "アクション: $ACTION"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "DRY RUN モード: 実際の変更は行いません"
    fi
    
    # バックアップ作成（restore以外）
    if [[ "$ACTION" != "restore" && "$CREATE_BACKUP" == "true" ]]; then
        create_backup
    fi
    
    case "$ACTION" in
        "backup")
            log_success "バックアップが完了しました"
            ;;
        "restore")
            restore_backup
            ;;
        "paths")
            update_paths
            ;;
        "config")
            update_config
            ;;
        "templates")
            update_templates
            ;;
        "sync-git")
            sync_git_changes
            ;;
        "sync-all")
            sync_all_files
            ;;
        "sync-project")
            sync_to_project
            ;;
        "all")
            validate_configuration || exit 1
            sync_git_changes
            update_paths
            update_templates
            update_config
            log_success "全ての更新が完了しました"
            ;;
        *)
            log_error "不明なアクション: $ACTION"
            exit 1
            ;;
    esac
    
    if [[ "$DRY_RUN" != "true" && "$ACTION" != "backup" && "$ACTION" != "restore" ]]; then
        log_info "更新完了時刻: $(date)"
        log_info "バックアップ場所: $BACKUP_DIR"
    fi
}

# スクリプト実行
main "$@"