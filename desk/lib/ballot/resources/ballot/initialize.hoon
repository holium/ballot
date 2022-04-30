/-  *plugin
/+  *plugin
|%
++  on
  |=  [=bowl:gall store=json context=(map @t json)]
  |%
    ++  action
      |=  [payload=json]
      ^-  action-result

      %-  (slog leaf+"{<dap.bowl>}: {<dap.bowl>} resource initializing..." ~)

      =/  store  (to-map store)
      =/  resource-store  (~(get by store) 'resources')
      ?~  resource-store
        ~&  >>>  "{<dap.bowl>}: {<dap.bowl>} store missing resources. check config"
        !!
      =/  resource-store  (to-map (need resource-store))
      =/  booth-store  (~(get by resource-store) 'booth')
      ?~  booth-store
        ~&  >>>  "{<dap.bowl>}: {<dap.bowl>} store missing booth resource. check config"
        !!
      =/  booth-store  (to-map (need booth-store))

      =/  owner  `@t`(scot %p our.bowl)
      =/  timestamp  (crip (en-json:html (time:enjs:format now.bowl)))

      =/  booth-key  (crip "{<our.bowl>}")
      =/  booth-name  (crip "{<our.bowl>}")
      =/  booth-slug  (spat /(scot %p our.bowl))

      =/  booth=json
      %-  pairs:enjs:format
      :~
        ['type' s+'ship']
        ['key' s+booth-key]
        ['name' s+booth-name]
        ['slug' s+booth-slug]
        ['image' ~]
        ['owner' s+owner]
        ['created' (time:enjs:format now.bowl)]
        ['policy' s+'invite-only']
        ['status' s+'active']
      ==

      =/  booth-store  (~(put by booth-store) booth-key booth)

      =/  participant-key  (crip "{<our.bowl>}")

      =|  booth-participants=(map @t json)

      =/  participant=json
      %-  pairs:enjs:format
      :~
        ['key' s+participant-key]
        ['name' s+participant-key]
        ['status' s+'active']
        ['role' s+'owner']
        ['created' (time:enjs:format now.bowl)]
      ==

      =.  booth-participants  (~(put by booth-participants) participant-key participant)

      %-  (slog leaf+"{<dap.bowl>}: {<dap.bowl>} resource initialized" ~)

      ::  generate a list of effects (cards) based on the booths in the store
      =/  effects  (turn ~(val by booth-store) to-booth-sub)

      =/  resource-store  (~(put by resource-store) 'booth' [%o booth-store])
      =/  store  (~(put by store) 'resources' [%o resource-store])

      %-  (slog leaf+"{<dap.bowl>}: subscribing to groups..." ~)
      =/  effects  (snoc effects [%pass /resources/group %agent [our.bowl %group-store] %watch /groups])

      `action-result`[success=%.y data=~ store=[%o store] effects=effects]

    ++  to-booth-sub
      |=  [jon=json]
      ^-  card:agent:gall
      =/  booth  (to-map jon)
      =/  booth-key  (so:dejs:format (~(got by booth) 'key'))
      =/  owner  (so:dejs:format (~(got by booth) 'owner'))
      =/  booth-ship=@p  `@p`(slav %p owner)
      =/  destpath=path  `path`/resources/booth/(scot %tas booth-key)
      %-  (slog leaf+"ballot: subscribing to {<destpath>}..." ~)
      [%pass destpath %agent [booth-ship %ballot] %watch destpath]
  --
--