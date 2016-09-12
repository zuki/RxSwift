実例
========

1. [計算済み変数](#計算済み変数)
1. [シンプルなUIバインディング](#シンプルなuiバインディング)
1. [自動補完](#自動補完)
1. [more examples](../RxExample)
1. [Playgrounds](Playgrounds.md)

## 計算済み変数

それでは命令型のSwiftコードから始めましょう。
この例の目的はある条件が満たされた場合に `a` と `b` から計算される値を `c` にバインドすることです。

以下が `c` の値を計算する命令型のSwiftコードです:

```swift
// これは通重の命令形コードです
var c: String
var a = 1       // `a` に `1` を一度代入するだけ
var b = 2       // `b` に `2` を一度代入するだけ

if a + b >= 0 {
    c = "\(a + b) is positive" // `c` に値を一度代入するだけ
}
```

今、`c` の値は `3 is positive` です。しかし、`a` の値を `4` に変更しても、`c` は依然として古い値のままです。

```swift
a = 4           // c は依然として "3 is positive" と等しいまま、これは良くない。
                // c は "6 is positive" と等しくなるべき、なぜなら 4 + 2 = 6 だから
```

これは求めている振る舞いではありません。

RxSwiftフレームワークをあなたのプロジェクトに統合するには、プロジェクトにフレームワークを含めて`import RxSwift`と書くだけです。

以下はRxSwiftを使用した同じロジックです。

```swift
let a /*: Observable<Int>*/ = Variable(1)   // a = 1
let b /*: Observable<Int>*/ = Variable(2)   // b = 2

// 以下は rx変数 `c` に次のような定義を"bind" する
// if a + b >= 0 {
//      c = "\(a + b) is positive"
// }

// variable `a` と `b` の最新の値を `+` を使用して結合する:
let c = Observable.combineLatest(a.asObservable(), b.asObservable()) { $0 + $1 }
	.filter { $0 >= 0 }         // `a + b >= 0` が真なら、`a + b` はmapオペレーターに渡される
	.map { "\($0) is positive" } // `a + b` を "\(a + b) is positive" にマップする

// 初期値は a = 1, b = 2 であるので
// 1 + 2 = 3 で >= 0 なので、 `c` は最初 "3 is positive" と等しくなる

// Rx変数`c` から値を引き出すために、`c` からの値を subscribe する。
// `subscribeNext` は variable `c`のnext値（新たな値）を subscribe するという意味。
// これにも初期値 "3 is positive" が含まれている。
c.subscribeNext { print($0) }          // 表示: "3 is positive"

// `a` の値を増やしてみる
// RxSwiftで a = 4
a.value = 4                            // 表示: 6 is positive
// 最新の値の合計は `4 + 2`, `6` は >= 0 なので、mapオペレーターは "6 is positive" を
// 生成する。そして、この結果は `c` に "アサイン(assigned)" される。
// `c` の値が更新されたので、`{ print($0) }` が呼び出され、"6 is positive" が表示される。

// 次に `b` の値を変えてみる
// RxSwiftで b = -8
b.value = -8                           // 何も表示されない
// 最新の値の合計は `4 + (-8)`, `-4` は >= 0 ではないので、map は実行されない。
// これは `c` がまだ "6 is positive" であることを意味し、それは正しい。
// `c` は更新されていないので、それは次の値が生成されていないことを意味する。
// そのため `{ print($0) }` は呼び出されない。

// ...
```

## シンプルなUIバインディング

* Variableにバインドする代わりに、Textフィールドの値(rx_text)にバインドしてみましょう
* 次に、フィールド値を整数にパースし、非同期APIを使用して数値が素数か否か計算します(map)
* text フィールド値が非同期呼び出しが完了する前に更新された場合は、新しい非同期呼び出しがエンキューされます(concat)
* 結果をlabelにバインドします(bindTo(resultLabel.rx_text))

```swift
let subscription/*: Disposable */ = primeTextField.rx_text    // 型は Observable<String>
            .map { WolframAlphaIsPrime(Int($0) ?? 0) }        // 型は Observable<Observable<Prime>>
            .concat()                                         // 型は Observable<Prime>
            .map { "number \($0.n) is prime? \($0.isPrime)" } // 型は Observable<String>
            .bindTo(resultLabel.rx_text)                      // 全てのバインド解除に使用できるDisposable を返す

// これはサーバーコールが完了した後に resultLabel.text に "number 43 is prime? true" を設定する
primeTextField.text = "43"

// ...

// 全てのバインドを解除するには、次を呼ぶだけ
subscription.dispose()
```

この例で使用したオペレーターはすべて、Variableを使った最初の例で使用したオペレーターと同じです。
特別なものは何もありません。

## 自動補完

もしあなたがRxに慣れていなければ、おそらく次の例には少し圧倒されるでしょう。しかし、これこそ、現実的な例においてRxコードがどのようになるかを示すものです。

3番目の例は現実的なものであり、進捗通知のある非同期バリデーションロジックを持つ複雑なUIです。

全ての操作は `disposeBag` が解放された瞬間にキャンセルされます。

それではやってみましょう。

```swift
// UIコントロール値を直接バインドし
// `usernameOutlet`の値を、username値のソースとして使用する
self.usernameOutlet.rx_text
    .map { username in

        // 同期バリテーション、ここでは特別なことはない
        if username.isEmpty {
            // 同期の結果を構築するのに便利。
            // 同期と非同期のコードが同じメソッドに混在している場合は、直ちに解決される非同期の結果を構築する
            return Observable.just((valid: false, message: "ユーザー名は空にできません"))
        }

        ...

        // 全てのユーザーインターフェースは、非同期操作の実行中にはおそらく何らかの状態を表示する。
        // 結果を待っている間、 "使用できるか確認中" と表示したいと仮定する。
        // validパラメーターは以下とする
        //  * true  - 有効
        //  * false - 無効
        //  * nil   - バリデーション保留中
        typealias LoadingInfo = (valid : String?, message: String?)
        let loadingValue : LoadingInfo = (valid: nil, message: "使用できるか確認中 ...")

        // 以下はユーザー名が既に存在するか確認するためのサーバーコールを発行する。
        // 型は `Observable<ValidationResult>` である。
        return API.usernameAvailable(username)
          .map { available in
              if available {
                  return (true, "ユーザー名は使用可能です")
              }
              else {
                  return (false, "ユーザー名は既に使用されています")
              }
          }
          // サーバーが反応するまで `loadingValue` を使用する
          .startWith(loadingValue)
    }
// 今の型は `Observable<Observable<ValidationResult>>` であるので、
// 何とかして通常の `Observable` の世界に戻る必要がある。
// 2番目の例のように `concat` オペレーターが使用できるだろう。
// しかし、新しいユーザー名が提供された場合は、明らかに保留中の非同期操作をキャンセルしたい。
// `switchLatest` が行うのはそれである。
    .switchLatest()
// 今やこれを何とかしてユーザーインターフェースにバインドする必要がある。
// 古き良き `subscribeNext` はそれをすることができる。
// それは`Observable` チェーンの終わりである。
// これは全てのバインドを解除して保留中の非同期操作をキャンセルすることができる `Disposable` オブジェクトを生成する。
    .subscribeNext { valid in
        errorLabel.textColor = validationColor(valid)
        errorLabel.text = valid.message
    }
// 一体なぜ手作業で行うのか、それは冗長だ、
// ビューコントローラーが開放される時に自動的にすべて dispose しよう。
    .addDisposableTo(disposeBag)
```

これより簡単にすることはできません。
リポジトリには[更なる例](../RxExample)があります。気軽にチェックアウトしてください。

例にはMVVMパターンのコンテキストでの使い方やパターンを使わないものなどが含まれています。
