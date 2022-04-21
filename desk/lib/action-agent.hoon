/+  skeleton, log=log-core
|%
+$  card  card:agent:gall
+$  versioned-state
  $%  state-0
  ==
::  'main' agent store is a tree (map) of stores
+$  state-0  [%0 store=(map @t json)]
--
|*  [agent=* help=*]
?:  ?=(%& help)
  ~|  %default-agent-helpfully-crashing
  skeleton
%-  agent:dbug
=|  state-0
=*  state  -

^-  agent:gall
|_  =bowl:gall
++  on-init
  `agent
::
++  on-save
  !>(~)
::
++  on-load
  |=  old-state=vase
  `agent
::
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)

  |^

  ?+  mark  (on-poke:def mark vase)

      %auth
        =^  cards  state
          =/  val  !<(@t vase)
          (set-authentication-mode val)
        [cards this]

      %initialize
        =^  cards  state
          (initialize ~)
        [cards agent]

      :: %json can either come from eyre or direct agent pokes
      %json
        =^  cards  state
          =/  jon  !<(json vase)
          (handle-resource-action-poke jon)
        [cards agent]

      :: direct http interface w/ eyre
      %handle-http-request
        =^  cards  state
          (on-http-request !<((pair @ta inbound-request:eyre) vase))
        [cards agent]

    ==

    ++  set-authentication-mode
      |=  [mode=@t]
      %-  (slog leaf+"{<dap.bowl>}: setting authentication {<mode>}..." ~)
      :: `state(authentication mode)
      `agent

    ::
    ::  ARM:  ++  initialize-booths
    ::
    ::   Called when the agent is initialized (on-init). Perform
    ::     one-time initialization; mainly setting up the ship's default
    ::     booth and subscribing to the ship's group store to sync booths
    ::     with groups.
    ::
    ++  initialize
      |=  [jon=json]

      =/  config-file=path  /(scot %p our.bowl)/(scot %tas dap.bowl)/(scot %da now.bowl)/cfg/(scot %tas dap.bowl)/json

      %-  (write:log "{<dap.bowl>}: {<dap.bowl>} initializing...")

      ?.  .^(? %cu config-file)
        ~&  >>>  "{<dap.bowl>}: {<dap.bowl>} config file not found. create a /cfg/{<dap.bowl>}.json file and try again"
        `agent

      =/  config  .^(json %cx config-file)
      =/  cfg  ((om json):dejs:format config)

      =/  action-endpoint  (~(get by cfg) 'action-endpoint')
      ?~  action-endpoint
        ~&  >>>  "{<dap.bowl>}: action-endpoint not found. please fix the /cfg/{<dap.bowl>}.json file and try again"
        `agent
      =/  action-endpoint  `(list @t)`(stab (so:dejs:format (need action-endpoint)))

      =/  resources  (~(get by cfg) 'resources')
      ?~  resources
        ~&  >>>  "{<dap.bowl>}: resources element not found. please fix the /cfg/{<dap.bowl>}.json file and try again"
        `agent

      =/  resources  (need resources)

      =/  log-level  (~(get by cfg) 'log-level')
      =/  log-level  ?~  log-level
        ~&  >>  "{<dap.bowl>}: log-level not found in config. defaulting to 0."
        0
      (ni:dejs:format (need log-level))

      :_  agent

      :~
          ::  setup route for direct http request/response handling
          [%pass /bind-route %arvo %e %connect action-endpoint dap.bowl]
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
      ::     ~&  >>>  "ballot: authentication is enabled. request is not authenticated"
      ::     (send-api-error req 'not authenticated')

      :: parse query string portion of url into map of arguments (key/value pair)
      =/  req-args
            (my q:(need `(unit (pair pork:eyre quay:eyre))`(rush url.request.q.req ;~(plug apat:de-purl:html yque:de-purl:html))))

      %-  (slog leaf+"ballot: [on-poke] => processing request at endpoint {<(stab url.request.q.req)>}" ~)

      =/  path  (stab url.request.q.req)

      ::  all actions come in as POST method requests over http
      ?+    method.request.q.req  (send-api-error req 'unsupported')

            %'POST'

              ?+  path  (send-api-error req 'route not found')

                [%ballot %api %booths ~]
                  (handle-resource-action-http req req-args)

              ==
      ==

      ::
      ::  ARM:  ++  handle-resource-action
      ::
      ::   All actions funnel thru this arm. They come into Eyre as http
      ::     POST method requests.
      ::
      ++  handle-resource-action-http
        |=  [req=(pair @ta inbound-request:eyre) args=(map @t @t)]
        ^-  (quip card _state)

        =/  til=octs
              (tail body.request.q.req)

        ::  variable to hold request body (as $json)
        =/  payload  (need (de-json:html q.til))

        =/  result  (handle-resource-action payload)

        =/  =response-header:http
          :-  500
          :~  ['Content-Type' 'text/plain']
          ==

        ::  convert the string to a form that arvo will understand
        =/  data=octs
              (as-octs:mimes:html 'ok')

        :_  agent
        :~
          [%give %fact [/http-response/[p.req]]~ %http-response-header !>(response-header)]
          [%give %fact [/http-response/[p.req]]~ %http-response-data !>(`data)]
          [%give %kick [/http-response/[p.req]]~ ~]
        ==

      ++  handle-resource-action-poke
        |=  [payload=json]
        ^-  (quip card _state)

        (handle-resource-action payload)

      ++  handle-resource-action
        |=  [payload=json]

        ::  check store in state to ensure there's configured resources
        =/  resources  (~(get by store.state) 'resources')
        ?~  resources  (send-error "{<dap.bowl>}: invalid agent state. missing resources" ~)
        =/  resources  ((om json):dejs:format (need resources))

        ::  do some initial validation
        =/  action-payload  ((om json):dejs:format payload)

        =/  context  (~(get by action-payload) 'context')
        ?~  context  (send-error "{<dap.bowl>}: invalid payload. missing context element" ~)
        =/  context  ((om json):dejs:format (need context))

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

        =/  lib-file=path  /(scot %p our.bowl)/(scot %tas dap.bowl)/(scot %da now.bowl)/lib/(scot %tas dap.bowl)/resources/(scot %tas resource)/actions/hoon

        ?.  .^(? %cu lib-file)
          (send-error "{<dap.bowl>}: resource action lib file {<lib-file>} not found" ~)

        =/  action-lib  .^([p=type q=*] %ca lib-file)
        =/  on-func  (slam (slap action-lib [%limb %on]) !>([bowl resource-store context]))
        =/  action-result=[effects=(list card) state=(map @t json)]  !<([(list card) (map @t json)] (slam (slap on-func [%limb action]) !>(data)))

        %-  (write:log "{<dap.bowl>}: committing store to agent state {<state.action-result>}...")

        `agent :: (store (~(put by store.state) resource [%o (tail action-result)]))

      ::  send an error as poke back to calling agent
      ++  send-error
        |=  [reason=tape jon=json]
        ~&  >>>  tape
        ::  if json is null, send back reason error as json string
        =/  payload=json  ?~  jon
              ::  then
              s+(crip reason)  :: send back reason error as string
            :: else stuff payload with error message
            %-  pairs:enjs:format
            :~
              ['error' s+(crip reason)]
            ==
        ::  ensure action: 'error' in json for this to be recognized
        ::   on the remote agent
        :_  agent
        :~  [%pass /errors %agent [src.bowl %ballot] %poke %json !>(payload)]
        ==

      ::  use this for errors that should appear in UI
      ++  give-error
        |=  [jon=json]
        :_  state
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

        :_  agent
        :~
          [%give %fact [/http-response/[p.req]]~ %http-response-header !>(response-header)]
          [%give %fact [/http-response/[p.req]]~ %http-response-data !>(`data)]
          [%give %kick [/http-response/[p.req]]~ ~]
        ==
    --
