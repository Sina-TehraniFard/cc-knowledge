# /dev/test - テスト支援コマンド

テストの作成・修正・レビューを自動化するコマンドです。TDD実装をサポートします。

## 使用方法

```bash
# テスト自動修正
/dev/test --fix UserTest.java

# テスト品質レビュー
/dev/test --review TestSuite.js

# 新規テスト作成
/dev/test --create UserService.java

# カバレッジ分析
/dev/test --coverage src/
```

## 主要機能

### テスト自動修正（--fix）
失敗しているテストを段階的に修正:

```bash
/dev/test --fix UserServiceTest.java

# 実行フロー:
# 1. テスト失敗原因の分析
# 2. 修正パターンの検索（既存ナレッジから）
# 3. 段階的修正の実行
# 4. 各修正後のテスト実行
# 5. 成功パターンの自動保存
```

### テストレビュー（--review）
テストの品質と網羅性を分析:

```bash
/dev/test --review UserServiceTest.java

# 分析項目:
# - テストカバレッジ分析
# - テストケースの網羅性
# - アサーションの適切性
# - テスト構造の改善提案
# - パフォーマンステストの必要性
```

### 新規テスト作成（--create）
対象コードから最適なテストを生成:

```bash
/dev/test --create UserService.java

# 生成内容:
# - 単体テスト（各メソッドのテスト）
# - 境界値テスト（エッジケース）
# - 異常系テスト（エラーハンドリング）
# - 統合テスト（依存関係含む）
```

## 自動ナレッジ蓄積

### テスト修正パターンの保存
```bash
# 修正成功時の自動保存
auto_save_problem_solution \
    "テスト失敗: $ERROR_MESSAGE" \
    "修正方法: $SOLUTION_APPLIED" \
    "テストファイル: $TEST_FILE" \
    "同様エラーの予防: $PREVENTION_STRATEGY"

# テストパターンの保存
auto_save_implementation_pattern \
    "テストパターン: $TEST_TYPE" \
    "テスト対象: $TARGET_CODE" \
    "テスト実装: $TEST_IMPLEMENTATION" \
    "高品質なテストコード" \
    "プロジェクト固有のテスト要件"
```

## 段階的修正システム

### 修正戦略の優先順位
1. **軽微な修正** - タイポ、インポート不備
2. **アサーション修正** - 期待値の調整
3. **モック・スタブ修正** - 依存関係の調整
4. **ロジック修正** - テスト対象コードの修正
5. **テスト設計見直し** - テストアプローチの変更

### 自動修正例
```bash
# Import不備の自動修正
if grep -q "import.*not found" $TEST_OUTPUT; then
    echo "🔧 Import文を自動修正中..."
    # 必要なimport文を自動追加
    fix_imports $TEST_FILE
    run_test_and_check
fi

# モック設定の自動修正
if grep -q "mock.*undefined" $TEST_OUTPUT; then
    echo "🔧 モック設定を自動生成中..."
    # 依存関係からモック設定を生成
    generate_mocks $TEST_FILE
    run_test_and_check
fi
```

## 実行例

```bash
# 失敗テストの自動修正
/dev/test --fix PaymentServiceTest.java

# 実行結果:
# ✅ Import文を修正 (mockito.Mock → org.mockito.Mock)
# ✅ モック設定を追加 (paymentGateway.mockReturn)
# ✅ アサーションを調整 (expected: 100, actual: 100.00)
# ✅ テスト成功 - 修正パターンをナレッジに保存

# 出力:
# → PaymentServiceTest.java (修正済みテスト)
# → テスト修正レポート.md (修正内容と学習事項)  
# → .claude/knowledge/patterns/ に修正パターン保存
```

## カバレッジ分析

```bash
/dev/test --coverage src/services/

# 分析結果:
# 📊 行カバレッジ: 85% (目標: 90%)
# 📊 分岐カバレッジ: 78% (目標: 80%)
# 📊 未カバー箇所: UserService.handleError()
#
# 🎯 推奨アクション:
# 1. エラーハンドリングのテスト追加
# 2. 境界値テストの強化
# 3. 例外系テストの網羅性向上
```

## 品質基準

### テスト品質チェック項目
- **命名規則** - should_xxx_when_yyy 形式
- **AAA パターン** - Arrange, Act, Assert の明確な分離
- **1テスト1アサーション** - 単一の検証項目
- **独立性** - テスト間の依存関係なし
- **再現性** - 何度実行しても同じ結果

### 自動品質チェック
```bash
# テスト品質の自動評価
evaluate_test_quality() {
    local test_file="$1"
    local quality_score=0
    
    # 命名規則チェック
    if grep -q "should.*when" "$test_file"; then
        ((quality_score += 20))
    fi
    
    # AAAパターンチェック  
    if grep -q -E "(// Arrange|// Act|// Assert)" "$test_file"; then
        ((quality_score += 20))
    fi
    
    echo "テスト品質スコア: $quality_score/100"
}
```

## 連携コマンド

```bash
# 開発フロー例
/dev/implement @tdd design.md    # TDD実装
/dev/test --review              # テスト品質確認  
/dev/test --coverage           # カバレッジ確認
/work/next                     # 次のステップ
```