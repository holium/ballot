/-  *plugin
|%
++  on
  |=  [=bowl:gall store=json context=(map @t json)]
  |%
    ++  on-action
      |=  data=json
      ^-  action-result

      ~&  >>  "{<dap.bowl>}: hello from ballot initialize action => {<[bowl store context data]>}"

      `action-result`[success=%.y data=store effects=~]
  --
--