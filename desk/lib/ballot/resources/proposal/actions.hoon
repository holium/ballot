|%
++  on
  |=  [=bowl:gall store=(map @t json) context=(map @t json)]
  |%
    ++  add
      |=  data=json
      ^-  [(list card:agent:gall) (map @t json)]

      ~&  >>  "{<dap.bowl>}: hi from proposal add! => {<[bowl store context data]>}"

      [~ store]
  --
--