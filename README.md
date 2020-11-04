# Future

> Cancellable futures for ReScript

## Installation

Run the following in your console:

```console
$ yarn add rescript-future
```

Then add `rescript-future` to your `bsconfig.json`'s `bs-dependencies`:

```diff
 {
   "bs-dependencies": [
+    "rescript-future"
   ]
 }
```

## Basics

A **Future** is a data structure that represents a potential value. It works both **synchronously** & **asynchrously**. It consists of **3 possible states**:

- `Pending`: The value is yet to be resolved
- `Cancelled`: The future has been cancelled before could resolve
- `Resolved`: The future holds its value

```reason
// Basic synchronous future
Future.value(1)
->Future.map(x => x + 1)
->Future.flatMap(x => Future.value(x + 1))
->Future.get(Js.log)
// Logs: 3
```

## Utils

### Create

- `value('a) => Future.t<'a>`: creates a resolved future
- `makePure(('a => unit) => unit) => Future.t<'a>`: creates a future
- `make(('a => unit) => option<unit => unit>) => Future.t<'a>`: creates a future with a cancellation effect

### Cancel

- `cancel(future)`: Cancels a future and its dependents

### Extract

- `get(future, cb) => unit`: Executes `cb` with `future`'s resolved value 

### Transform

- `map(future, mapper)`: Returns a new mapped future
- `map(future, mapper)`: Returns a new mapped future with mapper returning a future itself

### Test

- `isPending(future) => bool`
- `isCancelled(future) => bool`
- `isResolved(future) => bool`


### Result transforms

- `mapResult(future, mapper)`
- `mapOk(future, mapper)`
- `flatMapOk(future, mapper)`
- `mapError(future, mapper)`
- `flatMapError(future, mapper)`

### Debug

- `tap(future, cb) => future`
- `tapOk(resultFuture, cb) => resultFuture`
- `tapError(resultFuture, cb) => resultFuture`

### Multiple futures

- `all2((future, future))`
- `all3((future, future, future))`
- `all4((future, future, future, future))`
- `all5((future, future, future, future, future))`
- `all6((future, future, future, future, future, future))`
- `all(array<future>)`

## Cancellation

In JavaScript, `Promises` are not cancellable. That can be limiting at times, especially when using `React`'s `useEffect`, that let's you return a cancellation effect in order to prevent unwanted side-effects.

```reason
let valueFromServer = Future.make(resolve => {
  let request = getFromServer((err, data) => {
    if err {
      resolve(Error(err))
    } else {
      resolve(Ok(data))
    }
  })
  Some(() => cancelRequest(request))
})

let deserializedValueFromServer = 
  valueFromServer->Future.map(deserialize)

Future.cancel(valueFromServer)
// valueFromServer & deserializedValueFromServer are cancelled if they were still pending
```

## Aknowledgments

Heavily inspired by [RationalJS/future](https://github.com/RationalJS/future)'s API
