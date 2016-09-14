# RxSwift 1.9 から RxSwift 2.0 への移行

移行は極めて簡単なはずです。変更はほとんどが表面的なもので、すべての機能はそのままです。

* すべての `>- ` を探して `.` に変換する
* すべての `variable` を探して `shareReplay(1)` に変換する
* すべての `catch` を探して `catchErrorJustReturn` に変換する
* すべての `returnElement` を探して `Observable.just` に変換する
* すべての `failWith` を探して `Observable.error` に変換する
* すべての `never` を探して `Observable.never` に変換する
* すべての `empty` を探して `Observable.empty` に変換する
* `>-` から `.` に移行したので、フリー関数はメソッドになります。そのため、たとえば、`>- switchLatest` の代わりに `.switchLatest()` を、`>- distinctUntilChanged` の代わりに `.distinctUntilChanged()`を使用してください。
* フリー関数からextensionに移行しましたので、たとえば、`concat([a, b, c])` は `[a, b, c].concat()` に、 `merge(sequences)` は `.merge()` となります。
* 同様に、`>- disposeBag.addDisposable` は `subscribe { n in ... }.addDisposableTo(disposeBag)` になります。
* `Variable` の `next` メソッドは、`value` セッターになります。
* `UITableView` や `UICollectionView` を使いたい場合は、次が基本的な使用例です。

```swift
viewModel.rows
    .bindTo(resultsTableView.rx_itemsWithCellIdentifier("WikipediaSearchCell", cellType: WikipediaSearchCell.self)) { (_, viewModel, cell) in
        cell.viewModel = viewModel
    }
    .addDisposableTo(disposeBag)
```

RxSwift 2.0における概念がどのように動作するかについて疑問がある場合は、[Example app](../RxExample) やプレイグラウンドをチェックしてみてください。
