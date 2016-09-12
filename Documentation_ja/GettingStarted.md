入門
==============
RxSwiftは[ReactiveX.io](http://reactivex.io/)と調和するよう心がけています。
一般的なクロスプラットフォームのマニュアルとチュートリアルは`RxSwift`でも有効です。

1. [Observablesまたの名をSequences](#observablesまたの名をsequences)
1. [廃棄(Disposing)](#破棄 Disposing)
1. [暗黙的な `Observable` の保証](#暗黙的な-observable-の保証)
1. [初めての `Observable` (observable sequence)の作成](#初めての-observable-aka-observable-sequenceの作成)
1. [動作する `Observable` の作成](#動作する-observable-の作成)
1. [共有サブスクリプションと `shareReplay` オペレーター](#共有サブスクリプションと-sharereplay-オペレーター)
1. [オペレーター](#オペレーター)
1. [Playgrounds](#playgrounds)
1. [カスタムオペレーター](#カスタムオペレーター)
1. [エラーハンドリング](#エラーハンドリング)
1. [コンパイルエラーのデバッグ](#コンパイルエラーのデバッグ)
1. [デバッグ](#デバッグ)
1. [メモリリークのデバッグ](#メモリリークのデバッグ)
1. [KVO](#kvo)
1. [UIレイヤーのコツ](#uiレイヤーのコツ)
1. [HTTPリクエストの作成](#HTTPリクエストの作成)
1. [RxDataSources](#rxdatasources)
1. [Driver](Units.md#driver-unit)
1. [実例](Examples.md)

# Observablesまたの名をSequences

## 基本

オブサーバーパターン(`Observable<Element>`シーケンス)と通常のシーケンス(`SequenceType`)が等価であることはRxを理解する上で最も重要です。

**すべての`Observable`は単なるシーケンスです。`Observable`がSwiftの`SequenceType`に対する第一の利点は、要素を非同期に受けとることもできる点です。これがRxSwiftの肝です。以下のドキュメントはこのアイデアをさらに詳しく説明する以下の諸点に関するものです。**

- `Observable` (`ObservableType`)は`SequenceType`と等価である。
- `ObservableType.subscribe`メソッドは`SequenceType.generate`メソッドと投下である。
- シーケンス要素を受け取るためには、返されたジェネレーターの`next()`を呼ぶのではなく、オブザーバー(コールバック)を`ObservableType.subcribe`に渡す必要がある。

シーケンスはシンプルで、 **可視化するのが簡単な** おなじみの概念です。

人は大きな視覚野を持つ生き物です。概念が簡単に視覚化できればそれを容易に理解することができます。

Rxオペレーター内部のイベントステートマシンをシミュレートしようとする際に発生する多くの認知的負荷を取り除き、シーケンスに対する高レベルな操作に置き換えることができます。

もしRxを使わずに非同期システムをモデル化するとしたらそれはおそらく私達のコードが、抽象化ではなくシミュレートのために必要なステートマシンや過渡的状態に満ちたものになることを意味します。

リストとシーケンスはおそらく数学者とプログラマが最初に学ぶ概念です。

これは数字のシーケンスです:

```
--1--2--3--4--5--6--| // 正常終了
```

文字のシーケンスもあります:

```
--a--b--a--a--a---d---X // エラーで終了
```

シーケンスには有限なものもあれば、ボタンタップのシーケンスのように無限なものもあります:

```
---tap-tap-------tap--->
```

これらはマーブルダイアグラムと呼ばれます。他にもマーブルダイアグ無はたくさん存在します。[rxmarbles.com](http://rxmarbles.com)を参照してください。

シーケンス文法を正規表現で指定するとしたら次のようになるでしょう:

**Next* (Error | Completed)?**

これは下記のことを述べています:

* **シーケンスは0以上の要素を持つことができる**
* **一度 `Error` または `Completed` イベントを受信すると、シーケンスはそれ以上要素を作り出すことができない**

Rxのシーケンスはプッシュインターフェース(通称コールバック)によって記述されます。

```swift
enum Event<Element>  {
    case Next(Element)      // シーケンスの次の要素
    case Error(ErrorType)   // シーケンスはエラーで機能不全
    case Completed          // シーケンスは成功裏に終了
}

class Observable<Element> {
    func subscribe(observer: Observer<Element>) -> Disposable
}

protocol ObserverType {
    func on(event: Event<Element>)
}
```

**シーケンスが `Complete` または `Error` イベントを送信するとシーケンス要素を計算するためのすべての内部リソースは解放されます。**

**シーケンス要素の生産をキャンセルして直ちにリソースを解放するには、返されたサブスクリプションの `dispose`を呼び出してください。**

シーケンスが有限時間で終了する場合は、`dispose` をコールしたり `addDisposableTo(disposeBag)` を使用しなくても永続的なリソースリークが発生することはありません。
しかしながら、それらのリソースはシーケンスが完了するか、要素の生産を終了するか、エラーを返すまで利用されます。

もしシーケンスが何らかの理由で終了しない場合、`dispose`を明に呼び出すか、`disposeBag`や`takeUntil`またはなんかの方法の中で自動的に呼び出されないと、リソースは永久に割り当てられたままになります。

**dispose bagsまたは`takeUntil`オペレータの使用は、リソースを確実にクリーンアップするロバストな方法です。
プロダクション環境ではたとえシーケンスが有限時間で終了する場合でもこれらを使うことを推奨します。**

`ErrorType`がなぜジェネリックでないのか不思議に思った方は、[ここ](DesignRationale.md#why-error-type-isnt-generic)に説明があります。

## 破棄 Disposing

オブサーブされたシーケンスを終了できるもう一つの方法があります。
シーケンスの利用が終わり、次の要素を計算するために割り当てられた全てのリソースを解放したい時は、
サブスクリプションの`dispose`を呼び出すことができます。

次は`interval`オペレーターの例です。

```swift
let subscription = Observable<Int>.interval(0.3, scheduler: scheduler)
    .subscribe { event in
        print(event)
    }

NSThread.sleepForTimeInterval(2)

subscription.dispose()

```

これは次のように出力します:

```
0
1
2
3
4
5
```

通常は明に`dispose`を実行する必要はないことに注意してください。これは単なる教育用の例です。
手動によるdisposeの呼び出しは通常悪いコードの臭いがします。
サブスクリプションをdisposeするもっと良い方法があります。
`DisposeBag`や`takeUntil`オペレーター、または他の機構を使用することができます。

ところでこのコードは`dispose`の呼出し後にも何かを表示できるでしょうか？
答えはケースバイケースです。

* `scheduler`が **シリアルスケジューラ** (例. `MainScheduler`)で、`dispose`が **同じシリアルスケジューラ上で**実行された場合、答えは **no** です。
* その他の場合は **yes** です。

スケジューラについて更に知りたい場合は[ここ](Schedulers.md)を見てください。

並列に実行している次の2つのプロセスがあるとします。

* 一つは要素を生成している
* もう一つはサブスクリプションをdisposeしている

この2つのプロセスが異なるスケジュラー上にある場合は、先の質問「後で何か表示できるか？」はまったく意味がありません。

念のためもう少し例を示します（`observeOn`に関しては[ここ](Schedulers.md)で説明されています）。

次のような場合です:

```swift
let subscription = Observable<Int>.interval(0.3, scheduler: scheduler)
            .observeOn(MainScheduler.instance)
            .subscribe { event in
                print(event)
            }

// ....

subscription.dispose() // メインスレッドから呼ばれる

```

**`dispose`呼び出しが返った後は何も表示されません。それは保証されています。**

また、次の場合も:

```swift
let subscription = Observable<Int>.interval(0.3, scheduler: scheduler)
            .observeOn(serialScheduler)
            .subscribe { event in
                print(event)
            }

// ...

subscription.dispose() // 同じ`serialScheduler`で実行している

```

**`dispose`呼び出しが返った後は何も表示されません。それは保証されています。**

### Dispose Bags

Dispose bagsはRxにARCライクな振る舞いを返すのに用いられます。

`DisposeBag`が解放される時、追加されたdisposableの各々について`dispose`を呼び出します。

`DisposeBag`は`dispose`メソッドを持っていないので、故意に明示的にdiposeを呼び出すことはできません。
直ちにクリーンアップする必要がある場合は、新しいbagを作成するだけです。

```swift
  self.disposeBag = DisposeBag()
```

これは古い参照をクリアするので、それによりリソースの破棄を引き起こします。

それでもまだ手動による明示的な破棄を望む場合は、`CompositeDisposable`を使ってください。
**これは望みどおりの動作をしますが、一旦`dispose`メソッドが呼ばれると直ちに新たに追加されたすべてのdisposableを破棄します。**

### Take until

開放時にサブリクションを自動的に破棄するもう一つの方法に、`takeUntil`オペレータの使用があります。

```swift
sequence
    .takeUntil(self.rx_deallocated)
    .subscribe {
        print($0)
    }
```

## 暗黙的な `Observable` の保証

また、全てのシーケンス作成者(`Observable`)が順守しなければならない保証がいくつかあります。

要素の生成をどのスレッドを行うかは重要ではありませんが、一つの要素を生成してオブサーバに送信する `observer.on(.Next(nextElement))` 場合、`observer.on`メソッドの実行が終わるまでは、次の要素を送信できません。

また、`.Next`イベントが終了するまでは、`.Completed` や `.Error` による終了を送信できません。

手短に、次の例で考えます:

```swift
someObservable
  .subscribe { (e: Event<Element>) in
      print("Event processing started")
      // processing
      print("Event processing ended")
  }
```

これは常に次のように表示し:

```
Event processing started
Event processing ended
Event processing started
Event processing ended
Event processing started
Event processing ended
```

決して次のようには表示しません:

```
Event processing started
Event processing started
Event processing ended
Event processing ended
```

## 独自の `Observable` (またの名を observable sequence)の作成

observableを理解するために重要なことが一つあります。

**observableが作られても、作られたという理由だけで何らかの作業を行うことはありません。**

`Observable`はいろいろな方法で要素を作成できることは事実です。それらの中には副作用を引き起こすものもあれば、マウスイベントのタッピングなどのように既存の実行中プロセスに入り込むものもあります。

**ただし`Observable`を返すメソッドを呼んだだけでは、シーケンスの生成は一切行われず副作用もありません。
`Observable`はシーケンスをどのように生成するか、また要素の生成に使用されるパラメータが何であるかを定義するだけです。
シーケンスの生成が開始されるのは `subscribe` メソッドが呼ばれた時です。**

例えば、同様のプロトタイプを持つメソッドがあるとします。

```swift
func searchWikipedia(searchTerm: String) -> Observable<Results> {}
```

```swift
let searchForMe = searchWikipedia("me")

// リクエストは実行されていない、何の作業も実行されなていない、URLリクエストは発行さｒていない

let cancel = searchForMe
  // この段階でシーケンスの生成が開始され、URLリクエストが発行される
  .subscribeNext { results in
      print(results)
  }

```

独自の`Observable`シーケンスを作成する方法はたくさん存在します。おそらく最も簡単な方法は`create`関数を使うことです。

サブスクリプションに際して一つの要素を返すシーケンスを作る関数を作ってみましょう。
この関数は'just'と呼ばれます。

*以下が実際の実装です*

```swift
func myJust<E>(element: E) -> Observable<E> {
    return Observable.create { observer in
        observer.on(.Next(element))
        observer.on(.Completed)
        return NopDisposable.instance
    }
}

myJust(0)
    .subscribeNext { n in
      print(n)
    }
```

次のように表示されます:

```
0
```

悪くないですね。でも`create`関数とは何でしょう？

それはSwiftのクロージャを用いて`subscribe`メソッドを簡単に実装できるようにする単なる便利なメソッドです。
`subscribe`メソッドと同様に、一つの引数 `observer`を取り、disposableを返します。

この方法で実装したシーケンスは実は同期的です。要素を生成し、`subscribe`コールがsubscriptionを表すdisposableを返す前に終了します。そのため、どのようなdisposableを返すかは実際は問題ではありません。要素を生成するプロセスは中断されることはありません。

同期的なシーケンスを生成する場合、通常、`NopDisposable`のシングルトンインスタンスをdisposableとして返します。


次に、配列から要素を返すobservableを作ってみましょう。

*以下が実際の実装です*

```swift
func myFrom<E>(sequence: [E]) -> Observable<E> {
    return Observable.create { observer in
        for element in sequence {
            observer.on(.Next(element))
        }

        observer.on(.Completed)
        return NopDisposable.instance
    }
}

let stringCounter = myFrom(["first", "second"])

print("Started ----")

// 初回
stringCounter
    .subscribeNext { n in
        print(n)
    }

print("----")

// もう一度
stringCounter
    .subscribeNext { n in
        print(n)
    }

print("Ended ----")
```

次のように表示されます:

```
Started ----
first
second
----
first
second
Ended ----
```

## 仕事をする `Observable` の作成

それではもっと面白くしていきます。前回の例で使用した`interval`オペレーターを作成してみましょう。

*以下ははディスパッチキュースケジューラと同等の実際の実装です。*

```swift
func myInterval(interval: NSTimeInterval) -> Observable<Int> {
    return Observable.create { observer in
        print("Subscribed")
        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        let timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue)

        var next = 0

        dispatch_source_set_timer(timer, 0, UInt64(interval * Double(NSEC_PER_SEC)), 0)
        let cancel = AnonymousDisposable {
            print("Disposed")
            dispatch_source_cancel(timer)
        }
        dispatch_source_set_event_handler(timer, {
            if cancel.disposed {
                return
            }
            observer.on(.Next(next))
            next += 1
        })
        dispatch_resume(timer)

        return cancel
    }
}
```

```swift
let counter = myInterval(0.1)

print("Started ----")

let subscription = counter
    .subscribeNext { n in
       print(n)
    }

NSThread.sleepForTimeInterval(0.5)

subscription.dispose()

print("Ended ----")
```

次のように表示されます:

```
Started ----
Subscribed
0
1
2
3
4
Disposed
Ended ----
```

次にように書くとどうなるでしょう

```swift
let counter = myInterval(0.1)

print("Started ----")

let subscription1 = counter
    .subscribeNext { n in
       print("First \(n)")
    }
let subscription2 = counter
    .subscribeNext { n in
       print("Second \(n)")
    }

NSThread.sleepForTimeInterval(0.5)

subscription1.dispose()

NSThread.sleepForTimeInterval(0.5)

subscription2.dispose()

print("Ended ----")
```

次のように表示されるでしょう:

```
Started ----
Subscribed
Subscribed
First 0
Second 0
First 1
Second 1
First 2
Second 2
First 3
Second 3
First 4
Second 4
Disposed
Second 5
Second 6
Second 7
Second 8
Second 9
Disposed
Ended ----
```

**サブスクリプションのすべてのサブスクライバーは通常、各自別の要素シーケンスを生成します。
オペレーターはデフォルトではステートレスです。ステートフルなオペレータよりもステートレスなオペレーターの方がはるかに多く存在します。**


## サブスクリプションの共有と`shareReplay`オペレーター

ではもし一つのsubscriptionからのイベント(要素)を複数のobserverで共有したいならどうしますか？

以下の２つを定義する必要があります。

* 新たなサブスクライバーがオブザーブすることに興味を持つ前に受け取っていた過去の要素の扱い方(最新要素のみリプレイ、すべてリプレイ、最新n個のリプレイ)。
* 共有化されたサブスクリプションを発行するタイミングの決定方法(参照カウント、手動またはその他のアルゴリズム)

通常の選択はこれらの組み合わせ `replay(1).refCount()`、すなわち `shareReplay()` です。

```swift
let counter = myInterval(0.1)
    .shareReplay(1)

print("Started ----")

let subscription1 = counter
    .subscribeNext { n in
       print("First \(n)")
    }
let subscription2 = counter
    .subscribeNext { n in
       print("Second \(n)")
    }

NSThread.sleepForTimeInterval(0.5)

subscription1.dispose()

NSThread.sleepForTimeInterval(0.5)

subscription2.dispose()

print("Ended ----")
```

次のように表示されます:

```
Started ----
Subscribed
First 0
Second 0
First 1
Second 1
First 2
Second 2
First 3
Second 3
First 4
Second 4
First 5
Second 5
Second 6
Second 7
Second 8
Second 9
Disposed
Ended ----
```

今度はなぜか`Subscribed`と`Disposed`イベントが一つしかないことに注目してください。

URL observableの振る舞いも同じです。

以下はHTTPリクエストをRxでラップする方法です。`interval`オペレーターと大体同じパターンです。

```swift
extension NSURLSession {
    public func rx_response(request: NSURLRequest) -> Observable<(NSData, NSURLResponse)> {
        return Observable.create { observer in
            let task = self.dataTaskWithRequest(request) { (data, response, error) in
                guard let response = response, data = data else {
                    observer.on(.Error(error ?? RxCocoaURLError.Unknown))
                    return
                }

                guard let httpResponse = response as? NSHTTPURLResponse else {
                    observer.on(.Error(RxCocoaURLError.NonHTTPResponse(response: response)))
                    return
                }

                observer.on(.Next(data, httpResponse))
                observer.on(.Completed)
            }

            task.resume()

            return AnonymousDisposable {
                task.cancel()
            }
        }
    }
}
```

## オペレーター

RxSwiftには多数のオペレーターが実装されています。完全なリストは[ここ](API.md)で見ることができます。

全てのオペレーターのマーブルダイアグラムは[ReactiveX.io](http://reactivex.io/)で見ることができます。

ほとんど全てのオペレーターのデモは[Playgrounds](../Rx.playground)で見ることができます。

Playgroundを使うには、`Rx.xcworkspace`を開いて、`RxSwift-OSX`スキーマをビルドし、`Rx.xcworkspace`ツリービューのPlaygroundを開いてください。

あるオペレーターが必要だが、その見つけ方が分からない場合は[オペレーターの決定木](http://reactivex.io/documentation/operators.html#tree)を見てください。

[RxSwiftがサポートしているオペレーター](API.md#rxswift-supported-operators)では探しやすいように、各オペレータが機能別にグループ分けされています。

### カスタムオペレーター

カスタムオペレーターの作成には2つの方法があります。

#### 簡単な方法

全ての内部コードは高度に最適化されたバージョンのオペレーターを使用しているので、チュートリアルに最適な題材ではありません。これは標準的なオペレーターの使用を大いに推奨する理由です。

幸運なことにオペレーターを作成する簡単な方法があります。実際、新たなオペレーターの作成は、observableの作成にほかなりません。それを行う方法は前章ですでに記述しています。

最適化されていないmapオペレーターをどのように実装できるか見てみましょう。

```swift
extension ObservableType {
    func myMap<R>(transform: E -> R) -> Observable<R> {
        return Observable.create { observer in
            let subscription = self.subscribe { e in
                    switch e {
                    case .Next(let value):
                        let result = transform(value)
                        observer.on(.Next(result))
                    case .Error(let error):
                        observer.on(.Error(error))
                    case .Completed:
                        observer.on(.Completed)
                    }
                }

            return subscription
        }
    }
}
```

これであなたのmapを使うことができます:

```swift
let subscription = myInterval(0.1)
    .myMap { e in
        return "This is simply \(e)"
    }
    .subscribeNext { n in
        print(n)
    }
```

そして次のように表示されます

```
Subscribed
This is simply 0
This is simply 1
This is simply 2
This is simply 3
This is simply 4
This is simply 5
This is simply 6
This is simply 7
This is simply 8
...
```

### 人生いろいろあるけどなんとかなるさ -Life happens-

カスタムオペレーターで解決するには難しすぎる場合はどうしましょう？
その場合は、Rxモナドを脱出して、命令的な世界の中でアクションを実行し、その結果を`Subject`を使って再びRxに戻すことができます。

これはしばしば行うべきものではありませんし悪いコードの臭いがしますが、とにかく実行することはできます。

```swift
  let magicBeings: Observable<MagicBeing> = summonFromMiddleEarth()

  magicBeings
    .subscribeNext { being in     // Rxモナドを脱出
        self.doSomeStateMagic(being)
    }
    .addDisposableTo(disposeBag)

  //
  // ごちゃごちゃ
  //
  let kitten = globalParty(   // ごちゃごちゃな世界で何か計算する
    being,
    UIApplication.delegate.dataSomething.attendees
  )
  kittens.on(.Next(kitten))   // 結果をRxに送り戻す
  //
  // 別のごちゃごちゃ
  //

  let kittens = Variable(firstKitten) // 再びRxモナドに戻る

  kittens.asObservable()
    .map { kitten in
      return kitten.purr()
    }
    // ....
```

あなたがこれを行うたびに、誰かがおそらくどこかで次のようなコードを書くでしょう

```swift
  kittens
    .subscribeNext { kitten in
      // so something with kitten
    }
    .addDisposableTo(disposeBag)
```

だから、これを実行しないようにしてください。

## Playgrounds

あるオペレーターが正確にどう動くか確信が持てない場合は、[playgrounds](../Rx.playground)を見れば、ほとんど全てのオペレーターについてそのの振る舞いを示す小さな例が用意されています。

**Playgroundを使うには、Rx.xcworkspaceを開いて、RxSwift-OSXスキーマをビルドし、Rx.xcworkspaceツリービューのPlaygroundを開いてください。**

**playgroundに含まれている例の結果を見るには、`Assistant Editor`を開いてください。
`Assistant Editor`を開くには、`View > Assistant Editor > Show Assistant Editor`をクリックしてください。**

## エラーハンドリング

2つのエラー機構があります。

### observable内の非同期エラーハンドリング機構

エラーハンドリングは非常に簡単です。あるシーケンスがエラーで終了したら、それに依存する
全てのシーケンスがエラーで終了します。それはよくある短絡論理です。

catchオペレーターを使うことで失敗したobservableから復帰することができます。
復帰の詳細を指定できるさまざまなオーバーロードがあります。

またシーケンスにエラーが発生した場合にリトライを可能にする`retry`オペレーターも存在します。

## コンパイルエラーのデバッグ

エレガントなRxSwift/RxCocoaコードを書く際に`Observable`の型の推定にはおそらくコンパイラを大いに頼りにしているでしょう。これはSwiftがいかにすばらしいかの理由の一つですが、時にイライラさせられます。

```swift
images = word
    .filter { $0.containsString("important") }
    .flatMap { word in
        return self.api.loadFlickrFeed("karate")
            .catchError { error in
                return just(JSON(1))
            }
      }
```

もしコンパイラがこの式のどこかにエラーがあると報告してきたら、私はまず戻り値の型に注釈をつけることをお勧めします。

```swift
images = word
    .filter { s -> Bool in s.containsString("important") }
    .flatMap { word -> Observable<JSON> in
        return self.api.loadFlickrFeed("karate")
            .catchError { error -> Observable<JSON> in
                return just(JSON(1))
            }
      }
```

これで動かなければ、エラーの場所を突き止めるまで更に注釈をつけることを続けてください。

```swift
images = word
    .filter { (s: String) -> Bool in s.containsString("important") }
    .flatMap { (word: String) -> Observable<JSON> in
        return self.api.loadFlickrFeed("karate")
            .catchError { (error: NSError) -> Observable<JSON> in
                return just(JSON(1))
            }
      }
```

**まず戻り値の型とクロージャの引数に注釈をつけることをお勧めします。**

通常、エラーを解決した後は、注釈を削除して再びコードを綺麗にすることができます。

## デバッグ

デバッガの使用だけでも便利ですが、`debug`オペレーターを使用すると通常より効率的になります。
`debug`オペレーターは全てのイベントを標準出力に出力します、また、それらのイベントにラベルを付けることもできます。

`debug`はプローブのように作用します。以下はこれを使った例です:

```swift
let subscription = myInterval(0.1)
    .debug("my probe")
    .map { e in
        return "This is simply \(e)"
    }
    .subscribeNext { n in
        print(n)
    }

NSThread.sleepForTimeInterval(0.5)

subscription.dispose()
```

次のように表示されます

```
[my probe] subscribed
Subscribed
[my probe] -> Event Next(Box(0))
This is simply 0
[my probe] -> Event Next(Box(1))
This is simply 1
[my probe] -> Event Next(Box(2))
This is simply 2
[my probe] -> Event Next(Box(3))
This is simply 3
[my probe] -> Event Next(Box(4))
This is simply 4
[my probe] dispose
Disposed
```

また、独自バージョンの`debug`オペレーターも簡単に作成できます。

```swift
extension ObservableType {
    public func myDebug(identifier: String) -> Observable<Self.E> {
        return Observable.create { observer in
            print("subscribed \(identifier)")
            let subscription = self.subscribe { e in
                print("event \(identifier)  \(e)")
                switch e {
                case .Next(let value):
                    observer.on(.Next(value))

                case .Error(let error):
                    observer.on(.Error(error))

                case .Completed:
                    observer.on(.Completed)
                }
            }
            return AnonymousDisposable {
                   print("disposing \(identifier)")
                   subscription.dispose()
            }
        }
    }
 }
```

## メモリリークのデバッグ

Rxはデバッグモードでは全ての確保したリソースをグローバル変数`resourceCount`で追跡しています。

リソースリークを検出するロジックが欲しい場合、最もシンプルな方法は定期的に `RxSwift.resourceCount` を出力することです。

```swift
    /* func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool
     * のどこかに以下を追加
     */
    _ = Observable<Int>.interval(1, scheduler: MainScheduler.instance)
        .subscribeNext { _ in
        print("Resource count \(RxSwift.resourceCount)")
    }
```

メモリリークをテストする最も効率的な方法は:

* 画面に移動してそれを使用
* navigate back
* 最初のリソースカウントを記録
* 再度画面に移動してそれを使用
* navigate back
* 最後のリソースカウントを記録

最初と最後でリソースカウントに差があった場合、どこかにメモリリークがあるかもしれません。

ナビゲーションを2回行うことを提案している理由は、最初のナビゲーションでlazyリソースの読み込みが強制されるからです。

## Variable

`Variable`はobservableの状態を表します。
値を持たない`Variable`は存在しません。初期化関数が初期値を必要とするからです。

`Variable`は[`Subject`](http://reactivex.io/documentation/subject.html)をラップします。より正確に言えば`BehaviorSubject`をラップします。
`BehaviorSubject`と異なり、Variableは値のインターフェースを晒すだけです。したがって、Variableは終了も失敗もすることはありません。

Variableはサブスクリプションに現在値を直ちにブロードキャストします。

Variableが解放されると、`.asObservable()`から返されたobservableシーケンスを終了させます。

```swift
let variable = Variable(0)

print("Before first subscription ---")

_ = variable.asObservable()
    .subscribe(onNext: { n in
        print("First \(n)")
    }, onCompleted: {
        print("Completed 1")
    })

print("Before send 1")

variable.value = 1

print("Before second subscription ---")

_ = variable.asObservable()
    .subscribe(onNext: { n in
        print("Second \(n)")
    }, onCompleted: {
        print("Completed 2")
    })

variable.value = 2

print("End ---")
```

次のように表示されます

```
Before first subscription ---
First 0
Before send 1
First 1
Before second subscription ---
Second 1
First 2
Second 2
End ---
Completed 1
Completed 2
```

## KVO

KVOはObjective-Cの機構です。それは型安全性を念頭に置いて作られていないことを意味します。
このプロジェクトは問題の一部を解決しようとしています。

このライブラリにはKVOをサポートする2つの方法がビルドインされています。

```swift
// KVO
extension NSObject {
    public func rx_observe<E>(type: E.Type, _ keyPath: String, options: NSKeyValueObservingOptions, retainSelf: Bool = true) -> Observable<E?> {}
}

#if !DISABLE_SWIZZLING
// KVO
extension NSObject {
    public func rx_observeWeakly<E>(type: E.Type, _ keyPath: String, options: NSKeyValueObservingOptions) -> Observable<E?> {}
}
#endif
```

`UIView`のframeを監視する方法の例を示します。

**WARNING: UIKitはKVOに準拠していませんが、以下は動きます。**

```swift
view
  .rx_observe(CGRect.self, "frame")
  .subscribeNext { frame in
    ...
  }
```

または

```swift
view
  .rx_observeWeakly(CGRect.self, "frame")
  .subscribeNext { frame in
    ...
  }
```

### `rx_observe`

`rx_observe`は、KVO機構のただのシンプルなラッパーなので、パフォーマンスには優れますが、使用シナリオは大きく制限されます。

* `self` または所有者グラフの祖先から始まるpathの監視に使用できる (`retainSelf = false`)
* 所有者グラフの子孫から始まるpathの監視に使用できる (`retainSelf = true`)
* pathは`強い`プロパティのみで構成されていなければならない。さもないと、解放前にKVOオブザーバの登録解除を忘れるとシステムをクラッシュする可能性がある。

例.

```swift
self.rx_observe(CGRect.self, "view.frame", retainSelf: false)
```

### `rx_observeWeakly`

`rx_observeWeakly`は、弱参照の場合にオブジェクトの解放をハンドルする必要があるので `rx_observe`よりやや遅い。

`rx_observeWeakly`は`rx_observe`を使用できる全ての場合で使用することができ、さらに

* 監視対象を保持しないので、所有関係が不明な任意のオブジェクトグラフの監視に使用できる
* `弱い`プロパティの監視に使用できる

例.

```swift
someSuspiciousViewController.rx_observeWeakly(Bool.self, "behavingOk")
```

### 構造体の監視

KVOはObjective-Cの機構であり、`NSValue`に大きく依存しています。

**RxCocoaには`CGRect`, `CGSize` それに `CGPoint` 構造体のKVOサポートが組み込まれています。**

その他の構造体を監視するには、手作業で`NSValue`から構造体を抽出する必要があります。

[ここ](../RxCocoa/Common/KVORepresentable+CoreGraphics.swift)には、`KVORepresentable` プロトコルの実装によりその他の構造体向けにKVO監視機構を拡張して`rx_observe*`メソッドを作成する例があります。

## UIレイヤーのコツ

UIKitコントロールにバインドする際にあなたの`Observable`がUIレイヤーで満たす必要がある幾つかの物事があります。

### スレッディング

`Observable`は`MainScheduler`(UIThread)で値を送信する必要があります。これは単なる通常のUIKit/Cocoaの要件です。

通常あなたのAPIが`MainScheduler`で結果を返すのは良いアイデアです。
何かをバックグラウンドスレッドからUIにバインドしようとすると、**デバッグ**ビルドされたRxCocoaは通常例外を投げてそのことを通知します。

これを修正するには`observeOn(MainScheduler.instance)`を追加する必要があります。

**デフォルトではNSURLSession拡張は結果を`MainScheduler`で返しません。**

### エラー

UIKitコントロールに失敗をバインドすることはできません。なぜならそれは未定義の動作だからです。

`Observable`が失敗する可能性があるかわからない場合は、`catchErrorJustReturn(valueThatIsReturnedWhenErrorHappens)`を使用して失敗しないことを保証することができます。**ただし、エラーが発生すると、配下のシーケンスは依然として終了(complete)します。**

配下のシーケンスでの望ましい動作が要素の生成を続けることなら、何らかのバージョンの`retry`オペレーターが必要です。

### サブスクリプションの共有

UIレイヤーでは通常サブスクリプションの共有を望みます。複数のUI要素に同一のデータをバインドするために個別にHTTPを呼び出したくはありません。

次のようなコードがあるとします:

```swift
let searchResults = searchText
    .throttle(0.3, $.mainScheduler)
    .distinctUntilChanged
    .flatMapLatest { query in
        API.getSearchResults(query)
            .retry(3)
            .startWith([]) // 新規検索用に結果をクリアする
            .catchErrorJustReturn([])
    }
    .shareReplay(1)              // <- `shareReplay`オペレーターに注目
```

通常望むことは、一旦計算された検索結果を共有することです。これが`shareReplay`が行うことです。

**通常、UIレイヤーの変換チェーンの最後に`shareReplay`を追加するのは確かな経験則です。
  実際に計算結果の共有を望むからです。複数のUI要素に`searchResults`をバインドするたびに個別にHTTPコネクションを発行したくはありません。**

**`Driver` ユニットもちょっと見ておきましょう。これは`shareReplay`コールを透過的にラップし、要素がメインUIスレッドで監視されることとUIにエラーがバインドされないことを保証するように設計されています。**

## HTTPリクエストの作成

HTTPリクエストの作成は皆が最初に試みるものです。

まず実行すべき作業を表現する`NSURLRequest`オブジェクトを構築が必要です。

リクエストは、それがGETリクエストなのか、POSTリクエストなのか、リクエスト本体やクエリパラメーターは何かなどを決めます。

以下はシンプルなGETリクエストを作成する方法です

```swift
let request = NSURLRequest(URL: NSURL(string: "http://en.wikipedia.org/w/api.php?action=parse&page=Pizza&format=json")!)
```

他のobservableとは独立に単にリクエストを実行したいなら、実行すべきものは以下です。

```swift
let responseJSON = NSURLSession.sharedSession().rx_JSON(request)

// この時点ではリクエストは実行されていない
// `responseJSON` は単なるレスポンスをフェッチする方法の記述に過ぎない

let cancelRequest = responseJSON
    // これがリクエストを発行する
    .subscribeNext { json in
        print(json)
    }

NSThread.sleepForTimeInterval(3)

// 3秒経過後にリクエストをキャンセルしたい場合は、単に以下をコール
cancelRequest.dispose()

```

**NSURLSession拡張はデフォルトでは結果を`MainScheduler`で返しません。**

レスポンスへのもっと低レベルなアクセスを望む場合は、次のコードを使用できます:

```swift
NSURLSession.sharedSession().rx_response(myNSURLRequest)
    .debug("my request") // コンソールに情報を出力します
    .flatMap { (data: NSData!, response: NSURLResponse!) -> Observable<String> in
        if let response = response as? NSHTTPURLResponse {
            if 200 ..< 300 ~= response.statusCode {
                return just(transform(data))
            }
            else {
                return failWith(yourNSError)
            }
        }
        else {
            rxFatalError("response = nil")
            return failWith(yourNSError)
        }
    }
    .subscribe { event in
        print(event) // if error happened, this will also print out error to console
    }
```

### HTTPトラフィックのロギング

デバッグモードのRxCocoaでは、デフォルトで全てのHTTPリクエストのログをコンソールに出力します。
この振る舞いを変えたい場合は`Logging.URLRequests`フィルターを設定してください。

```swift
// 独自の設定を読む
public struct Logging {
    public typealias LogURLRequest = (NSURLRequest) -> Bool

    public static var URLRequests: LogURLRequest =  { _ in
    #if DEBUG
        return true
    #else
        return false
    #endif
    }
}
```

## RxDataSources

RxDataSourcesは`UITableView`と`UICollectionView`用の完全に機能するリアクティブデータソースを実装した一連のクラスです。

RxDataSourcesは[ここ](https://github.com/RxSwiftCommunity/RxDataSources)にバンドルされています。

これらの使い方に関する完全に機能するデモは[RxExample](../RxExample)プロジェクトに含まれています。
