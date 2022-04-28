/-  *plugin
|%
++  on
  |=  [=bowl:gall store=(map @t json) context=(map @t json)]
  |%
    ++  action
      |=  [payload=json]
      ^-  (unit action-result)

      =/  resource-store  (~(get by store) 'resources')
      ?~  resource-store  (return-error s+'error: resources not found')
      =/  resource-store  ((om json):dejs:format (need resource-store))

      =/  booth-store  (~(get by resource-store) 'booth')
      ?~  booth-store  (return-error s+'error: booth store not found')
      =/  booth-store  (need booth-store)

      (some `action-result`[success=%.y data=booth-store effects=~])

    ++  return-error
      |=  [data=json]
      ^-  (unit action-result)
      (some `action-result`[success=%.n data=data effects=~])
  --
--