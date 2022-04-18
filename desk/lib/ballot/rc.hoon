|_  [=bowl:gall store=json]

++  ls
  |=  [rc-key=@t]
  =/  data  ((om json):dejs:format store)
  =/  entry  (~(get by data) rc-key)
  ?~  entry  ``json+!>(s+'resource entries not found')
  =/  entry  ((om json):dejs:format entry)
  ``json+!>([%a (~(val by entry))])

