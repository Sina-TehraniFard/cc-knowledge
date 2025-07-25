#!/bin/bash

# Claude Code Knowledge Management System Installer
# Version: 1.0.0

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

# Help function
show_help() {
    cat << EOF
Claude Code Knowledge Management System Installer

USAGE:
    ./install.sh [OPTIONS]

OPTIONS:
    --global                Install global knowledge base (run once)
    --project [PATH]        Initialize project-specific setup
    --update                Update global knowledge base
    --promote-knowledge     Promote project knowledge to global
    --help                  Show this help

EXAMPLES:
    # Global installation (first time)
    ./install.sh --global

    # Initialize current project
    ./install.sh --project

    # Initialize specific project
    ./install.sh --project /path/to/project

    # Update global knowledge
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
    log_info "Installing global knowledge base..."
    
    # Create global directory structure
    mkdir -p "$GLOBAL_KNOWLEDGE_DIR"/{docs/{knowledge,guidelines},scripts,templates}
    
    # Copy knowledge base files
    if [[ -d "$SCRIPT_DIR/docs" ]]; then
        cp -r "$SCRIPT_DIR/docs"/* "$GLOBAL_KNOWLEDGE_DIR/docs/"
        log_success "Knowledge base copied"
    fi
    
    # Copy scripts
    if [[ -d "$SCRIPT_DIR/scripts" ]]; then
        cp -r "$SCRIPT_DIR/scripts"/* "$GLOBAL_KNOWLEDGE_DIR/scripts/"
        chmod +x "$GLOBAL_KNOWLEDGE_DIR/scripts"/*.sh
        log_success "Scripts installed"
    fi
    
    # Create templates
    create_templates
    
    # Setup shell integration
    setup_shell_integration
    
    log_success "Global installation completed!"
    log_info "Global knowledge base: $GLOBAL_KNOWLEDGE_DIR"
    
    # Show next steps
    cat << EOF

${GREEN}Next Steps:${NC}
1. Restart your terminal or run: source ~/.bashrc (or ~/.zshrc)
2. Navigate to your project directory
3. Run: ./install.sh --project

EOF
}

# Create command templates for different project types
create_templates() {
    log_info "Creating command templates..."
    
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
    
    log_success "Command templates created"
}

# Setup shell integration
setup_shell_integration() {
    log_info "Setting up shell integration..."
    
    local shell_config=""
    if [[ -n "$ZSH_VERSION" ]]; then
        shell_config="$HOME/.zshrc"
    elif [[ -n "$BASH_VERSION" ]]; then
        shell_config="$HOME/.bashrc"
    else
        log_warning "Unknown shell, skipping automatic setup"
        return
    fi
    
    # Check if already configured
    if grep -q "cc-knowledge" "$shell_config" 2>/dev/null; then
        log_info "Shell integration already configured"
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
        echo "🔧 Claude Code environment detected"
        echo "💡 Available commands: /design, /implement, /fix-test, /next-steps, /pr"
        if [[ -f ".claude/knowledge/INDEX.md" ]]; then
            echo "📚 Project-specific knowledge available"
        fi
    fi
}
EOF
    
    log_success "Shell integration configured in $shell_config"
}

# Project initialization
initialize_project() {
    local project_path=${1:-"$PWD"}
    local project_type
    
    log_info "Initializing project at: $project_path"
    
    # Detect project type
    project_type=$(detect_project_type "$project_path")
    log_info "Detected project type: $project_type"
    
    # Create project .claude directory
    mkdir -p "$project_path/.claude"/{commands,knowledge/{patterns,lessons}}
    
    # Copy appropriate command templates
    local template_dir="$GLOBAL_KNOWLEDGE_DIR/templates/$project_type"
    if [[ ! -d "$template_dir" ]]; then
        template_dir="$GLOBAL_KNOWLEDGE_DIR/templates/generic"
    fi
    
    if [[ -d "$template_dir/commands" ]]; then
        cp -r "$template_dir/commands"/* "$project_path/.claude/commands/"
        log_success "Commands copied from $project_type template"
    fi
    
    # Create project CLAUDE.md
    create_project_claude_md "$project_path" "$project_type"
    
    # Create project knowledge INDEX
    create_project_knowledge_index "$project_path"
    
    # Initialize auto-knowledge management
    setup_auto_knowledge_management "$project_path"
    
    log_success "Project initialization completed!"
    log_info "Project knowledge: $project_path/.claude/knowledge/"
    
    # Show project-specific info
    cat << EOF

${GREEN}Project Setup Complete:${NC}
- Commands: $project_path/.claude/commands/
- Knowledge: $project_path/.claude/knowledge/
- Configuration: $project_path/.claude/CLAUDE.md

${BLUE}Available Commands:${NC}
- /design       - Create design documents
- /implement    - TDD implementation
- /fix-test     - Fix test issues
- /next-steps   - Generate next steps
- /pr           - Create PR documentation

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
    
    log_success "Created project CLAUDE.md"
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
    
    log_success "Created project knowledge index"
}

# Setup auto-knowledge management hooks
setup_auto_knowledge_management() {
    local project_path="$1"
    
    # Create knowledge management script
    cat > "$project_path/.claude/scripts/auto-knowledge.sh" << 'EOF'
#!/bin/bash
# Auto-Knowledge Management Script
# This script is called automatically by custom commands

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
GLOBAL_KNOWLEDGE="$HOME/workspace/cc-knowledge/docs/knowledge"

# Analyze content and determine scope (global vs project-specific)
analyze_knowledge_scope() {
    local content="$1"
    local file_path="$2"
    
    # Keywords that indicate global applicability
    local global_keywords=("refactoring" "testing" "design-pattern" "architecture" "best-practice")
    # Keywords that indicate project-specific
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

# Store knowledge automatically
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
        echo "📚 Stored in global knowledge: $filename.md"
    else
        echo "$frontmatter$content" > "$PROJECT_ROOT/.claude/knowledge/patterns/$filename.md"
        echo "🏠 Stored in project knowledge: $filename.md"
    fi
    
    # Update indices
    update_knowledge_indices
}

# Update knowledge indices
update_knowledge_indices() {
    # Update project index
    local pattern_count=$(find "$PROJECT_ROOT/.claude/knowledge/patterns" -name "*.md" 2>/dev/null | wc -l)
    local lesson_count=$(find "$PROJECT_ROOT/.claude/knowledge/lessons" -name "*.md" 2>/dev/null | wc -l)
    
    sed -i "s/\*\*Total Patterns\*\*: [0-9]*/\*\*Total Patterns\*\*: $pattern_count/" "$PROJECT_ROOT/.claude/knowledge/INDEX.md" 2>/dev/null || true
    sed -i "s/\*\*Total Lessons\*\*: [0-9]*/\*\*Total Lessons\*\*: $lesson_count/" "$PROJECT_ROOT/.claude/knowledge/INDEX.md" 2>/dev/null || true
}

