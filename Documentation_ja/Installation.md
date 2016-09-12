## ビルド / インストール / 実行

Rxは外部依存がまったくありません。

現在サポートしているオプションは次の通りです:

### 手作業

Rx.xcworkspace を開いて、`RxExample` を選択して実行します。
この方法は全てをビルドしてサンプルアプリを実行します。


### [CocoaPods](https://guides.cocoapods.org/using/using-cocoapods.html)

**:warning: 重要! tvOS をサポートするには CocoaPods `0.39` が必要です。 :warning:**


```
# Podfile
use_frameworks!

target 'YOUR_TARGET_NAME' do
    pod 'RxSwift',    '~> 2.0'
    pod 'RxCocoa',    '~> 2.0'
    pod 'RxBlocking', '~> 2.0'
    pod 'RxTests',    '~> 2.0'
end
```

`YOUR_TARGET_NAME` を置き換えてから `Podfile` があるディレクトリで下記をタイプしてください。

```
$ pod install
```

### [Carthage](https://github.com/Carthage/Carthage)

**Xcode 7.1 が必要です**

以下を `Cartfile` に追加します。

```
github "ReactiveX/RxSwift" ~> 2.0
```

```
$ carthage update
```

### git submodule を使用して手作業で

* RxSwift をサブモジュールとして追加する

```
$ git submodule add git@github.com:ReactiveX/RxSwift.git
```

* `Rx.xcodeproj` をプロジェクトナビゲーターにドラッグする
* `Project > Targets > Build Phases > Link Binary With Libraries` に移動し、
  `+` をクリックして`RxSwift-[Platform]` と `RxCocoa-[Platform]` ターゲットを選択する
