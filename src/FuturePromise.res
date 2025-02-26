open Future

@send external then2: (promise<'a>, 'a => unit, exn => unit) => unit = "then"

let fromPromise = promise => {
  makePure(resolve => {
    promise->then2(ok => resolve(Ok(ok)), error => resolve(Error(error)))
  })
}

let toPromise = future => {
  Promise.make((resolve, _reject) => future->get(value => resolve(value)))
}

external asExn: 'a => exn = "%identity"

let resultToPromise = future => {
  Promise.make((resolve, reject) =>
    future->get(value =>
      switch value {
      | Ok(ok) => resolve(ok)
      | Error(error) => reject(asExn(error))
      }
    )
  )
}
