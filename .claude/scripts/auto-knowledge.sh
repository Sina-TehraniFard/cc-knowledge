#!/bin/bash
# 自動ナレッジ管理スクリプト
# このスクリプトはカスタムコマンドから自動的に呼び出されます

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
GLOBAL_KNOWLEDGE="$HOME/workspace/cc-knowledge/docs/knowledge"

# コンテンツを分析してスコープを決定（グローバル vs プロジェクト固有）
analyze_knowledge_scope() {
    local content="$1"
    local file_path="$2"
    
    # プロジェクト固有を強く示すキーワード（プロジェクト優先）
    local strong_project_keywords=("specific" "custom" "proprietary" "local" "internal" "company" "client" "project" "codebase" "repository" "this-app" "our-system")
    
    # プロジェクト固有を示すキーワード（通常の重み）
    local project_keywords=("business-rule" "domain-specific" "legacy-code" "migration" "config" "environment" "deployment" "workflow" "process" "requirement" "constraint" "limitation" "workaround" "hack" "temporary" "quick-fix")
    
    # グローバル適用可能性を示すキーワード（最低限）
    local global_keywords=("universal" "general" "common" "standard" "reusable" "generic" "best-practice" "pattern" "principle")
    
    local global_score=0
    local project_score=0
    local strong_project_score=0
    
    for keyword in "${strong_project_keywords[@]}"; do
        if echo "$content" | grep -qi "$keyword"; then
            ((strong_project_score += 3))  # 強いプロジェクト固有指標は3点
        fi
    done
    
    for keyword in "${project_keywords[@]}"; do
        if echo "$content" | grep -qi "$keyword"; then
            ((project_score++))
        fi
    done
    
    for keyword in "${global_keywords[@]}"; do
        if echo "$content" | grep -qi "$keyword"; then
            ((global_score++))
        fi
    done
    
    # ファイルパス解析（プロジェクト構造を考慮）
    if [[ -n "$file_path" ]]; then
        # プロジェクト特有のディレクトリ構造
        if echo "$file_path" | grep -qi -E "(src/|lib/|app/|components/|pages/|routes/|models/|controllers/|services/)"; then
            ((project_score += 2))
        fi
        # 設定ファイル系
        if echo "$file_path" | grep -qi -E "(config|settings|env|properties|yaml|json)"; then
            ((project_score += 2))
        fi
    fi
    
    local total_project_score=$((strong_project_score + project_score))
    
    # プロジェクト優先の判定ロジック
    if [[ $strong_project_score -gt 0 ]]; then
        echo "project"  # 強いプロジェクト指標があれば必ずプロジェクト
    elif [[ $total_project_score -ge $global_score ]]; then
        echo "project"  # 同点以上でプロジェクト優先
    elif [[ $global_score -gt 0 && $total_project_score -eq 0 ]]; then
        echo "global"   # 明確にグローバルでプロジェクト要素なし
    else
        echo "project"  # デフォルトはプロジェクト（疑わしきはプロジェクト）
    fi
}

