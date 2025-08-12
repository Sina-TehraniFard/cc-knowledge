# /work/commit - 品質チェック付きコミット作成

作業内容を自動分析し、適切なコミットメッセージとともに品質チェック付きでコミットを作成するコマンドです。

## 使用方法

```bash
# 自動コミット（推奨）
/work/commit

# メッセージ指定コミット
/work/commit --message "feat: add user authentication"

# 段階的コミット
/work/commit --interactive

# 品質チェックスキップ（非推奨）
/work/commit --skip-checks
```

## 自動品質チェック

### 実行前チェック項目
1. **テスト実行** - 全テストが通ることを確認
2. **Lint チェック** - コード規約準拠の確認
3. **型チェック** - TypeScript/静的型解析
4. **セキュリティチェック** - 秘密情報の混入確認
5. **依存関係チェック** - package.json等の整合性

```bash
# 品質チェック実行例
run_quality_checks() {
    echo "🔍 品質チェック実行中..."
    
    # テスト実行
    if ! run_tests; then
        echo "❌ テスト失敗 - コミット中止"
        echo "💡 推奨: /dev/test --fix で修正してから再実行"
        return 1
    fi
    
    # Lintチェック
    if ! run_lint; then
        echo "⚠️  Lint警告あり - 自動修正を試行"
        run_lint_fix
    fi
    
    # 秘密情報チェック
    if detect_secrets; then
        echo "🚨 機密情報を検出 - コミット中止"
        echo "🔒 APIキーやパスワードが含まれていないか確認してください"
        return 1
    fi
    
    echo "✅ 品質チェック完了"
    return 0
}
```

## 自動コミットメッセージ生成

### 変更内容の自動分析
```bash
# Git差分から変更タイプを自動判定
analyze_changes() {
    local added_files=$(git diff --cached --name-only --diff-filter=A)
    local modified_files=$(git diff --cached --name-only --diff-filter=M)
    local deleted_files=$(git diff --cached --name-only --diff-filter=D)
    
    # 変更タイプの判定
    if [[ -n "$added_files" && "$added_files" =~ \.test\.|\.spec\. ]]; then
        echo "test"
    elif [[ "$modified_files" =~ src/.*\.(js|ts|py|java) ]]; then
        if git diff --cached | grep -q "function\|def\|class"; then
            echo "feat"
        else
            echo "fix"
        fi
    elif [[ "$modified_files" =~ README|docs/ ]]; then
        echo "docs"
    elif [[ "$modified_files" =~ package\.json|requirements\.txt|pom\.xml ]]; then
        echo "deps"
    else
        echo "chore"
    fi
}

# 変更内容からサマリー生成
generate_commit_summary() {
    local change_type="$1"
    local files_changed=$(git diff --cached --name-only | wc -l)
    local lines_added=$(git diff --cached --numstat | awk '{sum+=$1} END {print sum}')
    local lines_removed=$(git diff --cached --numstat | awk '{sum+=$2} END {print sum}')
    
    case "$change_type" in
        "feat")
            echo "add new feature functionality"
            ;;
        "fix")
            echo "resolve issue in core logic"
            ;;
        "test")
            echo "improve test coverage and quality"
            ;;
        "docs")
            echo "update documentation"
            ;;
        *)
            echo "update project files"
            ;;
    esac
}
```

### Conventional Commits 準拠
```bash
# 生成されるコミットメッセージ例
generate_conventional_commit() {
    local type="$1"
    local summary="$2"
    local details="$3"
    
    cat << EOF
${type}: ${summary}

${details}

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
}
```

## 実行例

```bash
/work/commit

# 実行フロー:
# 🔍 変更内容を分析中...
#    → 3ファイル変更: UserService.js, UserService.test.js, README.md
#    → 変更タイプ: feat (新機能追加)
#
# 🧪 品質チェック実行中...
#    ✅ テスト実行: 全15テスト通過
#    ✅ Lint チェック: 問題なし
#    ✅ 型チェック: TypeScript OK
#    ✅ セキュリティ: 機密情報なし
#
# 📝 コミットメッセージ生成:
#    "feat: add user authentication with JWT support
#    
#    - Implement UserService.authenticate()
#    - Add comprehensive test coverage
#    - Update README with authentication guide
#    
#    🤖 Generated with [Claude Code](https://claude.ai/code)
#    
#    Co-Authored-By: Claude <noreply@anthropic.com>"
#
# ✅ コミット作成完了: a1b2c3d
# 📚 ナレッジ保存: 認証実装パターンを自動蓄積
```

## 段階的コミット（Interactive）

```bash
/work/commit --interactive

# 段階的確認:
# 1. ファイル選択 - どのファイルをコミットに含めるか
# 2. 変更レビュー - 各変更の内容確認
# 3. メッセージ確認 - 生成されたメッセージの編集
# 4. 品質チェック - 最終チェック実行
# 5. コミット実行 - 確認後にコミット作成
```

## プロジェクト固有ナレッジ蓄積

### コミットパターンの学習
```bash
# 成功したコミットパターンの保存
auto_save_work_knowledge \
    "commit-pattern" \
    "$(git log -1 --pretty=format:'%s')" \
    "コミット内容: $COMMIT_DETAILS" \
    "品質チェック通過・正常コミット" \
    "$(git diff --cached --name-only | tr '\n' ',')"

# 問題解決パターンの保存（エラー修正時）
if [[ "$COMMIT_TYPE" == "fix" ]]; then
    auto_save_problem_solution \
        "$PROBLEM_DESCRIPTION" \
        "$SOLUTION_DESCRIPTION" \
        "コミット作成時" \
        "同様問題の予防策"
fi
```

## エラーハンドリング

### テスト失敗時の対応
```bash
if [[ $TEST_RESULT != "PASS" ]]; then
    echo "❌ テスト失敗によりコミット中止"
    echo ""
    echo "🔧 推奨アクション:"
    echo "  1. /dev/test --fix で失敗テストを修正"
    echo "  2. /dev/test --review でテスト品質確認"  
    echo "  3. /work/commit で再実行"
    echo ""
    echo "📊 失敗テスト詳細:"
    show_failed_tests
    exit 1
fi
```

### 機密情報検出時の対応
```bash
if detect_secrets_in_changes; then
    echo "🚨 機密情報を検出しました"
    echo ""
    echo "検出された項目:"
    list_detected_secrets
    echo ""
    echo "🔒 対応方法:"
    echo "  1. 機密情報を環境変数に移動"
    echo "  2. .gitignore に機密ファイルを追加"
    echo "  3. git reset で変更を取り消し"
    echo ""
    echo "⚠️  コミットを中止します"
    exit 1
fi
```

## カスタマイズ設定

### プロジェクト固有設定
```markdown
### コミット設定
- 品質チェック: 有効
- 必須テストカバレッジ: 80%
- Conventional Commits: 有効
- 自動ナレッジ蓄積: 有効
- 機密情報チェック: 厳格モード
```

### チーム規約への対応
```bash
# チーム固有のコミットメッセージフォーマット
if [[ -f ".claude/commit-template.md" ]]; then
    apply_team_commit_template
fi

# Jira チケット番号の自動付与
if [[ -n "$JIRA_TICKET" ]]; then
    prepend_ticket_number "$JIRA_TICKET"
fi
```

## 連携コマンド

```bash
# 開発完了フロー
/dev/test --review          # テスト品質確認
/work/commit               # 品質チェック付きコミット
/work/pr                   # PR作成準備
```