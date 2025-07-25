# テストガイドライン

## 1. TDD (Test-Driven Development)

### TDDの黄金サイクル（Red-Green-Refactor）

1. **Red（レッドフェーズ）**
   - まず失敗するテストを書く
   - 最小限の実装に対するテストとする
   - コンパイルエラーも失敗の一種
   - **重要**: 失敗を確認せずに次に進まない

2. **Green（グリーンフェーズ）**
   - テストを通すための最小限のコードを書く
   - ベタ書き、ハードコーディングもOK
   - とにかくテストを通すことだけに集中
   - **重要**: 必要以上の実装をしない

3. **Refactor（リファクタフェーズ）**
   - テストが通っている状態を維持しながらコードを改善
   - 重複を除去し、設計を改善
   - テストコード自体もリファクタリング対象
   - **重要**: 新しい機能は追加しない

### TDDの原則
- **テストファースト**: 実装前に必ずテストを書く
- **小さなステップ**: 1つのテスト = 1つの振る舞い
- **三角測量**: 2つ以上の具体例から一般化を導く
- **明白な実装**: 確信がある場合は最初から正しい実装を書いてもよい

### TDDのアンチパターン
- ❌ すべてのテストを先に書いてから実装を始める
- ❌ privateメソッドを直接テストする
- ❌ テストのためだけに実装を変更する
- ❌ モックを使いすぎる
- ❌ 実装の詳細に依存したテストを書く

## 2. テストクラスの構成

### 基本ルール
- **1クラス1テストクラス（厳守）**: `UserService`に対して`UserServiceTest`のみ
- **テストクラスの分離禁止**: すべて同一テストクラス内に含める
- **@Nestedクラスで階層化**: メソッドや機能単位で整理

### ⚠️ @Nested使用上の重要な制約

#### データベーステスト基底クラスとの非互換性
```kotlin
// ❌ 危険：DatabaseTestBaseを継承するクラスで@Nestedを使用するとハング発生
class TransferTaskLifecycle : DatabaseTestBase() {
    @Nested  // ← これは危険
    inner class SomeTest {
        @Test
        fun test() { /* ハング発生の可能性 */ }
    }
}

// ✅ 安全：通常のテストクラスでの@Nested使用は問題なし
class UserServiceTest {
    @Nested
    inner class CreateUserTest {
        @Test
        fun shouldCreateUserSuccessfully() { /* 正常動作 */ }
    }
}
```

#### DatabaseTestBase使用時の代替パターン
```kotlin
class TransferTaskLifecycleTest : DatabaseTestBase() {
    // @Nestedは使用せず、メソッド名で階層を表現
    
    @Test
    @DisplayName("作成時 - 正常なパラメータでタスクが作成される")
    fun create_shouldCreateTask_withValidParameters() { }
    
    @Test  
    @DisplayName("作成時 - 不正なパラメータで例外が発生する")
    fun create_shouldThrowException_withInvalidParameters() { }
    
    @Test
    @DisplayName("更新時 - 正常な値で更新される") 
    fun update_shouldUpdateSuccessfully_withValidValues() { }
}
```

### 推奨階層構造（@Nested対応クラス）
```kotlin
class UserServiceTest {
    
    @Nested
    @DisplayName("ユーザー作成")
    inner class CreateUserTest {
        
        @Test
        @DisplayName("正常なパラメータでユーザーが作成される")
        fun shouldCreateUserSuccessfully() { }
        
        @Test
        @DisplayName("重複するメールアドレスで例外が発生する")
        fun shouldThrowExceptionWhenEmailDuplicated() { }
    }
    
    @Nested 
    @DisplayName("ユーザー検索")
    inner class FindUserTest {
        
        @Test
        @DisplayName("存在するIDでユーザーが取得される")
        fun shouldReturnUserWhenIdExists() { }
        
        @Test
        @DisplayName("存在しないIDでnullが返される")
        fun shouldReturnNullWhenIdNotExists() { }
    }
}
```

## 3. テストメソッドの命名と構造

### 命名規則
- **should + 動作 + 条件**: `shouldReturnUserWhenIdExists()`
- **日本語@DisplayName必須**: テストの意図を明確に記述
- **Given-When-Then構造**: コメントで明確に区分

