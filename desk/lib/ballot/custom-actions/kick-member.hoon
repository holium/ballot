/-  *plugin
/+  *ballot-plugin
|%
++  on
  |=  [=bowl:gall store=state-0:ballot-store context=[booth-key=@t proposal-key=@t] data=json]
  |%
    ++  action
      |=  [payload=json]
      ^-  action-result

      ::  check the group is a group booth
      ::  get the booth owner. the booth owner will be the group owner
      =/  booth  (~(get by booths.store) booth-key.context)
      ?~  booth  (mean leaf+"{<dap.bowl>}: invite-member custom action error. booth {<booth-key.context>} not found in store" ~)
      =/  booth  (need booth)
      =/  booth  ?:  ?=([%o *] booth)  p.booth  ~

      =/  booth-type  (~(get by booth) 'type')
      =/  booth-type  ?~(booth-type ~ (so:dejs:format (need booth-type)))
      ?.  =(booth-type 'group')
        (mean leaf+"{<dap.bowl>}: invite-member custom action error. booth type not defined" ~)

      =/  booth-name  (~(get by booth) 'name')
      =/  booth-name  ?~(booth-name ~ (so:dejs:format (need booth-name)))
      ?~  booth-name  (mean leaf+"{<dap.bowl>}: invite-member custom action error. cannot determine booth name" ~)

      =/  booth-owner  (~(get by booth) 'owner')
      =/  booth-owner  ?~(booth-owner ~ (so:dejs:format (need booth-owner)))
      =/  booth-ship  `@p`(slav %p booth-ship)

      =/  data  ?:  ?=([%o *] data)  p.data  ~
      =/  member  (~(get by data) 'member')
      =/  member  ?~(member ~ (so:dejs:format (need member)))
      =/  member  `@p`(slav %p member)

      =/  res  `resource`[booth-ship booth-name]
      :: [%remove-members =resource ships=(set ship)]

      =/  effects=(list card:agent:gall)
      :~  [%pass /group %agent [our.bowl %group-store] %poke %group-action !>([%remove-members res (sy [member ~])])]
      ==

      `action-result`[success=%.y data=~ store=~ effects=effects]

  --
--