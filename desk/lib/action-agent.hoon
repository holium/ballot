/-  plugin
/+  log=log-core
|%
+$  card  card:agent:gall
--

|_  [=bowl:gall store=json]

++  poke
  |=  [=mark =vase]
  ^-  [(list card) json]

  ?+  mark  [~ store]

      %auth
        (set-authentication-mode !<(@t vase))

      :: %initialize
        :: (initialize ~)

      :: %json can either come from eyre or direct agent pokes
      %json
        (handle-resource-action-poke !<(json vase))

      :: direct http interface w/ eyre
      %handle-http-request
        (on-http-request !<((pair @ta inbound-request:eyre) vase))

    ==

++  peek
  |=  =path
  ^-  (unit (unit cage))

  (handle-scry path)

++  set-authentication-mode
  |=  [mode=@t]
  %-  (slog leaf+"{<dap.bowl>}: setting authentication {<mode>}..." ~)
  [~ store]

++  initialize
  |=  [jon=json]
  ^-  action-result:plugin
  :: ^-  [(list card) (map @t json)]
  :: ^-  action-result:plugin

  %-  (write:log "{<dap.bowl>}: {<dap.bowl>} initializing...")

  =/  config-file=path  /(scot %p our.bowl)/(scot %tas dap.bowl)/(scot %da now.bowl)/cfg/(scot %tas dap.bowl)/json

  ?.  .^(? %cu config-file)
    ~&  >>>  "{<dap.bowl>}: {<dap.bowl>} config file not found. create a /cfg/{<dap.bowl>}/.json file and try again"
    !!

  =/  config  .^(json %cx config-file)
  =/  cfg  ((om json):dejs:format config)

  =/  log-level  (~(get by cfg) 'log-level')
  =/  log-level  ?~  log-level
    ~&  >>  "{<dap.bowl>}: log-level not found in config. defaulting to 0."
    0
  (ni:dejs:format (need log-level))

  :: =/  config-file=path  /(scot %p our.bowl)/(scot %tas dap.bowl)/(scot %da now.bowl)/(scot %tas dap.bowl)/resources/cfg

  :: ?.  .^(? %cu config-file)
  ::   ~&  >>>  "{<dap.bowl>}: /lib/{<dap.bowl>}/resources config file not found. create a /lib/{<dap.bowl>}/resources/.cfg file and try again"
  ::   `store

  :: =/  resources  .^(json %cx config-file)
  =/  resources  (~(get by cfg) 'resources')
  ?~  resources
    ~&  >>>  "{<dap.bowl>}: {<dap.bowl>} resources not found. fix the config file, nuke, and reinstall"
    !!
  =/  resources  (need resources)

  ~&  >  "{<dap.bowl>}: initialized"

  =/  action=json
  %-  pairs:enjs:format
  :~
    ['resource' s+dap.bowl]
    ['action' s+'initialize']
    ['context' ~]
    ['data' ~]
  ==

  =/  store=json  ?~(store [%o ~] store)
  ?>  ?=(%o -.store)
  =/  store  (~(put by p.store) 'resources' resources)
  =/  effects
    :~  [%pass /(scot %tas dap.bowl) %agent [our.bowl dap.bowl] %poke %json !>(action)]
    ==

  `action-result:plugin`[success=%.y data=[%o store] effects=effects]
  :: `action-result:plugin+!>([success=%.y data=[%o store] effects=effects])

  :: :_  (~(put by store) 'resources' resources)

  :: :~  [%pass /(scot %tas dap.bowl) %agent [our.bowl dap.bowl] %poke %json !>(action)]
  :: ==

