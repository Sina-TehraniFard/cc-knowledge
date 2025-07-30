#!/bin/bash

# Claude Code Knowledge Base Project Installer
# プロジェクトにcc-knowledgeの設定をインストール

set -e

# 色付きメッセージ用の定数
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# cc-knowledgeのパス設定
CC_KNOWLEDGE_PATH="${CC_KNOWLEDGE_PATH:-~/workspace/cc-knowledge}"
CC_KNOWLEDGE_EXPANDED=$(eval echo "$CC_KNOWLEDGE_PATH")

log_info "Claude Code Knowledge Base Project Installer"
log_info "現在のディレクトリ: $(pwd)"

# cc-knowledgeの存在確認
if [[ ! -d "$CC_KNOWLEDGE_EXPANDED" ]]; then
    log_warning "cc-knowledgeが見つかりません: $CC_KNOWLEDGE_EXPANDED"
    echo "CC_KNOWLEDGE_PATH環境変数で正しいパスを指定するか、"
    echo "以下のコマンドでクローンしてください："
    echo "  git clone https://github.com/YOUR_REPO/cc-knowledge.git ~/workspace/cc-knowledge"
    exit 1
fi

# update.shをダウンロード/コピー
if [[ -f "$CC_KNOWLEDGE_EXPANDED/update.sh" ]]; then
    log_info "update.shをコピー中..."
    cp "$CC_KNOWLEDGE_EXPANDED/update.sh" ./update.sh
    chmod +x ./update.sh
    log_success "update.shのコピー完了"
else
    log_warning "update.shが見つかりません。curlでダウンロードを試行..."
    if command -v curl >/dev/null 2>&1; then
        curl -sSL "https://raw.githubusercontent.com/YOUR_REPO/cc-knowledge/main/update.sh" -o update.sh
        chmod +x update.sh
        log_success "update.shのダウンロード完了"
    else
        echo "curlが利用できません。手動でupdate.shをコピーしてください。"
        exit 1
    fi
fi

# sync-projectを実行
log_info "cc-knowledgeから設定を同期中..."
./update.sh sync-project --force

log_success "インストール完了！"
echo ""
echo "次のステップ:"
echo "  1. git add ."
echo "  2. git commit -m 'chore: Claude Code設定を追加'"
echo "  3. ./update.sh sync-project で最新設定に更新"
echo ""
echo "使用可能なコマンド:"
echo "  ./update.sh sync-project    # cc-knowledgeから最新設定を同期"
echo "  ./update.sh --help          # ヘルプ表示"