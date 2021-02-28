let make = () => {
  let resolver = ref(_ => ())
  let future = Future.makePure(resolve => {
    resolver := resolve
  })
  (future, resolver.contents)
}