### テストメソッドのテンプレート
```kotlin
@Test
@DisplayName("存在するIDでユーザーが取得される")
fun shouldReturnUserWhenIdExists() {
    // Given
    // ユーザーが既に登録されている状態
    val existingUserId = 1L
    val expectedUser = User(id = existingUserId, name = "田中太郎")
    `when`(userRepository.findById(existingUserId)).thenReturn(expectedUser)
    
    // When
    // 存在するIDでユーザーを検索する
    val actualUser = userService.findById(existingUserId)
    
    // Then
    // 期待されるユーザーが返される
    assertThat(actualUser).isEqualTo(expectedUser)
    verify(userRepository).findById(existingUserId)
}
```

## 4. テストの命名と文書化

### @DisplayNameの書き方
- **日本語で記述**: ビジネス要件との対応を明確にする
- **具体的な条件と結果**: 「〜の場合、〜される」形式
- **ビジネス価値を表現**: 技術的詳細ではなく、ユーザー価値を記述

#### 良い例
```kotlin
@DisplayName("アクティブなプレミアムユーザーが高度な機能にアクセスできる")
@DisplayName("無効なメールアドレスでユーザー登録時にバリデーションエラーが発生する")
@DisplayName("管理者権限のないユーザーが管理機能にアクセスした時に認可エラーが返される")
```

#### 悪い例
```kotlin
@DisplayName("testCreateUser") // 技術的すぎる
@DisplayName("nullの場合") // 条件のみで結果が不明
@DisplayName("エラーテスト") // 抽象的すぎる
```

## 5. アサーションとモック

### AssertJの活用
```kotlin
// ✅ 推奨：AssertJの流暢なアサーション
assertThat(users)
    .hasSize(3)
    .extracting("name")
    .containsExactly("田中", "佐藤", "鈴木")

// ❌ 非推奨：JUnitの基本アサーション
assertEquals(3, users.size())
assertEquals("田中", users.get(0).getName())
```

### モックの適切な使用
```kotlin
class UserServiceTest {
    
    @Mock
    private lateinit var userRepository: UserRepository
    
    @InjectMocks
    private lateinit var userService: UserService
    
    @Test
    @DisplayName("ユーザー作成時にリポジトリのsaveメソッドが呼ばれる")
    fun shouldCallRepositorySaveWhenCreatingUser() {
        // Given
        // 新規ユーザーの情報が与えられた状態
        val newUser = User(name = "田中太郎", email = "tanaka@example.com")
        val savedUser = newUser.copy(id = 1L)
        `when`(userRepository.save(any())).thenReturn(savedUser)
        
        // When
        // ユーザー作成を実行した時
        val result = userService.createUser(newUser)
        
        // Then
        // リポジトリのsaveメソッドが適切な引数で呼ばれ、結果が返される
        verify(userRepository).save(argThat { user ->
            user.name == "田中太郎" && user.email == "tanaka@example.com"
        })
        assertThat(result).isEqualTo(savedUser)
    }
}
```

## 6. パラメータ化テスト

### @ParameterizedTestの活用
```kotlin
@ParameterizedTest
@DisplayName("無効なメールアドレス形式でバリデーションエラーが発生する")
@ValueSource(strings = ["", "invalid", "@example.com", "user@", "user@.com"])
fun shouldThrowValidationExceptionWithInvalidEmail(invalidEmail: String) {
    // Given
    // 無効なメールアドレスが与えられた状態
    val userWithInvalidEmail = User(name = "田中太郎", email = invalidEmail)
    
    // When & Then
    // ユーザー作成時にバリデーション例外が発生する
    assertThatThrownBy { 
        userService.createUser(userWithInvalidEmail) 
    }
    .isInstanceOf(ValidationException::class.java)
    .hasMessageContaining("メールアドレス")
}
```

## 7. データセットアップ

### テストデータビルダーパターン
```kotlin
// テストデータ作成用のビルダー
class UserTestDataBuilder {
    private var id: Long? = null
    private var name: String = "テストユーザー"
    private var email: String = "test@example.com"
    private var status: UserStatus = UserStatus.ACTIVE
    
    fun withId(id: Long) = apply { this.id = id }
    fun withName(name: String) = apply { this.name = name }
    fun withEmail(email: String) = apply { this.email = email }
    fun withStatus(status: UserStatus) = apply { this.status = status }
    
    fun build() = User(id = id, name = name, email = email, status = status)
    
    companion object {
        fun aUser() = UserTestDataBuilder()
        fun anActiveUser() = UserTestDataBuilder().withStatus(UserStatus.ACTIVE)
        fun anInactiveUser() = UserTestDataBuilder().withStatus(UserStatus.INACTIVE)
    }
}

// 使用例
@Test
@DisplayName("アクティブなユーザーがログインできる")
fun shouldAllowLoginForActiveUser() {
    // Given
    // アクティブなユーザーが存在する状態
    val activeUser = UserTestDataBuilder
        .anActiveUser()
        .withEmail("active@example.com")
        .build()
    
    // テスト実行...
}
```

