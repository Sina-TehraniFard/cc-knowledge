# /update-docs - コメント・ドキュメント更新コマンド

## 概要
リファクタリング後の実装に合わせて、不要なコメントを削除し、コードドキュメントやコメントを実態に合わせて更新するコマンドです。
現在のブランチでの変更差分（コミット済み＋未コミット）を対象に、コメントの整合性を確保します。

## 使用方法
```
/update-docs [オプション]
```

### オプション
```bash
# 基本使用（現在のブランチの全差分）
/update-docs

# ドライラン（変更内容の確認のみ）
/update-docs -n
/update-docs --dry-run

# 詳細モード（変更理由も表示）
/update-docs -v
/update-docs --verbose

# 組み合わせ使用
/update-docs -nv
/update-docs --dry-run --verbose
```

## 機能

### 1. 対象ファイルの自動検出
- 現在のブランチでの変更差分を検出
- コミット済み + 未コミットの両方を対象
- 主要プログラミング言語をサポート

### 2. 不要コメントの削除
- 実装と乖離した古いコメント
- TODOやFIXMEで既に対応済みのもの
- リファクタリングで不要になった説明

### 3. ドキュメント/コメントの更新
- メソッドシグネチャ変更に伴うパラメータ説明
- 返り値の型変更に対応
- クラス・インターフェースの責務変更を反映

### 4. 整合性チェック
- コメントと実装の一致を検証
- 必須ドキュメントの存在確認
- 命名規則との整合性

## プロンプト

現在のブランチでの変更差分を分析し、コメントとドキュメントを実装に合わせて更新してください。

**重要**: コメント更新ルールは必ず `~/workspace/cc-knowledge/docs/comment-exclusion-rules.md` を参照してください。

### 実行手順

1. **変更差分の取得**
   ```bash
   # 現在のブランチの分岐点を特定
   # developブランチとの共通祖先を取得
   git show-branch --merge-base HEAD origin/develop
   
   # または、masterブランチの場合
   git show-branch --merge-base HEAD origin/master
   
   # 分岐点からの変更ファイル一覧を取得
   git diff $(git merge-base HEAD origin/develop)..HEAD --name-only
   
   # 各ファイルの変更内容を確認
   git diff $(git merge-base HEAD origin/develop)..HEAD <ファイル名>
   ```
   
   **注意**: ブランチの分岐元を自動検出するため、以下の順序で確認します：
   1. `origin/develop` が存在する場合は develop を基準に
   2. `origin/master` が存在する場合は master を基準に
   3. `origin/main` が存在する場合は main を基準に

2. **対象ファイルの分析**
   ```
   各ファイルについて以下を確認：
   - 変更されたメソッド・クラスの特定
   - 既存のコメント・ドキュメントの内容
   - 実装との整合性チェック
   ```

3. **更新ルールの適用**

### コメント更新ルール

コメント・ドキュメントの更新ルールについては、以下のドキュメントを参照してください：
- [コメント除外ルール](../docs/comment-exclusion-rules.md)

このドキュメントには以下の内容が含まれています：
- 削除対象のコメントパターン
- 保持必須のコメント
- 更新対象の要素
- ドキュメント記述ガイドライン
- 判断基準と実例
- 検出が困難なパターン

### 命名規則との整合性確認

1. **メソッド名とドキュメントの一致**
   - `extractAndConvert` → "抽出して変換"
   - `validate` → "検証"
   - `transform` → "変換"

2. **パラメータ名の一貫性**
   - ドキュメント内のパラメータ説明とメソッドシグネチャの一致

### 実装パターン

#### ファイルの処理
```bash
# ファイル全体を読み込み（部分読み込みは避ける）
content = Read(filePath)

# comment-exclusion-rules.mdから削除対象パターンを確認
exclusionRules = Read("~/workspace/cc-knowledge/docs/comment-exclusion-rules.md")

# 削除対象パターンを検索
patternsToSearch = [
    "動的マッピング",
    "パターンに統一",
    "統合版",
    "〜と同じパターン",
    "〜による〜"
]

# 変更部分の特定
changes = analyzeGitDiff(filePath)

# 各変更箇所について
for change in changes:
    # 1. 関連するコメント・ドキュメントを特定
    relatedDocs = findRelatedDocumentation(change)
    
    # 2. 実装との整合性チェック
    isConsistent = checkConsistency(change, relatedDocs)
    
    # 3. 必要に応じて更新
    if not isConsistent:
        updateDocumentation(change, relatedDocs)

# ファイル書き込み
Edit(filePath, oldContent, newContent)
```

### 品質チェックリスト

更新後、以下を確認：
- [ ] すべてのpublicメソッドにドキュメントが存在
- [ ] パラメータ説明が最新のシグネチャと一致
- [ ] 返り値の説明が実際の型と一致
- [ ] クラスの責務説明が現在の実装と一致
- [ ] 不要なTODO/FIXMEが削除されている

