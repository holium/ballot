|_  [=bowl:gall store=(map @t (map @t json))]
++  dlg
  |=  key=@t
  ^-  json
  =/  participants  (~(get by store) key)
  ?~  participants  [%o ~]
  [%o (need participants)]
--