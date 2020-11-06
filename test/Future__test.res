open TestFramework
open Belt

describe("Future", ({testAsync}) => {
  testAsync("sync chaining", ({expect, callback}) =>
    Future.value("one")->Future.map(s => `${s}!`)->Future.get(s => {
      expect.string(s).toEqual("one!")
      callback()
    })
  )

  testAsync("async chaining", ({expect, callback}) =>
    Future.makePure(resolve => Js.Global.setTimeout(() => resolve(20), 25)->ignore)
    ->Future.map(s => Int.toString(s))
    ->Future.map(s => `${s}!`)
    ->Future.get(s => {
      expect.string(s).toEqual("20!")
      callback()
    })
  )

  testAsync("tap", ({expect, callback}) => {
    let v = ref(0)
    Future.value(99)->Future.tap(n => v := n + 1)->Future.map(n => n - 9)->Future.get(n => {
      expect.int(n).toBe(90)
      expect.int(v.contents).toBe(100)
      callback()
    })
  })

  testAsync("flatMap", ({expect, callback}) => {
    Future.value(59)->Future.flatMap(n => Future.value(n + 1))->Future.get(n => {
      expect.int(n).toBe(60)
      callback()
    })
  })

  testAsync("multiple gets", ({expect, callback}) => {
    let count = ref(0)
    let future = Future.makePure(resolve => {
      count := count.contents + 1
      resolve(count.contents)
    })

    future->Future.get(_ => ())
    future->Future.get(_ => ())

    expect.int(count.contents).toBe(1)
    callback()
  })

  testAsync("multiple gets (async)", ({expect, callback}) => {
    let count = ref(0)
    let future = Future.makePure(resolve => {
      let _ = Js.Global.setTimeout(() => {
        resolve(0)
      }, 25)
    })->Future.map(_ => count := count.contents + 1)
    future->Future.get(_ => ()) //Runs after previous future
    let initialCount = count.contents

    future->Future.get(_ => ())

    future->Future.get(_ => {
      expect.int(initialCount).toBe(0)
      expect.int(count.contents).toBe(1)
      callback()
    })
  })

  testAsync("all (async)", ({expect, callback}) => {
    Future.all([
      Future.value(1),
      Future.makePure(resolve => Js.Global.setTimeout(() => resolve(2), 50)->ignore),
      Future.makePure(resolve => Js.Global.setTimeout(() => resolve(3), 25)->ignore),
      Future.makePure(resolve =>
        Js.Global.setTimeout(() => resolve(), 75)->ignore
      )->Future.map(() => 4),
    ])->Future.get(result => {
      expect.value(result).toEqual([1, 2, 3, 4])
      callback()
    })
  })

  testAsync("all2", ({expect, callback}) => {
    Future.all2((
      Future.value(1),
      Future.makePure(resolve => Js.Global.setTimeout(() => resolve(2), 50)->ignore),
    ))->Future.get(result => {
      expect.value(result).toEqual((1, 2))
      callback()
    })
  })

  testAsync("all3", ({expect, callback}) => {
    Future.all3((
      Future.value(1),
      Future.makePure(resolve => Js.Global.setTimeout(() => resolve(2), 50)->ignore),
      Future.makePure(resolve => Js.Global.setTimeout(() => resolve(3), 25)->ignore),
    ))->Future.get(result => {
      expect.value(result).toEqual((1, 2, 3))
      callback()
    })
  })

  testAsync("all4", ({expect, callback}) => {
    Future.all4((
      Future.value(1),
      Future.makePure(resolve => Js.Global.setTimeout(() => resolve(2), 50)->ignore),
      Future.makePure(resolve => Js.Global.setTimeout(() => resolve(3), 25)->ignore),
      Future.makePure(resolve =>
        Js.Global.setTimeout(() => resolve(), 75)->ignore
      )->Future.map(() => 4),
    ))->Future.get(result => {
      expect.value(result).toEqual((1, 2, 3, 4))
      callback()
    })
  })

  testAsync("all5", ({expect, callback}) => {
    Future.all5((
      Future.value(1),
      Future.makePure(resolve => Js.Global.setTimeout(() => resolve(2), 50)->ignore),
      Future.makePure(resolve => Js.Global.setTimeout(() => resolve(3), 25)->ignore),
      Future.makePure(resolve =>
        Js.Global.setTimeout(() => resolve(), 75)->ignore
      )->Future.map(() => 4),
      Future.value(5),
    ))->Future.get(result => {
      expect.value(result).toEqual((1, 2, 3, 4, 5))
      callback()
    })
  })

  testAsync("all6", ({expect, callback}) => {
    Future.all6((
      Future.value(1),
      Future.makePure(resolve => Js.Global.setTimeout(() => resolve(2), 50)->ignore),
      Future.makePure(resolve => Js.Global.setTimeout(() => resolve(3), 25)->ignore),
      Future.makePure(resolve =>
        Js.Global.setTimeout(() => resolve(), 75)->ignore
      )->Future.map(() => 4),
      Future.value(5),
      Future.value(6),
    ))->Future.get(result => {
      expect.value(result).toEqual((1, 2, 3, 4, 5, 6))
      callback()
    })
  })
})

