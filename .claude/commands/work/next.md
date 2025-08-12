# /work/next - 次ステップ提案コマンド

プロジェクトの現状を分析し、次に取り組むべき作業を提案するコマンドです。

## 使用方法

```bash
# 基本使用
/work/next

# 特定領域の分析
/work/next --focus backend
/work/next --focus frontend  
/work/next --focus testing

# 詳細分析
/work/next --detailed
```

## 分析項目

### プロジェクト状況分析
1. **Git状態** - コミット状況、ブランチ状態
2. **テスト状況** - カバレッジ、失敗テスト
3. **依存関係** - ライブラリ更新、脆弱性
4. **コード品質** - 技術的負債、改善点
5. **ドキュメント** - 不足しているドキュメント

### 作業優先度の自動算出
```bash
# 優先度算出ロジック
calculate_priority() {
    local task="$1"
    local urgency=0    # 緊急度（0-10）
    local impact=0     # 影響度（0-10）
    local effort=0     # 工数（0-10、逆算）
    
    # 緊急度判定
    if [[ "$task" =~ "security|vulnerability" ]]; then
        urgency=10
    elif [[ "$task" =~ "bug|error|failed" ]]; then
        urgency=8
    elif [[ "$task" =~ "refactor|improvement" ]]; then
        urgency=5
    fi
    
    # 影響度判定
    if [[ "$task" =~ "core|critical|main" ]]; then
        impact=9
    elif [[ "$task" =~ "feature|enhancement" ]]; then
        impact=7
    fi
    
    # 優先度スコア = (緊急度 + 影響度) / 工数
    local priority_score=$(( (urgency + impact) * 10 / (effort + 1) ))
    echo "$priority_score"
}
```

## 実行例

```bash
/work/next

# 分析結果:
# 📊 プロジェクト状況分析完了
#
# 🚨 高優先度タスク:
# 1. [重要] PaymentServiceTest.java の失敗テスト修正
#    → 影響範囲: 決済機能全体
#    → 推定工数: 30分
#    → 推奨コマンド: /dev/test --fix PaymentServiceTest.java
#
# 2. [セキュリティ] npm audit で検出された脆弱性対応  
#    → CVE-2023-xxxx (High severity)
#    → 推定工数: 1時間
#    → 推奨コマンド: npm audit fix
#
# 🎯 中優先度タスク:
# 3. [品質] UserService.js のリファクタリング
#    → 循環的複雑度: 15 (推奨: <10)
#    → 推定工数: 2時間
#    → 推奨コマンド: /dev/implement --refactor UserService.js
#
# 📚 低優先度タスク:
# 4. [ドキュメント] API仕様書の更新
#    → 最終更新: 2週間前
#    → 推定工数: 1時間
#    → 推奨コマンド: /manage/docs --api
```

## プロジェクト固有ナレッジ活用

### 過去の作業パターン分析
```bash
# 過去の成功パターンから推奨アクション生成
analyze_historical_patterns() {
    local current_context="$1"
    
    # プロジェクトナレッジから類似パターン検索
    find .claude/knowledge/patterns -name "*.md" | while read pattern_file; do
        if grep -qi "$current_context" "$pattern_file"; then
            local success_rate=$(grep "success_rate:" "$pattern_file" | sed 's/.*"\([0-9]*\)%".*/\1/')
            if [[ "$success_rate" -ge 80 ]]; then
                echo "📚 過去の成功パターン発見: $(basename "$pattern_file")"
                echo "   成功率: ${success_rate}% - 推奨アプローチとして提案"
            fi
        fi
    done
}
```

### 作業履歴からの学習
```bash
# 作業完了時の自動ナレッジ保存
auto_save_work_knowledge \
    "next-steps-analysis" \
    "プロジェクト状況分析" \
    "優先度付きタスクリスト生成完了" \
    "効率的な作業順序の提案" \
    "$(pwd)"
```

## カスタムフォーカス分析

### バックエンド専用分析
```bash
/work/next --focus backend

# バックエンド固有の分析:
# 🔧 API設計の整合性
# 🗄️ データベースマイグレーション状況  
# 🔒 セキュリティ脆弱性スキャン
# 📊 パフォーマンスボトルネック
# 🧪 統合テストカバレッジ
```

### フロントエンド専用分析
```bash
/work/next --focus frontend

# フロントエンド固有の分析:
# 🎨 UIコンポーネントの品質
# 📱 レスポンシブデザイン対応
# ⚡ バンドルサイズ最適化
# 🧪 E2Eテストカバレッジ
# ♿ アクセシビリティ対応
```

## 自動実行提案

### ワンクリック実行
```bash
# 推奨コマンドの自動実行オプション
/work/next --auto-execute

# 確認プロンプト付きで最高優先度タスクを実行:
# "PaymentServiceTest.java の修正を実行しますか？ (y/N)"
# → y入力で /dev/test --fix PaymentServiceTest.java を自動実行
```

### バッチ実行
```bash
# 複数タスクの連続実行
/work/next --batch

# 実行例:
# 1. /dev/test --fix PaymentServiceTest.java
# 2. npm audit fix  
# 3. /dev/test --coverage
# 4. /work/commit --message "Fix payment tests and security updates"
```

## 出力形式

### 標準出力
- 優先度順のタスクリスト
- 各タスクの詳細情報（影響範囲、工数、推奨コマンド）
- プロジェクト健全性スコア

### ファイル出力
```bash
# 詳細レポートの自動保存
OUTPUT_PATH="/Users/$(whoami)/Documents/claude-outputs/$(date +%Y-%m-%d)/次ステップ分析-$(date +%H%M).md"

# 出力内容:
# - プロジェクト状況の詳細分析
# - 各タスクの根拠と推奨理由  
# - 過去の類似作業での成功事例
# - 長期的な改善提案
```

## 連携コマンド

```bash
# 分析 → 実行 → 確認のフロー
/work/next                    # 次タスク分析
/dev/test --fix TestFile.java # 推奨タスク実行  
/work/next                    # 進捗確認・次タスク
/work/commit                  # 作業コミット
```