/+  util=ballot-util
|_  [=bowl:gall booth-store=(map @t json) participant-store=(map @t (map @t json))]
++  tst
  |=  [booth-key=@t role=@t permission=@t]
  ^-  ?

  =/  booth  (~(get by booth-store) booth-key)
  =/  booth  ?~(booth ~ (need booth))
  =/  booth  ?:(?=([%o *] booth) p.booth ~)

  =/  permission-key  (crip (weld (trip role) "Permissions"))
  %-  (log:util %info "{<dap.bowl>}: grabbing both permissions {<permission-key>}")

  =/  permissions  (~(get by booth) permission-key)
  =/  permissions  ?~(permissions ~ (need permissions))
  =/  permissions  ?:(?=([%a *] permissions) p.permissions ~)
  %-  (log:util %info "{<dap.bowl>}: permissions => {<permissions>}")

  =/  matches
  %-  skim
  :-  permissions
  |=  a=json
    =/  perm  ?:(?=([%s *] a) p.a ~)
    %-  (log:util %info "{<dap.bowl>}: test {<a>} = {<permission>}...")
    =(perm permission)

  %-  (log:util %info "{<dap.bowl>}: {<matches>}")
  (gth (lent matches) 0)

++  chk
  |=  [booth-key=@t member-key=@t permission=@t]
  ^-  [? @t]

  %-  (log:util %info "{<dap.bowl>}: checking permissions...")
  =/  booth-members  (~(get by participant-store) booth-key)
  =/  booth-members  ?~(booth-members ~ (need booth-members))

  =/  member  (~(get by booth-members) member-key)
  ?~  member  [%.n 'member not found']
  =/  member  ?:(?=([%o *] u.member) p.u.member ~)

  =/  role  (~(get by member) 'role')
  ?~  role  [%.n 'member role not found']
  =/  role  (so:dejs:format (need role))

  ::  owners can do anything in a booth
  ?:  =(role 'owner')  [%.y 'no error']

  ::  so if this member's role has the permission OR
  ::    the member was the proposal creator, allow the action
  =/  granted  (tst booth-key role permission)
  ?.  granted
      [%.n 'insufficient privileges']
  [%.y 'no error']
--