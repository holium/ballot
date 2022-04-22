/-  *plugin
|%
++  run
  |=  =call-context
  ^-  [(list card:agent:gall) (map @t json)]

  =/  data  ((om json):dejs:format payload)

  =/  booth-key  (so:dejs:format (~(got by context) 'booth'))
  =/  booth  ((om json):dejs:format (~(got by store) booth-key))
  =/  res  ((om json):dejs:format (~(got by booth) 'resource'))
  =/  group-ship  `@p`(slav %p (so:dejs:format (~(got by res) 'entity')))
  =/  group-name  (so:dejs:format (~(got by res) 'name'))
  =/  ship  `@p`(slav %p (so:dejs:format (~(got by data) 'ship')))

  =/  action  !>([%add-members [group-ship group-name] (sy [ship ~])])

  :_  store

  :~  [%pass /groups %agent [our.bowl %group-store] %poke %group-action !>(action)]
  ==
--