open Future

@bs.send external then2: (Js.Promise.t<'a>, 'a => unit, Js.Promise.error => unit) => unit = "then"

let fromPromise = promise => {
  makePure(resolve => {
    promise->then2(ok => resolve(Ok(ok)), error => resolve(Error(error)))
  })
}

let toPromise = future => {
  Js.Promise.make((~resolve, ~reject as _) => future->get(value => resolve(. value)))
}

external asExn: 'a => exn = "%identity"

let resultToPromise = future => {
  Js.Promise.make((~resolve, ~reject) => future->get(value =>
      switch value {
      | Ok(ok) => resolve(. ok)
      | Error(error) => reject(. asExn(error))
      }
    ))
}
