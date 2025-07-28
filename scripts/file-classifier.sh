#!/bin/bash
# ファイル分類エンジン - Claude Code 自動保存システム
# 用途: ナレッジファイル vs ドキュメントファイルの自動分類
# 作成者: Claude Code Auto-Save System

# デバッグフラグ
DEBUG_CLASSIFIER=${DEBUG_CLASSIFIER:-false}

# ログ関数
log_classifier() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    if [[ "$DEBUG_CLASSIFIER" == "true" ]]; then
        echo "[$timestamp] [$level] [file-classifier] $message" >&2
    fi
}

# ナレッジファイルの判定条件をチェック
is_knowledge_content() {
    local content="$1"
    
    # ナレッジキーワードの検索
    local knowledge_keywords=(
        "パターン" "手法" "ベストプラクティス" "best-practice"
        "再利用可能" "汎用的" "実証済み" "成功率"
        "technique" "pattern" "guide" "guideline"
        "効果測定" "改善率" "複雑度削減" "パフォーマンス向上"
    )
    
    for keyword in "${knowledge_keywords[@]}"; do
        if echo "$content" | grep -qi "$keyword"; then
            log_classifier "DEBUG" "ナレッジキーワード検出: $keyword"
            return 0
        fi
    done
    
    # YAMLフロントマターのチェック（ナレッジファイル特有）
    if echo "$content" | grep -q "^success_rate:"; then
        log_classifier "DEBUG" "success_rate フィールド検出"
        return 0
    fi
    
    if echo "$content" | grep -q "^tags:.*\(pattern\|technique\|refactoring\)"; then
        log_classifier "DEBUG" "技術タグ検出"
        return 0
    fi
    
    return 1
}

# ドキュメントファイルの判定条件をチェック
is_document_content() {
    local content="$1"
    
    # ドキュメントキーワードの検索
    local document_keywords=(
        "設計書" "仕様書" "調査結果" "会議録" "報告書"
        "プロジェクト固有" "チケット" "TASK-" "ISSUE-"
        "design" "specification" "investigation" "report"
        "meeting" "project-specific"
    )
    
    for keyword in "${document_keywords[@]}"; do
        if echo "$content" | grep -qi "$keyword"; then
            log_classifier "DEBUG" "ドキュメントキーワード検出: $keyword"
            return 0
        fi
    done
    
    # プロジェクト固有のパスが含まれているかチェック
    if echo "$content" | grep -q "workspace/tasks/"; then
        log_classifier "DEBUG" "プロジェクト固有パス検出"
        return 0
    fi
    
    return 1
}

# ファイル名による分類判定
classify_by_filename() {
    local file_path="$1"
    local filename=$(basename "$file_path")
    
    # ナレッジファイル名パターン
    local knowledge_patterns=(
        "*pattern*" "*patterns*" "*technique*" "*guide*" 
        "*guidelines*" "*best-practice*" "*refactoring*"
    )
    
    for pattern in "${knowledge_patterns[@]}"; do
        if [[ "$filename" == $pattern ]]; then
            log_classifier "DEBUG" "ナレッジファイル名パターン検出: $pattern"
            echo "knowledge"
            return 0
        fi
    done
    
    # ドキュメントファイル名パターン
    local document_patterns=(
        "*design*" "*spec*" "*report*" "*investigation*"
        "*meeting*" "*analysis*" "*summary*"
    )
    
    for pattern in "${document_patterns[@]}"; do
        if [[ "$filename" == $pattern ]]; then
            log_classifier "DEBUG" "ドキュメントファイル名パターン検出: $pattern"
            echo "document"
            return 0
        fi
    done
    
    return 1
}

# コマンド別のデフォルト分類ルール
get_command_default_classification() {
    local command_context="$1"
    
    case "$command_context" in
        "design"|"design.md")
            echo "document"
            ;;
        "implement"|"implement.md")
            echo "knowledge"
            ;;
        "fix-test"|"fix-test.md")
            echo "knowledge"
            ;;
        "next-steps"|"next-steps.md")
            echo "document"
            ;;
        "pr"|"pr.md")
            echo "document"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# メイン分類関数
classify_file() {
    local file_path="$1"
    local content="$2"
    local command_context="$3"
    
    log_classifier "INFO" "ファイル分類開始: $file_path (command: $command_context)"
    
    # 引数チェック
    if [[ -z "$file_path" || -z "$content" ]]; then
        log_classifier "ERROR" "必須引数が不足: file_path=$file_path, content_length=${#content}"
        echo "unknown"
        return 1
    fi
    
    # 1. ファイル名による分類を最初に試行
    local filename_result
    if filename_result=$(classify_by_filename "$file_path"); then
        log_classifier "INFO" "ファイル名による分類結果: $filename_result"
        echo "$filename_result"
        return 0
    fi
    
    # 2. 内容による分類
    if is_knowledge_content "$content"; then
        log_classifier "INFO" "内容分析によりナレッジファイルと判定"
        echo "knowledge"
        return 0
    fi
    
    if is_document_content "$content"; then
        log_classifier "INFO" "内容分析によりドキュメントファイルと判定"
        echo "document"
        return 0
    fi
    
    # 3. コマンド別デフォルト分類
    local command_default=$(get_command_default_classification "$command_context")
    if [[ "$command_default" != "unknown" ]]; then
        log_classifier "INFO" "コマンド別デフォルト分類適用: $command_default"
        echo "$command_default"
        return 0
    fi
    
    # 4. デフォルトはドキュメント
    log_classifier "INFO" "デフォルト分類適用: document"
    echo "document"
    return 0
}

# 分類精度向上のための学習機能（将来拡張用）
record_classification_feedback() {
    local file_path="$1"
    local predicted_class="$2"
    local actual_class="$3"
    local feedback_file="$HOME/.claude/logs/classification-feedback.log"
    
    if [[ "$predicted_class" != "$actual_class" ]]; then
        mkdir -p "$(dirname "$feedback_file")"
        echo "$(date -Iseconds) MISMATCH $file_path $predicted_class $actual_class" >> "$feedback_file"
        log_classifier "WARN" "分類精度改善のためのフィードバック記録: $file_path"
    fi
}

# 設定読み込み（オプション）
load_classification_config() {
    local config_file="$HOME/.claude-config.yml"
    
    if [[ -f "$config_file" ]]; then
        log_classifier "INFO" "設定ファイル読み込み: $config_file"
        # YAML パースは複雑なので、簡易的な grep ベースで対応
        # 将来的には yq などのツールを使用することを検討
    fi
}

# 使用例とテスト用関数
test_classifier() {
    echo "=== ファイル分類エンジンテスト ==="
    
    # テストケース1: ナレッジファイル
    local knowledge_content="---
title: 複雜な条件ロジックリファクタリングパターン
tags: [refactoring, pattern]
success_rate: 95%
---
このパターンは実証済みの手法です。"
    
    local result1=$(classify_file "complex-logic-patterns.md" "$knowledge_content" "implement")
    echo "テスト1 (ナレッジ): $result1"
    
    # テストケース2: ドキュメントファイル
    local document_content="# プロジェクト設計書
TASK-12345 の設計内容
プロジェクト固有の実装について説明します。"
    
    local result2=$(classify_file "project-design.md" "$document_content" "design")
    echo "テスト2 (ドキュメント): $result2"
    
    echo "=== テスト完了 ==="
}

# スクリプトが直接実行された場合のテスト
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    DEBUG_CLASSIFIER=true
    test_classifier
fi

log_classifier "INFO" "ファイル分類エンジン読み込み完了"