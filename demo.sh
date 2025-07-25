#!/bin/bash

# Claude Code Knowledge Management System Demo
# This script demonstrates the installation and usage

set -e

DEMO_PROJECT_DIR="$HOME/workspace/demo-project"
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🎬 Claude Code Knowledge Management System Demo${NC}"
echo ""

# Step 1: Global Installation
echo -e "${YELLOW}Step 1: Global Installation${NC}"
echo "Running: ./install.sh --global"
echo ""
./install.sh --global
echo ""

# Step 2: Create Demo Project
echo -e "${YELLOW}Step 2: Creating Demo Project${NC}"
mkdir -p "$DEMO_PROJECT_DIR"
cd "$DEMO_PROJECT_DIR"

# Create package.json to simulate Node.js project
cat > package.json <<EOF
{
  "name": "demo-project",
  "version": "1.0.0",
  "scripts": {
    "test": "jest",
    "lint": "eslint ."
  }
}
EOF

echo "✅ Demo project created at: $DEMO_PROJECT_DIR"
echo ""

# Step 3: Project Initialization
echo -e "${YELLOW}Step 3: Project Initialization${NC}"
echo "Running: ~/workspace/yesod-claude-code/tehrani/install.sh --project"
echo ""
~/workspace/yesod-claude-code/tehrani/install.sh --project
echo ""

# Step 4: Show Results
echo -e "${YELLOW}Step 4: Results${NC}"
echo ""
echo -e "${GREEN}📁 Directory Structure:${NC}"
find .claude -type f | head -10
echo ""

echo -e "${GREEN}🧠 Knowledge System Status:${NC}"
if [[ -f ".claudeknowledge/INDEX.md" ]]; then
    echo "✅ Project knowledge initialized"
    head -5 .claude/knowledge/INDEX.md
else
    echo "❌ Project knowledge not found"
fi
echo ""

echo -e "${GREEN}⚙️  Available Commands:${NC}"
ls .claude/commands/ | head -5
echo ""

echo -e "${GREEN}🎯 Next Steps:${NC}"
echo "1. Try: cd $DEMO_PROJECT_DIR"
echo "2. Available commands: /design, /implement, /fix-test, /next-steps, /pr"
echo "3. Knowledge will be automatically collected as you use commands"
echo ""

echo -e "${BLUE}🎉 Demo completed! The system is ready to use.${NC}"