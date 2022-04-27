/-  *plugin
|%
++  on
  |=  [=bowl:gall store=(map @t json) context=(map @t json)]
  |%
    ++  get
      |=  [payload=json]
      ^-  (unit (unit cage))

      =/  booth-key  (so:dejs:format (~(got by context) 'booth'))

      =/  delegate-store  (~(get by store) 'delegate')
        ~&  >>>  "{<dap.bowl>}: app missing delegate store"
        !!
      =/  delegate-store  ((om json):dejs:format (need delegate-store))
      =/  participants  ~(val by delegate-store)

      =/  view
      %-  run
        :-  participants
        |:  [participant=`json`~ view=`(map @t json)`~]
        =/  participant  ((om json):dejs:format participant)
        =/  entries  ~(val by participant)
        %-  run
          :-  entry
          |:  [entry=`json`~ acc=`(map @t json)`~]
          =/  entry  ((om json):dejs:format entry)
          =/  entry-ship  (~(get by entry) 'ship')
          ?~
            ~&  >>  "{<dap.bowl>}: /delegate/views/delegates.hoon on get. warning. {<delegate>} has no ship element"
            view
          =/  entry-ship  (so:dejs:format (need entry-ship))
          =/  delegate  (~(get by view) entry-ship)
          =/  count  (~(get by delegate) 'vote-count')
          =/  count  ?~(count 0 (ni:dejs:format (need count)))
          =/  delegate  (~(put by delegate) 'vote-count' n+count)
          (~(put by view) entry-ship [%o delegate])

      ``json+!>([%o result])
  --
--