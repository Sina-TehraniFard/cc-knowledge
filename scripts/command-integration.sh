#!/bin/bash
# カスタムコマンド統合スクリプト - Claude Code 自動保存システム Phase 2
# 用途: 既存の11個のカスタムコマンドに自動保存機能を統合
# 作成者: Claude Code Auto-Save System Phase 2

# スクリプトディレクトリの取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 統合対象コマンドの定義
COMMANDS=(
    "design"
    "implement" 
    "fix-test"
    "next-steps"
    "test-review"
    "update-docs"
    "commit-changes"
    "orchestrator"
    "pr"
    "review-pr-local-branch"
    "lint-test"
)

# 統合コードテンプレート
get_integration_code() {
    local command_name="$1"
    cat << 'EOF'

# ===== Claude Code 自動保存システム統合 =====
# Phase 2: カスタムコマンド統合（自動追加）

# 統合条件チェック
if [[ -f "$HOME/workspace/cc-knowledge/scripts/auto-save-core.sh" ]]; then
    # ファイル生成が確認できた場合のみ自動保存を実行
    if [[ -n "$generated_file_path" && -n "$generated_content" ]]; then
        # 自動保存システムの読み込み（エラー時は無視）
        source "$HOME/workspace/cc-knowledge/scripts/auto-save-core.sh" 2>/dev/null || {
            echo "# 注意: 自動保存システムが利用できません" >&2
        }
        
        # 自動保存の実行
        if command -v auto_save_generated_file >/dev/null 2>&1; then
            auto_save_generated_file "$generated_file_path" "$generated_content" "COMMAND_NAME" 2>/dev/null || {
                echo "# 自動保存に失敗しましたが、処理を継続します" >&2
            }
        fi
    fi
fi

# ===== 自動保存システム統合終了 =====
EOF
}

# 安全なファイル編集のための関数
safe_add_integration() {
    local command_file="$1"
    local command_name="$2"
    local backup_file="${command_file}.backup.$(date '+%Y%m%d_%H%M%S')"
    
    echo "処理中: $command_name"
    
    # バックアップ作成
    cp "$command_file" "$backup_file"
    
    # 既に統合済みかチェック
    if grep -q "Claude Code 自動保存システム統合" "$command_file"; then
        echo "  ⚠️  既に統合済み: $command_name"
        rm "$backup_file"
        return 0
    fi
    
    # 統合コードを生成（コマンド名を置換）
    local integration_code=$(get_integration_code "$command_name" | sed "s/COMMAND_NAME/$command_name/g")
    
    # ファイルの最後に統合コードを追加
    echo "$integration_code" >> "$command_file"
    
    echo "  ✅ 統合完了: $command_name (バックアップ: $(basename "$backup_file"))"
    return 0
}

# メイン統合処理
integrate_all_commands() {
    local commands_dir="$HOME/workspace/cc-knowledge/commands"
    local success_count=0
    local skip_count=0
    local error_count=0
    
    echo "========================================="
    echo "🚀 Phase 2: カスタムコマンド統合開始"
    echo "========================================="
    echo "対象ディレクトリ: $commands_dir"
    echo "対象コマンド数: ${#COMMANDS[@]}"
    echo ""
    
    for command in "${COMMANDS[@]}"; do
        local command_file="$commands_dir/$command.md"
        
        if [[ -f "$command_file" ]]; then
            if safe_add_integration "$command_file" "$command"; then
                ((success_count++))
            else
                ((error_count++))
            fi
        else
            echo "  ❌ ファイルが存在しません: $command.md"
            ((error_count++))
        fi
    done
    
    echo ""
    echo "========================================="
    echo "📊 統合結果サマリー"
    echo "========================================="
    echo "✅ 成功: $success_count"
    echo "⚠️  既統合: $skip_count" 
    echo "❌ エラー: $error_count"
    echo "📁 バックアップ場所: $commands_dir/*.backup.*"
    echo ""
    
    if [[ $success_count -gt 0 ]]; then
        echo "🎉 Phase 2統合完了！"
        echo "💡 次回からすべてのカスタムコマンドで自動保存されます"
    else
        echo "⚠️  新たに統合されたコマンドはありません"
    fi
}

