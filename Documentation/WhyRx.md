Why Rx
======

Producing stable code fast is usually unexpectedly hard using just your vanilla language of choice.

There are many unexpected pitfalls that can ruin all of your hard work and halt development of new features.

### State

Languages that allow mutation make it easy to access global state and mutate it. Uncontrolled mutations of shared global state can easily cause [combinatorial explosion] (https://en.wikipedia.org/wiki/Combinatorial_explosion#Computing).

But on the other hand, when used in smart way, imperative languages can enable writing more efficient code closer to hardware.

The usual way to battle combinatorial explosion is to keep state as simple as possible, and use [unidirectional data flows](https://developer.apple.com/videos/wwdc/2014/#229) to model derived data.

This is what Rx really shines at.

Rx is that sweet spot between functional and imperative world. It enables you to use immutable definitions and pure functions to process snapshots of mutable state in a reliable composable way.

So what are some of the practical examples?

### Bindings

When writing embedded UI applications you would ideally want your program interface to be just a [pure function](https://en.wikipedia.org/wiki/Pure_function) of the [truth of the system](https://developer.apple.com/videos/wwdc/2014/#229). In that way user interface could be optimally redrawn only when truth changes, and there wouldn't be any inconsistencies.

These are so called bindings and Rx can help you model your system that way.

```swift
combineLatest(firstName.rx_text, lastName.rx_text) { $0 + " " + $1 }
            .map { "Greeting \($0)" }
            .bindTo(greetingLabel.rx_text)
```

** Official suggestion is to always use `.addDisposableTo(disposeBag)` even though that's not necessary for simple bindings.**

### Retries

It would be great if APIs wouldn't fail, but unfortunately they do. Let's say there is an API method

```swift
func doSomethingIncredible(forWho: String) throws -> IncredibleThing
```

If you are using this function as it is, it's really hard to do retries in case it fails. Not to mention complexities modelling [exponential backoffs](https://en.wikipedia.org/wiki/Exponential_backoff). Sure it's possible, but code would probably contain a lot of transient states that you really don't care about, and it won't be reusable.

You would ideally want to capture the essence of retrying, and to be able to apply it to any operation.

This is how you can do simple retries with Rx

```swift
  doSomethingIncredible("me")
    .retry(3)
```

You can also easily create custom retry operators.

### Aggregating network requests

What if you need to fire two requests, and aggregate results when they have both finished?

Well, there is of course `zip` operator

```swift
  let userRequest: Observable<User> = API.getUser("me")
  let friendsRequest: Observable<Friends> = API.getFriends("me")

  zip(userRequest, friendsRequest) { user, friends in
      return (user, friends)
    }
    .subscribeNext { user, friends in
        // bind them to user interface
    }
```

So what if those APIs return results on a background thread, and binding has to happen on main UI thread? There is `observeOn`.

```swift
  let userRequest: Observable<User> = API.getUser("me")
  let friendsRequest: Observable<[Friend]> = API.getFriends("me")

  zip(userRequest, friendsRequest) { user, friends in
      return (user, friends)
    }
    .observeOn(MainScheduler.sharedInstance)
    .subscribeNext { user, friends in
        // bind them to user interface
    }
```

There are many more practical use cases where Rx really shines.


### Compositional disposal

Lets assume that there is a scenario where you want to display blurred images in a table view. The images should be first fetched from URL, then decoded and then blurred.

It would also be nice if that entire process could be cancelled if cell exists visible table view area because bandwidth and processor time for blurring are expensive.

It would also be nice if we didn't just immediately start to fetch image once the cell enters visible area because if user swipes really fast there could be a lot of requests fired and cancelled.

It would be also nice if we could limit the number of concurrent image operations because blurring images is an expensive operation.

This is how we can do it using Rx.

```swift

let imageSubscripton = imageURLs
    .throttle(0.2, MainScheduler.sharedInstance)
    .flatMap { imageURL in
        API.fetchImage(imageURL)
    }
    .observeOn(operationScheduler)
    .map { imageData in
        return decodeAndBlurImage(imageData)
    }
    .observeOn(MainScheduler.sharedInstance)
    .subscribeNext { blurredImage in
        imageView.image = blurredImage
    }
    .addDisposableTo(reuseDisposeBag)
```

This code will do all that, and when `imageSubscription` is disposed it will cancel all dependent async operations and make sure no rogue image is bound to UI.


### Delegates

Delegates can be used both as a hook for customizing behavior and as an observing mechanism.

Each usage has it's drawbacks, but Rx can help remedy some of the problem with using delegates as a observing mechanism.

Using delegates and optional methods to report changes can be problematic because there can be usually only one delegate registered, so there is no way to register multiple observers.

Also, delegates usually don't fire initial value upon invoking delegate setter, so you'll also need to read that initial value in some other way. That is kind of tedious.

RxCocoa not only provides wrappers for popular UIKit/Cocoa classes, but it also provides a generic mechanism called `DelegateProxy` that enables wrapping your own delegates and exposing them as observable sequences.

This is real code taken from `UISearchBar` integration.

It uses delegate as a notification mechanism to create an `Observable<String>` that immediately returns current search text upon subscription, and then emits changed search values.

```swift
extension UISearchBar {

    public var rx_delegate: DelegateProxy {
        return proxyForObject(self) as RxSearchBarDelegateProxy
    }

    public var rx_searchText: Observable<String> {
        return defer { [weak self] in
            let text = self?.text ?? ""

            return self?.rx_delegate.observe("searchBar:textDidChange:") ?? empty()
                    .map { a in
                        return a[1] as? String ?? ""
                    }
                    .startWith(text)
        }
    }
}
```

Definition of `RxSearchBarDelegateProxy` can be found [here](RxCocoa/iOS/Proxies/RxSearchBarDelegateProxy.swift)

This is how that API can be now used

```swift

searchBar.rx_searchText
    .subscribeNext { searchText in
        print("Current search text '\(searchText)'")
    }

```

### Notifications

Notifications enable registering multiple observers easily, but they are also untyped. Values need to be extracted from either `userInfo` or original target once they fire.

They are just a notification mechanism, and initial value usually has to be acquired in some other way.

That leads to this tedious pattern:

```swift
let initialText = object.text

doSomething(initialText)

// ....

func controlTextDidChange(notification: NSNotification) {
    doSomething(object.text)
}

```

You can use `rx_notification` to create an observable sequence with wanted properties in a similar fashion like `searchText` was constructed in delegate example, and thus reduce scattering of logic and duplication of code.

### KVO

KVO is a handy observing mechanism, but not without flaws. It's biggest flaw is confusing memory management.

In case of observing a property on some object, the object has to outlive the KVO observer registration otherwise your system will crash with an exception.

```
`TickTock` was deallocated while key value observers were still registered with it. Observation info was leaked, and may even become mistakenly attached to some other object.
```

There are some rules that you can follow when observing some object that is a direct descendant or ancestor in ownership chain, but if that relation is unknown, then it becomes tricky.

It also has a really awkward callback method that needs to be implemented

```objc
-(void)observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object
                       change:(NSDictionary *)change
                      context:(void *)context
```

RxCocoa provides a really convenient observable sequence that solves those issues called [`rx_observe` and `rx_observeWeakly`](GettingStarted.md#kvo)

This is how they can be used:

```swift
view.rx_observe("frame")
    .subscribeNext { (frame: CGRect?) in
        print("Got new frame \(frame)")
    }
```

or

```swift
someSuspiciousViewController.rx_observeWeakly("behavingOk")
    .subscribeNext { (behavingOk: Bool?) in
        print("Cats can purr? \(behavingOk)")
    }
```
