/-  *plugin
|%
  ++  run
    |=  =call-context
    ^-  [(list card:agent:gall) (map @t json)]

    ::  the booth key is the group's resource id
    =/  booth-key  (~(get by context) 'booth')
    ?~  booth-key
      ~&  >>>  "{<dap.bowl>}: kick-member error. booth not found in context"
      !!
    =/  booth-key  (so:dejs:format (need booth-key))

    :: =/  booth-store  (~(get by app-store) 'booth')
    :: ?~  booth-store
    ::   ~&  >>>  "{<dap.bowl>}: kick-member error. booth resource not found in store"
    ::   !!
    :: =/  booth-store  ((om json):dejs:format (need booth-store))

    =/  booth  (~(get by store) booth-key)
    ?~  booth
      ~&  >>>  "{<dap.bowl>}: kick-member error. booth not found in booth store {<booth-key>}"
      !!
    =/  booth  ((om json):dejs:format (need booth))
    =/  res  (~(get by booth) 'resource')
    ?~  res
      ~&  >>>  "{<dap.bowl>}: kick-member error. resource not found in booth {<booth-key>}"
      !!
    =/  res  ((om json):dejs:format (need res))
    =/  group-ship  (~(get by res) 'entity')
    ?~  group-ship
      ~&  >>>  "{<dap.bowl>}: kick-member error. group ship not found in resource {<booth-key>}"
      !!
    =/  group-ship  `@p`(slav %p (so:dejs:format group-ship))

    =/  group-name  (~(get by res) 'name')
    ?~  group-name
      ~&  >>>  "{<dap.bowl>}: kick-member error. group name not found in resource {<booth-key>}"
      !!
    =/  group-name  (so:dejs:format group-ship)

    =/  data  ((om json):dejs:format payload)
    =/  ship  (~(get by data) 'ship')
    ?~  ship
      ~&  >>>  "{<dap.bowl>}: kick-member error. ship not found in data"
      !!
    =/  ship  (so:dejs:format (need ship))
    =/  ship  `@p`(slav %p ship)

    =/  action  !>([%remove [group-ship group-name] (sy [ship ~])])

    :_  store

    :~  [%pass /groups %agent [our.bowl %group-store] %poke %group-action !>(action)]
    ==

  ++  add-member
    |=  payload=json
    ^-  [(list card:agent:gall) (map @t json)]

    =/  data  ((om json):dejs:format payload)

    =/  booth-key  (so:dejs:format (~(got by context) 'booth'))
    =/  booth  ((om json):dejs:format (~(got by store) booth-key))
    =/  res  ((om json):dejs:format (~(got by booth) 'resource'))
    =/  group-ship  `@p`(slav %p (so:dejs:format (~(got by res) 'entity')))
    =/  group-name  (so:dejs:format (~(got by res) 'name'))
    =/  ship  `@p`(slav %p (so:dejs:format (~(got by data) 'ship')))

    =/  action  !>([%remove [group-ship group-name] (sy [ship ~])])

    :_  store

    :~  [%pass /groups %agent [our.bowl %group-store] %poke %group-action !>(action)]
    ==
--