# 統合状況の確認
check_integration_status() {
    local commands_dir="$HOME/workspace/cc-knowledge/commands"
    local integrated_count=0
    local total_count=${#COMMANDS[@]}
    
    echo "========================================"
    echo "📋 カスタムコマンド統合状況"
    echo "========================================"
    
    for command in "${COMMANDS[@]}"; do
        local command_file="$commands_dir/$command.md"
        
        if [[ -f "$command_file" ]]; then
            if grep -q "Claude Code 自動保存システム統合" "$command_file"; then
                echo "✅ $command.md - 統合済み"
                ((integrated_count++))
            else
                echo "❌ $command.md - 未統合"
            fi
        else
            echo "❓ $command.md - ファイル不存在"
        fi
    done
    
    echo ""
    echo "統合率: $integrated_count/$total_count ($(( integrated_count * 100 / total_count ))%)"
    
    if [[ $integrated_count -eq $total_count ]]; then
        echo "🎉 すべてのコマンドが統合済みです！"
        return 0
    else
        echo "💡 未統合のコマンドがあります。integrate を実行してください。"
        return 1
    fi
}

# 統合の取り消し（バックアップからの復元）
rollback_integration() {
    local commands_dir="$HOME/workspace/cc-knowledge/commands"
    local rollback_count=0
    
    echo "========================================"
    echo "🔄 統合のロールバック開始"
    echo "========================================"
    
    for command in "${COMMANDS[@]}"; do
        local command_file="$commands_dir/$command.md"
        local latest_backup=$(ls -t "${command_file}.backup."* 2>/dev/null | head -1)
        
        if [[ -n "$latest_backup" && -f "$latest_backup" ]]; then
            cp "$latest_backup" "$command_file"
            echo "✅ $command.md - バックアップから復元"
            ((rollback_count++))
        else
            echo "❌ $command.md - バックアップファイルが見つかりません"
        fi
    done
    
    echo ""
    echo "ロールバック完了: $rollback_count ファイル"
}

# テスト用の統合確認
test_integration() {
    echo "========================================"
    echo "🧪 統合テスト実行"
    echo "========================================"
    
    # 自動保存システムの動作確認
    if [[ -f "$HOME/workspace/cc-knowledge/scripts/auto-save-core.sh" ]]; then
        echo "✅ 自動保存システム: 利用可能"
        
        # テスト実行
        source "$HOME/workspace/cc-knowledge/scripts/auto-save-core.sh"
        if command -v auto_save_generated_file >/dev/null 2>&1; then
            echo "✅ 自動保存関数: 利用可能"
            
            # 簡易テスト
            local test_result=$(auto_save_generated_file "test-integration.md" "# 統合テスト\nPhase 2統合テストです。" "integration-test" 2>&1)
            if [[ $? -eq 0 ]]; then
                echo "✅ 統合テスト: 成功"
            else
                echo "❌ 統合テスト: 失敗"
                echo "エラー詳細: $test_result"
            fi
        else
            echo "❌ 自動保存関数: 利用不可"
        fi
    else
        echo "❌ 自動保存システム: Phase 1が未完了"
    fi
    
    # 統合状況確認
    check_integration_status
}

# 使用方法表示
show_usage() {
    echo "Claude Code 自動保存システム Phase 2 統合ツール"
    echo ""
    echo "使用方法:"
    echo "  $0 integrate    - 全コマンドに自動保存機能を統合"
    echo "  $0 status       - 統合状況を確認"
    echo "  $0 test         - 統合テストを実行"
    echo "  $0 rollback     - 統合をロールバック（バックアップから復元）"
    echo "  $0 help         - このヘルプを表示"
    echo ""
    echo "対象コマンド: ${COMMANDS[*]}"
}

# メイン処理
main() {
    case "${1:-integrate}" in
        "integrate")
            integrate_all_commands
            ;;
        "status")
            check_integration_status
            ;;
        "test")
            test_integration
            ;;
        "rollback")
            rollback_integration
            ;;
        "help"|"-h"|"--help")
            show_usage
            ;;
        *)
            echo "不明なオプション: $1"
            show_usage
            exit 1
            ;;
    esac
}

# スクリプトが直接実行された場合
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

echo "📋 Phase 2統合スクリプト読み込み完了"