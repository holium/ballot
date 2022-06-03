/-  *plugin, ballot, res=resource
|%
++  on
  |=  [=bowl:gall store=state-1:ballot context=[booth-key=@t proposal-key=@t]]
  |%
    ++  action
      |=  [action-data=json payload=json]
      ^-  action-result

      ~&  >>  "{<dap.bowl>}: invite-member {<action-data>}, {<payload>}..."

      =/  booth  (~(get by booths.store) booth-key.context)
      ?~  booth  (mean leaf+"{<dap.bowl>}: invite-member custom action error. booth {<booth-key.context>} not found in store" ~)
      =/  booth  (need booth)
      =/  booth  ?:(?=([%o *] booth) p.booth ~)
      =/  booth-type  (~(get by booth) 'type')
      =/  booth-type  ?~(booth-type ~ (so:dejs:format (need booth-type)))

      ::  check the group is a group booth
      ?.  =(booth-type 'group')
         (mean leaf+"{<dap.bowl>}: invite-member custom action error. booth {<booth-key.context>} must be a group booth" ~)

      =/  booth-name  (~(get by booth) 'name')
      ?~  booth-name  (mean leaf+"{<dap.bowl>}: invite-member custom action error. cannot determine booth name" ~)
      =/  booth-name  `@tas`(so:dejs:format (need booth-name))

      ::  get the booth owner. the booth owner will be the group owner
      =/  booth-owner  (~(get by booth) 'owner')
      ?~  booth-owner
          (mean leaf+"{<dap.bowl>}: invite-member custom action error. booth owner not found" ~)
      =/  booth-owner  (so:dejs:format (need booth-owner))
      =/  booth-ship  `@p`(slav %p booth-owner)

      :: =/  poll-results  ?:(?=([%o *] payload) p.payload ~)

      :: =/  top-choice  (~(got by poll-results) 'topChoice')
      :: =/  top-choice  ?:(?=([%o *] top-choice) p.top-choice ~)

      =/  action  ?:(?=([%o *] action-data) p.action-data ~)
      =/  data  (~(got by action) 'data')
      =/  data  ?:(?=([%o *] data) p.data ~)
      =/  member  (~(get by data) 'member')
      ?~  member
          (mean leaf+"{<dap.bowl>}: invite-member custom action error. member not found in data" ~)
      =/  member  (so:dejs:format (need member))
      =/  member  `@p`(slav %p member)

      :: =/  rc=resource:res  `resource:res`[booth-ship booth-name]

      :: =/  ctx=json
      :: %-  pairs:enjs:format
      :: :~
      ::   ['booth' s+booth-key.context]
      ::   ['participant' s+(crip "{<member>}")]
      :: ==

      :: =/  action=json
      :: %-  pairs:enjs:format
      :: :~
      ::   ['action' s+'invite']
      ::   ['resource' s+'booth']
      ::   ['context' ctx]
      :: ==

  :: =/  =action:inv
  ::   :^  %invites  %groups  (shaf %group-uid eny.bowl)
  ::   ^-  multi-invite:inv
  ::   [our.bowl %group-push-hook [booth-ship booth-name] (sy [member ~]) 'description here']
  :: ;<  ~  bind:m  (poke-our %invite-hook invite-action+!>(action))

      :: =/  effects=(list card:agent:gall)
      :: :~  [%pass /invite %agent [our.bowl %invite-hook] %poke %invite-action !>(action)]
      :: ==

      =/  effects=(list card:agent:gall)
      :~  [%pass /group %agent [our.bowl %group-store] %poke %group-action !>([%add-members [booth-ship booth-name] (sy [member ~])])]
      ==

      `action-result`[success=%.y data=~ store=~ effects=effects]

  --
--