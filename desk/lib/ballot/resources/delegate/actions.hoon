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

      =/  result=[effects=(list json) state=(map @t json)]  %-  roll
        :-  effects
        |:  [effect=`json`~ acc=`[effects=(list json) state=(map @t json)]`[~ ~]]
        =/  result=[effect=json state=(map @t json)]  (handle-effect effect)
        [(snoc effects.acc effect.result) state.result]

      =/  updated-effects  (~(put by data) 'effects' [%a effects.result])

      :_  state.result
      :~  [%give %fact [/booths]~ %json !>([%o updated-effects])]
      ==

      ++  handle-effect
        |=  [payload=json]
        ^-  [effect=json state=(map @t json)]

        ?~  payload
          ~&  >>>  "{<dap.bowl>}: handle-effect error. null effect payload encountered"
          [(inject-error ~ (crip "missing data attribute")) store]

        =/  data  ((om json):dejs:format payload)

        =/  effect  (~(get by data) 'effect')
        ?~  effect  [(inject-error data (crip "missing effect attribute")) store]
        =/  effect  (so:dejs:format (need effect))

        =/  effect-data  (~(get by data) 'data')
        ?~  effect-data  [(inject-error data (crip "missing data attribute")) store]
        =/  effect-data  ((om json):dejs:format (need effect-data))

        ?+  effect  [(inject-error data (crip "effect not supported")) store]

          %add
            (add data)

          %update
            (update data)

        ==

      ++  add
        |=  [data=(map @t json)]
        ^-  [effect=json state=(map @t json)]
        =/  key  (~(get by data) 'key')
        ?~  key  [(inject-error data (crip "{<dap.bowl>}: delegate add error. data missing key")) store]
        =/  key  (so:dejs:format (need key))
        [[%o data] (~(put by store) key [%o data])]

      ++  update
        |=  [data=(map @t json)]
        ^-  [effect=json state=(map @t json)]
        =/  key  (~(get by data) 'key')
        ?~  key  [(inject-error data (crip "{<dap.bowl>}: delegate update error. data missing key")) store]
        =/  key  (so:dejs:format (need key))
        =/  delegate  (~(get by store) key)
        ?~  delegate  [(inject-error data (crip "{<dap.bowl>}: update error. delegate not found in store")) store]
        =/  delegate  ((om json):dejs:format (need delegate))
        ::  merge new data with existing data
        =/  delegate  (~(gas by delegate) ~(tap by data))
        [[%o data] (~(put by store) key [%o delegate])]

      ++  inject-error
        |=  [data=(map @t json) msg=@t]
        ^-  json
        =/  data  (~(put by data) 'effect' s+'error')
        =/  data  (~(put by data) 'data' s+msg)
        [%o data]
  --
--
