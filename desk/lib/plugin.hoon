/-  *plugin
|%                                      ::  The |% rune produces a core

++  return-error
  |=  [store=json data=json]
  ^-  action-result
  `action-result`[success=%.n data=data store=store effects=~]

++  to-map
  |=  [jon=json]
  ^-  (map @t json)
  ?~  jon  ~
  ?>  ?=(%o -.jon)
  p.jon

++  path-to-action
  |=  [=bowl:gall store=json =path]
  ^-  action-result

  =/  segments  `(list @t)`(oust [0 1] path)
  =/  num-segments  (lent segments)

  :: assuming all paths start with /%x/<resource>/<action | key> means we need at least
  ::  3 segments  for this to be a valid path. aka we need at least one resource to
  ::  either lookup or take action on
  ?:  (lth (lent segments) 2)
    (return-error store s+'invalid path')
  ?>  ?=(%o -.store)
  =/  resource-store  (~(get by p.store) 'resources')
  ?~  resource-store
    ~&  >>>  "{<dap.bowl>}: invalid app state. no resources in store. crash."
    !!
  =/  resource-store  ((om json):dejs:format (need resource-store))
  =/  result=[idx=@ud last-seg=(unit @t) action=json]
    %-  roll
    :-  segments
    |:  [seg=`@t`~ curr=`[idx=@ud last-seg=(unit @t) action=json]`[0 ~ ~]]
    =/  action  ?~(action.curr ~ ((om json):dejs:format action.curr))
    =/  context  (~(get by action) 'context')
    =/  context  ?~(context ~ ((om json):dejs:format (need context)))
    ?:  =((add idx.curr 1) num-segments)
      =/  action  (~(put by action) 'action' s+seg)
      [(add idx.curr 1) (some seg) [%o action]]
    ?:  =((mod idx.curr 2) 1)
      :: odd
      =/  context  (~(put by context) (need last-seg.curr) s+seg)
      =/  action  (~(put by action) 'context' [%o context])
      [(add idx.curr 1) (some seg) [%o action]]
    :: even
    ?.  (~(has by resource-store) seg)  !!
    =/  action  (~(put by action) 'resource' s+seg)
    [(add idx.curr 1) (some seg) [%o action]]

  =/  action  ?~(action.result ~ ((om json):dejs:format action.result))
  =/  resource  (~(get by action) 'resource')
  ?~  resource  (return-error store s+'failed to resolve resource')
  =/  resource  (so:dejs:format (need resource))
  =/  action-name  (~(get by action) 'action')
  ?~  action-name  (return-error store s+'failed to resolve action')
  =/  action-name  (so:dejs:format (need action-name))
  =/  context  (~(get by action) 'context')
  =/  context  ?~(context ~ ((om json):dejs:format (need context)))
  =/  action  (~(put by action) 'data' ~)

  =/  lib-file  /(scot %p our.bowl)/(scot %tas dap.bowl)/(scot %da now.bowl)/lib/(scot %tas dap.bowl)/resources/(scot %tas resource)/(scot %tas action-name)/hoon

  ?.  .^(? %cu lib-file)
    (return-error store s+(crip "{<dap.bowl>}: resource action lib file {<lib-file>} not found"))

  =/  action-lib  .^([p=type q=*] %ca lib-file)
  =/  on-func  (slam (slap action-lib [%limb %on]) !>([bowl store context]))
  !<(action-result (slam (slap on-func [%limb %action]) !>([%o action])))
--