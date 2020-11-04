let fromPromise: Js.Promise.t<'a> => Future.t<result<'a, Js.Promise.error>>

let toPromise: Future.t<'a> => Js.Promise.t<'a>

let resultToPromise: Future.t<result<'a, 'b>> => Js.Promise.t<'a>
