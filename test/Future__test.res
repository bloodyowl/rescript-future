open Test

let isTrue = a => assertion(~operator="isTrue", (a, b) => a === b, a, true)
let isFalse = a => assertion(~operator="isFalse", (a, b) => a === b, a, false)
let stringEqual = (a: string, b: string) =>
  assertion(~operator="stringEqual", (a, b) => a === b, a, b)
let intEqual = (a: int, b: int) => assertion(~operator="intEqual", (a, b) => a === b, a, b)
let resultEqual = (a, b) =>
  assertion(
    ~operator="resultEqual",
    (a, b) => Result.equal(a, b, (a, b) => a == b, (e1, e2) => e1 === e2),
    a,
    b,
  )
let arrayEqual = (a, b) =>
  assertion(~operator="intEqual", (a, b) => Array.equal(a, b, (a, b) => a == b), a, b)
let deepEqual = (a, b) => assertion(~operator="intEqual", (a, b) => a == b, a, b)

testAsync("sync chaining", callback =>
  Future.value("one")
  ->Future.map(s => `${s}!`)
  ->Future.get(s => {
    stringEqual(s, "one!")
    callback()
  })
)

testAsync("async chaining", callback =>
  Future.makePure(resolve => setTimeout(() => resolve(20), 25)->ignore)
  ->Future.map(s => Int.toString(s))
  ->Future.map(s => `${s}!`)
  ->Future.get(s => {
    stringEqual(s, "20!")
    callback()
  })
)

testAsync("tap", callback => {
  let v = ref(0)
  Future.value(99)
  ->Future.tap(n => v := n + 1)
  ->Future.map(n => n - 9)
  ->Future.get(n => {
    intEqual(n, 90)
    intEqual(v.contents, 100)
    callback()
  })
})

testAsync("flatMap", callback => {
  Future.value(59)
  ->Future.flatMap(n => Future.value(n + 1))
  ->Future.get(n => {
    intEqual(n, 60)
    callback()
  })
})

testAsync("multiple gets", callback => {
  let count = ref(0)
  let future = Future.makePure(resolve => {
    count := count.contents + 1
    resolve(count.contents)
  })

  future->Future.get(_ => ())
  future->Future.get(_ => ())

  intEqual(count.contents, 1)
  callback()
})

testAsync("multiple gets (async)", callback => {
  let count = ref(0)
  let future = Future.makePure(resolve => {
    let _ = setTimeout(
      () => {
        resolve(0)
      },
      25,
    )
  })->Future.map(_ => count := count.contents + 1)
  future->Future.get(_ => ()) //Runs after previous future
  let initialCount = count.contents

  future->Future.get(_ => ())

  future->Future.get(_ => {
    intEqual(initialCount, 0)
    intEqual(count.contents, 1)
    callback()
  })
})

testAsync("all (async)", callback => {
  Future.all([
    Future.value(1),
    Future.makePure(resolve => setTimeout(() => resolve(2), 50)->ignore),
    Future.makePure(resolve => setTimeout(() => resolve(3), 25)->ignore),
    Future.makePure(resolve => setTimeout(() => resolve(), 75)->ignore)->Future.map(() => 4),
  ])->Future.get(result => {
    arrayEqual(result, [1, 2, 3, 4])
    callback()
  })
})

testAsync("all2", callback => {
  Future.all2((
    Future.value(1),
    Future.makePure(resolve => setTimeout(() => resolve(2), 50)->ignore),
  ))->Future.get(result => {
    deepEqual(result, (1, 2))
    callback()
  })
})

testAsync("all3", callback => {
  Future.all3((
    Future.value(1),
    Future.makePure(resolve => setTimeout(() => resolve(2), 50)->ignore),
    Future.makePure(resolve => setTimeout(() => resolve(3), 25)->ignore),
  ))->Future.get(result => {
    deepEqual(result, (1, 2, 3))
    callback()
  })
})

