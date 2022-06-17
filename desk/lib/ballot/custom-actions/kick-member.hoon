/-  *plugin, ballot, res=resource
|%
++  on
  |=  [=bowl:gall store=state-1:ballot context=[booth-key=@t proposal-key=@t]]
  |%
    ++  action
      |=  [action-data=json poll-results=json]
      ^-  action-result

      ::  check the group is a group booth
      ::  get the booth owner. the booth owner will be the group owner
      =/  booth  (~(get by booths.store) booth-key.context)
      ?~  booth  (mean leaf+"{<dap.bowl>}: invite-member custom action error. booth {<booth-key.context>} not found in store" ~)
      =/  booth  (need booth)
      =/  booth  ?:(?=([%o *] booth) p.booth ~)

      =/  booth-type  (~(get by booth) 'type')
      =/  booth-type  ?~(booth-type ~ (so:dejs:format (need booth-type)))
      ?.  =(booth-type 'group')
         (mean leaf+"{<dap.bowl>}: kick-member custom action error. booth {<booth-key.context>} must be a group booth" ~)

      =/  booth-name  (~(get by booth) 'name')
      =/  booth-name  ?~(booth-name ~ (so:dejs:format (need booth-name)))
      ?~  booth-name  (mean leaf+"{<dap.bowl>}: invite-member custom action error. cannot determine booth name" ~)

      =/  booth-owner  (~(get by booth) 'owner')
      ?~  booth-owner
          (mean leaf+"{<dap.bowl>}: kick-member custom action error. booth owner not found" ~)
      =/  booth-owner  (so:dejs:format (need booth-owner))
      =/  booth-ship  `@p`(slav %p booth-owner)

      =/  action  ?:(?=([%o *] action-data) p.action-data ~)
      =/  data  (~(got by action) 'data')
      =/  data  ?:(?=([%o *] data) p.data ~)
      =/  member  (~(get by data) 'member')
      ?~  member
          (mean leaf+"{<dap.bowl>}: invite-member custom action error. member not found in data" ~)
      =/  member  (so:dejs:format (need member))
      =/  member  `@p`(slav %p member)

      =/  effects=(list card:agent:gall)
      :~  [%pass /group %agent [our.bowl %group-store] %poke %group-action !>([%remove-members [booth-ship booth-name] (sy [member ~])])]
      ==

      `action-result`[success=%.y data=~ store=~ effects=effects]

  --
--