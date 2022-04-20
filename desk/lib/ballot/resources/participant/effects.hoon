|%
++  on
  |=  [=bowl:gall store=(map @t json) context=(map @t json)]
  |%
    ++  add
      |=  [data=json]
      ^-  [(list card:agent:gall) (map @t json)]

      =/  timestamp  (crip (en-json:html (time:enjs:format now.bowl)))

      =/  effect-data  ((om json):dejs:format data)
      =/  key  (so:dejs:format (~(got by effect-data) 'key'))

      `(~(put by store) key data)

    ++  update
      |=  [data=json]
      ^-  [(list card:agent:gall) (map @t json)]

      =/  timestamp  (crip (en-json:html (time:enjs:format now.bowl)))

      =/  effect-data  ((om json):dejs:format data)
      =/  key  (so:dejs:format (~(got by effect-data) 'key'))

      `(~(put by store) key data)
  --
--
