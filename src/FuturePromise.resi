let fromPromise: promise<'a> => Future.t<result<'a, exn>>

let toPromise: Future.t<'a> => promise<'a>

let resultToPromise: Future.t<result<'a, 'b>> => promise<'a>