describe("Future.t<result<a, b>>", ({testAsync}) => {
  testAsync("mapOk", ({expect, callback}) =>
    Future.value(Ok("one"))->Future.mapOk(s => `${s}!`)->Future.get(s => {
      expect.value(s).toEqual(Ok("one!"))
      callback()
    })
  )
  testAsync("mapOk error", ({expect, callback}) =>
    Future.value(Error("one"))->Future.mapOk(s => `${s}!`)->Future.get(s => {
      expect.value(s).toEqual(Error("one"))
      callback()
    })
  )
  testAsync("mapError", ({expect, callback}) =>
    Future.value(Error("one"))->Future.mapError(s => `${s}!`)->Future.get(s => {
      expect.value(s).toEqual(Error("one!"))
      callback()
    })
  )
  testAsync("mapError ok", ({expect, callback}) =>
    Future.value(Ok("one"))->Future.mapError(s => `${s}!`)->Future.get(s => {
      expect.value(s).toEqual(Ok("one"))
      callback()
    })
  )
  testAsync("mapResult", ({expect, callback}) =>
    Future.value(Ok("one"))->Future.mapResult(s => Ok(`${s}!`))->Future.get(s => {
      expect.value(s).toEqual(Ok("one!"))
      callback()
    })
  )
  testAsync("mapResult error", ({expect, callback}) =>
    Future.value(Error("one"))->Future.mapResult(s => Ok(`${s}!`))->Future.get(s => {
      expect.value(s).toEqual(Error("one"))
      callback()
    })
  )
  testAsync("flatMapOk", ({expect, callback}) =>
    Future.value(Ok("one"))->Future.flatMapOk(s => Future.value(Ok(`${s}!`)))->Future.get(s => {
      expect.value(s).toEqual(Ok("one!"))
      callback()
    })
  )
  testAsync("flatMapOk error", ({expect, callback}) =>
    Future.value(Error("one"))->Future.flatMapOk(s => Future.value(Ok(`${s}!`)))->Future.get(s => {
      expect.value(s).toEqual(Error("one"))
      callback()
    })
  )
  testAsync("flatMapError", ({expect, callback}) =>
    Future.value(Error("one"))
    ->Future.flatMapError(s => Future.value(Error(`${s}!`)))
    ->Future.get(s => {
      expect.value(s).toEqual(Error("one!"))
      callback()
    })
  )
  testAsync("flatMapError ok", ({expect, callback}) =>
    Future.value(Ok("one"))
    ->Future.flatMapError(s => Future.value(Error(`${s}!`)))
    ->Future.get(s => {
      expect.value(s).toEqual(Ok("one"))
      callback()
    })
  )

  testAsync("tapOk", ({expect, callback}) => {
    Future.value(Ok("one"))->Future.tapOk(s => {
      expect.string(s).toEqual("one")
    })->Future.get(_ => callback())
  })
  testAsync("tapOk error", ({expect, callback}) => {
    let counter = ref(0)

    Future.value(Error("one"))->Future.tapOk(_ => {
      incr(counter)
    })->Future.get(_ => {
      expect.int(counter.contents).toBe(0)
      callback()
    })
  })
  testAsync("tapError", ({expect, callback}) => {
    Future.value(Error("one"))->Future.tapError(s => {
      expect.string(s).toEqual("one")
    })->Future.get(_ => callback())
  })
  testAsync("tapError ok", ({expect, callback}) => {
    let counter = ref(0)

    Future.value(Ok("one"))->Future.tapError(_ => {
      incr(counter)
    })->Future.get(_ => {
      expect.int(counter.contents).toBe(0)
      callback()
    })
  })
})

