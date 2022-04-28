/-  *plugin
/+  *plugin
|%
++  on
  |=  [=bowl:gall store=json context=(map @t json)]
  |%
    ++  action
      |=  [payload=json]
      ^-  action-result

      ?~  payload  (return-error store s+'error: empty payload')

      ?>  ?=(%o -.payload)

      =/  data  (~(get by p.payload) 'data')
      ?~  data  (return-error store s+'error: missing data element')
      =/  data  (need data)
      ?>  ?=(%o -.data)

      =/  data  ((om json):dejs:format (need data))

      =/  key   (~(get by data) 'key')
      ?~  key :: no key, means we're adding a new booth
        'new-booth'
      (so:dejs:format (need key))

      =/  store  (to-map store)
      =/  resource-store  (~(get by store) 'resources')
      ?~  resource-store  (return-error store s+'error: resources not found')
      =/  resource-store  (need resource-store)
      ?>  ?=(%o -.resource-store)
      =/  booth-store  (~(get by p.resource-store) 'booth')
      ?~  booth-store  (return-error store s+'error: booth store not found')
      =/  booth-store  (need booth-store)
      ?>  ?=(%o -.booth-store)
      =/  booth  ?~(key ~ (~(get by p.booth-store) key))
      =/  booth=json  ?~(booth [%o ~] (need booth))
      ?>  ?=(%o -.booth)
      =/  booth  (~(gas by p.booth) (~tap by p.data)

      =/  booth  (~(put by booth-store) key [%o booth])
      =/  resource-store  (~(put by resource-store) 'booth' [%o booth-store])

      `action-result`[success=%.y data=[%o booth] store=[%o resource-store] effects=~]
  --
--