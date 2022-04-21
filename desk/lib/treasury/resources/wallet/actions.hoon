|%
++  on
  |=  [=bowl:gall store=(map @t json) context=(map @t json)]
  |%
    ++  buy-crypto
      |=  data=json
      ^-  [(list card:agent:gall) (map @t json)]

      ~&  >>  "{<dap.bowl>}: hello from {<dap.bowl>} initialize action => {<[bowl store context data]>}"

      [~ store]
  --
--