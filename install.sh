#!/bin/bash

# Claude Code ナレッジ管理システム インストーラー
# バージョン: 1.0.0

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
GLOBAL_KNOWLEDGE_DIR="$HOME/workspace/cc-knowledge"
TEMPLATES_DIR="$SCRIPT_DIR/templates"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[情報]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[成功]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[警告]${NC} $1"
}

log_error() {
    echo -e "${RED}[エラー]${NC} $1"
}

# ヘルプ機能
show_help() {
    cat << EOF
Claude Code ナレッジ管理システム インストーラー

使用方法:
    ./install.sh [オプション]

オプション:
    --global                グローバルナレッジベースをインストール (初回のみ)
    --project [パス]        プロジェクト固有の設定を初期化
    --update                グローバルナレッジベースを更新
    --promote-knowledge     プロジェクトナレッジをグローバルに昇格
    --help                  このヘルプを表示

使用例:
    # グローバルインストール（初回）
    ./install.sh --global

    # 現在のプロジェクトを初期化
    ./install.sh --project

    # 特定のプロジェクトを初期化
    ./install.sh --project /path/to/project

    # グローバルナレッジを更新
    ./install.sh --update

EOF
}

# Detect project type
detect_project_type() {
    local project_path=${1:-"$PWD"}
    
    if [[ -f "$project_path/package.json" ]]; then
        echo "nodejs"
    elif [[ -f "$project_path/pom.xml" ]]; then
        echo "java"
    elif [[ -f "$project_path/build.gradle" || -f "$project_path/build.gradle.kts" ]]; then
        echo "gradle"
    elif [[ -f "$project_path/Cargo.toml" ]]; then
        echo "rust"
    elif [[ -f "$project_path/go.mod" ]]; then
        echo "go"
    elif [[ -f "$project_path/requirements.txt" || -f "$project_path/pyproject.toml" ]]; then
        echo "python"
    else
        echo "generic"
    fi
}

