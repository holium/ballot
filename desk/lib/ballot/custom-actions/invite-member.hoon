/-  *plugin, ballot-store, res=resource
/+  *ballot-plugin
|%
++  on
  |=  [=bowl:gall store=state-0:ballot-store context=[booth-key=@t proposal-key=@t]]
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

      =/  booth-name  (~(get by booth) 'name')
      ?~  booth-name  (mean leaf+"{<dap.bowl>}: invite-member custom action error. cannot determine booth name" ~)
      =/  booth-name  (so:dejs:format (need booth-name))

      =/  booth-owner  (~(get by booth) 'owner')
      ?~  booth-owner
          (mean leaf+"{<dap.bowl>}: invite-member custom action error. booth owner not found" ~)
      =/  booth-owner  (so:dejs:format (need booth-owner))
      =/  booth-ship  `@p`(slav %p booth-owner)

      =/  poll-results  ?:(?=([%o *] payload) p.payload ~)

      =/  top-choice  (~(got by poll-results) 'topChoice')
      =/  top-choice  ?:(?=([%o *] top-choice) p.top-choice ~)

      =/  data  (~(got by top-choice) 'data')
      =/  data  ?:(?=([%o *] data) p.data ~)
      =/  member  (~(get by data) 'member')
      ?~  member
          (mean leaf+"{<dap.bowl>}: invite-member custom action error. member not found in data" ~)
      =/  member  (so:dejs:format (need member))
      =/  member  `@p`(slav %p member)

      =/  rc=resource:res  `resource:res`[booth-ship booth-name]
      :: [%remove-members =resource ships=(set ship)]

      =/  ctx=json
      %-  pairs:enjs:format
      :~
        ['booth' s+booth-key.context]
        ['participant' s+(crip "{<member>}")]
      ==

      =/  action=json
      %-  pairs:enjs:format
      :~
        ['action' s+'invite']
        ['resource' s+'booth']
        ['context' ctx]
      ==

      =/  effects=(list card:agent:gall)
      :~  [%pass /group %agent [our.bowl %ballot] %poke %json !>([%o action])]
      ==

      `action-result`[success=%.y data=~ store=~ effects=effects]

  --
--