describe("Future cancellation", ({testAsync}) => {
  testAsync("cancels promise and runs cancel effect", ({expect, callback}) => {
    let counter = ref(0)
    let effect = ref(0)
    let future = Future.make(resolve => {
      let timeoutId = Js.Global.setTimeout(() => {
        incr(counter)
        resolve(1)
      }, 10)
      Some(
        () => {
          Js.Global.clearTimeout(timeoutId)
          incr(effect)
        },
      )
    })
    future->Future.cancel
    expect.bool(future->Future.isCancelled).toBeTrue()
    let _ = Js.Global.setTimeout(() => {
      expect.int(counter.contents).toBe(0)
      expect.int(effect.contents).toBe(1)
      callback()
    }, 20)
  })
  testAsync("cancels future", ({expect, callback}) => {
    let counter = ref(0)
    let future = Future.make(resolve => {
      let timeoutId = Js.Global.setTimeout(() => {
        incr(counter)
        resolve(1)
      }, 10)
      Some(() => Js.Global.clearTimeout(timeoutId))
    })
    let future2 = future->Future.map(item => item + 1)
    future2->Future.cancel
    expect.bool(future->Future.isCancelled).toBeFalse()
    expect.bool(future2->Future.isCancelled).toBeTrue()
    let _ = Js.Global.setTimeout(() => {
      expect.int(counter.contents).toBe(1)
      callback()
    }, 20)
  })

  testAsync("doesn't cancel futures returned by flatMap", ({expect, callback}) => {
    let counter = ref(0)
    let secondCounter = ref(0)
    let future = Future.make(resolve => {
      let timeoutId = Js.Global.setTimeout(() => {
        incr(counter)
        resolve(1)
      }, 10)
      Some(() => Js.Global.clearTimeout(timeoutId))
    })
    let future2 = Future.make(resolve => {
      let timeoutId = Js.Global.setTimeout(() => {
        incr(secondCounter)
        resolve(1)
      }, 10)
      Some(() => Js.Global.clearTimeout(timeoutId))
    })
    let future3 = future->Future.flatMap(_ => future2)
    let future4 = future3->Future.map(item => item + 1)
    future4->Future.cancel
    expect.bool(future->Future.isCancelled).toBeFalse()
    expect.bool(future2->Future.isCancelled).toBeFalse()
    expect.bool(future3->Future.isCancelled).toBeFalse()
    expect.bool(future4->Future.isCancelled).toBeTrue()
    let _ = Js.Global.setTimeout(() => {
      expect.int(counter.contents).toBe(1)
      expect.int(secondCounter.contents).toBe(1)
      callback()
    }, 20)
  })

  testAsync("cancels to the top if specified", ({expect, callback}) => {
    let counter = ref(0)
    let secondCounter = ref(0)
    let effect = ref(0)

    let future = Future.make(resolve => {
      let timeoutId = Js.Global.setTimeout(() => {
        incr(counter)
        resolve(1)
      }, 10)
      Some(
        () => {
          incr(effect)
          Js.Global.clearTimeout(timeoutId)
        },
      )
    })
    let future2 = Future.make(resolve => {
      let timeoutId = Js.Global.setTimeout(() => {
        incr(secondCounter)
        resolve(1)
      }, 10)
      Some(() => Js.Global.clearTimeout(timeoutId))
    })
    let future3 = future->Future.flatMap(~propagateCancel=true, _ => future2)
    let future4 = future3->Future.map(~propagateCancel=true, item => item + 1)
    future4->Future.cancel
    expect.bool(future->Future.isCancelled).toBeTrue()
    expect.bool(future2->Future.isCancelled).toBeFalse()
    expect.bool(future3->Future.isCancelled).toBeTrue()
    expect.bool(future4->Future.isCancelled).toBeTrue()
    let _ = Js.Global.setTimeout(() => {
      expect.int(counter.contents).toBe(0)
      expect.int(effect.contents).toBe(1)
      expect.int(secondCounter.contents).toBe(1)
      callback()
    }, 20)
  })

  testAsync("cancels promise and runs cancel effect up the dependents", ({expect, callback}) => {
    let counter = ref(0)
    let future = Future.make(resolve => {
      let timeoutId = Js.Global.setTimeout(() => {
        incr(counter)
        resolve(1)
      }, 10)
      Some(() => Js.Global.clearTimeout(timeoutId))
    })
    let future2 = future->Future.map(item => item + 1)
    future->Future.cancel
    expect.bool(future->Future.isCancelled).toBeTrue()
    expect.bool(future2->Future.isCancelled).toBeTrue()
    let _ = Js.Global.setTimeout(() => {
      expect.int(counter.contents).toBe(0)
      callback()
    }, 20)
  })

  testAsync("doesn't cancel futures returned by flatMap", ({expect, callback}) => {
    let counter = ref(0)
    let secondCounter = ref(0)
    let future = Future.make(resolve => {
      let timeoutId = Js.Global.setTimeout(() => {
        incr(counter)
        resolve(1)
      }, 10)
      Some(() => Js.Global.clearTimeout(timeoutId))
    })
    let future2 = Future.make(resolve => {
      let timeoutId = Js.Global.setTimeout(() => {
        incr(secondCounter)
        resolve(1)
      }, 10)
      Some(() => Js.Global.clearTimeout(timeoutId))
    })
    let future3 = future->Future.flatMap(_ => future2)
    let future4 = future3->Future.map(item => item + 1)
    future->Future.cancel
    expect.bool(future->Future.isCancelled).toBeTrue()
    expect.bool(future2->Future.isCancelled).toBeFalse()
    expect.bool(future3->Future.isCancelled).toBeTrue()
    expect.bool(future4->Future.isCancelled).toBeTrue()
    let _ = Js.Global.setTimeout(() => {
      expect.int(counter.contents).toBe(0)
      expect.int(secondCounter.contents).toBe(1)
      callback()
    }, 20)
  })
})

