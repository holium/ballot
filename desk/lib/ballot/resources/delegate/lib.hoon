|%

+$  card  card:agent:gall

--

|_  [=bowl:gall store=(map @t json)]

++  save
  |=  [payload=(map @t json)]
  ^-  [effects=(list card) state=(map @t json)]

  =/  timestamp  (crip (en-json:html (time:enjs:format now.bowl)))

  =/  data  (~(get by payload) 'data')
  ?~  data
    ~&  >>>  "invalid payload. data element not found"
    [~ store]

  =/  data  ((om json):dejs:format (need data))

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
          [key ((om json):dejs:format delegate))]
        :: else
        =/  key  (so:dejs:format (need key))
        =/  delegate
        %-  pairs:enjs:format
        :~
          ['modified' n+timestamp]
        ==
        [key ((om json):dejs:format delegate))]

  =/  delegate  (~(gas by data) ~(tap by delegate))

  =/  store  (~(put by store) key [%o delegate])

  [~ store]

--