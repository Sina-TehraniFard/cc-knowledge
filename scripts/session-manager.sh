#!/bin/bash
# セッション管理スクリプト
# 使用方法: source ~/workspace/cc-knowledge/scripts/session-manager.sh

# チケット番号取得関数（汎用化版）
get_ticket_number() {
    # 優先順位に従ってチケット番号を取得
    local ticket_number=""
    
    # 1. Gitブランチ名から取得（TASK-XXXXX, ISSUE-XXXXX形式）
    if command -v git >/dev/null 2>&1 && git rev-parse --git-dir >/dev/null 2>&1; then
        ticket_number=$(git branch --show-current 2>/dev/null | grep -oE '[A-Z]+-[0-9]+' | head -1)
    fi
    
    # 2. 環境変数から取得
    if [[ -z "$ticket_number" && -n "$TASK_NUMBER" ]]; then
        ticket_number="$TASK_NUMBER"
    fi
    
    # 3. カレントディレクトリ名から取得
    if [[ -z "$ticket_number" ]]; then
        ticket_number=$(basename "$PWD" | grep -oE '[A-Z]+-[0-9]+' | head -1)
    fi
    
    # 4. デフォルト値
    if [[ -z "$ticket_number" ]]; then
        ticket_number="TASK-DEFAULT"
    fi
    
    echo "$ticket_number"
}

# セッション管理関数
get_or_create_session() {
    local ticket_number=$1
    local current_session=$(TZ=Asia/Tokyo date '+%Y-%m-%d_%H-%M')
    local base_dir="$HOME/workspace/tasks/${ticket_number}"
    local session_dir="$base_dir/sessions/${current_session}"
    
    # 5分以内の既存セッションがあれば再利用
    local existing_session=$(find "$base_dir/sessions" -name "$(TZ=Asia/Tokyo date '+%Y-%m-%d')_*" -mmin -5 2>/dev/null | head -1)
    
    if [[ -n "$existing_session" ]]; then
        echo "$existing_session"
        return
    fi
    
    # 新しいセッション作成
    mkdir -p "$session_dir"/{next-steps,reports,implementations}
    
    # session-summary.md作成
    cat > "$session_dir/session-summary.md" <<EOF
# セッション概要
- **開始時刻**: $(TZ=Asia/Tokyo date '+%Y-%m-%d %H:%M')
- **チケット番号**: $ticket_number
- **セッションID**: $current_session
- **ステータス**: 進行中

## 実行コマンド
- 作業開始

## 生成ファイル
（作業進行に応じて自動更新）

## 次のアクション
タスク実行準備中
EOF
    
    # latestリンク更新
    local latest_link="$base_dir/latest"
    rm -f "$latest_link" 2>/dev/null
    ln -sf "sessions/$current_session" "$latest_link"
    
    echo "✅ 新セッション作成: $session_dir"
    echo "🔗 最新リンク更新: $latest_link"
    echo "$session_dir"
}

# セッション情報表示
show_session_info() {
    local ticket_number=$(get_ticket_number)
    local session_dir=$(get_or_create_session "$ticket_number" 2>/dev/null | tail -1)
    
    echo "## 📋 現在のセッション情報"
    echo ""
    echo "- **チケット番号**: $ticket_number"
    echo "- **セッションディレクトリ**: $(basename "$session_dir")"
    echo "- **フルパス**: $session_dir"
    echo ""
    
    if [[ -f "$session_dir/session-summary.md" ]]; then
        echo "### セッション概要"
        head -10 "$session_dir/session-summary.md"
    fi
}

# セッション完了処理
complete_session() {
    local ticket_number=$(get_ticket_number)
    local session_dir=$(get_or_create_session "$ticket_number" 2>/dev/null | tail -1)
    
    if [[ -f "$session_dir/session-summary.md" ]]; then
        # セッション完了時刻を記録
        sed -i 's/進行中/完了/' "$session_dir/session-summary.md"
        echo "" >> "$session_dir/session-summary.md"
        echo "- **完了時刻**: $(TZ=Asia/Tokyo date '+%Y-%m-%d %H:%M')" >> "$session_dir/session-summary.md"
        
        echo "✅ セッション完了: $session_dir"
    fi
}

# セッション一覧表示
list_sessions() {
    local ticket_number=$(get_ticket_number)
    local base_dir="$HOME/workspace/tasks/${ticket_number}"
    
    echo "## 📁 セッション一覧 (${ticket_number})"
    echo ""
    
    if [[ -d "$base_dir/sessions" ]]; then
        find "$base_dir/sessions" -maxdepth 1 -type d -name "20*" | sort -r | head -10 | while read session_path; do
            local session_name=$(basename "$session_path")
            local status="進行中"
            
            if [[ -f "$session_path/session-summary.md" ]]; then
                if grep -q "完了" "$session_path/session-summary.md"; then
                    status="完了"
                fi
            fi
            
            echo "- **$session_name** ($status)"
        done
    else
        echo "セッションディレクトリが存在しません: $base_dir/sessions"
    fi
}

# セッション関連のヘルプ表示
show_session_help() {
    echo "## 📋 Session Manager - 使用方法"
    echo ""
    echo "### 基本機能"
    echo "- \`get_ticket_number\` - 現在のチケット番号を取得"
    echo "- \`get_or_create_session <ticket>\` - セッション取得/作成"
    echo "- \`show_session_info\` - 現在のセッション情報表示"
    echo "- \`complete_session\` - セッション完了処理"
    echo "- \`list_sessions\` - セッション一覧表示"
    echo ""
    echo "### チケット番号の取得優先順位"
    echo "1. Gitブランチ名から自動取得 (TASK-XXXXX形式)"
    echo "2. 環境変数 TASK_NUMBER"
    echo "3. カレントディレクトリ名"
    echo "4. デフォルト値 (TASK-DEFAULT)"
    echo ""
    echo "### セッションディレクトリ構造"
    echo "```"
    echo "~/workspace/tasks/TASK-XXXXX/"
    echo "├── sessions/"
    echo "│   └── 2025-07-25_14-30/"
    echo "│       ├── session-summary.md"
    echo "│       ├── reports/"
    echo "│       ├── implementations/"
    echo "│       └── next-steps/"
    echo "└── latest -> sessions/2025-07-25_14-30"
    echo "```"
}

echo "📋 Session Manager システム読み込み完了"
echo "💡 使用方法: show_session_help"