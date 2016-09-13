Tips
====

* システムやそのパーツは常に純粋関数としてモデル化する努力をしてください。
  純粋関数はテストが簡単でオペレーターの振る舞いの変更にも使用することができます。
* Rxを使う場合は、まずビルトインのオペレーターで構成するようにしてください。
* ある種の組み合わせのオペレータを頻繁に使用する場合は、独自のコンビニエンスオペレータを作成してください。

例.

```swift
extension ObservableType where E: MaybeCool {

    @warn_unused_result(message="http://git.io/rxs.uo")
    public func coolElements()
        -> Observable<E> {
          return filter { e -> Bool in
              return e.isCool
          }
    }
}
```

  * Rxオペレーターはできるだけ一般的なものですが、モデル化が難しいエッジケースは常にあります。そのような場合は、おそらくビルトインオペレーターのいずれかを参考にして、独自のオペレータを作成することができます。

  * 常にオペレーターを使用してsubscriptionを構成してください。

  **なんとしてもネストしたsubscribe呼び出しは避けてください。次のコードは悪い臭いがします。**

  ```swift
  textField.rx_text.subscribeNext { text in
      performURLRequest(text).subscribeNext { result in
          ...
      }
      .addDisposableTo(disposeBag)
  }
  .addDisposableTo(disposeBag)
  ```

  **好ましい方法はオペレーターを使用してdisposableをチェインすることです。**

  ```swift
  textField.rx_text
      .flatMapLatest { text in
          // 個々では失敗がなく、メインスケジューラ上で結果を返すことを仮定しています。
          // そうでない場合は、`catchError` と `observeOn(MainScheduler.instance)`
          // を使って修正することができます。
          return performURLRequest(text)
      }
      ...
      .addDisposableTo(disposeBag) // 最上位の1つのdisposableのみ
  ```
