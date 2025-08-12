# /work/pr - プルリクエスト作成コマンド

コミット履歴とコード変更を分析し、包括的なPRドキュメントを自動生成するコマンドです。

## 使用方法

```bash
# 基本PR作成
/work/pr

# タイトル指定PR作成
/work/pr --title "feat: add user authentication system"

# ドラフトPR作成
/work/pr --draft

# レビュアー指定PR作成
/work/pr --reviewers "alice,bob,charlie"
```

## 自動分析・生成内容

### PR情報の自動抽出
```bash
# コミット履歴からPR内容を分析
analyze_pr_content() {
    local base_branch="${1:-main}"
    local current_branch=$(git branch --show-current)
    
    # 変更されたファイルの分析
    local changed_files=$(git diff "$base_branch"...HEAD --name-only)
    local added_lines=$(git diff "$base_branch"...HEAD --numstat | awk '{sum+=$1} END {print sum}')
    local removed_lines=$(git diff "$base_branch"...HEAD --numstat | awk '{sum+=$2} END {print sum}')
    
    # コミットメッセージからタイプを判定
    local commit_types=$(git log "$base_branch"..HEAD --pretty=format:"%s" | grep -oE "^[a-z]+:" | sort | uniq -c)
    
    # 主要な変更タイプを決定
    if echo "$commit_types" | grep -q "feat:"; then
        echo "feature"
    elif echo "$commit_types" | grep -q "fix:"; then
        echo "bugfix"
    elif echo "$commit_types" | grep -q "refactor:"; then
        echo "refactoring"
    else
        echo "enhancement"
    fi
}
```

### 自動生成PR説明文
```markdown
# PR説明文テンプレート例

## 概要
ユーザー認証システムの実装により、セキュアなログイン・ログアウト機能を追加

## 変更内容
### 追加機能
- JWT認証の実装
- ユーザーセッション管理
- パスワードハッシュ化（bcrypt）

### 修正項目
- ログイン失敗時のエラーハンドリング改善
- セッションタイムアウト処理の最適化

### 影響範囲
- `src/auth/` - 新規認証モジュール
- `src/middleware/` - 認証ミドルウェア追加
- `tests/auth/` - 認証関連テスト追加

## テスト結果
✅ 単体テスト: 28/28 passed
✅ 統合テスト: 12/12 passed  
✅ E2Eテスト: 5/5 passed
✅ セキュリティテスト: 脆弱性なし

## パフォーマンス影響
- ログイン処理: ~200ms
- JWT検証: ~5ms
- メモリ使用量: +2MB (許容範囲内)

## チェックリスト
- [x] テストカバレッジ 90%以上
- [x] セキュリティレビュー完了
- [x] ドキュメント更新
- [x] マイグレーション不要
- [x] 後方互換性維持

## 関連リンク
- 設計書: [認証システム設計.md](link)
- API仕様: [OpenAPI Spec](link)
- セキュリティ監査: [Security Report](link)

## スクリーンショット
（該当する場合のUI変更画面）

## レビューポイント
1. **セキュリティ** - JWT実装とパスワードハッシュ化
2. **パフォーマンス** - 認証処理の最適化
3. **エラーハンドリング** - 認証失敗時の適切な処理

🤖 Generated with [Claude Code](https://claude.ai/code)
```

## 実行例

```bash
/work/pr

# 実行フロー:
# 🔍 ブランチ分析中...
#    → ベースブランチ: main
#    → 現在ブランチ: feature/user-auth
#    → コミット数: 8
#    → 変更ファイル数: 15
#
# 📊 変更内容分析中...
#    → 変更タイプ: feature (新機能)
#    → 追加行数: +1,247
#    → 削除行数: -89
#    → 主要変更: 認証システム実装
#
# 🧪 テスト結果収集中...
#    ✅ 単体テスト: 45/45 passed
#    ✅ 統合テスト: 12/12 passed
#    ✅ Lint: No issues
#    ✅ Security: No vulnerabilities
#
# 📝 PR説明文生成中...
#    → タイトル: "feat: implement JWT-based user authentication system"
#    → 説明文: 自動生成完了
#    → チェックリスト: 自動作成
#
# 🚀 PR作成完了!
#    → URL: https://github.com/user/repo/pull/123
#    → レビュアー: 自動アサイン
#    → ラベル: feature, authentication
```

## 高度な分析機能

