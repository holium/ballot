|_  [=bowl:gall store=(map @t (map @t json))]
++  dlg
  |=  key=@t
  ^-  json
  =/  participants  (~(get by store) key)
  =/  participants  ?~(participants ~ (need participants))
  =/  result
  %-  ~(rep in participants)
  |=  [[key=@t data=json] acc=json]
    ^-  json
    %-  (slog leaf+"{<dap.bowl>}: {<[key data]>}" ~)
    =/  view-data  ?:  ?=([%o *] acc)  p.acc  ~
    =/  delegate-data  ?:  ?=([%o *] data)  p.data  ~
    =/  delegate-key  (~(get by delegate-data) 'delegate')
    ?~  delegate-key  acc
    =/  delegate-key  (so:dejs:format (need delegate-key))
    =/  view-entry  (~(get by view-data) delegate-key)
    =/  view-entry  ?~(view-entry ~ (need view-entry))
    =/  view-entry  ?:  ?=([%o *] view-entry)  p.view-entry  ~
    =/  count  (~(get by view-entry) 'count')
    =/  count  ?~(count 1 (ni:dejs:format (need count)))
    =/  count  (add count 1)
    =/  view-entry  (~(put by view-entry) 'count' n+(crip "{<count>}"))
    =/  view-data  (~(put by view-data) delegate-key [%o view-entry])
    [%o view-data]
  result
--