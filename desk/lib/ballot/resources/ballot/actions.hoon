|%
++  on
  |=  [=bowl:gall store=(map @t json) context=(map @t json)]
  |%
    ++  initialize
      |=  data=json
      :: ^-  [(list card:agent:gall) (map @t json)]
      ^-  (unit (unit cage))

      ~&  >>  "{<dap.bowl>}: hello from ballot initialize action => {<[bowl store context data]>}"

      (some (some [%quip [~ store]]))
  --
--