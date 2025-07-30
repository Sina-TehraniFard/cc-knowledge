# TDD Refactor フェーズテンプレート

## 概要
- **対象機能**: [テスト対象の機能名]
- **フェーズ**: 🟢 Refactor（品質向上）
- **作成日**: [作成日]

## リファクタリング原則

### 基本方針
1. **テストを壊さない**（Green状態を維持）
2. **段階的な改善**（一度に多くを変更しない）
3. **設計品質の向上**
4. **保守性・可読性の改善**

## リファクタリングパターン

### 1. ハードコーディング解消
```typescript
// Before: Green フェーズのハードコーディング
function authenticateUser(username: string, password: string): boolean {
  if (username === 'testuser' && password === 'testpass') {
    return true;
  }
  return false;
}

// After: 実際のロジック実装
/**
 * 機能目的: ユーザー認証処理
 * 実装戦略: データベース連携による認証
 * 対応テスト: 'should authenticate valid user'
 * 信頼性レベル: 🟢（本格実装完了、十分テスト済み）
 */
function authenticateUser(username: string, password: string): boolean {
  const user = userRepository.findByUsername(username);
  if (!user) return false;
  
  return hashService.verify(password, user.hashedPassword);
}
```

### 2. 重複コード整理
```typescript
// Before: 重複したバリデーションロジック
function validateEmail(email: string): boolean {
  return email.includes('@') && email.includes('.');
}

function validatePassword(password: string): boolean {
  return password.length >= 8;
}

// After: 共通バリデーションクラス
/**
 * クラス目的: 入力データの統一的バリデーション
 * 実装戦略: 設定駆動型バリデーション
 * 対応テスト: ValidationService テストスイート
 * 信頼性レベル: 🟢（包括的テスト済み）
 */
class ValidationService {
  static validateEmail(email: string): boolean {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  }
  
  static validatePassword(password: string): boolean {
    return password.length >= 8 && /[A-Z]/.test(password) && /[0-9]/.test(password);
  }
}
```

### 3. 設計パターン適用
```typescript
// Before: 直接的な依存関係
class UserService {
  saveUser(user: User): void {
    // データベース直接操作
    database.save(user);
  }
}

// After: Dependency Injection パターン
/**
 * クラス目的: ユーザー管理ビジネスロジック
 * 実装戦略: DI パターンによる疎結合設計
 * 対応テスト: UserService 統合テスト
 * 信頼性レベル: 🟢（設計パターン適用済み、テスト完備）
 */
class UserService {
  constructor(private userRepository: IUserRepository) {}
  
  saveUser(user: User): void {
    this.userRepository.save(user);
  }
}
```

### 4. エラーハンドリング強化
```typescript
// Before: 基本的なエラーハンドリング
function processData(data: any): any {
  if (!data) return null;
  return data.process();
}

// After: 包括的エラーハンドリング
/**
 * 機能目的: データ処理とエラーハンドリング
 * 実装戦略: Result パターンによる安全な処理
 * 対応テスト: エラーケース含む全シナリオテスト
 * 信頼性レベル: 🟢（エラーハンドリング完備）
 */
function processData(data: any): Result<ProcessedData, Error> {
  try {
    if (!data) {
      return Result.failure(new Error('Data is required'));
    }
    
    const processed = data.process();
    return Result.success(processed);
  } catch (error) {
    return Result.failure(error as Error);
  }
}
```

## リファクタリングチェックリスト

### 必須項目
- [ ] 全テストが通る（Green状態維持）
- [ ] ハードコーディング解消
- [ ] 重複コード整理
- [ ] 適切なエラーハンドリング
- [ ] 信頼性レベル更新（🟢）

### 品質項目
- [ ] コードの可読性向上
- [ ] 保守性の改善
- [ ] 設計パターンの適用
- [ ] パフォーマンス最適化
- [ ] セキュリティ考慮

### ドキュメント更新
- [ ] 関数・クラスコメントの更新
- [ ] 実装戦略の詳細化
- [ ] 信頼性レベルの更新

## リファクタリング後の検証

### テスト実行
```bash
# 全テスト実行
npm test

# カバレッジ確認
npm run test:coverage

# 品質チェック
npm run lint
npm run typecheck
```

### 品質指標
- テスト成功率: 100%
- カバレッジ: [目標値]%以上
- Lint エラー: 0件
- Type エラー: 0件

## 完了基準

### Definition of Done
1. **全テストが通る**
2. **品質チェックをパスする**
3. **コードレビューを通過する**
4. **ドキュメントが更新されている**
5. **信頼性レベルが🟢になっている**

### 最終コメント例
```typescript
/**
 * 機能目的: [最終的な機能説明]
 * 実装戦略: [採用した設計パターンと理由]
 * 対応テスト: [包括的テストケース]
 * 信頼性レベル: 🟢（本格実装完了、十分テスト済み、本番準備完了）
 */
```

## 次のステップ
TDD サイクル完了 → 次の機能開発 or 統合テスト

### 後続作業
- 統合テスト実施
- パフォーマンステスト
- セキュリティテスト
- デプロイメント準備

## 関連文書
- Red フェーズ: [リンク]
- Green フェーズ: [リンク]
- 設計書: [リンク]
- テスト仕様: [リンク]