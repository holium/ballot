|%
++  on
  |=  [=bowl:gall store=(map @t json) context=(map @t json)]
  |%
    ::  ++  delegate
    ::  delegate action arm
    ++  delegate
      |=  [data=json]
      ^-  [(list card:agent:gall) (map @t json)]
      =/  timestamp  (crip (en-json:html (time:enjs:format now.bowl)))

      =/  booth-key  (~(get by context) 'booth')
      ?~  booth-key  !!
      =/  booth-key  (so:dejs:format (need booth-key))

      =/  data  ((om json):dejs:format data)

      ::  ~lodlev-migdev
      ::   if key exist, assume save; otherwise create new resource
      =/  key  (~(get by data) 'key')

      =/  is-create  ?~(key %.y %.n)

      =/  delegate=[key=@t data=(map @t json)]
            ::  if creating
            ?:  is-create
              ::  then
              =/  key  (crip (weld "delegate-" (trip timestamp)))
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
  --
--

:: ++  delegate-reaction
::   |=  [action-data=json]
::   ^-  [effects=(list card:agent:gall) state=(map @t json)]

::   =/  timestamp  (crip (en-json:html (time:enjs:format now.bowl)))

::   =/  data  ((om json):dejs:format action-data)

::   =/  effects  (~(get by data) 'effects')
::   ?~  effects
::     ~&  >>>  "{<dap.bowl>}: delegate-reaction. missing effects data"
::     !!
::   =/  effects  ((ar json):dejs:format (need effects))

::   =/  result  %-  roll
::     :-  effects
::     |:  [effect=`json`~ acc=`[@f json]`[%.n ~]]
::     ?:  -.acc
::       (handle-effect effect)
::     acc

::   ::  lodlev-migdev - only update the official
::   ::   store/state if all effects succeeded
::   =/  new-state  ?:  -.result
::       =/  dat  ((om json):dejs:format +.acc)
::       (~(gas by state) ~(tap by dat))
::     state

::   :_  new-state
::       ::  inform the UI
::   :~  [%give %fact [/booths]~ %json !>(effects)]
::   ==

::   ++  handle-effect
::     |=  [payload=json acc=[@f json]]
::     ^-  [@f (map @t json)]

::     =/  result  ?~  payload
::       [%.y (make-error (crip "{<dap.bowl>}: handle-effect error. missing payload"))]

::     =/  data  ((om json):dejs:format payload)

::     =/  key  ((om json):dejs:format (~(get by data) 'key'))
::     =/  result  ?~  key
::       [%.y [%o (make-error (crip "{<dap.bowl>}: handle-effect error. missing key attribute"))]]

::     =/  effect  (so:dejs:format (~(get by data) 'effect'))
::     =/  result  ?~  effect
::       [%.y [%o (make-error (crip "{<dap.bowl>}: handle-effect error. missing effect attribute"))]]

::     =/  effect-data  ((om json):dejs:format (~(get by data) 'data'))
::     =/  result  ?~  effect-data
::       [%.y [%o (make-error (crip "{<dap.bowl>}: handle-effect error. missing effect attribute"))]]

::     ?+  effect  [%.y (make-error (crip "{<dap.bowl>}: handle-effect error. effect not supported"))]

::       %add
::         (~(put by +.acc) key [%o effect-data])

::       %update
::         =/  delegate  ((om json):dejs:format (~(get by store) key))
::         =/  result  ?~  delegate
::           [%.y (make-error (crip "{<dap.bowl>}: handle-effect error. delegate {<key>} not found"))]
::         ::  merge new data with existing data
::         =/  delegate  (~(gas by delegate) ~(tap by effect-data))
::         (~(put by +.acc) key [%o delegate])

::     ==

  :: ++  send-error
  ::   |=  [msg=@t]
  ::   ^-  [(list card:agent:gall) (map @t json)]
  ::   =/  error-effect
  ::   %-  pairs:enjs:format
  ::   :~
  ::     ['resource' s+'delegate']
  ::     ['effect' s+'error']
  ::     ['data' s+msg]
  ::   ==
  ::   =/  error-effects=json
  ::   %-  pairs:enjs:format
  ::   :~
  ::     ['action' s+'delegate-error']
  ::     ['context' [%o context.g]]
  ::     ['effects' [%a ~[error-effect]]]
  ::   ==
  ::   :_  store.g
  ::       ::  inform the UI
  ::   :~  [%give %fact [/booths]~ %json !>(error-effects)]
  ::   ==
