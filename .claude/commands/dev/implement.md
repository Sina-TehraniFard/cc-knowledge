# /dev/implement - TDD実装コマンド

設計書からTDDサイクルで実装を自動実行するコマンドです。Red-Green-Refactorを自動化します。

## 使用方法

```bash
# 基本TDD実行
/dev/implement design.md

# タグ付きTDD実行
/dev/implement @tdd design.md

# 段階的実装
/dev/implement --step-by-step UserService.java
```

## TDDサイクル自動実行

### Red フェーズ（失敗テスト作成）
1. **設計書解析** - 機能要件の抽出
2. **テストケース生成** - 期待動作の定義
3. **失敗テスト作成** - 意図的に失敗するテスト
4. **実行確認** - テストが確実に失敗することを確認

### Green フェーズ（最小実装）
1. **最小実装作成** - テストを通す最小限のコード
2. **テスト実行** - すべてのテストがパスすることを確認
3. **実装検証** - 機能の基本動作確認

### Refactor フェーズ（品質向上）
1. **コード品質改善** - 可読性・保守性の向上
2. **パフォーマンス最適化** - 効率的な実装への改善
3. **テスト実行** - リファクタリング後の動作確認
4. **ナレッジ蓄積** - 実装パターンの自動保存

## 自動ナレッジ蓄積

```bash
# TDD実装パターンの自動保存
auto_save_implementation_pattern \
    "TDD実装: $FEATURE_NAME" \
    "機能実装時のテスト駆動開発" \
    "$IMPLEMENTATION_DETAILS" \
    "品質の高い実装とテストカバレッジ" \
    "TDDサイクルの継続的実行"

# 問題解決パターンの保存
auto_save_problem_solution \
    "$ENCOUNTERED_PROBLEM" \
    "$SOLUTION_APPLIED" \
    "TDD実装中" \
    "同様問題の予防策"
```

## 実行例

```bash
# ユーザーサービスのTDD実装
/dev/implement @tdd user-auth-design.md

# 実行フロー:
# [Red] UserAuthService.test.js 作成 → テスト失敗確認
# [Green] UserAuthService.js 最小実装 → テスト成功確認  
# [Refactor] コード品質改善 → 最終テスト確認
# [Knowledge] 実装パターンを自動保存

# 出力:
# → src/services/UserAuthService.js (実装コード)
# → tests/services/UserAuthService.test.js (テストコード)
# → 実装レポート.md (実装過程と学習事項)
# → .claude/knowledge/patterns/ に実装パターン保存
```

## 段階的実装モード

```bash
# 関数単位での段階的実装
/dev/implement --step-by-step UserService.java

# 各関数ごとに:
# 1. テスト作成・実行（失敗確認）
# 2. 実装・実行（成功確認）
# 3. 次の関数へ進む前に確認プロンプト
```

## エラーハンドリング

```bash
# テスト失敗時の自動修正
if [[ $TEST_RESULT != "PASS" ]]; then
    echo "⚠️ テスト失敗を検出しました"
    echo "🔧 自動修正を試行中..."
    
    # /dev/test コマンドで自動修正
    /dev/test --fix $FAILED_TEST_FILE
    
    # 修正後再実行
    if [[ $RETRY_RESULT == "PASS" ]]; then
        echo "✅ 自動修正成功 - TDDサイクル継続"
    else
        echo "❌ 手動確認が必要です"
        exit 1
    fi
fi
```

## 連携コマンド

```bash
# 設計 → 実装 → 確認のフロー
/dev/design "新機能"           # 設計書生成
/dev/implement design.md       # TDD実装
/dev/test --review            # 実装レビュー
/work/next                    # 次のステップ提案
```

## 設定カスタマイズ

プロジェクト固有のTDD設定:
```markdown
### TDD設定
- テストフレームワーク: Jest / JUnit / pytest
- カバレッジ目標: 90%以上
- リファクタリング基準: 循環的複雑度 < 10
- 自動ナレッジ蓄積: 有効
```