# Global installation
install_global() {
    log_info "グローバルナレッジベースをインストール中..."
    
    # Check if we're already in the target directory
    if [[ "$SCRIPT_DIR" == "$GLOBAL_KNOWLEDGE_DIR" ]]; then
        log_info "すでにグローバルナレッジディレクトリにいます"
        
        # Just ensure proper permissions
        if [[ -d "$SCRIPT_DIR/scripts" ]]; then
            chmod +x "$SCRIPT_DIR/scripts"/*.sh
            log_success "スクリプトの権限を更新しました"
        fi
        
        # Create templates in place
        create_templates
        
        # Setup shell integration
        setup_shell_integration
        
        log_success "グローバルインストールが完了しました！"
        log_info "グローバルナレッジベース: $GLOBAL_KNOWLEDGE_DIR"
        
        # Show next steps
        cat << EOF

${GREEN}次のステップ:${NC}
1. ターミナルを再起動するか、以下を実行: source ~/.bashrc (または ~/.zshrc)
2. プロジェクトディレクトリに移動
3. 実行: ~/workspace/cc-knowledge/install.sh --project

EOF
        return
    fi
    
    # If not in target, do the copy (for future use if structure changes)
    # Create global directory structure
    mkdir -p "$GLOBAL_KNOWLEDGE_DIR"/{docs/{knowledge,guidelines},scripts,templates}
    
    # Copy knowledge base files
    if [[ -d "$SCRIPT_DIR/docs" ]]; then
        cp -r "$SCRIPT_DIR/docs"/* "$GLOBAL_KNOWLEDGE_DIR/docs/"
        log_success "ナレッジベースをコピーしました"
    fi
    
    # Copy scripts
    if [[ -d "$SCRIPT_DIR/scripts" ]]; then
        cp -r "$SCRIPT_DIR/scripts"/* "$GLOBAL_KNOWLEDGE_DIR/scripts/"
        chmod +x "$GLOBAL_KNOWLEDGE_DIR/scripts"/*.sh
        log_success "スクリプトをインストールしました"
    fi
    
    # Create templates
    create_templates
    
    # Setup shell integration
    setup_shell_integration
    
    log_success "グローバルインストールが完了しました！"
    log_info "グローバルナレッジベース: $GLOBAL_KNOWLEDGE_DIR"
    
    # Show next steps
    cat << EOF

${GREEN}次のステップ:${NC}
1. ターミナルを再起動するか、以下を実行: source ~/.bashrc (または ~/.zshrc)
2. プロジェクトディレクトリに移動
3. 実行: ./install.sh --project

EOF
}

# Create command templates for different project types
create_templates() {
    log_info "コマンドテンプレートを作成中..."
    
    # Create template directories
    mkdir -p "$GLOBAL_KNOWLEDGE_DIR/templates"/{nodejs,java,python,generic}/commands
    
    # Generic templates (will be copied for all project types)
    local generic_commands=(
        "design.md"
        "implement.md" 
        "fix-test.md"
        "next-steps.md"
        "pr.md"
        "test-review.md"
    )
    
    for cmd in "${generic_commands[@]}"; do
        if [[ -f "$SCRIPT_DIR/commands/$cmd" ]]; then
            # Copy to all template directories
            for proj_type in nodejs java python generic; do
                cp "$SCRIPT_DIR/commands/$cmd" "$GLOBAL_KNOWLEDGE_DIR/templates/$proj_type/commands/"
            done
        fi
    done
    
    log_success "コマンドテンプレートを作成しました"
}

# シェル統合の設定
setup_shell_integration() {
    log_info "シェル統合を設定中..."
    
    local shell_config=""
    if [[ -n "$ZSH_VERSION" ]]; then
        shell_config="$HOME/.zshrc"
    elif [[ -n "$BASH_VERSION" ]]; then
        shell_config="$HOME/.bashrc"
    else
        log_warning "不明なシェルです。自動設定をスキップします"
        return
    fi
    
    # Check if already configured
    if grep -q "cc-knowledge" "$shell_config" 2>/dev/null; then
        log_info "シェル統合はすでに設定済みです"
        return
    fi
    
    # Add integration
    cat >> "$shell_config" << 'EOF'

# Claude Code Knowledge Management System
if [[ -f "$HOME/workspace/cc-knowledge/scripts/session-manager.sh" ]]; then
    source "$HOME/workspace/cc-knowledge/scripts/session-manager.sh"
fi

# Auto-detect Claude Code projects
cd() {
    builtin cd "$@"
    if [[ -f ".claude/CLAUDE.md" ]]; then
        echo "🔧 Claude Code環境を検出しました"
        echo "💡 利用可能なコマンド: /design, /implement, /fix-test, /next-steps, /pr"
        if [[ -f ".claude/knowledge/INDEX.md" ]]; then
            echo "📚 プロジェクト固有のナレッジが利用可能です"
        fi
    fi
}
EOF
    
    log_success "$shell_config にシェル統合を設定しました"
}

# Project initialization
initialize_project() {
    local project_path=${1:-"$PWD"}
    local project_type
    
    log_info "プロジェクトを初期化中: $project_path"
    
    # Detect project type
    project_type=$(detect_project_type "$project_path")
    log_info "検出されたプロジェクトタイプ: $project_type"
    
    # Create project .claude directory
    mkdir -p "$project_path/.claude"/{commands,knowledge/{patterns,lessons}}
    
    # Copy appropriate command templates
    local template_dir="$GLOBAL_KNOWLEDGE_DIR/templates/$project_type"
    if [[ ! -d "$template_dir" ]]; then
        template_dir="$GLOBAL_KNOWLEDGE_DIR/templates/generic"
    fi
    
    if [[ -d "$template_dir/commands" ]]; then
        cp -r "$template_dir/commands"/* "$project_path/.claude/commands/"
        log_success "$project_type テンプレートからコマンドをコピーしました"
    fi
    
    # Create project CLAUDE.md
    create_project_claude_md "$project_path" "$project_type"
    
    # Create project knowledge INDEX
    create_project_knowledge_index "$project_path"
    
    # Initialize auto-knowledge management
    setup_auto_knowledge_management "$project_path"
    
    log_success "プロジェクトの初期化が完了しました！"
    log_info "プロジェクトナレッジ: $project_path/.claude/knowledge/"
    
    # Show project-specific info
    cat << EOF

${GREEN}プロジェクト設定完了:${NC}
- コマンド: $project_path/.claude/commands/
- ナレッジ: $project_path/.claude/knowledge/
- 設定: $project_path/.claude/CLAUDE.md

${BLUE}利用可能なコマンド:${NC}
- /design       - 設計ドキュメントを作成
- /implement    - TDD実装
- /fix-test     - テストの問題を修正
- /next-steps   - 次のステップを生成
- /pr           - PRドキュメントを作成

EOF
}

# Create project-specific CLAUDE.md
create_project_claude_md() {
    local project_path="$1"
    local project_type="$2"
    local project_name=$(basename "$project_path")
    
    cat > "$project_path/.claude/CLAUDE.md" << EOF
# $project_name - Claude Code Configuration

## Project Information
- **Name**: $project_name
- **Type**: $project_type
- **Knowledge Management**: Enabled
- **Auto-promotion**: Enabled

## Project-Specific Guidelines

### Development Standards
- Follow existing code patterns in the codebase
- Use TDD for new features
- Update tests when modifying existing code

### Knowledge Management
- Project-specific patterns are stored in \`.claude/knowledge/patterns/\`
- Lessons learned are stored in \`.claude/knowledge/lessons/\`
- Patterns with high reusability are auto-promoted to global knowledge

### Custom Commands
Commands are customized for $project_type projects and available in \`.claude/commands/\`

## Auto-Knowledge Settings
- **Promotion Threshold**: 90% success rate + 3+ references
- **Scope Detection**: Automatic based on content analysis
- **Pattern Recognition**: Enabled

## Local Overrides
Add project-specific overrides below:

<!-- Add custom guidelines here -->

EOF
    
    log_success "プロジェクトCLAUDE.mdを作成しました"
}

# Create project knowledge index
create_project_knowledge_index() {
    local project_path="$1"
    
    cat > "$project_path/.claude/knowledge/INDEX.md" << EOF
# Project Knowledge Index

## 📚 Overview
This directory contains project-specific knowledge and patterns that are unique to this codebase.

## 🎯 Categories

### Patterns (\`patterns/\`)
- Project-specific implementation patterns
- Architecture-specific solutions
- Framework-specific techniques

### Lessons (\`lessons/\`)
- Troubleshooting guides specific to this project
- Performance optimizations discovered
- Gotchas and pitfalls to avoid

## 🔄 Auto-Management
- Patterns are automatically categorized based on content
- High-value patterns are promoted to global knowledge
- Knowledge is updated as you work

## 📊 Statistics
- **Total Patterns**: 0
- **Total Lessons**: 0
- **Promoted to Global**: 0

---
*This index is automatically maintained*
EOF
    
    log_success "プロジェクトナレッジインデックスを作成しました"
}

# Setup auto-knowledge management hooks
setup_auto_knowledge_management() {
    local project_path="$1"
    
    # Create knowledge management script
    cat > "$project_path/.claude/scripts/auto-knowledge.sh" << 'EOF'
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
EOF
    
    chmod +x "$project_path/.claude/scripts/auto-knowledge.sh"
    mkdir -p "$project_path/.claude/scripts"
    
    log_success "自動ナレッジ管理の設定が完了しました"
}

# グローバルナレッジベースの更新
update_global() {
    log_info "グローバルナレッジベースを更新中..."
    
    if [[ ! -d "$GLOBAL_KNOWLEDGE_DIR" ]]; then
        log_error "グローバルナレッジベースが見つかりません。まず --global を実行してください。"
        exit 1
    fi
    
    # Update knowledge files
    if [[ -d "$SCRIPT_DIR/docs" ]]; then
        cp -r "$SCRIPT_DIR/docs"/* "$GLOBAL_KNOWLEDGE_DIR/docs/"
        log_success "ナレッジベースを更新しました"
    fi
    
    # Update scripts
    if [[ -d "$SCRIPT_DIR/scripts" ]]; then
        cp -r "$SCRIPT_DIR/scripts"/* "$GLOBAL_KNOWLEDGE_DIR/scripts/"
        chmod +x "$GLOBAL_KNOWLEDGE_DIR/scripts"/*.sh
        log_success "スクリプトを更新しました"
    fi
    
    log_success "グローバル更新が完了しました！"
}

# Main execution
main() {
    case "$1" in
        --global)
            install_global
            ;;
        --project)
            initialize_project "$2"
            ;;
        --update)
            update_global
            ;;
        --help)
            show_help
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
}

# Check if no arguments provided
if [[ $# -eq 0 ]]; then
    show_help
    exit 1
fi

main "$@"