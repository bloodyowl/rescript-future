type t<'a>

let isPending: t<'a> => bool
let isCancelled: t<'a> => bool
let isResolved: t<'a> => bool

/**
 * `Future.value(x)` creates a future resolved to `x`
 */
let value: 'a => t<'a>

/**
 * `Future.make(initializer)` creates a future and resolves it
 * with the value passed to the `resolve` function, which is passed
 * as first argument to the initializer.
 *
 * The initializer can return an optional cancellation effect
 * (e.g. a function that cancels a request or a timer).
 *
 * example:
 *
 * ```reason
 * Future.make(resolve => {
 *   let timeoutId = setTimeout(resolve, 100)
 *   Some(() => clearTimeout(timeoutId))
 * })
 * ```
 */
let make: (('a => unit) => option<unit => unit>) => t<'a>

/**
 * `Future.makePure(initializer)` creates a future and resolves it
 * with the value passed to the `resolve` function, which is passed
 * as first argument to the initializer.
 *
 * As opposed to `make`, `makePure` doesn't accept an cancellation effect.
 * Only use `makePure` for side-effect free functions.
 *
 * example:
 *
 * ```reason
 * Future.makePure(resolve => {
 *   resolve(1)
 * })
 * ```
 */
let makePure: (('a => unit) => unit) => t<'a>

/**
 * Executes the callback when the future is resolved
 *
 * example:
 *
 * future->Future.get(Console.log)
 */
let get: (t<'a>, 'a => unit) => unit

/**
 * Cancels:
 * - the future you call it on
 * - the futures it depends on (if the future was created using `map` or `flatMap`)
 *
 * Note that it doesn't cancel futures returned by the flatMap callback
 *
 * example:
 *
 * let request = getUser()
 * let friends = request->Future.flatMap(getFriends)
 * let transformed = request->Future.map(deserialize)
 *
 * request->Future.cancel // cancels `request`, `friends` and `transformed`
 * friends->Future.cancel // cancels `friends` and `transformed`
 * transformed->Future.cancel // cancels `transformed`
 */
let cancel: t<'a> => unit

/**
 * Adds a handler to be called if the future is canceled.
 */
let onCancel: (t<'a>, unit => unit) => unit

/**
 * Returns a future with the value of the source future mapped
 */
let map: (t<'a>, ~propagateCancel: bool=?, 'a => 'b) => t<'b>

/**
 * Returns a future with the value of the source future mapped where the mapper returns a future itself
 */
let flatMap: (t<'a>, ~propagateCancel: bool=?, 'a => t<'b>) => t<'b>

/**
 * Debug
 */
let tap: (t<'a>, 'a => unit) => t<'a>

/**
 * Utils for Future.t<result<'a, 'b>>
 */
let mapResult: (
  t<result<'a, 'b>>,
  ~propagateCancel: bool=?,
  'a => result<'c, 'b>,
) => t<result<'c, 'b>>

let mapOk: (t<result<'a, 'b>>, ~propagateCancel: bool=?, 'a => 'c) => t<result<'c, 'b>>

let mapError: (t<result<'a, 'b>>, ~propagateCancel: bool=?, 'b => 'c) => t<result<'a, 'c>>

let flatMapOk: (
  t<result<'a, 'b>>,
  ~propagateCancel: bool=?,
  'a => t<result<'c, 'b>>,
) => t<result<'c, 'b>>

let flatMapError: (
  t<result<'a, 'b>>,
  ~propagateCancel: bool=?,
  'b => t<result<'a, 'c>>,
) => t<result<'a, 'c>>

let tapOk: (t<result<'a, 'b>>, 'a => unit) => t<result<'a, 'b>>

let tapError: (t<result<'a, 'b>>, 'b => unit) => t<result<'a, 'b>>

/**
 * Utils for waiting for multiple futures
 */
let all2: ((t<'a>, t<'b>)) => t<('a, 'b)>

let all3: ((t<'a>, t<'b>, t<'c>)) => t<('a, 'b, 'c)>

let all4: ((t<'a>, t<'b>, t<'c>, t<'d>)) => t<('a, 'b, 'c, 'd)>

let all5: ((t<'a>, t<'b>, t<'c>, t<'d>, t<'e>)) => t<('a, 'b, 'c, 'd, 'e)>

let all6: ((t<'a>, t<'b>, t<'c>, t<'d>, t<'e>, t<'f>)) => t<('a, 'b, 'c, 'd, 'e, 'f)>

let all: array<t<'a>> => t<array<'a>>
