|%
+$  card  card:agent:gall
--
|_  [=bowl:gall store=(map @t json) context=(map @t json)]
::
++  initial
  |=  [effect-data=json]
  ^-  [code=@tas effects=(list card) state=(map @t json)]

  =/  store  (~(put by store) key.delegate [%o data.delegate])

  :_  store
      ::  inform the UI
  :~  [%give %fact [/booths]~ %json !>(effects)]
      ::  send off to remote booth participants
      [%give %fact [/booths/(scot %tas booth-key)]~ %json !>(effects)]
  ==

++  add
  |=  [effect-data=json]
  ^-  [code=@tas effects=(list card) state=(map @t json)]

  =/  store  (~(put by store) key.delegate [%o data.delegate])

  :_  store
      ::  inform the UI
  :~  [%give %fact [/booths]~ %json !>(effects)]
      ::  send off to remote booth participants
      [%give %fact [/booths/(scot %tas booth-key)]~ %json !>(effects)]
  ==

++  update
  |=  [effect-data=json]
  ^-  [code=@tas effects=(list card) state=(map @t json)]

  =/  store  (~(put by store) key.delegate [%o data.delegate])

  :_  store
      ::  inform the UI
  :~  [%give %fact [/booths]~ %json !>(effects)]
      ::  send off to remote booth participants
      [%give %fact [/booths/(scot %tas booth-key)]~ %json !>(effects)]
  ==

++  delete
  |=  [effect-data=json]
  ^-  [code=@tas effects=(list card) state=(map @t json)]

  =/  store  (~(put by store) key.delegate [%o data.delegate])

  :_  store
      ::  inform the UI
  :~  [%give %fact [/booths]~ %json !>(effects)]
      ::  send off to remote booth participants
      [%give %fact [/booths/(scot %tas booth-key)]~ %json !>(effects)]
  ==

++  error
  |=  [effect-data=json]
  ^-  [code=@tas effects=(list card) state=(map @t json)]

  =/  store  (~(put by store) key.delegate [%o data.delegate])

  :_  store
      ::  inform the UI
  :~  [%give %fact [/booths]~ %json !>(effects)]
      ::  send off to remote booth participants
      [%give %fact [/booths/(scot %tas booth-key)]~ %json !>(effects)]
  ==
--