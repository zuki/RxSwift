ユニットテスト
==========

## カスタムオペレーターのテスト

RxSwiftは、x.xcworkspace`プロジェクト`のAllTests-*ターゲットにあるすべてのオペレーターのテストに `RxTests` を使っています。

以下は、`RxSwift` オペレータの典型的なユニットテストの例です:

```swift
func testMap_Range() {
        // テストスケジューラを初期化
        // テストスケジューラは、ローカルマシンのクロックから切り離された仮想時間を実装している
        // これは可能な限り高速にシミュレーションを実行し、
        // すべてのイベントが処理されていることを証明することを可能にします。
        let scheduler = TestScheduler(initialClock: 0)

        // hot observableシーケンスのモックを作る。
        // シーケンスはsubscribeしているobserverがあるとないとにかかわらず
        // 指定した時間にイベントを発行する。いくつかのがいても構いません。
        // (これがhotが意味するものです)
        // このobservableシーケンスは、その生存期間中に行われたすべてのsubscriptionを記録します。
        // (`subscriptions`プロパティ)
        let xs = scheduler.createHotObservable([
            next(150, 1),  // 1番目の引数は仮想時間、2番目の引数は要素の値
            next(210, 0),
            next(220, 1),
            next(230, 2),
            next(240, 4),
            completed(300) // 完了が送信される仮想時間
            ])

        // `start`メソッドはデフォルトで以下を行う
        // * シミュレーションを実行し、`res`によって参照されるobserverを使用してすべてのイベントを記録
        // * 仮想時間200にsubscribe
        // * 仮想時間1000にsubscriptionをdispose
        let res = scheduler.start { xs.map { $0 * 2 } }

        let correctMessages = [
            next(210, 0 * 2),
            next(220, 1 * 2),
            next(230, 2 * 2),
            next(240, 4 * 2),
            completed(300)
        ]

        let correctSubscriptions = [
            Subscription(200, 300)
        ]

        XCTAssertEqual(res.events, correctMessages)
        XCTAssertEqual(xs.subscriptions, correctSubscriptions)
    }
```

## オペレーターの組み合わせのテスト (view models, components)

オペレーターの組み合わせをテストする方法の例は `Rx.xcworkspace`内の`RxExample-iOSTests`ターゲットに含まれます。

テストを読みやすく書けるように `RxTests` のExtensionを定義するのは容易です。

提供されている `RxExample-iOSTests` に含まれている実例は、そのようなExtensionをどのように書くことができるかを示す一例にすぎませんが、それらのテストを書く方法には多くの可能性があります。

```swift
    // 予想されるイベントとテストデータ
    let (
        usernameEvents,
        passwordEvents,
        repeatedPasswordEvents,
        loginTapEvents,

        expectedValidatedUsernameEvents,
        expectedSignupEnabledEvents
    ) = (
        scheduler.parseEventsAndTimes("e---u1----u2-----u3-----------------", values: stringValues).first!,
        scheduler.parseEventsAndTimes("e----------------------p1-----------", values: stringValues).first!,
        scheduler.parseEventsAndTimes("e---------------------------p2---p1-", values: stringValues).first!,
        scheduler.parseEventsAndTimes("------------------------------------", values: events).first!,

        scheduler.parseEventsAndTimes("e---v--f--v--f---v--o----------------", values: validations).first!,
        scheduler.parseEventsAndTimes("f--------------------------------t---", values: booleans).first!
    )
```

## 統合テスト

`RxBlocking`オペレーターを使用して統合テストを書くことも可能です。

`RxBlocking`ライブラリからオペレーターをインポートすると、カレントスレッドのブロックを有効にし、シーケンスの結果を待ちます。

```swift
let result = try fetchResource(location)
        .toBlocking()
        .toArray()

XCTAssertEqual(result, expectedResult)
```
