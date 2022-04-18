|%

+$  card  card:agent:gall

--

|_  [=bowl:gall store=(map @t json) context=(map @t json)]

++  on-action
  |=  [action=@t payload=json]
  ^-  [effects=(list card) state=(map @t json)]

  %-  (slog leaf+"{<dap.bowl>}: action handler called {<bowl>}, {<action>}, {<payload>}..." ~)

  ?+  action  [~ store]

    %delegate
      (on-delegate payload)

  ==

++  on-delegate
  |=  [action-data=json]
  ^-  [effects=(list card) state=(map @t json)]

  =/  timestamp  (crip (en-json:html (time:enjs:format now.bowl)))

  =/  data  ((om json):dejs:format action-data)

  ::  ~lodlev-migdev
  ::   if key exist, assume save; otherwise create new resource
  =/  key  (~(get by data) 'key')

  =/  is-create  ?~(key %.y %.n)

  =/  delegate=[key=@t data=(map @t json)]
        ::  if creating
        ?:  is-create
          ::  then
          =/  key  (crip "delegate-{<(scot %t timestamp)>}")
          =/  delegate
          %-  pairs:enjs:format
          :~
            ['key' s+key]
            ['created' n+timestamp]
          ==
          [key ((om json):dejs:format delegate)]
        :: else
        =/  key  (so:dejs:format (need key))
        =/  delegate
        %-  pairs:enjs:format
        :~
          ['modified' n+timestamp]
        ==
        [key ((om json):dejs:format delegate)]

  =/  delegate=[key=@t data=(map @t json)]  [key.delegate (~(gas by data) ~(tap by data.delegate))]

  =/  resource-effect=json
  %-  pairs:enjs:format
  :~
    ['resource' s+'delegate']
    ['effect' s+?:(is-create 'add' 'update')]
    ['key' s+key.delegate]
    ['data' [%o data.delegate]]
  ==

  =/  effect=json
  %-  pairs:enjs:format
  :~
    ['action' s+'delegate-reaction']
    ['context' [%o context]]
    ['effects' [%a ~[resource-effect]]]
  ==

  =/  store  (~(put by store) key.delegate [%o data.delegate])

  [~ store]

--