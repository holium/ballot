/-  *plugin
/+  *plugin
|%
++  on
  |=  [=bowl:gall store=json context=(map @t json)]
  |%
    ++  action
      |=  [payload=json]
      ^-  action-result

      ?~  payload  ~

      =/  action  ((om json):dejs:format payload)

      =/  data  (~(get by action) 'data')
      ?~  data  (return-error s+'error: missing data element')
      =/  data  ((om json):dejs:format (need data))

      =/  key   (~(get by data) 'key')
      ?~  key :: no key, means we're adding a new booth
        'new-booth'
      (so:dejs:format (need key))

      =/  resource-store  (~(get by store) 'resources')
      ?~  resource-store  (return-error s+'error: resources not found')
      =/  resource-store  ((om json):dejs:format (need resource-store))

      =/  booth-store  (~(get by resource-store) 'booth')
      ?~  booth-store  (return-error s+'error: booth store not found')
      =/  booth-store  ((om json):dejs:format (need booth-store))

      =/  booth  ?~(key ~ (~(get by booth-store) key))
      =/  booth  ?~(booth ~ ((om json):dejs:format (need booth)))
      =/  booth  (~(gas by booth) (~tap by data)

      =/  booth  (~(put by booth-store) key [%o booth])
      =/  resource-store  (~(put by resource-store) 'booth' [%o booth-store])

      `action-result`[success=%.y data=[%o resource-store] effects=~]
  --
--