Linux
=====

Linuxのための概念実証を行っています。

これをテストするには、テストディレクトリに次の内容の `Package.swift`を作成します。

```
import PackageDescription

let package = Package(
    name: "MyShinyUnicornCat",
    dependencies: [
        .Package(url: "https://github.com/ReactiveX/RxSwift.git", Version(2, 0, 0))
    ]
)
```

動くもの:

* Swiftパッケージマネージャを使用した配布
* シングルスレッドモード (CurrentThreadScheduler)
* ユニットテストの半分がパス
* コンパイルでき、「使用可能」なプロジェクト
    * RxSwift
    * RxBlocking
    * RxTests

動かない者:

* スケジューラ - これは https://github.com/apple/swift-corelibs-libdispatch に依存していますが、まだリリースされていないため
* マルチスレッド - まだc11ロックにアクセスできません
* 何らかの理由で、`Linux` 上で `ErrorType` を使うとSwiftコンパイラは間違ったコードを生成するように思えます。そのため、エラーは使用しないでください。さもないと、不可解なクラッシュがおきる可能性があります。