::
++  on-watch
  |=  =path
  ~|  "unexpected subscription to {<dap.bowl>} on path {<path>}"
  !!
::
++  on-leave
  |=  path
  `agent
::
++  on-peek
  |=  =path
  ~|  "unexpected scry into {<dap.bowl>} on path {<path>}"
  !!
::
++  on-agent
  |=  [=wire =sign:agent:gall]
  ^-  (quip card:agent:gall _agent)
  ?-    -.sign
      %poke-ack
    ?~  p.sign
      `agent
    %-  (slog leaf+"poke failed from {<dap.bowl>} on wire {<wire>}" u.p.sign)
    `agent
  ::
      %watch-ack
    ?~  p.sign
      `agent
    =/  =tank  leaf+"subscribe failed from {<dap.bowl>} on wire {<wire>}"
    %-  (slog tank u.p.sign)
    `agent
  ::
      %kick  `agent
      %fact
    ~|  "unexpected subscription update to {<dap.bowl>} on wire {<wire>}"
    ~|  "with mark {<p.cage.sign>}"
    !!
  ==
::
++  on-arvo
  |=  [=wire =sign-arvo]
  ~|  "unexpected system response {<-.sign-arvo>} to {<dap.bowl>} on wire {<wire>}"
  !!
::
++  on-fail
  |=  [=term =tang]
  %-  (slog leaf+"error in {<dap.bowl>}" >term< tang)
  `agent
--
