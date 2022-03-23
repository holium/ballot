:: utility functions / helpers
|%

++  key-from-path
  |=  [val=@]
  ^-  @t
  =/  ls  `(list @)`(trip val)
  =/  first  (snag 0 ls)
  ?:  .=(first 126)
    (crip "{<`@p`(slav %p val)>}")
  (woad val)

++  to-key
  |=  [val=@]
  ^-  (unit @t)
  =/  ls  `(list @)`(trip val)
  =/  first  (snag 0 ls)
  =/  result  ?:(=(first 126) (crip "{<`@p`(slav %p val)>}") (woad val))
  (some result)

--
