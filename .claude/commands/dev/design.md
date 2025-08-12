# /dev/design - 設計書生成コマンド

開発における設計フェーズを支援するコマンドです。要件から技術設計書・アーキテクチャ図を生成します。

## 使用方法

```bash
# 基本使用
/dev/design "機能名・要件"

# ファイル指定
/dev/design requirements.md

# 詳細オプション付き
/dev/design --detailed "ユーザー認証システム"
```

## 機能

### 自動生成内容
- **技術設計書** - 実装指針とアーキテクチャ
- **API設計** - エンドポイント・データ構造
- **データベース設計** - テーブル設計・ER図
- **セキュリティ考慮事項** - 認証・認可・データ保護
- **テスト戦略** - テスト方針・テストケース設計

### 出力先
- **設計書**: `/Users/$(whoami)/Documents/claude-outputs/$(date +%Y-%m-%d)/{機能名}-設計書.md`
- **アーキテクチャ図**: 同ディレクトリに図表ファイル
- **実装ガイド**: 開発者向けの実装手順書

### プロジェクト固有ナレッジ自動蓄積
```bash
# 設計パターンの自動保存
source .claude/scripts/auto-knowledge.sh
auto_save_implementation_pattern \
    "設計パターン: $DESIGN_NAME" \
    "機能設計時" \
    "$DESIGN_CONTENT" \
    "再利用可能な設計知見" \
    "プロジェクト固有の設計制約"
```

## 実行例

```bash
# ユーザー認証機能の設計
/dev/design "ユーザー認証・JWT・OAuth2対応"

# 実行結果:
# → ユーザー認証-設計書.md (技術設計書)
# → 認証フロー図.mermaid (フロー図)
# → API仕様書.yaml (OpenAPI仕様)
# → テスト戦略.md (テスト計画)
# → プロジェクトナレッジに設計パターンを自動保存
```

## 連携コマンド

設計完了後の推奨フロー:
```bash
# 1. 設計書生成
/dev/design "新機能"

# 2. 実装開始
/dev/implement design-file.md

# 3. 進捗確認
/work/next
```

## プロジェクト固有設定

`.claude/CLAUDE.md`で設計テンプレートをカスタマイズ可能:
```markdown
### 設計テンプレート
- アーキテクチャスタイル: マイクロサービス
- 使用技術スタック: Node.js, React, PostgreSQL
- セキュリティ要件: SOC2準拠
```