# ナレッジを自動保存
store_knowledge() {
    local title="$1"
    local content="$2"
    local tags="$3"
    local success_rate="$4"
    
    local scope=$(analyze_knowledge_scope "$content" "")
    local timestamp=$(date '+%Y-%m-%d')
    
    # Generate filename
    local filename=$(echo "$title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g')
    
    # Create frontmatter
    local frontmatter="---
title: \"$title\"
tags: [$tags]
created: \"$timestamp\"
success_rate: \"$success_rate\"
scope: \"$scope\"
domain: \"auto-generated\"
---

"
    
    if [[ "$scope" == "global" ]]; then
        echo "$frontmatter$content" > "$GLOBAL_KNOWLEDGE/$filename.md"
        echo "📚 グローバルナレッジに保存: $filename.md"
    else
        echo "$frontmatter$content" > "$PROJECT_ROOT/.claude/knowledge/patterns/$filename.md"
        echo "🏠 プロジェクトナレッジに保存: $filename.md"
    fi
    
    # インデックスを更新
    update_knowledge_indices
}

# ナレッジインデックスを更新
update_knowledge_indices() {
    # Update project index
    local pattern_count=$(find "$PROJECT_ROOT/.claude/knowledge/patterns" -name "*.md" 2>/dev/null | wc -l)
    local lesson_count=$(find "$PROJECT_ROOT/.claude/knowledge/lessons" -name "*.md" 2>/dev/null | wc -l)
    
    sed -i "s/\*\*Total Patterns\*\*: [0-9]*/\*\*Total Patterns\*\*: $pattern_count/" "$PROJECT_ROOT/.claude/knowledge/INDEX.md" 2>/dev/null || true
    sed -i "s/\*\*Total Lessons\*\*: [0-9]*/\*\*Total Lessons\*\*: $lesson_count/" "$PROJECT_ROOT/.claude/knowledge/INDEX.md" 2>/dev/null || true
}

# 昇格候補を確認
check_promotion_candidates() {
    find "$PROJECT_ROOT/.claude/knowledge/patterns" -name "*.md" -type f | while read file; do
        local success_rate=$(grep "^success_rate:" "$file" | sed 's/.*"\([0-9]*\)%".*/\1/')
        local created_date=$(grep "^created:" "$file" | sed 's/.*"\([^"]*\)".*/\1/')
        
        # Simple promotion logic (can be enhanced)
        if [[ "$success_rate" -ge 90 ]] && [[ -n "$created_date" ]]; then
            echo "🎯 昇格候補: $(basename "$file")"
            # Auto-promote logic can be added here
        fi
    done
}

# 作業完了時の自動ナレッジ保存
auto_save_work_knowledge() {
    local work_type="$1"      # 作業タイプ (analysis, implementation, debugging, etc.)
    local work_target="$2"    # 作業対象 (ファイル名、機能名等)
    local work_content="$3"   # 作業内容・発見事項
    local work_result="$4"    # 作業結果・成果
    local file_paths="$5"     # 関連ファイルパス (オプション)
    
    if [[ -z "$work_content" ]]; then
        return 0  # 内容がない場合はスキップ
    fi
    
    local title="${work_type} - ${work_target}"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # ナレッジ内容の構築
    local knowledge_content="# ${title}

## 作業概要
- **作業タイプ**: ${work_type}
- **対象**: ${work_target}
- **日時**: ${timestamp}

## 作業内容・発見事項
${work_content}

## 結果・成果
${work_result}

## 関連ファイル
${file_paths:-N/A}

## 学習ポイント
- プロジェクト固有の知見として蓄積
- 類似作業時の参考資料として活用

## タグ
- ${work_type}
- project-specific
- $(basename "$work_target" 2>/dev/null || echo "general")
"
    
    # 自動保存実行
    store_knowledge "$title" "$knowledge_content" "\"${work_type}\", \"project-specific\", \"auto-generated\"" "100"
    
    echo "📝 作業ナレッジを自動保存しました: $title"
}

# 問題解決パターンの自動保存
auto_save_problem_solution() {
    local problem="$1"        # 問題の説明
    local solution="$2"       # 解決方法
    local context="$3"        # 問題が発生した文脈
    local prevention="$4"     # 予防策（オプション）
    
    if [[ -z "$problem" || -z "$solution" ]]; then
        return 0
    fi
    
    local title="Problem Solution - $(echo "$problem" | head -c 50)..."
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    local knowledge_content="# ${title}

## 問題
${problem}

## 解決方法
${solution}

## 発生文脈
${context}

## 予防策
${prevention:-今後の対策は検討中}

## メモ
- 日時: ${timestamp}
- プロジェクト固有の問題解決パターン
- 類似問題発生時の参考資料

## タグ
- problem-solving
- project-specific
- troubleshooting
"
    
    store_knowledge "$title" "$knowledge_content" "\"problem-solving\", \"project-specific\", \"troubleshooting\"" "95"
    
    echo "🔧 問題解決パターンを自動保存しました"
}

# 実装パターンの自動保存
auto_save_implementation_pattern() {
    local pattern_name="$1"   # パターン名
    local use_case="$2"       # 使用場面
    local implementation="$3" # 実装内容
    local benefits="$4"       # メリット
    local considerations="$5" # 注意点
    
    if [[ -z "$pattern_name" || -z "$implementation" ]]; then
        return 0
    fi
    
    local title="Implementation Pattern - ${pattern_name}"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    local knowledge_content="# ${title}

## パターン名
${pattern_name}

## 使用場面
${use_case}

## 実装方法
${implementation}

## メリット
${benefits}

## 注意点・考慮事項
${considerations}

## プロジェクト情報
- 記録日時: ${timestamp}
- このプロジェクトでの実装パターン
- 再利用可能な実装知識

## タグ
- implementation-pattern
- project-specific
- reusable
"
    
    store_knowledge "$title" "$knowledge_content" "\"implementation-pattern\", \"project-specific\", \"reusable\"" "90"
    
    echo "💡 実装パターンを自動保存しました: $pattern_name"
}

# Export functions for use by commands
export -f analyze_knowledge_scope
export -f store_knowledge
export -f update_knowledge_indices
export -f check_promotion_candidates
export -f auto_save_work_knowledge
export -f auto_save_problem_solution
export -f auto_save_implementation_pattern
