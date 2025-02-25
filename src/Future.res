type pendingPayload<'a> = {
  mutable resolveCallbacks: option<array<'a => unit>>,
  mutable cancelCallbacks: option<array<unit => unit>>,
  mutable cancel: option<unit => unit>,
}

type status<'a> = [#Pending(pendingPayload<'a>) | #Cancelled | #Resolved('a)]

type t<'a> = {mutable status: status<'a>}

let isPending = future => {
  switch future.status {
  | #Pending(_) => true
  | #Cancelled | #Resolved(_) => false
  }
}

let isCancelled = future => {
  switch future.status {
  | #Cancelled => true
  | #Pending(_) | #Resolved(_) => false
  }
}

let isResolved = future => {
  switch future.status {
  | #Resolved(_) => true
  | #Pending(_) | #Cancelled => false
  }
}

let value = value => {
  status: #Resolved(value),
}

let run = (callbacks, value) => callbacks->Array.forEach(callback => callback(value))

let make = init => {
  let pendingPayload = {
    resolveCallbacks: None,
    cancelCallbacks: None,
    cancel: None,
  }
  let future = {
    status: #Pending(pendingPayload),
  }
  let resolver = value => {
    switch future.status {
    | #Pending(pendingPayload) =>
      future.status = #Resolved(value)
      switch pendingPayload.resolveCallbacks {
      | Some(resolveCallbacks) => run(resolveCallbacks, value)
      | _ => ()
      }
    | #Resolved(_) | #Cancelled => ()
    }
  }
  pendingPayload.cancel = init(resolver)
  future
}

let makePure = init => {
  make(resolve => {
    init(resolve)
    None
  })
}

let get = (future, func) => {
  switch future.status {
  | #Cancelled => ()
  | #Pending(pendingPayload) =>
    switch pendingPayload.resolveCallbacks {
    | Some(resolveCallbacks) => resolveCallbacks->Array.push(func)->ignore
    | None =>
      let resolveCallbacks = [func]
      pendingPayload.resolveCallbacks = Some(resolveCallbacks)
    }
  | #Resolved(value) => func(value)
  }
}

let onCancel = (future, func) => {
  switch future.status {
  | #Cancelled => func()
  | #Pending(pendingPayload) =>
    switch pendingPayload.cancelCallbacks {
    | Some(cancelCallbacks) => cancelCallbacks->Array.push(func)->ignore
    | None =>
      let cancelCallbacks = [func]
      pendingPayload.cancelCallbacks = Some(cancelCallbacks)
    }
  | #Resolved(_) => ()
  }
}

let cancel = future => {
  switch future.status {
  | #Pending(pendingPayload) =>
    future.status = #Cancelled
    switch pendingPayload.cancel {
    | Some(cancel) => cancel()
    | None => ()
    }
    switch pendingPayload.cancelCallbacks {
    | Some(cancelCallbacks) => run(cancelCallbacks, ())
    | None => ()
    }
  | #Cancelled | #Resolved(_) => ()
  }
}

let map = (source, ~propagateCancel=false, f) => {
  let future = make(resolve => {
    source->get(value => {
      resolve(f(value))
    })
    if propagateCancel {
      Some(
        () => {
          source->cancel
        },
      )
    } else {
      None
    }
  })
  source->onCancel(() => {
    let _ = future->cancel
  })
  future
}

let flatMap = (source, ~propagateCancel=false, f) => {
  let pendingPayload = {
    resolveCallbacks: None,
    cancelCallbacks: None,
    cancel: None,
  }
  let future = {
    status: #Pending(pendingPayload),
  }
  source->get(value => {
    let source' = f(value)
    source'->get(value => {
      future.status = #Resolved(value)
      switch pendingPayload.resolveCallbacks {
      | Some(resolveCallbacks) => run(resolveCallbacks, value)
      | _ => ()
      }
    })
    source'->onCancel(() => future->cancel)
  })
  if propagateCancel {
    pendingPayload.cancel = Some(
      () => {
        source->cancel
      },
    )
  }
  source->onCancel(() => future->cancel)
  future
}

let tap = (future, f) => {
  future->get(f)
  future
}

let tapOk = (future, f) => {
  future->get(result => {
    switch result {
    | Ok(ok) => f(ok)
    | Error(_) => ()
    }
  })
  future
}

let tapError = (future, f) => {
  future->get(result => {
    switch result {
    | Ok(_) => ()
    | Error(error) => f(error)
    }
  })
  future
}

let mapResult = (future, ~propagateCancel=?, f) => {
  future->map(~propagateCancel?, result =>
    switch result {
    | Ok(ok) => f(ok)
    | Error(error) => Error(error)
    }
  )
}

let mapOk = (future, ~propagateCancel=?, f) => {
  future->map(~propagateCancel?, result =>
    switch result {
    | Ok(ok) => Ok(f(ok))
    | Error(error) => Error(error)
    }
  )
}

let mapError = (future, ~propagateCancel=?, f) => {
  future->map(~propagateCancel?, result =>
    switch result {
    | Ok(ok) => Ok(ok)
    | Error(error) => Error(f(error))
    }
  )
}

let flatMapOk = (future, ~propagateCancel=?, f) => {
  future->flatMap(~propagateCancel?, result =>
    switch result {
    | Ok(ok) => f(ok)
    | Error(error) => value(Error(error))
    }
  )
}

let flatMapError = (future, ~propagateCancel=?, f) => {
  future->flatMap(~propagateCancel?, result =>
    switch result {
    | Ok(ok) => value(Ok(ok))
    | Error(error) => f(error)
    }
  )
}

let all2 = ((a, b)) => makePure(resolve => a->get(a' => b->get(b' => resolve((a', b')))))

let all3 = ((a, b, c)) =>
  makePure(resolve => all2((a, b))->get(((a', b')) => c->get(c' => resolve((a', b', c')))))

let all4 = ((a, b, c, d)) =>
  makePure(resolve =>
    all3((a, b, c))->get(((a', b', c')) => d->get(d' => resolve((a', b', c', d'))))
  )

let all5 = ((a, b, c, d, e)) =>
  makePure(resolve =>
    all4((a, b, c, d))->get(((a', b', c', d')) => e->get(e' => resolve((a', b', c', d', e'))))
  )

let all6 = ((a, b, c, d, e, f)) =>
  makePure(resolve =>
    all5((a, b, c, d, e))->get(((a', b', c', d', e')) =>
      f->get(f' => resolve((a', b', c', d', e', f')))
    )
  )

let all = futures => {
  let length = futures->Array.length

  let rec reduce = (i, acc) =>
    if i < length {
      let acc =
        futures
        ->Array.getUnsafe(i)
        ->flatMap(value =>
          acc->map(xs => {
            xs->Array.push(value)->ignore
            xs
          })
        )
      reduce(i + 1, acc)
    } else {
      acc
    }

  reduce(0, value([]))
}
