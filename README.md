<img src="assets/Rx_Logo_M.png" width="36" height="36"> RxSwift: ReactiveX for Swift
======================================

[![Travis CI](https://travis-ci.org/ReactiveX/RxSwift.svg?branch=master)](https://travis-ci.org/ReactiveX/RxSwift)

Hang out with us on [rxswift.slack.com](http://slack.rxswift.org) <img src="http://slack.rxswift.org/badge.svg">

### Requirements

Xcode 7 / Swift 2.0 required

**This README.md describes alpha version of RxSwift 2.0.**

You can find **RxSwift 1.9 for Swift 1.2 [here](https://github.com/ReactiveX/RxSwift/tree/rxswift-1.0).**

**We will be applying critical hotfixes to 1.9 version**, but since the entire ecosystem is migrating towards Swift 2.0, **we will be focusing on adding new features only to RxSwift 2.0 version.**

**We will support all environments where Swift 2.0 will run.**

### Project Structure 

```
RxSwift
|
├-LICENSE.md
├-README.md
├-RxSwift         - platform agnostic core
├-RxCocoa         - extensions for UI, NSURLSession, KVO ...
├-RxBlocking      - set of blocking operators for unit testing
├-RxExample       - example apps: taste of Rx
└-Rx.xcworkspace  - workspace that contains all of the projects hooked up
```

## Light Intro to RxSwift

Rx, also called Reactive Extensions, is a [generic abstraction of computation](https://youtu.be/looJcaeboBY) expressed through `Observable<Element>` interface. 

RxSwift is a Swift version of [Rx](https://github.com/Reactive-Extensions/Rx.NET) that tries to port as many concepts from the original version as possible, but some concepts were adapted for more pleasant integration with iOS/OSX environment and better performances.

You can find cross platform documentation on [ReactiveX.io](http://reactivex.io/) website.

Like the original Rx implementation, the intention of RxSwift is to enable simple composition of asynchronous operations and event/data streams. For example: KVO observing, async operations and streams are all unified under [abstraction of sequence](Documentation/GettingStarted.md#observables-aka-sequences). **This is the reason why Rx is so simple, elegant and powerful.**

## Quick Example

Less chat, more code, time to see some code: let's assume you have to write a typical autocomplete example.

If you were asked to write the autocomplete code without Rx, the very first problem that probably needs to be addressed is when `c` in `abc` is typed, this implies you have a pending request for `ab` that has to be canceled. Right, that shouldn't be too hard to solve, you just create additional variable to hold reference to a pending request and if a previous one is still processing, you cancel it.

The next problem is if the request fails, you then need to do that messy retry logic. Again, a couple of more fields that capture number of retries that need to be cleaned up.

Then, because your code fires a request on every single character typed, you receive a call from the backend guys complaining because the application is spamming the server with an unreasonable amount of requests when users are typing something long. A potential solution is a timer, isn't it?

When you thought you finally nailed it, another problem arise, what needs to be shown on screen while that search is executing? 
Also what needs to be shown in case we fail even with all of the retries? Last but not least, what about properly testing this code?

Assuming your head is definitely full of potential implementations, but also questions and that the final code would look like [Spaghetti code](https://sourcemaking.com/antipatterns/spaghetti-code), this is the exactly same logic written with RxSwift:

```swift
  searchTextField.rx_text
    .throttle(0.3, MainScheduler.sharedInstance)
    .distinctUntilChanged()
    .map { query in
        API.getSearchResults(query)
            .retry(3)
            .startWith([]) // clears results on new search term
            .catchErrorJustReturn([])
    }
    .switchLatest()
    .subscribeNext { results in
      // bind to ui
    }
```

Guess what? There's no addition for flags or fields required. 
**Rx takes care of all that transient mess for you.**

## Benefits of using Rx

As the previous example demonstrated, using Rx will make your code:

* composable <- because Rx is composition's nick name
* reusable <- because it's composable
* declarative <- because definitions are immutable and only data changes
* understandable and concise <- raising level of abstraction and removing transient states
* stable <- because Rx code is thoroughly unit tested
* less stateful <- because you are modeling application as unidirectional data flows
* without leaks <- because resource management is simple

### Rx is not all or nothing

It is usually a good idea to model as much of your application as possible using Rx. 

But what if you don't know all of the operators and does there even exist some operator that models your particular case?

Well, all of the Rx operators are based on math and should be intuitive.

The good news is that about 10-15 operators cover most typical use cases. And that list already includes some of the familiar ones like `map`, `filter`, `zip`, `observeOn` ...

There is a huge list of [all Rx operators](http://reactivex.io/documentation/operators.html) and list of all of the [currently supported RxSwift operators](API.md).

For each operator there is [marble diagram](http://reactivex.io/documentation/operators/retry.html) that helps to explain how does it work.

But what if you need some operator that isn't on that list? Well, you can make your own operator.

What if creating that kind of operator is really hard for some reason, or you have some legacy stateful piece of code that you need to work with? Well, you've got yourself in a mess, but you can [jump out of Rx monad](Documentation/GettingStarted.md#life-happens) easily, process the data, and return back into it.

## Type of Events

RxSwift is based on the concept of events, an Event is an enum defined in the following way:

```swift
enum Event<Element>  {
    case Next(Element)      // next element of a sequence
    case Error(ErrorType)   // sequence failed with error
    case Completed          // sequence terminated successfully
}
```

This means we have three kind of events:

* **Next:** A new element is produced and the consumer (or subscription) should process it
* **Error:** An error occurred, at this point all the subscriptions are canceled and the sequence is terminated
* **Complete:** The sequence has terminated and all subscriptions can be canceled

## Integration

The most common question is: **how do I create an observable**?
**It's pretty simple**. 

This code snippet is take directly from RxCocoa and that's all you need to wrap HTTP requests with `NSURLSession`:

```swift
extension NSURLSession {
    public func rx_response(request: NSURLRequest) -> Observable<(NSData!, NSURLResponse!)> {
        return create { observer in
            let task = self.dataTaskWithRequest(request) { (data, response, error) in
                if data == nil || response == nil {
                    observer.on(.Error(error ?? UnknownError))
                }
                else {
                    observer.on(.Next(data, response))
                    observer.on(.Completed)
                }
            }

            task.resume()

            return AnonymousDisposable {
                task.cancel()
            }
        }
    }
}
```

I would then be able to use it in this way:

```swift
NSURLSession.sharedSession().rx_response(request).subscribeNext() { data, response in
    // process the result of a request      
  }
```

or if handling all events is necessary:

```swift
NSURLSession.sharedSession().rx_response(request).subscribe(next: { data, response in
              // process the data
            },
            error: { e in
              // process an error
            },
            completed: {
              // finalize the sequence
            },
            disposed: {
              // performed when a sequence is about to be disposed
        })
```

## Getting Started

Rx doesn't contain any external dependencies and supports OS X 10.9+ and iOS 7.0+.

### Manual

Open Rx.xcworkspace, choose `RxExample` and hit run. This method will build everything and run sample app

### [CocoaPods](https://guides.cocoapods.org/using/using-cocoapods.html)

**:warning: IMPORTANT! For tvOS support through CocoaPods use [this hack](https://github.com/orta/cocoapods-expert-difficulty) until `0.39` is released, or install the pre-release version with `$ [sudo] gem install cocoapods --pre`. :warning:**

```
# Podfile
use_frameworks!

pod 'RxSwift', '~> 2.0.0-alpha'
pod 'RxCocoa', '~> 2.0.0-alpha'
pod 'RxBlocking', '~> 2.0.0-alpha'
```

type in `Podfile` directory

```
$ pod install
```

### [Carthage](https://github.com/Carthage/Carthage)

Add this to `Cartfile`

```
git "git@github.com:ReactiveX/RxSwift.git" "2.0.0-alpha.4"
```

```
$ carthage update
```

### Manually using git submodules

* Add RxSwift as a submodule

```
$ git submodule add git@github.com:ReactiveX/RxSwift.git
```

* Drag `Rx.xcodeproj` into Project Navigator
* Go to `Project > Targets > Build Phases > Link Binary With Libraries`, click `+` and select `RxSwift-[Platform]` and `RxCocoa-[Platform]` targets

**If you require to link against iOS 7, please follow the dedicated guide ![in the Appendix section](#appendix).**

## Documentation

If you need more information about RxSwift, you can find it here:

1. [Why](Documentation/WhyRx.md)
1. [Getting started](Documentation/GettingStarted.md)
1. [Examples](Documentation/Examples.md)
1. [API - RxSwift operators / RxCocoa extensions](Documentation/API.md)
1. [Math behind](Documentation/MathBehindRx.md)
1. [Hot and cold observables](Documentation/HotAndColdObservables.md)
1. [Feature comparison with other frameworks](#feature-comparison-with-other-frameworks)
1. [Roadmap](https://github.com/ReactiveX/RxSwift/wiki/roadmap)
1. [Playgrounds](#playgrounds)
1. [RxExamples](#rxexamples)
1. [References](#references)


## Feature comparison with other frameworks in the Swift's reactive space

|                                                           | Rx[Swift] |      ReactiveCocoa     | Bolts | PromiseKit |
|:---------------------------------------------------------:|:---------:|:----------------------:|:-----:|:----------:|
| Language                                                  |   swift   |       objc/swift       |  objc | objc/swift |
| Basic Concept                                             |  Sequence | Signal SignalProducer  |  Task |   Promise  |
| Cancellation                                              |     •     |            •           |   •   |      •     |
| Async operations                                          |     •     |            •           |   •   |      •     |
| map/filter/...                                            |     •     |            •           |   •   |            |
| cache invalidation                                        |     •     |            •           |       |            |
| cross platform                                            |     •     |                        |   •   |            |
| blocking operators for unit testing                       |     •     |                        |  N/A  |     N/A    |
| Lockless single sequence operators (map, filter, ...)     |     •     |                        |  N/A  |     N/A    |
| Unified hot and cold observables                          |     •     |                        |  N/A  |     N/A    |
| RefCount                                                  |     •     |                        |  N/A  |     N/A    |
| Concurrent schedulers                                     |     •     |                        |  N/A  |     N/A    |
| Generated optimized narity operators (combineLatest, zip) |     •     |                        |  N/A  |     N/A    |
| Reentrant operators                                       |     •     |                        |  N/A  |     N/A    |

** Comparison with RAC with respect to v3.0-RC.1

## Playgrounds

To use playgrounds:

* Open `Rx.xcworkspace`
* Build `RxSwift-OSX` scheme
* And then open `Rx` playground in `Rx.xcworkspace` tree view.
* Choose `View > Show Debug Area`

## RxExamples

To use playgrounds:

* Open `Rx.xcworkspace`
* Choose one of example schemes and hit `Run`.

## References

* [http://reactivex.io/](http://reactivex.io/)
* [Reactive Extensions GitHub (GitHub)](https://github.com/Reactive-Extensions)
* [Erik Meijer (Wikipedia)](http://en.wikipedia.org/wiki/Erik_Meijer_%28computer_scientist%29)
* [Expert to Expert: Brian Beckman and Erik Meijer - Inside the .NET Reactive Framework (Rx) (video)](https://youtu.be/looJcaeboBY)
* [Subject/Observer is Dual to Iterator (paper)](http://csl.stanford.edu/~christos/pldi2010.fit/meijer.duality.pdf)
* [Rx standard sequence operators visualized (visualization tool)](http://rxmarbles.com/)
* [Haskell](https://www.haskell.org/)

## Change Log (from 1.9 version)

* Removes deprecated APIs
* Adds `ObservableType`
* Moved from using `>-` operator to protocol extensions `.`
* Adds support for Swift 2.0 error handling `try`/`do`/`catch`

You can now just write

```swift
    API.fetchData(URL)
      .map { rawData in
          if invalidData(rawData) {
              throw myParsingError
          }

          ...

          return parsedData
      }
```

* RxCocoa introduces `bindTo` extensions

```swift
    combineLatest(firstName.rx_text, lastName.rx_text) { $0 + " " + $1 }
            .map { "Greeting \($0)" }
            .bindTo(greetingLabel.rx_text)
```

... works for `UITableView`/`UICollectionView` too

```swift
viewModel.rows
            .bindTo(resultsTableView.rx_itemsWithCellIdentifier("WikipediaSearchCell")) { (_, viewModel, cell: WikipediaSearchCell) in
                cell.viewModel = viewModel
            }
            .addDisposableTo(disposeBag)
```

* Adds new operators (array version of `zip`, array version of `combineLatest`, ...)
* Renames `catch` to `catchError`
* Change from `disposeBag.addDisposable` to `disposable.addDisposableTo`
* Deprecates `aggregate` in favor of `reduce`
* Deprecates `variable` in favor of `shareReplay(1)` (to be consistent with RxJS version)

Check out [Migration guide to RxSwift 2.0](Documentation/Migration.md)

## Appendix

### Using with iOS 7

iOS 7 is installation is little tricky, but it can be done. **The main problem is that iOS 7 doesn't support dynamic frameworks.**

These are the steps to include RxSwift/RxCocoa projects in an iOS7 project

* RxSwift/RxCocoa projects have no external dependencies so just manually **including all of the `.swift`, `.m`, `.h` files** in build target should import all of the necessary source code.

You can either do that by copying the files manually or using git submodules.

`git submodule add git@github.com:ReactiveX/RxSwift.git`

After you've included files from `RxSwift` and `RxCocoa` directories, you'll need to remove files that are platform specific.

If you are compiling for **`iOS`**, please **remove references** to OSX specific files located in **`RxCocoa/OSX`**.

If you are compiling for **`OSX`**, please **remove references** to iOS specific files located in **`RxCocoa/iOS`**.

* Add **`RX_NO_MODULE`** as a custom Swift preprocessor flag

Go to your target's `Build Settings > Swift Compiler - Custom Flags` and add `-D RX_NO_MODULE`

* Include **`RxCocoa.h`** in your bridging header

If you already have a bridging header, adding `#import "RxCocoa.h"` should be sufficient.

If you don't have a bridging header, you can go to your target's `Build Settings > Swift Compiler - Code Generation > Objective-C Bridging Header` and point it to `[path to RxCocoa.h parent directory]/RxCocoa.h`.
