import Foundation

public func map<T, E, R>(_ f: (T) -> R) -> (Signal<T, E>) -> Signal<R, E> {
    return { signal in
        return Signal<R, E> { subscriber in
            return signal.start(next: { next in
                subscriber.putNext(f(next))
            }, error: { error in
                subscriber.putError(error)
            }, completed: {
                subscriber.putCompletion()
            })
        }
    }
}

public func filter<T, E>(_ f: (T) -> Bool) -> (Signal<T, E>) -> Signal<T, E> {
    return { signal in
        return Signal<T, E> { subscriber in
            return signal.start(next: { next in
                if f(next) {
                    subscriber.putNext(next)
                }
            }, error: { error in
                subscriber.putError(error)
            }, completed: {
                subscriber.putCompletion()
            })
        }
    }
}

public func mapError<T, E, R>(_ f: (E) -> R) -> (Signal<T, E>) -> Signal<T, R> {
    return { signal in
        return Signal<T, R> { subscriber in
            return signal.start(next: { next in
                subscriber.putNext(next)
            }, error: { error in
                subscriber.putError(f(error))
            }, completed: {
                subscriber.putCompletion()
            })
        }
    }
}

private class DistinctUntilChangedContext<T> {
    var value: T?
}

public func distinctUntilChanged<T: Equatable, E>(_ signal: Signal<T, E>) -> Signal<T, E> {
    return Signal { subscriber in
        let context = Atomic(value: DistinctUntilChangedContext<T>())
        
        return signal.start(next: { next in
            let pass = context.with { context -> Bool in
                if let value = context.value where value == next {
                    return false
                } else {
                    context.value = next
                    return true
                }
            }
            if pass {
                subscriber.putNext(next)
            }
        }, error: { error in
            subscriber.putError(error)
        }, completed: {
            subscriber.putCompletion()
        })
    }
}
