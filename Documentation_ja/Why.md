## なんのために

**Rxは宣言的な方法によるアプリの作成を可能にします。**

### バインディング


```swift
Observable.combineLatest(firstName.rx_text, lastName.rx_text) { $0 + " " + $1 }
            .map { "Greeting \($0)" }
            .bindTo(greetingLabel.rx_text)
```

これは `UITableView` と `UICollectionView` でも動作します。

```swift
viewModel
  .rows
  .bindTo(resultsTableView.rx_itemsWithCellIdentifier("WikipediaSearchCell", cellType: WikipediaSearchCell.self)) { (_, viewModel, cell) in
    cell.title = viewModel.title
    cell.url = viewModel.url
  }
  .addDisposableTo(disposeBag)
```

**単純なバインディングで必要がなくても、常に `.addDisposableTo(disposeBag)` を使用することを公式に提案します。**

### リトライ

APIが失敗しないのであればすばらしいのですが、残念ながら失敗します。たとえば、次のようなAPIメソッドがあったとします。

```swift
func doSomethingIncredible(forWho: String) throws -> IncredibleThing
```

この関数をそのまま使うのは、失敗した場合にリトライすることが実に難しくなります。
[exponential backoff](https://en.wikipedia.org/wiki/Exponential_backoff)のモデル化の複雑さは言うまでもありません。もちろん可能ですが、そのコードはおそらく実際には気にすることのないたくさんの過渡的な状態を含み、また再利用もできません。

理想的には、望むことはリトライの本質を捉え、任意の操作に適用できるようにすることです。

以下は、Rxを使って簡単にリトライできる方法です。

```swift
doSomethingIncredible("me")
  .retry(3)
```

カスタムリトライ演算子を作成することも簡単です。

### デリゲート

次のように、退屈で非表現的に行う代わりに

```swift
public func scrollViewDidScroll(scrollView: UIScrollView) { // どのScrollViewにバインドされているの？
    self.leftPositionConstraint.constant = scrollView.contentOffset.x
}
```

次のように書きます。

```swift
self.resultsTableView
  .rx_contentOffset
  .map { $0.x }
  .bindTo(self.leftPositionConstraint.rx_constant)
```

### KVO

次のような状態や

```
キー値オブサーバーがまだ登録されているのに `TickTock` が解放された。
監視情報がリークし、他のオブジェクトに誤ってアタッチされるかもしれない。
```

次のようなコードの代わりに、

```objc
-(void)observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object
                       change:(NSDictionary *)change
                      context:(void *)context
```

[`rx_observe` と `rx_observeWeakly`](GettingStarted.md#kvo)を使用してください。

これらは、次のように使用します。

```swift
view.rx_observe(CGRect.self, "frame")
    .subscribeNext { frame in
        print("Got new frame \(frame)")
    }
```

または

```swift
someSuspiciousViewController
    .rx_observeWeakly(Bool.self, "behavingOk")
    .subscribeNext { behavingOk in
        print("Cats can purr? \(behavingOk)")
    }
```

### 通知

次の関数を使用する代わりに

```swift
    @available(iOS 4.0, *)
    public func addObserverForName(name: String?, object obj: AnyObject?, queue: NSOperationQueue?, usingBlock block: (NSNotification) -> Void) -> NSObjectProtocol
```

次のように書きます。

```swift
    NSNotificationCenter.defaultCenter()
      .rx_notification(UITextViewTextDidBeginEditingNotification, object: myTextView)
      .map { /*do something with data*/ }
      ....
```

### 過渡的な状態

非同期プログラムを書く際には過渡的な状態に関連する問題もたくさんあります。典型的な例はオートコンプリート検索ボックスです。

Rxを使用せずオートコンプリートのコードを書く場合、最初に解決しなければならない問題は、`abc` の `c` が入力された時に `ab` に対する保留中のリクエストがある場合、保留中のリクエストはキャンセルされることです。大丈夫、これを解決するのはそんなに難しくないはずです。保留中のリクエストへの参照を保持する新たな変数を作成するだけです。

次の問題は、リクエストが失敗した時、面倒なリトライロジックを実行する必要があることです。しかし大丈夫、クリーンアップに必要な回数分のリトライを保持するためにさらに2,3のフィールドを作成すればよい。

サーバにリクエストを発行する前にプログラムがある時間待つことができれば素晴らしいことです。何しろ誰かが何か非常に長い文章を入力している際にサーバにスパムしたくありません。タイマーフィールドを追加しますか。

また、検索実行中にスクリーンに何を表示する必要があるかという問題もありますし、すべてのリトライが失敗した場合に何かを表示する必要があるかという問題もあります。

これらをすべて書き、適切にテストすることは面倒です。以下は同じロジックをRxで書いたものです。

```swift
  searchTextField.rx_text
    .throttle(0.3, scheduler: MainScheduler.instance)
    .distinctUntilChanged()
    .flatMapLatest { query in
        API.getSearchResults(query)
            .retry(3)
            .startWith([]) // 新たな検索語のために結果をクリア
            .catchErrorJustReturn([])
    }
    .subscribeNext { results in
      // UIにバインド
    }
```

フラグやフィールドを追加する必要はありません。Rxがそのような過渡的な面倒のすべてを世話します。

### 構成廃棄 -Compositional disposal-

仮にテーブルビューにブラー画像を表示するシナリオがあるとしましょう。まず、その画像はURLから読み込み、デコードした後、ブラーをかける必要があります。

帯域幅とブラー処理時間は高価なので、セルが可視テーブルビュー領域から離れた場合にプロセス全体をキャンセルできるとよいでしょう。

また、ユーザーが本当に素早くスワイプするとたくさんのリクエストが発行されキャンセルされる可能性があるので、セルが可視エリア入ってもすぐに画像の読み込みを開始しないとよいでしょう。

さらに、画像にブラーをかけるのは高価な処理なので、同時に処理する画像の数に制限をかけられるとよいでしょう。

以下はRxを使いこのシナリオを実現する方法です。

```swift
// これは概念的な解です
let imageSubscription = imageURLs
    .throttle(0.2, scheduler: MainScheduler.instance)
    .flatMapLatest { imageURL in
        API.fetchImage(imageURL)
    }
    .observeOn(operationScheduler)
    .map { imageData in
        return decodeAndBlurImage(imageData)
    }
    .observeOn(MainScheduler.instance)
    .subscribeNext { blurredImage in
        imageView.image = blurredImage
    }
    .addDisposableTo(reuseDisposeBag)
```

このコードはすべてを行います。`imageSubscription` が破棄されると、依存するすべての非同期操作はキャンセルされ、不正な画像がUIにバインドされることはありません。

### 通信リクエストの集約

2つのリクエストを発行し、両者の終了後に結果を集約する必要がある場合どうしますか？

もちろん `zip` 演算子があります。

```swift
  let userRequest: Observable<User> = API.getUser("me")
  let friendsRequest: Observable<Friends> = API.getFriends("me")

  Observable.zip(userRequest, friendsRequest) { user, friends in
      return (user, friends)
    }
    .subscribeNext { user, friends in
        // bind them to user interface
    }
```

これらのAPIがバックグラウンドスレッドで結果を返し、バインドはメインUIスレッドでしなければならない場合はどうしますか？ `observeOn` があります。

```swift
  let userRequest: Observable<User> = API.getUser("me")
  let friendsRequest: Observable<[Friend]> = API.getFriends("me")

  Observable.zip(userRequest, friendsRequest) { user, friends in
      return (user, friends)
    }
    .observeOn(MainScheduler.instance)
    .subscribeNext { user, friends in
        // 結果をユーザインターフェースにバインド
    }
```

Rxが光り輝く実用的なユースケースはさらに数多く存在します。

### 状態

変更を認めている言語は、グローバルな状態にアクセスし変更することが簡単にできます。共有されているグローバルな状態の自由な変更は、[組み合わせの爆発](https://en.wikipedia.org/wiki/Combinatorial_explosion#Computing)を容易に引き起こします。

しかし一方で、スマートな方法を使用した場合、命令型言語はハードウェアに密接した、より効率的なコードを書くことができます。

組み合わせの爆発に立ち向かう通常の方法は、状態をできるだけシンプルに保ち、派生データのモデル化に単方向のデータフローを使うことです。

ここがRxが本当に輝く場所です。

Rxは、関数世界と命令世界の間のスイートスポットです。Rxは、不変な適宜と純粋関数を使い、信頼できる構成可能な方法で、可変状態のスナップショットを処理することができます。

では、実用的な例はどんなものでしょうか？

### 簡単な統合

独自のobservableを作成する必要がある場合はどうしましょか。とても簡単です。以下のコードはRxCocoaから取り出したものですが、必要なのは `NSURLSession` でHTTPリクエストをラップすることだけす。

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

### 利点

手短に言うと、Rxを使うとコードは次のようになります。

* 組み立て可能 <- Rxはコンポジション(組み立て)のニックネームだから
* 再利用可能 <- 組み立て可能だから
* 宣言的 <- 定義は不変でデータだけが変化するから
* 分かりやすく簡潔 <- 抽象化のレベルを上げ、過渡的な状態を削除するから
* 安定 <- Rxコードは徹底的にユニットテストされているから
* ステートフルでない <- 単方向データフローとしてアプリケーションをモデル化するから
* リーク無し <- リソース管理が簡単だから

### 全か無かではない

通常、可能な限りRxを使ってアプリケーションをモデル化することは良いアイデアです。

しかし、すべての演算子を知っているわけでなく、特定のケースもモデル化するオペレータが存在するか否かがわからない場合はどうでしょうか。

すべてのRx演算子は数学に基づいており、直感的であるべきです。

10〜15の演算子で最も一般的なユースケースがカバーされることは朗報です。そして、そのリストにはすでにお馴染みの `map`, `filter`, `zip`, `observeOn` などが含まれています。

[すべてのRx演算子](http://reactivex.io/documentation/operators.html)の巨大なリストと、[現在RxSwiftでサポートされている演算子](API.md)のリストを見ることができます。

各演算子について、それがどのように動作するかを説明する[マーブルダイアグラム](http://reactivex.io/documentation/operators/retry.html)が示されています。

では、必要としている演算子がリストに含まれていない場合はどうしますか。そう、独自の演算子を作ることができます。

何らかの理由でそのような演算子を作るのが難しい場合や、一緒に使用する必要のある何らかのレガシーでステートフルなコードがある場合はどうしますか。苦境に陥りました。しかし、容易に[Rxモナドから飛び出して](GettingStarted.md#life-happens)、データを処理し、また、Rxの世界に戻ることができます。
