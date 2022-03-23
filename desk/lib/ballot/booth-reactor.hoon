|%
+$  card  card:agent:gall
--

:: {
::   "save-proposal": {
        :: // use this for payload validation
        :: "payload": {
        ::   "context": { // object required
        ::     "booth-key": string required
        ::   }
        ::   "data": {  // object required
        ::     "title"  string required
        ::     "content"  string required
        ::     ...
        ::   }
        :: }
::     "reactor": {
::       "type": "hoon | agent | lib",
::       "hoon": {
::         "type": "file|code",
::         "src": "filename | source"
::       },
::       "agent": {
::         "name": "agent-name",
::         "entry": "arm | gate",
::         "gate": {
::           "hoon": "|=  [@t]  ~"
::         }
::         "arm": "gate",
::         ...
::       },
::       "lib": {
::         "name": "lib-name",
::         "gate": "gate",
::         ...
::       }
::     },
::     "stores": ['booth', 'proposal']
::   }
:: }

|_  [=bowl:gall state=(map @t json)]

++  on-action
  |=  [payload=json]
  ^-  [@tas body=json effects=(list card) state=json]

  =/  timestamp  (en-json:html (time:enjs:format now.bowl))

  =/  payload  ((om json):dejs:format payload)

  =/  context  (~(get by payload) 'context')
  =/  context  ?~(context ~ ((om json):dejs:format (need context)))

  =/  booth-key  (~(get by context) 'booth-key')
  ?~  booth-key
        [%nack body=s+'context missing booth-key' effects=~ [%o state]]

  =/  data  (~(get by payload) 'data')
  =/  data  ?~(data ~ ((om json):dejs:format (need data)))
  =/  proposal-key  (~(get by data) 'key')
  =/  is-create  ?~(proposal-key %.y %.n)
  =/  proposal-key
        ?~  proposal-key
              (crip (weld "proposal-" timestamp))
            (so:dejs:format (need proposal-key))

  =/  booth-key  (so:dejs:format (need booth-key))

  =/  proposal-store  (~(get by state) 'proposal')
  ?~  proposal-store
        [%nack body=s+'state missing booth store' effects=~ [%o state]]

  =/  proposal-store  ((om json):dejs:format (need proposal-store))
  =/  proposals  (~(get by proposal-store) booth-key)
  =/  proposals  ?~(proposals ~ ((om json):dejs:format (need proposals)))
  =/  proposals  (~(put by proposals) proposal-key [%o data])

  [%ack [%o data] ~ [%o (~(put by state) 'proposal' [%o proposal-store])]]

::  on-reaction would be called when ???
++  on-reaction
  |=  [payload=json]
  ^-  [@tas body=json effects=(list card) state=json]

  [%ack ~ ~ [%o state]]

++  on-effects
  |=  [payload=json]
  ^-  [@tas body=json effects=(list card) state=json]

  [%ack ~ ~ [%o state]]

--