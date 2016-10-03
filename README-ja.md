<img src="assets/Rx_Logo_M.png" alt="Miss Electric Eel 2016" width="36" height="36"> RxSwift: ReactiveX for Swift
======================================

[![Travis CI](https://travis-ci.org/ReactiveX/RxSwift.svg?branch=master)](https://travis-ci.org/ReactiveX/RxSwift) ![platforms](https://img.shields.io/badge/platforms-iOS%20%7C%20OSX%20%7C%20tvOS%20%7C%20watchOS%20%7C%20Linux%28experimental%29-333333.svg) ![pod](https://img.shields.io/cocoapods/v/RxSwift.svg) [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

## Rxについて

**:warning: このREADMEはSwift 3.0を必要とするRxSwift 3.0バージョンについて記述していいます。**

**:warning: Swift 2.3互換バージョンを探している場合は、RxSwift ~> 2.0 バージョンと[swift-2.3](https://github.com/ReactiveX/RxSwift/tree/rxswift-2.0) ブランチを見てください。**

Rxは`Observable<Element>`インターフェースで表現した[計算の一般的な抽象化](https://youtu.be/looJcaeboBY)です。

RxSwiftは[Rx](https://github.com/Reactive-Extensions/Rx.NET)のSwiftバージョンです。

可能な限りオリジナルから多くの概念を取り入れていますが、より快適なパフォーマンスのためにiOS/OSX環境に適合させた概念もあります。

クロスプラットフォームのドキュメントは[ReactiveX.io](http://reactivex.io/)で見つけることができます。

オリジナルのRxと同様に、非同期操作とイベント/データストリームの構成を容易にすることを意図しています。

KVO、非同期操作そしてストリームは抽象化されたシーケンスの下に一元化されます。
これがRxがとてもシンプルでエレガント、そしてパワフルである理由です。

## 私がここにきたのは ...

###### ... 知りたいから

* [なぜRxを使うのか](Documentation_ja/Why.md)
* [RxSwiftの入門と基礎](Documentation_ja/GettingStarted.md)
* [単位](Documentation_ja/Units.md) - `Driver`, `ControlProperty`, `Variable`とは何か、そしてなぜ存在しているのか
* [テスティング](Documentation_ja/UnitTests.md)
* [コツと共通エラー](Documentation_ja/Tips.md)
* [デバッキング](Documentation_ja/GettingStarted.md#debugging)
* [Rxの裏にある数学](Documentation_ja/MathBehindRx.md)
* [hotとcoldなobservable sequenceとは何か](Documentation_ja/HotAndColdObservables.md)
* [どのような公開APIがあるのか](Documentation_ja/API.md)

###### ... インストールしたいから

* RxSwift/RxCocoa をアプリに統合する. [インストールガイド](#インストール)

###### ... ハックしたいから

* アプリの実例. [実例アプリを実行する](Documentation_ja/ExampleApp.md)
* playgroundで演算子を試す. [Playgrounds](Documentation_ja/Playgrounds.md)

###### ... 交流したいから

* これだけでも十分ですが、RxSwiftを使っている仲間と交流し経験を分かち合うと良いでしょう。<br />[![Slack channel](http://rxswift-slack.herokuapp.com/badge.svg)](http://slack.rxswift.org) [Join Slack Channel](http://rxswift-slack.herokuapp.com)
* ライブラリを使用して見つけたバグを報告してください。 [バグ報告テンプレートを使ってIssueを作る](Issue_Template.md)
* 新しい機能をリクエストしてください。 [機能リクエストテンプレートを使ってIssueを作る](Documentation/NewFeatureRequestTemplate.md)


###### ... 比較したいから

* [他のライブラリ](Documentation/ComparisonWithOtherLibraries.md)


###### ... 互換性を見つけたいから

* [RxSwiftコミュニティ](https://github.com/RxSwiftCommunity)のライブラリ
* [RxSwiftを使っているPods](https://cocoapods.org/?q=uses%3Arxswift)

###### ... より広範なビジョンを見たいから

* Android向けはありますか? => [RxJava](https://github.com/ReactiveX/RxJava)
* 全てはどこに向かっていますか？未来は？Reactiveアーキテクチャとは？どのようにこの方法でアプリ全体をデザインしますか？ => [Cycle.js](https://github.com/cyclejs/cycle-core) - これはJavascriptですが[RxJS](https://github.com/Reactive-Extensions/RxJS)はRxのJavascriptバージョンです。

## 利用法

<table>
  <tr>
    <th width="30%">これは例です</th>
    <th width="30%">実行例</th>
  </tr>
  <tr>
    <td>GitHubリポジトリの検索を定義する ...</td>
    <th rowspan="9"><img src="https://raw.githubusercontent.com/kzaher/rxswiftcontent/master/GithubSearch.gif"></th>
  </tr>
  <tr>
    <td><div class="highlight highlight-source-swift"><pre>
let searchResults = searchBar.rx.text
    .throttle(0.3, scheduler: MainScheduler.instance)
    .distinctUntilChanged()
    .flatMapLatest { query -> Observable<[Repository]> in
        if query.isEmpty {
            return .just([])
        }

        return searchGitHub(query)
            .catchErrorJustReturn([])
    }
    .observeOn(MainScheduler.instance)</pre></div></td>
  </tr>
  <tr>
    <td>... 次に、その結果をtableviewに結びつける</td>
  </tr>
  <tr>
    <td width="30%"><div class="highlight highlight-source-swift"><pre>
searchResults
    .bindTo(tableView.rx.items(cellIdentifier: "Cell")) {
        (index, repository: Repository, cell) in
        cell.textLabel?.text = repository.name
        cell.detailTextLabel?.text = repository.url
    }
    .addDisposableTo(disposeBag)</pre></div></td>
  </tr>
</table>

## 必要とする環境

* Xcode 8.0 GM (8A218a)
* Swift 3.0

* iOS 8.0+
* Mac OS X 10.10+
* tvOS 9.0+
* watchOS 2.0+

## インストール

Rxは外部依存性がありません。

以下の選択肢があります。

### 手で

Rx.xcworkspace を開き, `RxExample` を選択し、run をクリック。これによりすべてがビルドされ、サンプルアプリが実行されます。

### [CocoaPods](https://guides.cocoapods.org/using/using-cocoapods.html)

**:warning: 重要! tvOSをサポートするには CocoaPods `0.39` が必要です。 :warning:**

```
# Podfile
use_frameworks!

target 'YOUR_TARGET_NAME' do
    pod 'RxSwift',    '~> 3.0.0-beta.1'
    pod 'RxCocoa',    '~> 3.0.0-beta.1'
end

# RxTestsとRxBlocking はユニットテスト/統合テストにおいて必要となります。
target 'YOUR_TESTING_TARGET' do
    pod 'RxBlocking', '~> 3.0.0-beta.1'
    pod 'RxTests',    '~> 3.0.0-beta.1'
end
```

`YOUR_TARGET_NAME` を実際のターゲット名に置き換えて、`Podfile` のあるディレクトリで次を実行してください:

**:warning: Xcode 8.0 beta と Swift 3.0でCocoaPodsを使用する場合は、profileに以下の行を追加する必要があるでしょう。:warning:**

```
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['SWIFT_VERSION'] = '3.0'
      config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '10.10'
    end
  end
end
```

```
$ pod install
```

### [Carthage](https://github.com/Carthage/Carthage)

次の内容の `Cartfile` を追加して、

```
github "ReactiveX/RxSwift" "3.0.0-beta.1"
```

次を実行する:

```
$ carthage update
```

### git submodules を使用して手作業で

* RxSwift をサブモジュールとして追加する。

```
$ git submodule add git@github.com:ReactiveX/RxSwift.git
```

* Drag `Rx.xcodeproj` をプロジェクトナビゲーターにドラック
* Go to `Project > Targets > Build Phases > Link Binary With Libraries` を開き、`+` をクリックし、`RxSwift-[Platform]` および `RxCocoa-[Platform]` ターゲットを選択する。


##### リファレンス

* [http://reactivex.io/](http://reactivex.io/)
* [Reactive Extensions GitHub (GitHub)](https://github.com/Reactive-Extensions)
* [Erik Meijer (Wikipedia)](http://en.wikipedia.org/wiki/Erik_Meijer_%28computer_scientist%29)
* [Expert to Expert: Brian Beckman and Erik Meijer - Inside the .NET Reactive Framework (Rx) (video)](https://youtu.be/looJcaeboBY)
* [Reactive Programming Overview (Jafar Husain from Netflix)](https://www.youtube.com/watch?v=dwP1TNXE6fc)
* [Subject/Observer is Dual to Iterator (paper)](http://csl.stanford.edu/~christos/pldi2010.fit/meijer.duality.pdf)
* [Rx standard sequence operators visualized (visualization tool)](http://rxmarbles.com/)
* [Haskell](https://www.haskell.org/)
