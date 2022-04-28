/-  *plugin
/+  *plugin
|%
++  on
  |=  [=bowl:gall store=(map @t json) context=(map @t json)]
  |%
    ++  action
      |=  [payload=json]
      ^-  (unit action-result)

      ?~  payload  ~

      =/  action  ((om json):dejs:format payload)

      =/  context  (~(get by action) 'context')
      ?~  context  (return-error s+'error: context missing booth element')
      =/  context  ((om json):dejs:format (need context))

      =/  key  (~(get by context) 'booth')
      ?~  key  (return-error s+'error: context missing booth element')
      =/  key  (so:dejs:format (need key))

      =/  resource-store  (~(get by store) 'resources')
      ?~  resource-store  (return-error s+'error: resources not found')
      =/  resource-store  ((om json):dejs:format (need resource-store))

      =/  booth-store  (~(get by resource-store) 'booth')
      ?~  booth-store  (return-error s+'error: booth store not found')
      =/  booth-store  ((om json):dejs:format (need booth-store))

      =/  booth  (~(get by booth-store) key)
      ?~  booth  (return-error s+'error: context booth not found')
      =/  booth  (need booth)

      (some `action-result`[success=%.y data=booth effects=~])
  --
--