### 出力形式

#### コンソール出力
```
========================================
🚀 実行中: update-docs
========================================
📍 ステップ 1/3: 変更差分の取得
⏱️  開始時刻: 2025-01-21 10:30:00

✅ ステップ 1 完了
   実行時間: 2.3秒
   検出ファイル: 5個
----------------------------------------
📍 ステップ 2/3: コメント整合性チェック
⏱️  開始時刻: 2025-01-21 10:30:02

✅ ステップ 2 完了
   実行時間: 5.1秒
   更新必要箇所: 13個
----------------------------------------
📍 ステップ 3/3: ファイル更新とレポート生成
⏱️  開始時刻: 2025-01-21 10:30:07

✅ ステップ 3 完了
   実行時間: 3.2秒
   出力: /Users/$(whoami)/Documents/claude-outputs/TASK-12345comment-update-report.md
========================================
✅ update-docs 完了
========================================
📊 実行サマリー:
  - 総実行時間: 10.6秒
  - 処理ファイル: 5個
  - 更新箇所: 13個
  - レポート: comment-update-report.md
========================================
```

#### レポートファイル形式
- **ファイル名**: `comment-update-report.md`
- **保存先**: `/Users/$(whoami)/Documents/claude-outputs/$(date +%Y-%m-%d)`
- **内容**:
```markdown
# コメント・ドキュメント更新レポート

## 実行情報
- 実行日時: 2025-01-21 10:30:00
- ブランチ: feature/TASK-12345-refactor
- 基準ブランチ: origin/develop
- オプション: [--verbose]

## 更新サマリー
| カテゴリ | 件数 |
|----------|------|
| ドキュメント更新 | 8 |
| コメント削除 | 3 |
| 新規追加 | 2 |
| 合計 | 13 |

## 更新対象ファイル
1. `path/to/file1.kt`: 5箇所更新
2. `path/to/file2.kt`: 3箇所更新
3. `path/to/file3.kt`: 3箇所更新
4. `path/to/file4.kt`: 1箇所更新
5. `path/to/file5.kt`: 1箇所更新

## 更新内容詳細

### `path/to/file1.kt`

#### 1. ドキュメント更新 (line 25-30)
**理由**: パラメータ`id`が追加されたため

**変更前**:
```kotlin
/**
 * ユーザーを取得する
 * @param name ユーザー名
 */
fun getUser(name: String, id: Long): User
```

**変更後**:
```kotlin
/**
 * ユーザーを取得する
 * @param name ユーザー名
 * @param id ユーザーID
 */
fun getUser(name: String, id: Long): User
```

#### 2. コメント削除 (line 45)
**理由**: Converterクラスが削除されたため

**削除内容**:
```kotlin
// Converterを使用して変換
```

### 適用されたルール
1. ✅ 削除対象パターンの検出と除去
2. ✅ パラメータ説明の同期
3. ✅ 不要なTODO/FIXMEの削除
4. ✅ 実装と乖離したコメントの更新

## 次のステップ
- [ ] 更新内容を確認してコミット
- [ ] 残存する手動更新箇所の対応
- [ ] コードレビューでの最終確認
```

### 実行例

```bash
# 基本実行
/update-docs

# ドライラン（変更内容を確認）
/update-docs -n
/update-docs --dry-run

# 詳細モード（変更理由も表示）
/update-docs -v
/update-docs --verbose

# ドライラン＋詳細モード
/update-docs -nv
/update-docs --dry-run --verbose
```

### エラーハンドリング

1. **Git管理外のファイル**
   - 警告を表示して処理をスキップ
   - レポートに記録

2. **構文エラーのあるファイル**
   - エラーを報告して該当ファイルをスキップ
   - エラー詳細をレポートに含める

3. **権限エラー**
   - 読み取り専用ファイルは更新対象から除外
   - スキップ理由をレポートに記載

4. **ブランチ検出エラー**
   - 基準ブランチが見つからない場合はエラーメッセージとともに終了
   - 推奨される基準ブランチを提示

### 成功基準

- コメントと実装の乖離がゼロ
- 必須ドキュメントの欠落がゼロ  
- コンパイル警告の減少
- コードレビューでの指摘事項減少

## 出力ファイル
| ファイルタイプ | パス | 説明 |
|--------------|------|------|
| レポート | `/Users/$(whoami)/Documents/claude-outputs/$(date +%Y-%m-%d)/comment-update-report.md` | 更新内容の詳細レポート |

**重要**: このコマンドは変更を直接ファイルに適用します。実行前に必ず変更内容を確認し、必要に応じてバックアップを取ってください。
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
            auto_save_generated_file "$generated_file_path" "$generated_content" "update-docs" 2>/dev/null || {
                echo "# 自動保存に失敗しましたが、処理を継続します" >&2
            }
        fi
    fi
fi

# ===== 自動保存システム統合終了 =====
