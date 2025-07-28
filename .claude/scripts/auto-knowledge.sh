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
    
    # グローバル適用可能性を示すキーワード
    local global_keywords=("refactoring" "testing" "design-pattern" "architecture" "best-practice")
    # プロジェクト固有を示すキーワード
    local project_keywords=("business-rule" "domain-specific" "legacy-code" "migration")
    
    local global_score=0
    local project_score=0
    
    for keyword in "${global_keywords[@]}"; do
        if echo "$content" | grep -qi "$keyword"; then
            ((global_score++))
        fi
    done
    
    for keyword in "${project_keywords[@]}"; do
        if echo "$content" | grep -qi "$keyword"; then
            ((project_score++))
        fi
    done
    
    if [[ $global_score > $project_score ]]; then
        echo "global"
    else
        echo "project"
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

# Export functions for use by commands
export -f analyze_knowledge_scope
export -f store_knowledge
export -f update_knowledge_indices
export -f check_promotion_candidates
