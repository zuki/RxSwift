Rxの裏にある数学
==============

## Observer と Iterator / Enumerator / Generator / Sequences の双対性

observerとgenerator patternの間には双対性があります。
これが非同期のコールバックの世界からシーケンス変換の同期世界への移行を可能にするものです。

要するに、列挙子(Enumerator)もオブザーバーパターンもシーケンスを記述します。
列挙子がなぜシーケンスを定義しているのかはほとんど明らかですが、observerはもう少し複雑です。

しかしながら、数学の知識をあまり必要としない非常に単純な例があります。
たとえば、ある時間における画面上のマウスカーソルの位置を監視していると仮定します。
時間が経つにつれてマウスの位置はシーケンスを形成します。要するにこれがobservableシーケンスです。

シーケンスの要素にアクセスするには2つの基本的な方法があります:

* プッシュインターフェース - Observer (監視される要素が時間とともにシーケンスを作成する)
* プルインターフェース - Iterator / Enumerator / Generator

このビデオでよりフォーマルな説明を見ることができます:

* [Expert to Expert: Brian Beckman and Erik Meijer - Inside the .NET Reactive Framework (Rx) (video)](https://www.youtube.com/watch?v=looJcaeboBY)
* [Reactive Programming Overview (Jafar Husain from Netflix)](https://www.youtube.com/watch?v=dwP1TNXE6fc)
