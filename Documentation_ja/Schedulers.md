スケジューラ -Schedulers-
==========

1. [シリアル vs コンカレント スケジューラ](#シリアル-vs-コンカレント-スケジューラ)
1. [カスタムスケジューラ](#カスタムスケジューラ)
1. [組み込みスケジューラ](#組み込みスケジューラ)

スケジューラは作業を実行するメカニズムを抽象化するものです。

作業を実行するためのメカニズムには、カレントスレッド、ディスパッチキュー、オペレーションキュー、新しいスレッド、スレッドプール、ループ実行などがあります。

スケジューラと連携する2つの主要なオペレーターがあります。`observeOn` と `subscribeOn` です。

異なるスケジューラで作業を実行したい場合は、単に `observeOn(scheduler)` オペレーターを使用します。

通常 `subscribeOn` よりも `observeOn` を使用する機会が多いでしょう。

`observeOn` が明示的に指定されていない場合は、作業は生成されているスレッド/スケジューラ要素上で実行されます。

以下は `observeOn` オペレーターの使用例です

```
sequence1
  .observeOn(backgroundScheduler)
  .map { n in
      print("これはバックグラウンドスケジューラで実行されます")
  }
  .observeOn(MainScheduler.instance)
  .map { n in
      print("これはメインスケジューラで実行されます")
  }
```

特定のスケジューラ上でシーケンスの生成を開始(`subscribe` メソッド)し、disposeを呼び出したい場合は `subscribeOn(scheduler)` を使用します。

`subscribeOn`が明示的に指定されない場合、`subscribe` は `subscribe(onNext:)` または `subscribe` が呼ばれた時と同じスレッド/スケジューラ上で呼び出されます。

`subscribeOn`が明示的に指定されない場合、`dispose`メソッドは破棄を開始した同じスレッド/スケジューラ上で呼び出されます。

要するに、スケジューラを明示的に選ばなければ、これらのメソッドはカレントスレッド/スケジューラ上で呼び出されます。

# シリアル vs コンカレント スケジューラ

実際、スケジューラは何でも使えますし、シーケンスを変換する全てのオペレーターはさらに[暗黙的な保証](GettingStarted.md#暗黙的な-observable-の保証)も守る必要がありますので、どんな種類のスケジューラを作成しているかは重要です。

スケジューラがコンカレントな場合、Rxの `observeOn` と `subscribeOn` オペレーターは全てが完璧に動作することを保証します。

Rxがシリアルだと証明できる何らかのスケジューラを使う場合は、さらなる最適化を行えるでしょう。

現在のところ、そのような最適化はディスパッチキュースケジューラのみで実現されています。

シリアルディスパッチキュースケジューラの場合、`observeOn`はシンプルな単なる`dispatch_async`コールに最適化されています。

# カスタムスケジューラ

カレントスケジューラに加えて独自のスケジューラを書くことができます。

単に直ちに作業を実行する必要があることを記述したい場合は、`ImmediateScheduler`プロトコルを実装することにより独自のスケジューラを作成できます。

```swift
public protocol ImmediateScheduler {
    func schedule<StateType>(state: StateType, action: (/*ImmediateScheduler,*/ StateType) -> RxResult<Disposable>) -> RxResult<Disposable>
}
```

時間ベースの操作をサポートする新しいスケジューラを作成したい場合は、`Scheduler` プロトコルを実装する必要があります。

```swift
public protocol Scheduler: ImmediateScheduler {
    associatedtype TimeInterval
    associatedtype Time

    var now : Time {
        get
    }

    func scheduleRelative<StateType>(state: StateType, dueTime: TimeInterval, action: (StateType) -> RxResult<Disposable>) -> RxResult<Disposable>
}
```

定期的なスケジューリング能力のみをもつスケジューラの場合は、`PeriodicScheduler`プロトコルを実装することによりRxに通知できます。

```swift
public protocol PeriodicScheduler : Scheduler {
    func schedulePeriodic<StateType>(state: StateType, startAfter: TimeInterval, period: TimeInterval, action: (StateType) -> StateType) -> RxResult<Disposable>
}
```

スケジューラが`PeriodicScheduling`能力をサポートしない場合は、Rxが透過的に定期的なスケジューリングをエミュレートします。

# 組み込みスケジューラ

Rxは全てのタイプのスケジューラを使えますが、スケジューラがシリアルだと証明されていれば、さらに最適化も行えます。

以下は現在サポートされているスケジューラです。

## CurrentThreadScheduler (シリアルスケジューラ)

カレントスレッド上で作業するスケジューラユニット。これは要素を生成するオペレーターのデフォルトのスケジューラです。

このスケジューラは `trampoline scheduler`(トランポリンスケジューラ)と呼ばれることもあります。

`CurrentThreadScheduler.instance.schedule(state) { }`が何らかのスレッド上で初めて呼び出されると、スケジュールされたアクションがすぐに実行され、再帰的にスケジュールされるすべてのアクションを一時的にエンキューする隠れたキューが作成されます。

コールスタック上の親フレームが既に`CurrentThreadScheduler.instance.schedule(state) { }`を実行している場合は、スケジュールされたアクションはエンキューされ、現在実行中のアクションとそれ以前にエンキューされていたすべてのアクションの実行が完了した後に実行されます。

## MainScheduler (シリアルスケジューラ)

`MainThread`上で実行される必要がある作業を抽象化します。メインスレッドから`schedule` メソッドが呼ばれた場合、スケジューリング無しに直ちにアクションを実行します。

このスケジューラは通常、UI作業の実行に使われます。

## SerialDispatchQueueScheduler (シリアルスケジューラ)

特定の`dispatch_queue_t`上で実行される必要がある作業を抽象化します。
たとえコンカレントディスパッチキューが渡されたとしてもシリアルキューに変換されることが保証されます。

シリアルスケジューラは`observeOn`に対するある種の最適化を可能にします。

メインスケジューラは`SerialDispatchQueueScheduler`のインスタンスです。

## ConcurrentDispatchQueueScheduler (コンカレントスケジューラ)

特定の`dispatch_queue_t`上で実行される必要がある作業を抽象化します。
シリアルディスパッチキューも渡すことができ、何の問題も起こしません。

このスケジューラはバックグラウンドで実行する必要がある作業に適しています。

## OperationQueueScheduler (コンカレントスケジューラ)

特定の`NSOperationQueue`上で実行される必要がある作業を抽象化します。

このスケジューラは、バックグラウンドで実行する必要がある大量の作業があり、`maxConcurrentOperationCount`を使用して並行処理を細かくチューニングしたい場合に適しています。