## 8. 例外テスト

### 例外の詳細な検証
```kotlin
@Test
@DisplayName("存在しないユーザーIDで検索した時にUserNotFoundExceptionが発生する")
fun shouldThrowUserNotFoundExceptionWhenUserNotExists() {
    // Given
    // 存在しないユーザーIDが指定された状態
    val nonExistentUserId = 999L
    `when`(userRepository.findById(nonExistentUserId)).thenReturn(null)
    
    // When & Then
    // ユーザー検索実行時に適切な例外が発生する
    assertThatThrownBy { 
        userService.findById(nonExistentUserId) 
    }
    .isInstanceOf(UserNotFoundException::class.java)
    .hasMessage("ユーザーが見つかりません: ID=$nonExistentUserId")
    .satisfies { exception ->
        assertThat(exception.userId).isEqualTo(nonExistentUserId)
    }
}
```

## 9. テストデータの分離

### テストクラス毎のデータ分離
```kotlin
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
class UserServiceIntegrationTest {
    
    @BeforeEach
    fun setUp() {
        // 各テスト実行前にデータをクリーンアップ
        testDataCleanup.cleanAllTables()
    }
    
    @Test
    @DisplayName("ユーザー登録から検索までの一連の流れが正常に動作する")
    fun shouldWorkEndToEndUserRegistrationAndSearch() {
        // Given
        // クリーンな状態のデータベース
        val newUser = UserTestDataBuilder.aUser()
            .withEmail("integration@example.com")
            .build()
        
        // When
        // ユーザー登録と検索を実行
        val savedUser = userService.createUser(newUser)
        val foundUser = userService.findById(savedUser.id!!)
        
        // Then
        // 期待される結果が得られる
        assertThat(foundUser).isEqualTo(savedUser)
    }
}
```

## 10. パフォーマンステスト

### 実行時間の測定
```kotlin
@Test
@DisplayName("大量ユーザー検索が5秒以内に完了する")
@Timeout(5)
fun shouldCompleteBulkUserSearchWithinFiveSeconds() {
    // Given
    // 大量のユーザーデータが存在する状態
    val userIds = (1..10000).map { it.toLong() }
    
    // When
    // 大量検索を実行
    val startTime = System.currentTimeMillis()
    val users = userService.findByIds(userIds)
    val executionTime = System.currentTimeMillis() - startTime
    
    // Then
    // 期待される時間内に完了し、正しい結果が得られる
    assertThat(users).hasSize(10000)
    assertThat(executionTime).isLessThan(5000)
}
```

## 11. テストカテゴリ

### テストの分類
```kotlin
// 単体テスト
@Tag("unit")
class UserServiceTest { }

// 統合テスト
@Tag("integration")
class UserServiceIntegrationTest { }

// エンドツーエンドテスト
@Tag("e2e")
class UserRegistrationE2ETest { }

// 実行方法の例
// ./gradlew test --tests "*Test"              # 単体テストのみ
// ./gradlew test --tests "*IntegrationTest"   # 統合テストのみ
// ./gradlew test                              # 全テスト実行
```

## 12. 継続的な改善

### テストメトリクス
- **カバレッジ率**: 80%以上を維持
- **実行時間**: 単体テストは10分以内、統合テストは30分以内
- **成功率**: 常に100%を目指す
- **メンテナンスコスト**: テストコードの複雑度を定期的に見直し

### レビューチェックポイント
- [ ] テストの意図が@DisplayNameで明確に表現されているか
- [ ] Given-When-Thenの構造が明確か
- [ ] アサーションが適切か（過不足がないか）
- [ ] テストデータの作成が適切か
- [ ] モックの使用が適切か（過度でないか）
- [ ] テストの独立性が保たれているか

このガイドラインを遵守することで、保守性が高く、信頼性のあるテストコードを作成することができます。