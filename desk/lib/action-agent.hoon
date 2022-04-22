/-  plugin
/+  log=log-core
|%
+$  card  card:agent:gall
--

|_  [=bowl:gall store=(map @t json)]

++  poke
  |=  [=mark =vase]
  ^-  [(list card) (map @t json)]

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

++  set-authentication-mode
  |=  [mode=@t]
  %-  (slog leaf+"{<dap.bowl>}: setting authentication {<mode>}..." ~)
  `(~(put by store) 'authentication-mode' s+mode)

++  initialize
  |=  [jon=json]
  ^-  [(list card) (map @t json)]

  %-  (write:log "{<dap.bowl>}: {<dap.bowl>} initializing...")

  =/  config-file=path  /(scot %p our.bowl)/(scot %tas dap.bowl)/(scot %da now.bowl)/(scot %tas dap.bowl)/cfg

  ?.  .^(? %cu config-file)
    ~&  >>>  "{<dap.bowl>}: {<dap.bowl>} config file not found. create a /lib/{<dap.bowl>}/.cfg file and try again"
    `store

  =/  config  .^(json %cx config-file)
  =/  cfg  ((om json):dejs:format config)

  =/  log-level  (~(get by cfg) 'log-level')
  =/  log-level  ?~  log-level
    ~&  >>  "{<dap.bowl>}: log-level not found in config. defaulting to 0."
    0
  (ni:dejs:format (need log-level))

  =/  config-file=path  /(scot %p our.bowl)/(scot %tas dap.bowl)/(scot %da now.bowl)/(scot %tas dap.bowl)/resources/cfg

  ?.  .^(? %cu config-file)
    ~&  >>>  "{<dap.bowl>}: /lib/{<dap.bowl>}/resources config file not found. create a /lib/{<dap.bowl>}/resources/.cfg file and try again"
    `store

  =/  resources  .^(json %cx config-file)

  ~&  >  "{<dap.bowl>}: initialized"

  =/  action=json
  %-  pairs:enjs:format
  :~
    ['resource' s+dap.bowl]
    ['action' s+'initialize']
    ['context' ~]
    ['data' ~]
  ==

  :_  (~(put by store) 'resources' resources)

  :~  [%pass /(scot %tas dap.bowl) %agent [our.bowl dap.bowl] %poke %json !>(action)]
  ==

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
  ^-  [(list card) (map @t json)]

  =/  til=octs
        (tail body.request.q.req)

  ::  variable to hold request body (as $json)
  =/  payload  (need (de-json:html q.til))

  =/  result=[effects=(list card) state=(map @t json)]  (handle-resource-action payload)

  =/  =response-header:http
    :-  500
    :~  ['Content-Type' 'text/plain']
    ==

  ::  convert the string to a form that arvo will understand
  =/  data=octs
        (as-octs:mimes:html 'ok')

  :_  state.result
  :~
    [%give %fact [/http-response/[p.req]]~ %http-response-header !>(response-header)]
    [%give %fact [/http-response/[p.req]]~ %http-response-data !>(`data)]
    [%give %kick [/http-response/[p.req]]~ ~]
  ==

++  handle-resource-action-poke
  |=  [payload=json]
  ^-  [(list card) (map @t json)]

  (handle-resource-action payload)

++  handle-resource-action
  |=  [payload=json]
  ^-  [(list card) (map @t json)]

  ::  check store in state to ensure there's configured resources
  =/  resources  (~(get by store) 'resources')
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

  =+  c-ctx=`call-context:plugin`[bowl context store data]

  ?+  dispatch-mode  (send-error "{<dap.bowl>}: unrecognized dispatcher value" ~)

    %direct
      (execute-direct resource action c-ctx)

    %proxy
      (execute-by-proxy resource action c-ctx)

  ==

++  execute-direct
  |=  [resource=@t action=@t c=call-context:plugin]
  ^-  [(list card) (map @t json)]

  =/  lib-file=path  /(scot %p our.bowl)/(scot %tas dap.bowl)/(scot %da now.bowl)/lib/(scot %tas dap.bowl)/resources/(scot %tas resource)/(scot %tas action)/hoon

  ?.  .^(? %cu lib-file)
    (send-error "{<dap.bowl>}: resource action lib file {<lib-file>} not found" ~)

  =/  action-lib  .^([p=type q=*] %ca lib-file)
  =/  result=[effects=(list card) state=(map @t json)]  !<([(list card) (map @t json)] (slam (slap action-lib [%limb %run]) !>(c)))

  %-  (write:log "{<dap.bowl>}: committing store to agent state {<result>}...")

  :_  state.result

  effects.result

++  execute-by-proxy
  |=  [resource=@t action=@t c=call-context:plugin]
  ^-  [(list card) (map @t json)]

  =/  lib-file=path  /(scot %p our.bowl)/(scot %tas dap.bowl)/(scot %da now.bowl)/lib/(scot %tas dap.bowl)/resources/(scot %tas resource)/actions/hoon

  ?.  .^(? %cu lib-file)
    (send-error "{<dap.bowl>}: resource action lib file {<lib-file>} not found" ~)

  =/  action-lib  .^([p=type q=*] %ca lib-file)
  =/  on-func  (slam (slap action-lib [%limb %on]) !>([bowl.c store.c args.c]))
  =/  result=[effects=(list card) state=(map @t json)]  !<([(list card) (map @t json)] (slam (slap on-func [%limb action]) !>(payload.c)))

  %-  (write:log "{<dap.bowl>}: committing store to agent state {<result>}...")

  :_  state.result

  effects.result

::  send an error as poke back to calling agent
++  send-error
  |=  [reason=tape jon=json]
  ^-  [(list card) (map @t json)]
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
    :_  store
    :~  [%pass /errors %agent [src.bowl dap.bowl] %poke %json !>(payload)]
    ==
  (give-error payload)

::  use this for errors that should appear in UI
++  give-error
  |=  [jon=json]
  ^-  [(list card) (map @t json)]
  :_  store
  :~  [%give %fact ~[/errors] %json !>(jon)]
  ==

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
--