::
::  ARM:  ++  on-http-request
::
::   Called when http request received from Eyre. All actions come into
::    our agent as POST requests.
::
++  on-http-request
  |=  [req=(pair @ta inbound-request:eyre)]

  :: ?:  ?&  =(authentication.state 'enable')
  ::         !authenticated.q.req
  ::     ==
  ::     ~&  >>>  "{<dap.bowl>}: authentication is enabled. request is not authenticated"
  ::     (send-api-error req 'not authenticated')

  :: parse query string portion of url into map of arguments (key/value pair)
  =/  req-args
        (my q:(need `(unit (pair pork:eyre quay:eyre))`(rush url.request.q.req ;~(plug apat:de-purl:html yque:de-purl:html))))

  %-  (slog leaf+"{<dap.bowl>}: [on-poke] => processing request at endpoint {<(stab url.request.q.req)>}" ~)

  =/  path  (stab url.request.q.req)

  ::  all actions come in as POST method requests over http
  ?+    method.request.q.req  (send-api-error req 'unsupported')

        %'POST'
          (handle-resource-action-http req req-args)

  ==

::
::  ARM:  ++  handle-resource-action
::
::   All actions funnel thru this arm. They come into Eyre as http
::     POST method requests.
::
++  handle-resource-action-http
  |=  [req=(pair @ta inbound-request:eyre) args=(map @t @t)]
  ^-  [(list card) json]

  =/  til=octs
        (tail body.request.q.req)

  ::  variable to hold request body (as $json)
  =/  payload  (need (de-json:html q.til))

  =/  result=action-result:plugin  (handle-resource-action payload)

  =/  =response-header:http
    :-  ?:(success.result 200 500)
    :~  ['Content-Type' 'application/json']
    ==

  =/  response-data  (crip (en-json:html data.result))

  ::  convert the string to a form that arvo will understand
  =/  data=octs
        (as-octs:mimes:html response-data)

  :_  data.result
  :~
    [%give %fact [/http-response/[p.req]]~ %http-response-header !>(response-header)]
    [%give %fact [/http-response/[p.req]]~ %http-response-data !>(`data)]
    [%give %kick [/http-response/[p.req]]~ ~]
  ==

++  handle-resource-action-poke
  |=  [payload=json]
  ^-  [(list card) json]

  =/  result=action-result:plugin  (handle-resource-action payload)

  :_  data.result  effects.result

++  handle-resource-action
  |=  [payload=json]
  :: ^-  [(list card) (map @t json)]
  ^-  action-result:plugin

  ~&  >>  "{<dap.bowl>}: handle-resource-action called {<payload>}..."

  ::  check store in state to ensure there's configured resources
  ?>  ?=(%o -.store)

  =/  resources  (~(get by p.store) 'resources')
  ?~  resources  (send-error "{<dap.bowl>}: invalid agent state. missing resources" ~)
  =/  resources  ((om json):dejs:format (need resources))

  ::  do some initial validation
  =/  action-payload  ((om json):dejs:format payload)

  %-  (write:log "{<dap.bowl>}: fetching context...")

  =/  context  (~(get by action-payload) 'context')
  ?~  context  (send-error "{<dap.bowl>}: invalid payload. missing context element" ~)
  =/  context  (need context)
  =/  context  ?~(context ~ ((om json):dejs:format context))

  %-  (write:log "{<dap.bowl>}: {<context>}...")

  =/  action  (~(get by action-payload) 'action')
  ?~  action  (send-error "{<dap.bowl>}: invalid payload. missing action element" ~)
  =/  action  (so:dejs:format (need action))

  =/  data  (~(get by action-payload) 'data')
  ?~  data  (send-error "{<dap.bowl>}: invalid payload. missing data element" ~)
  =/  data  (need data)

  =/  resource  (~(get by action-payload) 'resource')
  ?~  resource  (send-error "{<dap.bowl>}: invalid payload. missing resource element" ~)
  =/  resource  (so:dejs:format (need resource))

  =/  resource-store  (~(get by resources) resource)
  ?~  resource-store  (send-error "{<dap.bowl>}: resource {<resource>} store not found" ~)
  =/  resource-store  ((om json):dejs:format (need resource-store))

  =/  dispatch-mode  (~(get by resource-store) 'dispatcher')
  =/  dispatch-mode  ?~(dispatch-mode 'direct' (so:dejs:format (need dispatch-mode)))

  =+  c-ctx=`call-context:plugin`[bowl context p.store data]

  ?+  dispatch-mode  (send-error "{<dap.bowl>}: unrecognized dispatcher value" ~)

    %direct
      (execute-direct resource action c-ctx)

    %proxy
      (execute-by-proxy resource action c-ctx)

  ==

++  execute-direct
  |=  [resource=@t action=@t c=call-context:plugin]
  :: ^-  [(list card) (map @t json)]
  ^-  action-result:plugin

  =/  lib-file=path  /(scot %p our.bowl)/(scot %tas dap.bowl)/(scot %da now.bowl)/lib/(scot %tas dap.bowl)/resources/(scot %tas resource)/(scot %tas action)/hoon

  ?.  .^(? %cu lib-file)
    (send-error "{<dap.bowl>}: resource action lib file {<lib-file>} not found" ~)

  =/  action-lib  .^([p=type q=*] %ca lib-file)
  =/  action-lib  .^([p=type q=*] %ca lib-file)
  =/  on-func  (slam (slap action-lib [%limb %on]) !>([bowl.c store.c args.c]))
  =/  result  !<(action-result:plugin (slam (slap on-func [%limb %action]) !>(payload.c)))
  :: =/  result=[effects=(list card) state=(map @t json)]  !<([(list card) (map @t json)] (slam (slap action-lib [%limb %run]) !>(c)))

  %-  (write:log "{<dap.bowl>}: committing store to agent state {<result>}...")

  result
  :: `action-result+!>([%.y ~ ~ ])

  :: :_  state.result

  :: effects.result

++  execute-by-proxy
  |=  [resource=@t action=@t c=call-context:plugin]
  :: ^-  [(list card) (map @t json)]
  ^-  action-result:plugin

  =/  lib-file=path  /(scot %p our.bowl)/(scot %tas dap.bowl)/(scot %da now.bowl)/lib/(scot %tas dap.bowl)/resources/(scot %tas resource)/actions/hoon

  ?.  .^(? %cu lib-file)
    (send-error "{<dap.bowl>}: resource action lib file {<lib-file>} not found" ~)

  =/  action-lib  .^([p=type q=*] %ca lib-file)
  =/  on-func  (slam (slap action-lib [%limb %on]) !>([bowl.c store.c args.c]))
  =/  result=action-result:plugin  !<(action-result:plugin (slam (slap on-func [%limb action]) !>(payload.c)))

  %-  (write:log "{<dap.bowl>}: committing store to agent state {<result>}...")

  result
  :: :_  state.result

  :: effects.result

::  send an error as poke back to calling agent
++  send-error
  |=  [reason=tape jon=json]
  :: ^-  [(list card) (map @t json)]
  ^-  action-result:plugin
  ~&  >>>  (crip reason)
  ::  if json is null, send back reason error as json string
  =/  payload=json  ?~  jon
        ::  then
        s+(crip reason)  :: send back reason error as string
      :: else stuff payload with error message
      %-  pairs:enjs:format
      :~
        ['error' s+(crip reason)]
      ==

  ?.  =(our.bowl src.bowl)
    ::  ensure action: 'error' in json for this to be recognized
    ::   on the remote agent
    =/  effects
    :~  [%pass /errors %agent [src.bowl dap.bowl] %poke %json !>(payload)]
    ==
    !<(action-result:plugin !>([success=%.n data=payload effects=effects]))
    :: :_  store
    :: :~  [%pass /errors %agent [src.bowl dap.bowl] %poke %json !>(payload)]
    :: ==
  (give-error payload)

::  use this for errors that should appear in UI
++  give-error
  |=  [jon=json]
  :: ^-  [(list card) (map @t json)]
  ^-  action-result:plugin
  =/  effects
  :~  [%give %fact ~[/errors] %json !>(jon)]
  ==
  !<(action-result:plugin !>([success=%.n data=jon effects=effects]))
  :: :_  store
  :: :~  [%give %fact ~[/errors] %json !>(jon)]
  :: ==

++  send-api-error
  |=  [req=(pair @ta inbound-request:eyre) msg=@t]

  =/  =response-header:http
    :-  500
    :~  ['Content-Type' 'text/plain']
    ==

  ::  convert the string to a form that arvo will understand
  =/  data=octs
        (as-octs:mimes:html msg)

  :_  store
  :~
    [%give %fact [/http-response/[p.req]]~ %http-response-header !>(response-header)]
    [%give %fact [/http-response/[p.req]]~ %http-response-data !>(`data)]
    [%give %kick [/http-response/[p.req]]~ ~]
  ==

  ++  handle-scry
    |=  res-path=path
    ^-  (unit (unit cage))

    ::  remove /x/ballot part of path
    =/  segments  `(list @t)`(oust [0 1] res-path)
    =/  num-segments  (lent segments)

    :: assuming all paths start with /%x/<resource>/<action | key> means we need at least
    ::  3 segments  for this to be a valid path. aka we need at least one resource to
    ::  either lookup or take action on
    ?:  (lth (lent segments) 2)
        ``json+!>(s+'invalid path')
    ?>  ?=(%o -.store)
    =/  resource-store  (~(get by p.store) 'resources')
    ?~  resource-store
      ~&  >>>  "{<dap.bowl>}: invalid app state. no resources in store. crash."
      !!
    =/  resource-store  ((om json):dejs:format (need resource-store))

    =/  result=[idx=@ud last-seg=(unit @t) action=json]
      %-  roll
      :-  segments
      |:  [seg=`@t`~ curr=`[idx=@ud last-seg=(unit @t) action=json]`[0 ~ ~]]
      =/  action  ?~(action.curr ~ ((om json):dejs:format action.curr))
      =/  context  (~(get by action) 'context')
      =/  context  ?~(context ~ ((om json):dejs:format (need context)))
      ?:  =((add idx.curr 1) num-segments)
        =/  action  (~(put by action) 'action' s+seg)
        [(add idx.curr 1) (some seg) [%o action]]
      ?:  =((mod idx.curr 2) 1)
        :: odd
        =/  context  (~(put by context) (need last-seg.curr) s+seg)
        =/  action  (~(put by action) 'context' [%o context])
        [(add idx.curr 1) (some seg) [%o action]]
      :: even
      ?.  (~(has by resource-store) seg)  !!
      =/  action  (~(put by action) 'resource' s+seg)
      [(add idx.curr 1) (some seg) [%o action]]

    =/  action  ?~(action.result ~ ((om json):dejs:format action.result))
    =/  resource  (~(get by action) 'resource')
    ?~  resource  ``json+!>(s+'failed to resolve resource')
    =/  resource  (so:dejs:format (need resource))
    =/  action-name  (~(get by action) 'action')
    ?~  action-name  ``json+!>(s+'failed to resolve action')
    =/  action-name  (so:dejs:format (need action-name))
    =/  context  (~(get by action) 'context')
    =/  context  ?~(context ~ ((om json):dejs:format (need context)))
    =/  action  (~(put by action) 'data' ~)

    =/  lib-file=path  /(scot %p our.bowl)/(scot %tas dap.bowl)/(scot %da now.bowl)/lib/(scot %tas dap.bowl)/resources/(scot %tas resource)/(scot %tas action-name)/hoon

    ?.  .^(? %cu lib-file)
      ``json+!>(s+(crip "{<dap.bowl>}: resource action lib file {<lib-file>} not found"))

    =/  action-lib  .^([p=type q=*] %ca lib-file)
    =/  on-func  (slam (slap action-lib [%limb %on]) !>([bowl store context]))
    =/  result  !<(action-result:plugin (slam (slap on-func [%limb %action]) !>([%o action])))
    :: =/  result  ?~(result ~ (need result))

    ``json+!>(data.result)
    :: ``json+!>(?~(result ~ data.result))
--