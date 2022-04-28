|%
++  on
  |=  [=bowl:gall store=(map @t json) context=(map @t json)]
  |%
    ++  on-action
      |=  data=json
      :: ^-  [(list card:agent:gall) (map @t json)]
      ^-  (unit cage)

      ~&  >>  "{<dap.bowl>}: hello from ballot initialize action => {<[bowl store context data]>}"

      `quip+!>([~ store])
  --
--