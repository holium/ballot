|%
++  on
  |=  [=bowl:gall store=(map @t json) context=(map @t json)]
  |%
    ++  kick-member
      |=  data=json
      ^-  [(list card:agent:gall) (map @t json)]

      ~&  >>  "{<dap.bowl>}: hello from ballot initialize action => {<[bowl store context data]>}"

      [~ store]
  --
--