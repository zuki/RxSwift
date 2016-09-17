ユニット
=====

ここではユニットとは何なのか、なぜ有用な概念なのか、どのように作成し使用するかを説明します。

* [なぜ](#なぜ)
* [どのように動作するか](#どのように動作するか)
* [なぜユニットと名付けられたか](#なぜユニットと名付けられたか)
* [RxCocoa units](#rxcocoa-units)
* [Driver units](#driver-unit)
    * [なぜDriverと命名されたのか](#なぜdriverと命名されたのか)
    * [実用的な使用例](#実用的な使用例)

## なぜ

Swiftは強力な型システムを持っており、これを使って、アプリケーションの正確さや安定性を向上させたり、Rxの使用をより直感的で分かりやすい体験にすることができます。

**Unitは[RxCocoa](https://github.com/ReactiveX/RxSwift/tree/master/RxCocoa)プロジェクトのみに特化したものですが、必要であれば、同じ原理を他のRx実装にも簡単に実装することができます。非公開APIの魔法は必要ありません。**

**Unitは完全にオプションです。プログラムのどこにでも生のobservableシーケンスを使えます。また、全てのRxCocoa APIはobservableシーケンスと共に動作します。**

また、Unitはコミュニケーションを支援し、インターフェースの境界を超えてobservableシーケンスのプロパティを保証します。

以下はCocoa/UIKitアプリケーションを書く際に重要なプロパティの一部です。

* エラー出力しない
* main scheduler上でobserveする
* main scheduler上でsubscribeする
* 副作用を共有する

## どのように動作するか

根本的には、Unitはobservableシーケンスへの参照を持つ単なる構造体です。

observableシーケンスのためのBuilderパターンの一種と考えることができます。
シーケンスが構築されると、`.asObservable()`の呼び出しによりユニットが普通のobservableシーケンスに変換されます。


## なぜユニットと名付けられたか

馴染みのない概念を理解するにはアナロジーが役に立ちます。以下の表には、物理学とRxCocoa(Rx units)におけるUnitがどのように類似しているかを示すアナロジーを挙げています。

類似:

| 物理 units                      | Rx units                                                            |
|-------------------------------------|---------------------------------------------------------------------|
| 数 (1つの値)                  | observable シーケンス (複数の値のシーケンス)                            |
| 次元の単位 (m, s, m/s, N ...) | Swift構造体 (Driver, ControlProperty, ControlEvent, Variable...) |

物理unitは数と対応する次元の単位のペアです。Rx unitはobservableシーケンスと対応するobservableシーケンスプロパティを記述する構造体のペアです。

数は、物理unitで作業する際の基本的な構成的グルーであり、通常、実数または複素数です。Observableシーケンスは、Rx unitsで作業する際の基本的な構成的グルーです。

物理Unitと[次元解析](https://en.wikipedia.org/wiki/Dimensional_analysis#Checking_equations_that_involve_dimensions)は複雑な計算においてある種のエラーを軽減することができます。Rx unitの型チェックはリアクティブプログラムを書く際にある種の論理エラーを軽減することができます。

数は次の演算子を持ちます: `+`, `-`, `*`, `/`
Observableシーケンスも演算子を持ちます: `map`, `filter`, `flatMap` ...

物理Unitは対応する数の演算を使用して演算を定義します。

たとえば、物理Unitにおける `/`演算は、数における `/`演算を使用して定義されています。

11 m / 0.5 s = ...

* まず、Unitを数値に変換し、`/` **演算子** を **適用します**。 `11 / 0.5 = 22`
* 次に、単位を計算します (m / s)
* 最後に、両者を合体して結果は = 22 m / s

Rx unitは対応するobservableシーケンスの演算を使用して演算を定義(オペレーターが内部でどのように動作するか)します。

たとえば、`Driver`における`map`演算は、そのobservableシーケンスにおける`map`演算を使用して定義されています。

```swift
let d: Driver<Int> = Drive.just(11)
driver.map { $0 / 0.5 } = ...
```

* まず、`Driver`を **observableシーケンス** に変換し、`map` **演算子** を **適用します**。

```swift
let mapped = driver.asObservable().map { $0 / 0.5 } // この`map`はobservableシーケンスにおいて定義されている
```

* 次に、それを合体させてUnitを取得します。

```swift
let result = Driver(mapped)
```

物理学には互いに直交する基本的な単位のセット[(`m`, `kg`, `s`, `A`, `K`, `cd`, `mol`)](https://en.wikipedia.org/wiki/SI_base_unit)があります。
`RxCocoa`には互いに直行するobservableシーケンスの基本的な興味深いプロパティのセットがあります。

    * エラー出力しない
    * main scheduler上でobserveする
    * main scheduler上でsubscribeする
    * 副作用を共有する

物理学の派生単位には特別な名前を持つものがあります。
たとえば、

```
N (ニュートン: Newton) = kg * m / s / s
C (クーロン: Coulomb) = A * s
T (テスラ: Tesla) = kg / A / s / s
```

Rxの派生unitも特別な名前を持ちます。たとえば、

```
Driver = (エラー出力しない) * (main scheduler上でobserveする) * (副作用を共有する)
ControlProperty = (副作用を共有する) * (main scheduler上でsubscribeする)
Variable = (エラー出力しない) * (副作用を共有する)
```

物理学における異なるUnit間の変換は、数において定義されている演算子 `*`, `/` の助けを借りて行われます。
RXにおける異なるUnit間の変換は、observableシーケンスオペレーターの助けを借りて行われます。たとえば、

```
エラー出力しない = catchError
main scheduler上でobserveする = observeOn(MainScheduler.instance)
main scheduler上でsubscribeする = subscribeOn(MainScheduler.instance)
副作用を共有する = share* (`share` オペレータのいずれか)
```


## RxCocoa units

### Driver unit

* エラー出力しない
* main scheduler上でobserveする
* 副作用を共有する (`shareReplayLatestWhileConnected`)

### ControlProperty / ControlEvent

* エラー出力しない
* main scheduler上でobserveする
* main scheduler上でsubscribeする
* 副作用を共有する

### Variable

* エラー出力しない
* 副作用を共有する

## Driver

最も複雑なunitです。その意図はUIレイヤーでリアクティブなコードを書く直感的な方法を提供することです。

### なぜDriverと命名されたのか

想定したユースケースは、アプリケーションを動作させるシーケンスのモデル化でした。

たとえば

* CoreDataモデルでUIを動作させる
* 他のUI要素の値を使用してUIを動作させる(バインディング)...

オペレーティングシステムの通常のドライバのように、シーケンスでエラーが生じた場合、アプリケーションはユーザー入力への応答を停止します。

シーケンス要素がメインスレッドでobserveされることも極めて重要です。なぜなら、UI要素とアプリケーションロジックは通常スレッドセーフではないからです。

また、`Driver` unitは副作用を共有するobservableシーケンスを構築します。

例.

### 実用的な使用例

以下は典型的な初心者の例です。

```swift
let results = query.rx_text
    .throttle(0.3, scheduler: MainScheduler.instance)
    .flatMapLatest { query in
        fetchAutoCompleteItems(query)
    }

results
    .map { "\($0.count)" }
    .bindTo(resultCount.rx_text)
    .addDisposableTo(disposeBag)

results
    .bindTo(resultsTableView.rx_itemsWithCellIdentifier("Cell")) { (_, result, cell) in
        cell.textLabel?.text = "\(result)"
    }
    .addDisposableTo(disposeBag)
```

このコードの想定動作は

* ユーザー入力を絞る
* サーバーに接続してユーザー指定の結果リストを取得する(クエリ毎に一度)
* 2つのUI要素、すなわち、結果表示用テーブルビューと結果の数を表示するラベル、に結果をバインドする。

では、このコードの問題は何か?

* `fetchAutoCompleteItems` observableシーケンスがエラー(接続失敗やパースエラー)を出力した場合、このエラーはすべてのバインドを解除し、UIはそれ以上新しいクエリに応答しなくなります。
* `fetchAutoCompleteItems`が何らかのバックグラウンドスレッドで結果を返した場合、
  結果はバックグラウンドスレッドでUI要素にバインドされ、これが非決定性のクラッシュを引き起こす可能性があります。
* 結果は2つのUI要素にバインドされています。これは各々のユーザークエリに対して2つのHTTPリクエスト、各UI要素ごとに一つ、が行われることを意味します。これは想定した動作ではありません。

より適切なコードは次のようになるでしょう。

```swift
let results = query.rx_text
    .throttle(0.3, scheduler: MainScheduler.instance)
    .flatMapLatest { query in
        fetchAutoCompleteItems(query)
            .observeOn(MainScheduler.instance) // 結果はMainScheduler上で返される
            .catchErrorJustReturn([])          // 最悪の場合、エラー処理される
    }
    .shareReplay(1)                            // HTTPリクエストは共有され、
                                               // 結果はすべてのUI要素で再生される

results
    .map { "\($0.count)" }
    .bindTo(resultCount.rx_text)
    .addDisposableTo(disposeBag)

results
    .bindTo(resultTableView.rx_itemsWithCellIdentifier("Cell")) { (_, result, cell) in
        cell.textLabel?.text = "\(result)"
    }
    .addDisposableTo(disposeBag)
```

大規模システムにおいてこれらの要求をすべて適切に処理することを確実に行うことは困難なことかもしれません。しかし、コンパイラとUnitを使いこれらの要件を満たすことを証明する簡単な方法があります。

次のコードはほとんど同ように見えます:

```swift
let results = query.rx_text.asDriver()        // これは通常のシーケンスを`Driver`シーケンスに変換する
    .throttle(0.3, scheduler: MainScheduler.instance)
    .flatMapLatest { query in
        fetchAutoCompleteItems(query)
            .asDriver(onErrorJustReturn: [])  // ビルダーはエラーの場合に何を返すかという情報だけを必要とする
    }

results
    .map { "\($0.count)" }
    .drive(resultCount.rx_text)               // `bindTo`の代わりに利用できる`drive`メソッドがある場合、
    .addDisposableTo(disposeBag)              // それはすべてのプロパティが満たさされていることを
                                              // コンパイラが証明したことを意味する

results
    .drive(resultTableView.rx_itemsWithCellIdentifier("Cell")) { (_, result, cell) in
        cell.textLabel?.text = "\(result)"
    }
    .addDisposableTo(disposeBag)
```

ここで何が起こっているのでしょう？

まず、`asDriver`メソッドで `ControlProperty` unit を `Driver` unit に変換しています。

```swift
query.rx_text.asDriver()
```

これをするのに特別なことは何も必要がないことに注意してください。`Driver`は、`ControlProperty` unit の全てのプロパティに加えて、さらにいくつかのプロパティを持っています。根底にあるobservableシーケンスがただ`Driver` unitとしてラップされている、それだけです。

２つ目の変更は

```swift
  .asDriver(onErrorJustReturn: [])
```

任意のobservableシーケンスは、以下の3つのプロパティを満たしていれば `Driver` unit に変換できます。

* エラーを出さない
* main schedulerでobserveする
* 副作用を共有する (`shareReplayLatestWhileConnected`)

それでは、これらの特性が確実に満たされるようにするにはどうすればいいでしょうか？通常のRxオペレーターを使うだけです。`asDriver(onErrorJustReturn: [])`は次のコードと同等です。

```
let safeSequence = xs
  .observeOn(MainScheduler.instance)       // main schedulerでイベントをobserveする
  .catchErrorJustReturn(onErrorJustReturn) // エラーを出さない
  .shareReplayLatestWhileConnected         // 副作用を共有する
return Driver(raw: safeSequence)           // 上記をラップする
```

最後のピースは`bindTo`の代わりに`drive`を使用することです。

`drive`は、`Driver` unit上でのみ定義されています。これは、コードの中に`drive`を見つけたら、observableシーケンスは決してエラーを出さず、監視はメインスレッド上で行われており、UI要素へのバインドは安全である、ということを意味します。

しかしながら、理論的には、`ObservableType`やその他のインターフェース上で動作する`driver`メソッドを定義することもできます。そのため、より安全にするためには、その完全な証明のために、UI要素にバインドする前に `let results: Driver<[Results]> = ...` により一時的な定義を作成することが必要になることに注意してください。ただし、これが現実的なシナリオであるか否かを決定するのは読者に任せます。