testAsync("all4", callback => {
  Future.all4((
    Future.value(1),
    Future.makePure(resolve => setTimeout(() => resolve(2), 50)->ignore),
    Future.makePure(resolve => setTimeout(() => resolve(3), 25)->ignore),
    Future.makePure(resolve => setTimeout(() => resolve(), 75)->ignore)->Future.map(() => 4),
  ))->Future.get(result => {
    deepEqual(result, (1, 2, 3, 4))
    callback()
  })
})

testAsync("all5", callback => {
  Future.all5((
    Future.value(1),
    Future.makePure(resolve => setTimeout(() => resolve(2), 50)->ignore),
    Future.makePure(resolve => setTimeout(() => resolve(3), 25)->ignore),
    Future.makePure(resolve => setTimeout(() => resolve(), 75)->ignore)->Future.map(() => 4),
    Future.value(5),
  ))->Future.get(result => {
    deepEqual(result, (1, 2, 3, 4, 5))
    callback()
  })
})

testAsync("all6", callback => {
  Future.all6((
    Future.value(1),
    Future.makePure(resolve => setTimeout(() => resolve(2), 50)->ignore),
    Future.makePure(resolve => setTimeout(() => resolve(3), 25)->ignore),
    Future.makePure(resolve => setTimeout(() => resolve(), 75)->ignore)->Future.map(() => 4),
    Future.value(5),
    Future.value(6),
  ))->Future.get(result => {
    deepEqual(result, (1, 2, 3, 4, 5, 6))
    callback()
  })
})

testAsync("mapOk", callback =>
  Future.value(Ok("one"))
  ->Future.mapOk(s => `${s}!`)
  ->Future.get(s => {
    deepEqual(s, Ok("one!"))
    callback()
  })
)
testAsync("mapOk error", callback =>
  Future.value(Error("one"))
  ->Future.mapOk(s => `${s}!`)
  ->Future.get(s => {
    deepEqual(s, Error("one"))
    callback()
  })
)
testAsync("mapError", callback =>
  Future.value(Error("one"))
  ->Future.mapError(s => `${s}!`)
  ->Future.get(s => {
    deepEqual(s, Error("one!"))
    callback()
  })
)
testAsync("mapError ok", callback =>
  Future.value(Ok("one"))
  ->Future.mapError(s => `${s}!`)
  ->Future.get(s => {
    deepEqual(s, Ok("one"))
    callback()
  })
)
testAsync("mapResult", callback =>
  Future.value(Ok("one"))
  ->Future.mapResult(s => Ok(`${s}!`))
  ->Future.get(s => {
    deepEqual(s, Ok("one!"))
    callback()
  })
)
testAsync("mapResult error", callback =>
  Future.value(Error("one"))
  ->Future.mapResult(s => Ok(`${s}!`))
  ->Future.get(s => {
    deepEqual(s, Error("one"))
    callback()
  })
)
testAsync("flatMapOk", callback =>
  Future.value(Ok("one"))
  ->Future.flatMapOk(s => Future.value(Ok(`${s}!`)))
  ->Future.get(s => {
    deepEqual(s, Ok("one!"))
    callback()
  })
)
testAsync("flatMapOk error", callback =>
  Future.value(Error("one"))
  ->Future.flatMapOk(s => Future.value(Ok(`${s}!`)))
  ->Future.get(s => {
    deepEqual(s, Error("one"))
    callback()
  })
)
testAsync("flatMapError", callback =>
  Future.value(Error("one"))
  ->Future.flatMapError(s => Future.value(Error(`${s}!`)))
  ->Future.get(s => {
    deepEqual(s, Error("one!"))
    callback()
  })
)
testAsync("flatMapError ok", callback =>
  Future.value(Ok("one"))
  ->Future.flatMapError(s => Future.value(Error(`${s}!`)))
  ->Future.get(s => {
    deepEqual(s, Ok("one"))
    callback()
  })
)