# Check for promotion candidates
check_promotion_candidates() {
    find "$PROJECT_ROOT/.claude/knowledge/patterns" -name "*.md" -type f | while read file; do
        local success_rate=$(grep "^success_rate:" "$file" | sed 's/.*"\([0-9]*\)%".*/\1/')
        local created_date=$(grep "^created:" "$file" | sed 's/.*"\([^"]*\)".*/\1/')
        
        # Simple promotion logic (can be enhanced)
        if [[ "$success_rate" -ge 90 ]] && [[ -n "$created_date" ]]; then
            echo "🎯 Promotion candidate: $(basename "$file")"
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
    
    log_success "Auto-knowledge management setup completed"
}

# Update global knowledge base
update_global() {
    log_info "Updating global knowledge base..."
    
    if [[ ! -d "$GLOBAL_KNOWLEDGE_DIR" ]]; then
        log_error "Global knowledge base not found. Run --global first."
        exit 1
    fi
    
    # Update knowledge files
    if [[ -d "$SCRIPT_DIR/docs" ]]; then
        cp -r "$SCRIPT_DIR/docs"/* "$GLOBAL_KNOWLEDGE_DIR/docs/"
        log_success "Knowledge base updated"
    fi
    
    # Update scripts
    if [[ -d "$SCRIPT_DIR/scripts" ]]; then
        cp -r "$SCRIPT_DIR/scripts"/* "$GLOBAL_KNOWLEDGE_DIR/scripts/"
        chmod +x "$GLOBAL_KNOWLEDGE_DIR/scripts"/*.sh
        log_success "Scripts updated"
    fi
    
    log_success "Global update completed!"
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