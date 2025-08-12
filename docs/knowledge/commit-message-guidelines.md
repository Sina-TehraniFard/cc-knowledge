# コミットメッセージガイドライン

## 最重要ルール

### 署名に関する絶対ルール
- **禁止事項**: コミットメッセージに以下の記載は絶対に含めない
  - `🤖 Generated with Claude Code`
  - `Generated with [Claude Code](https://claude.ai/code)`
  - `Co-Authored-By: Claude <noreply@anthropic.com>`
  - その他、AIツールによる生成を示す記載

### 許可される署名
- ユーザーが明示的に要求した場合のみ、ユーザーの署名を追加可能
  - 例: `Co-Authored-By: Sina-TehraniFard <tf.sina.system@gmail.com>`

## コミットメッセージの構造

### 基本フォーマット
```
<type>: <subject>

<body>

[Co-Authored-By: <user-name> <user-email>] (ユーザー要求時のみ)
```

### type の種類
- `feat`: 新機能
- `fix`: バグ修正
- `docs`: ドキュメントのみの変更
- `style`: コードの意味に影響しない変更（空白、フォーマット、セミコロンなど）
- `refactor`: バグ修正や機能追加を伴わないコード変更
- `test`: テストの追加や修正
- `chore`: ビルドプロセスやツールの変更

### 良いコミットメッセージの例
```
refactor: 未使用UIコンポーネントを削除

削除対象:
- ErrorMessage.tsx: MessageDialogコンポーネントで代替されているため削除
- HikarinoProfile.tsx: 現在のUIデザインで使用されていないため削除

これにより、UIコンポーネント数が19個から17個に削減され、
コードベースの保守性が向上しました。

Co-Authored-By: Sina-TehraniFard <tf.sina.system@gmail.com>
```

## 重要な注意事項

1. **AI生成の痕跡を残さない**: コミットメッセージからAIツールの使用を示す記載は完全に排除する
2. **ユーザー署名の扱い**: ユーザーが明示的に要求した場合のみ追加
3. **簡潔性と明確性**: 変更内容と理由を簡潔かつ明確に記載

## 更新履歴
- 2025-08-12: 初版作成 - AIツール署名の禁止ルールを明文化