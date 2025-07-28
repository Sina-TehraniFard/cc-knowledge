#!/bin/bash
# Claude Code 自動保存システム - カスタムコマンド統合用スクリプト
# 用途: 各カスタムコマンドから呼び出される統合エントリーポイント
# 作成者: Claude Code Auto-Save System Phase 2

# スクリプトディレクトリの取得
INTEGRATION_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 自動保存コアシステムの読み込み
if [[ -f "$INTEGRATION_SCRIPT_DIR/auto-save-core.sh" ]]; then
    source "$INTEGRATION_SCRIPT_DIR/auto-save-core.sh"
else
    echo "警告: auto-save-core.sh が見つかりません。自動保存をスキップします。" >&2
fi

# カスタムコマンド統合用の簡易ラッパー関数
integrate_auto_save() {
    local generated_file_path="$1"
    local generated_content="$2"
    local command_name="$3"
    local additional_context="$4"
    
    # 自動保存システムが利用可能かチェック
    if ! command -v auto_save_generated_file >/dev/null 2>&1; then
        echo "警告: 自動保存システムが利用できません。手動保存が必要です。" >&2
        return 1
    fi
    
    # ファイルパスと内容が有効かチェック
    if [[ -z "$generated_file_path" || -z "$generated_content" ]]; then
        echo "警告: 自動保存に必要な情報が不足しています。" >&2
        return 1
    fi
    
    # 自動保存の実行
    if auto_save_generated_file "$generated_file_path" "$generated_content" "$command_name" "$additional_context"; then
        echo "✅ 自動保存完了: $(basename "$generated_file_path")"
        return 0
    else
        echo "❌ 自動保存に失敗しました: $(basename "$generated_file_path")" >&2
        return 1
    fi
}

echo "📋 Claude Code 自動保存統合システム読み込み完了"