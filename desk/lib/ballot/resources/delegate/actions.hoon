|%

+$  card  card:agent:gall

--

|_  [=bowl:gall store=(map @t json) context=(map @t json)]

:: ++  on-action
::   |=  [action=@t payload=json]
::   ^-  [effects=(list card) state=(map @t json)]

::   %-  (slog leaf+"{<dap.bowl>}: action handler called {<bowl>}, {<action>}, {<payload>}..." ~)

::   ?+  action  [~ store]

::     %delegate
::       (on-delegate payload)

::   ==

::  ++  delegate
::  delegate action arm
++  delegate
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

  =/  effects=json
  %-  pairs:enjs:format
  :~
    ['action' s+'delegate-reaction']
    ['context' [%o context]]
    ['effects' [%a ~[resource-effect]]]
  ==

  =/  store  (~(put by store) key.delegate [%o data.delegate])

  :_  store
      ::  inform the UI
  :~  [%give %fact [/booths]~ %json !>(effects)]
      ::  send off to remote booth participants
      [%give %fact [/booths/(scot %tas booth-key)]~ %json !>(effects)]
  ==

++  delegate-reaction
  |=  [action-data=json]
  ^-  [effects=(list card) state=(map @t json)]

  =/  timestamp  (crip (en-json:html (time:enjs:format now.bowl)))

  =/  data  ((om json):dejs:format action-data)

  =/  effects  (~(get by data) 'effects')
  ?~  effects
    ~&  >>>  "{<dap.bowl>}: delegate-reaction. missing effects data"
    !!
  =/  effects  ((ar json):dejs:format (need effects))
  =/  error  %-  roll
    :-  effects
    |:  [effect=`json`~ results=`(map @t json)`~]
    (handle-effect effect)


  :_  store
      ::  inform the UI
  :~  [%give %fact [/booths]~ %json !>(effects)]
  ==

  ++  handle-effect
    |=  [payload=json]

    =/  data  ((om json):dejs:format payload)
    =/  key  (so:dejs:format (~(got by data) 'key'))
    =/  effect  (so:dejs:format (~(got by data) 'effect'))
    =/  effect-data  ((om json):dejs:format (~(got by data) 'data'))

    ?+  effect  (give-effect-error payload)

      %add
        (~(put by store) key [%o effect-data])

      %update
        =/  delegate  ((om json):dejs:format (~(got by store) key))
        ::  merge new data with existing data
        =/  delegate  (~(gas by delegate) ~(tap by effect-data))
        (~(put by store) key [%o delegate])

    ==


--