testAsync("tapOk", callback => {
  Future.value(Ok("one"))
  ->Future.tapOk(s => {
    stringEqual(s, "one")
  })
  ->Future.get(_ => callback())
})
testAsync("tapOk error", callback => {
  let counter = ref(0)

  Future.value(Error("one"))
  ->Future.tapOk(_ => {
    Int.Ref.increment(counter)
  })
  ->Future.get(_ => {
    intEqual(counter.contents, 0)
    callback()
  })
})
testAsync("tapError", callback => {
  Future.value(Error("one"))
  ->Future.tapError(s => {
    stringEqual(s, "one")
  })
  ->Future.get(_ => callback())
})
testAsync("tapError ok", callback => {
  let counter = ref(0)

  Future.value(Ok("one"))
  ->Future.tapError(_ => {
    Int.Ref.increment(counter)
  })
  ->Future.get(_ => {
    intEqual(counter.contents, 0)
    callback()
  })
})

testAsync("cancels promise and runs cancel effect", callback => {
  let counter = ref(0)
  let effect = ref(0)
  let future = Future.make(resolve => {
    let timeoutId = setTimeout(
      () => {
        Int.Ref.increment(counter)
        resolve(1)
      },
      10,
    )
    Some(
      () => {
        clearTimeout(timeoutId)
        Int.Ref.increment(effect)
      },
    )
  })
  future->Future.cancel
  isTrue(future->Future.isCancelled)
  let _ = setTimeout(() => {
    intEqual(counter.contents, 0)
    intEqual(effect.contents, 1)
    callback()
  }, 20)
})
testAsync("cancels future", callback => {
  let counter = ref(0)
  let future = Future.make(resolve => {
    let timeoutId = setTimeout(
      () => {
        Int.Ref.increment(counter)
        resolve(1)
      },
      10,
    )
    Some(() => clearTimeout(timeoutId))
  })
  let future2 = future->Future.map(item => item + 1)
  future2->Future.cancel
  isFalse(future->Future.isCancelled)
  isTrue(future2->Future.isCancelled)
  let _ = setTimeout(() => {
    intEqual(counter.contents, 1)
    callback()
  }, 20)
})

testAsync("doesn't cancel futures returned by flatMap", callback => {
  let counter = ref(0)
  let secondCounter = ref(0)
  let future = Future.make(resolve => {
    let timeoutId = setTimeout(
      () => {
        Int.Ref.increment(counter)
        resolve(1)
      },
      10,
    )
    Some(() => clearTimeout(timeoutId))
  })
  let future2 = Future.make(resolve => {
    let timeoutId = setTimeout(
      () => {
        Int.Ref.increment(secondCounter)
        resolve(1)
      },
      10,
    )
    Some(() => clearTimeout(timeoutId))
  })
  let future3 = future->Future.flatMap(_ => future2)
  let future4 = future3->Future.map(item => item + 1)
  future4->Future.cancel
  isFalse(future->Future.isCancelled)
  isFalse(future2->Future.isCancelled)
  isFalse(future3->Future.isCancelled)
  isTrue(future4->Future.isCancelled)
  let _ = setTimeout(() => {
    intEqual(counter.contents, 1)
    intEqual(secondCounter.contents, 1)
    callback()
  }, 20)
})

testAsync("cancels to the top if specified", callback => {
  let counter = ref(0)
  let secondCounter = ref(0)
  let effect = ref(0)

  let future = Future.make(resolve => {
    let timeoutId = setTimeout(
      () => {
        Int.Ref.increment(counter)
        resolve(1)
      },
      10,
    )
    Some(
      () => {
        Int.Ref.increment(effect)
        clearTimeout(timeoutId)
      },
    )
  })
  let future2 = Future.make(resolve => {
    let timeoutId = setTimeout(
      () => {
        Int.Ref.increment(secondCounter)
        resolve(1)
      },
      10,
    )
    Some(() => clearTimeout(timeoutId))
  })
  let future3 = future->Future.flatMap(~propagateCancel=true, _ => future2)
  let future4 = future3->Future.map(~propagateCancel=true, item => item + 1)
  future4->Future.cancel
  isTrue(future->Future.isCancelled)
  isFalse(future2->Future.isCancelled)
  isTrue(future3->Future.isCancelled)
  isTrue(future4->Future.isCancelled)
  let _ = setTimeout(() => {
    intEqual(counter.contents, 0)
    intEqual(effect.contents, 1)
    intEqual(secondCounter.contents, 1)
    callback()
  }, 20)
})