### コード品質分析
```bash
# 変更されたコードの品質分析
analyze_code_quality() {
    local changed_files="$1"
    
    echo "📊 コード品質分析結果:"
    
    # 循環的複雑度分析
    for file in $changed_files; do
        if [[ "$file" =~ \.(js|ts|py|java)$ ]]; then
            local complexity=$(calculate_complexity "$file")
            if [[ "$complexity" -gt 10 ]]; then
                echo "⚠️  高複雑度: $file (複雑度: $complexity)"
            fi
        fi
    done
    
    # 重複コード検出
    detect_code_duplication $changed_files
    
    # 技術的負債の評価
    evaluate_technical_debt $changed_files
}
```

### セキュリティ分析
```bash
# セキュリティ観点での変更分析
analyze_security_impact() {
    local changed_files="$1"
    
    echo "🔒 セキュリティ影響分析:"
    
    # 認証・認可関連の変更
    if echo "$changed_files" | grep -qE "(auth|login|security|permission)"; then
        echo "🚨 認証・認可関連の変更を検出"
        echo "   → セキュリティレビューが必要"
    fi
    
    # データベース関連の変更
    if echo "$changed_files" | grep -qE "(model|schema|migration|sql)"; then
        echo "🗄️ データベース関連の変更を検出"
        echo "   → データ整合性の確認が必要"
    fi
    
    # 外部API関連の変更
    if grep -r "http\|fetch\|axios\|requests" $changed_files; then
        echo "🌐 外部API呼び出しの変更を検出"
        echo "   → API セキュリティの確認が必要"
    fi
}
```

## プロジェクト固有ナレッジ蓄積

### PR作成パターンの学習
```bash
# 成功したPRパターンの保存
auto_save_implementation_pattern \
    "PR作成パターン: $PR_TYPE" \
    "PR作成・レビュー通過時" \
    "変更内容: $CHANGE_SUMMARY" \
    "効率的なPR作成とレビュープロセス" \
    "プロジェクト固有のPR要件"

# レビュー観点の蓄積
auto_save_work_knowledge \
    "pr-review-points" \
    "PRレビューポイント生成" \
    "プロジェクト固有のレビュー観点: $REVIEW_POINTS" \
    "レビュー効率向上" \
    "$CHANGED_FILES"
```

## 自動レビュアーアサイン

### コード変更に基づく推奨レビュアー
```bash
# 変更ファイルから適切なレビュアーを推奨
suggest_reviewers() {
    local changed_files="$1"
    local suggested_reviewers=""
    
    # CODEOWNERS ファイルからレビュアーを抽出
    if [[ -f ".github/CODEOWNERS" ]]; then
        for file in $changed_files; do
            local owners=$(grep "$file" .github/CODEOWNERS | awk '{print $2}' | tr '@' ' ')
            suggested_reviewers="$suggested_reviewers $owners"
        done
    fi
    
    # Git履歴からアクティブなコントリビューターを推奨
    local frequent_contributors=$(git log --pretty=format:"%an" --since="1 month ago" -- $changed_files | sort | uniq -c | sort -rn | head -3 | awk '{print $2}')
    
    echo "推奨レビュアー: $suggested_reviewers $frequent_contributors"
}
```

## CI/CD 連携

### 自動チェック結果の統合
```bash
# CI/CDの結果をPR説明文に自動反映
integrate_ci_results() {
    local pr_number="$1"
    
    # GitHub Actions の結果取得
    if command -v gh >/dev/null 2>&1; then
        local checks=$(gh pr checks $pr_number --json name,conclusion)
        
        echo "## CI/CD結果" >> pr_description.md
        echo "$checks" | jq -r '.[] | "- \(.conclusion == "success" and "✅" or "❌") \(.name)"' >> pr_description.md
    fi
}
```

## プルリクエストテンプレート

### プロジェクト固有テンプレート
```bash
# .github/pull_request_template.md が存在する場合の処理
if [[ -f ".github/pull_request_template.md" ]]; then
    echo "📋 プロジェクトPRテンプレートを適用中..."
    apply_project_pr_template
else
    echo "📋 汎用PRテンプレートを使用"
    use_default_pr_template
fi
```

## 連携コマンド

```bash
# 開発完了からPRまでのフロー
/dev/test --review         # 最終テスト確認
/work/commit              # 品質チェック付きコミット
/work/pr                  # PR作成
/analyze/code --security  # セキュリティ確認（オプション）
```

## 出力ファイル

### 生成ファイル一覧
```bash
# PR関連ファイルの自動生成
OUTPUT_DIR="/Users/$(whoami)/Documents/claude-outputs/$(date +%Y-%m-%d)"

# 生成されるファイル:
# → PRドキュメント.md (PR説明文)
# → レビューガイド.md (レビュアー向けガイド)
# → テスト結果サマリー.md (テスト実行結果)
# → セキュリティチェック結果.md (セキュリティ分析)
```