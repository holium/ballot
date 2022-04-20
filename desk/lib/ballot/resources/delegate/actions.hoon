|%
++  on
  |=  [=bowl:gall store=(map @t json) context=(map @t json)]
  |%
    ::  ++  delegate
    ::  delegate action arm
    ++  delegate
      |=  [action-data=json]
      ^-  [(list card:agent:gall) (map @t json)]
      =/  timestamp  (crip (en-json:html (time:enjs:format now.bowl)))

      =/  booth-key  (~(get by context) 'booth')
      ?~  booth-key  !!
      =/  booth-key  (so:dejs:format (need booth-key))

      =/  data  ((om json):dejs:format action-data)

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

    ++  delegate-reaction
      |=  [action-data=json]
      ^-  [effects=(list card:agent:gall) state=(map @t json)]

      =/  timestamp  (crip (en-json:html (time:enjs:format now.bowl)))

      =/  data  ((om json):dejs:format action-data)

      =/  effects  (~(get by data) 'effects')
      ?~  effects
        ~&  >>>  "{<dap.bowl>}: delegate-reaction. missing effects data"
        !!
      =/  effects  ((ar json):dejs:format (need effects))

      =/  result  %-  roll
        :-  effects
        |:  [effect=`json`~ acc=`[ok=? jon=json]`[%.n ~]]
        =/  result  (handle-effect effect)
        =/  has-error  ?.  ok.result  =.  ok.acc  %.n
        [has-error data.result]

      ::  lodlev-migdev - only update the official
      ::   store/state if all effects succeeded
      =/  new-state  ?:  -.result
          =/  dat  ((om json):dejs:format +.acc)
          (~(gas by state) ~(tap by dat))
        state

      :_  new-state
          ::  inform the UI
      :~  [%give %fact [/booths]~ %json !>(effects)]
      ==

      ++  handle-effect
        |=  [payload=json acc=[@f json]]
        ^-  [? json]

        =/  result  ?~  payload
          [%.y (make-error (crip "{<dap.bowl>}: handle-effect error. missing payload"))]

        =/  data  ((om json):dejs:format payload)

        =/  effect  (~(get by data) 'effect')
        ?~  effect  [%.y (inject-error data (crip "{<dap.bowl>}: handle-effect error. missing effect attribute"))]
        =/  effect  (so:dejs:format (need effect))

        =/  effect-data  (~(get by data) 'data')
        ?~  effect-data  [%.y (inject-error data (crip "{<dap.bowl>}: handle-effect error. missing data attribute"))]
        =/  effect-data  ((om json):dejs:format (need effect-data))

        ?+  effect  [%.y (inject-error data (crip "{<dap.bowl>}: handle-effect error. effect not supported"))]

          %add
            (add data)

          %update
            (update data)

        ==

      ++  add
        |=  [data=(map @t json)]
        ^-  [? json]
        =/  key  (~(get by data) 'key')
        ?~  key  [%.n (inject-error data (crip "{<dap.bowl>}: delegate add error. data missing key"))]
        =/  key  (so:dejs:format (need key))
        [%.y [%o data]]

      ++  update
        |=  [data=(map @t json)]
        ^-  [? json]
        =/  key  (~(get by data) 'key')
        ?~  key  [%.n (inject-error data (crip "{<dap.bowl>}: delegate update error. data missing key"))
        =/  key  (so:dejs:format (need key))
        =/  delegate  (~(get by store) key)
        ?~  delegate  [%.n (inject-error data (crip "{<dap.bowl>}: update error. delegate not found in store"))]
        =/  delegate  ((om json):dejs:format (need delegate))
        ::  merge new data with existing data
        =/  delegate  (~(gas by delegate) ~(tap by data))
        [%.y [%o delegate]]

      ++  inject-error
        |=  [data=(map @t json) msg=@t]
        ^-  json
        (~(put by data) 'error' s+msg)
  --
--