testAsync("cancels promise and runs cancel effect up the dependents", callback => {
  let counter = ref(0)
  let future = Future.make(resolve => {
    let timeoutId = setTimeout(
      () => {
        Int.Ref.increment(counter)
        resolve(1)
      },
      10,
    )
    Some(() => clearTimeout(timeoutId))
  })
  let future2 = future->Future.map(item => item + 1)
  future->Future.cancel
  isTrue(future->Future.isCancelled)
  isTrue(future2->Future.isCancelled)
  let _ = setTimeout(() => {
    intEqual(counter.contents, 0)
    callback()
  }, 20)
})

testAsync("doesn't cancel futures returned by flatMap", callback => {
  let counter = ref(0)
  let secondCounter = ref(0)
  let future = Future.make(resolve => {
    let timeoutId = setTimeout(
      () => {
        Int.Ref.increment(counter)
        resolve(1)
      },
      10,
    )
    Some(() => clearTimeout(timeoutId))
  })
  let future2 = Future.make(resolve => {
    let timeoutId = setTimeout(
      () => {
        Int.Ref.increment(secondCounter)
        resolve(1)
      },
      10,
    )
    Some(() => clearTimeout(timeoutId))
  })
  let future3 = future->Future.flatMap(_ => future2)
  let future4 = future3->Future.map(item => item + 1)
  future->Future.cancel
  isTrue(future->Future.isCancelled)
  isFalse(future2->Future.isCancelled)
  isTrue(future3->Future.isCancelled)
  isTrue(future4->Future.isCancelled)
  let _ = setTimeout(() => {
    intEqual(counter.contents, 0)
    intEqual(secondCounter.contents, 1)
    callback()
  }, 20)
})

external asExn: 'a => exn = "%identity"

testAsync("simple from promise", callback =>
  FuturePromise.fromPromise(Promise.resolve("one"))
  ->Future.mapOk(s => `${s}!`)
  ->Future.get(s => {
    deepEqual(s, Ok("one!"))
    callback()
  })
)
testAsync("simple from promise", callback =>
  FuturePromise.fromPromise(Promise.reject(Not_found))
  ->Future.mapOk(s => `${s}!`)
  ->Future.mapError(asExn)
  ->Future.get(s => {
    deepEqual(s, Error(Not_found))
    callback()
  })
)
testAsync("simple to promise", callback =>
  Future.value("ok")
  ->FuturePromise.toPromise
  ->FuturePromise.fromPromise
  ->Future.mapOk(s => `${s}!`)
  ->Future.mapError(asExn)
  ->Future.get(s => {
    deepEqual(s, Ok("ok!"))
    callback()
  })
)
testAsync("simple to promiseResult", callback =>
  Future.value(Ok("ok"))
  ->FuturePromise.resultToPromise
  ->FuturePromise.fromPromise
  ->Future.mapOk(s => `${s}!`)
  ->Future.mapError(asExn)
  ->Future.get(s => {
    deepEqual(s, Ok("ok!"))
    callback()
  })
)
testAsync("simple to promiseResult", callback =>
  Future.value(Error(Not_found))
  ->FuturePromise.resultToPromise
  ->FuturePromise.fromPromise
  ->Future.mapOk(s => `${s}!`)
  ->Future.mapError(asExn)
  ->Future.get(s => {
    deepEqual(s, Error(Not_found))
    callback()
  })
)

testAsync("Deferred", callback => {
  let v = ref(0)
  let (future, resolve) = Deferred.make()

  future
  ->Future.tap(n => v := n + 1)
  ->Future.map(n => n - 9)
  ->Future.get(n => {
    intEqual(n, 90)
    intEqual(v.contents, 100)
    callback()
  })

  resolve(99)
})