external asExn: 'a => exn = "%identity"

describe("FuturePromise", ({testAsync}) => {
  testAsync("simple from promise", ({expect, callback}) =>
    FuturePromise.fromPromise(Js.Promise.resolve("one"))
    ->Future.mapOk(s => `${s}!`)
    ->Future.get(s => {
      expect.value(s).toEqual(Ok("one!"))
      callback()
    })
  )
  testAsync("simple from promise", ({expect, callback}) =>
    FuturePromise.fromPromise(Js.Promise.reject(Not_found))
    ->Future.mapOk(s => `${s}!`)
    ->Future.mapError(asExn)
    ->Future.get(s => {
      expect.value(s).toEqual(Error(Not_found))
      callback()
    })
  )
  testAsync("simple to promise", ({expect, callback}) =>
    Future.value("ok")
    ->FuturePromise.toPromise
    ->FuturePromise.fromPromise
    ->Future.mapOk(s => `${s}!`)
    ->Future.mapError(asExn)
    ->Future.get(s => {
      expect.value(s).toEqual(Ok("ok!"))
      callback()
    })
  )
  testAsync("simple to promiseResult", ({expect, callback}) =>
    Future.value(Ok("ok"))
    ->FuturePromise.resultToPromise
    ->FuturePromise.fromPromise
    ->Future.mapOk(s => `${s}!`)
    ->Future.mapError(asExn)
    ->Future.get(s => {
      expect.value(s).toEqual(Ok("ok!"))
      callback()
    })
  )
  testAsync("simple to promiseResult", ({expect, callback}) =>
    Future.value(Error(Not_found))
    ->FuturePromise.resultToPromise
    ->FuturePromise.fromPromise
    ->Future.mapOk(s => `${s}!`)
    ->Future.mapError(asExn)
    ->Future.get(s => {
      expect.value(s).toEqual(Error(Not_found))
      callback()
    })
  )
})
