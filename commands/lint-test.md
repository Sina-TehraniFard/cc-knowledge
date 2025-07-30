# lint-test - テストコードがガイドラインに準拠しているかをチェックします

## 概要
指定されたテストコードがプロジェクトのテストガイドラインに準拠しているかを確認します。

## 使用方法
```
/lint-test [タグ] <TestCode or TestFilePath>
```

### 例
```bash
# 基本使用方法
/lint-test UserServiceTest.kt

# タグ付き実行
/lint-test @test-fix AzureAdConnectorGatewayTest.kt
/lint-test @api @tdd AzureClientTest.kt
/lint-test @refactor GroupMapperTest.kt
```

### 利用可能なタグ
- `@test-fix`: 段階的テスト改善パターン適用
- `@api`: API関連テスト特有の要件チェック
- `@tdd`: TDDサイクルでのテスト構造検証
- `@refactor`: 既存テスト保持要件でのリファクタリング確認

## 実行内容
1. テストガイドラインの読み込み
2. テストコードの分析
3. ガイドライン準拠のチェック
4. 改善点の指摘
5. **チェック結果レポートの生成とファイル保存**

## 出力ファイル
| ファイルタイプ | パス | 説明 |
|--------------|------|------|
| レポート | `/Users/$(whoami)/Documents/claude-outputs/$(date +%Y-%m-%d)/lint-{テストクラス名}-report.md` | 準拠チェック結果の詳細レポート |
| ログ | `/Users/$(whoami)/Documents/claude-outputs/$(date +%Y-%m-%d)/` | 実行ログとエラー情報 |

## プロンプト
まず、テストガイドラインを読み込んでから、{TestCode or TestFilePath} がガイドラインに沿っているかを確認してください。

テストガイドラインの場所: ~/workspace/cc-knowledge/docs/guidelines/testing.md


以下の手順で確認してください：

1. **テストガイドラインの読み込み**
   - guidelines/testing.mdを読み込む
   - 重要な規則を把握する

2. **テストコードの分析**
   - テストメソッドの命名規則（shouldで始まる）
   - @DisplayNameの記述形式（明確な説明）
   - Given-When-Thenの構造
   - アサーションの適切性
   - テストデータの準備方法

3. **準拠状況の確認**
   - 各規則への準拠状況をチェック
   - 違反箇所を特定
   - 良い点も評価

4. **結果の報告**
   - 準拠している項目：✅
   - 準拠していない項目：❌
   - 改善が推奨される項目：⚠️
   - 具体的な改善提案

5. **レポートファイルの生成**
   - チケット番号の取得: ブランチ名やファイルパスから抽出
   - ファイル名: `lint-{テストクラス名}-report.md`
   - 保存先: `/Users/$(whoami)/Documents/claude-outputs/$(date +%Y-%m-%d)`
   - レポート形式:
     ```markdown
     # Lintチェックレポート: {テストクラス名}
     
     ## 実行情報
     - 実行日時: {timestamp}
     - 対象ファイル: {file_path}
     - 使用タグ: {tags}
     
     ## チェック結果サマリー
     - ✅ 合格: {pass_count}項目
     - ❌ 違反: {fail_count}項目
     - ⚠️ 警告: {warn_count}項目
     
     ## 詳細結果
     
     ### ✅ 準拠している項目
     1. {項目名}
        - 詳細: {説明}
     
     ### ❌ 違反項目
     1. {違反内容}
        - 場所: line {line_number}
        - 理由: {reason}
        - 推奨: {recommendation}
        - 修正例:
          ```kotlin
          // Before
          {before_code}
          
          // After
          {after_code}
          ```
     
     ### ⚠️ 改善推奨項目
     1. {改善内容}
        - 理由: {reason}
        - 提案: {suggestion}
     
     ## 次のステップ
     - [ ] `/fix-test`コマンドで自動修正を実行
     - [ ] 手動で修正が必要な項目を確認
     - [ ] 修正後に再度lint-testを実行
     ```

特に以下の点に注意してください：
- テストの可読性と保守性
- テストの独立性
- 適切なモックの使用
- エッジケースのカバー

## エラーハンドリング
- **ファイルが見つからない**: ファイルパスを確認して再実行を提案
- **構文エラー**: コンパイル可能な状態に修正してから再実行を提案
- **ガイドライン未設定**: testing.mdの存在を確認
# ===== Claude Code 自動保存システム統合 =====
# Phase 2: カスタムコマンド統合（自動追加）

# 統合条件チェック
if [[ -f "$HOME/workspace/cc-knowledge/scripts/auto-save-core.sh" ]]; then
    # ファイル生成が確認できた場合のみ自動保存を実行
    if [[ -n "$generated_file_path" && -n "$generated_content" ]]; then
        # 自動保存システムの読み込み（エラー時は無視）
        source "$HOME/workspace/cc-knowledge/scripts/auto-save-core.sh" 2>/dev/null || {
            echo "# 注意: 自動保存システムが利用できません" >&2
        }
        
        # 自動保存の実行
        if command -v auto_save_generated_file >/dev/null 2>&1; then
            auto_save_generated_file "$generated_file_path" "$generated_content" "lint-test" 2>/dev/null || {
                echo "# 自動保存に失敗しましたが、処理を継続します" >&2
            }
        fi
    fi
fi

# ===== 自動保存システム統合終了 =====
