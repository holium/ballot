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

  ++  log
    |=  [t=@tas m=tape]
    ^+  same

    ?:  =(1 1)  same

    ?+  t  same
      %info
        %-  (slog leaf+m ~)
        same

      %good
        ~&  >  m
        same

      %warn
        ~&  >>  m
        same

      %error
        ~&  >>>  m
        same

    ==
  ::  add config which will affect state which will affect app upgrade. needs more research
  :: ?:  %.n
    :: %-  (slog leaf+msg ~)

--
