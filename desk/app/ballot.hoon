::
::  @author  :  ~lodlev-migdev
::
::    -  manages direct http interface (API) used by the frontend UI
::    -  agent-to-agent communications (i.e. pokes, subscriptions, etc.)
::
::  Configurable/dynamic aspects of ballot:
::
::   - strategies - single-choice, multi-choice
::   - post voting results actions (e.g. boot member from group)
::   - security (e.g. pub/priv key signing, ring sig, etc...)
::
/-  *group, group-store, ballot-store
/+  store=group-store, default-agent, dbug, resource, pill, core=ballot-core

|%
+$  card  card:agent:gall
+$  versioned-state
  $%  state-0
  ==
::  'main' agent store is a tree (map) of stores
+$  state-0  [%0 authentication=@t store=(map @t json)]
--

%-  agent:dbug
=|  state-0
=*  state  -

^-  agent:gall
|_  =bowl:gall

+*  this  .
    def   ~(. (default-agent this %.n) bowl)

++  on-init
  ^-  (quip card _this)

  ?.  .^(? %cu /hol/ballot/cfg)
    %-  (log:core %error "ballot: ballot config file not found. create a /hol/ballot.cfg file and try again")
    `this

  =/  config  .^(json %cx /hol/ballot/cfg)
  =/  cfg  ((om json):dejs:format config)

  =/  resources  (~(get by cfg) 'resources')
  ?~  resources
    %-  (log:core %error "ballot: resources element not found. please fix the /hol/ballot.cfg file and try again")
    `this

  =/  resources  ((om json):dejs:format (need resources))

  =/  log-level  (~(get by cfg) 'log-level')
  =/  log-level  ?~  log-level
    %-  (log:core %warn "ballot: log-level not found in config. defaulting to 0.")
    0
  (ni:dejs:format (need log-level))


  ::  add resources this agent will support. load from config file?
  :: =|  resources=(map @t json)  ~

  :: =.  resources  (~(put by resources) 'booth' ~)
  :: =.  resources  (~(put by resources) 'proposal' ~)
  :: =.  resources  (~(put by resources) 'participant' ~)
  :: =.  resources  (~(put by resources) 'poll' ~)
  :: =.  resources  (~(put by resources) 'vote' ~)
  :: =.  resources  (~(put by resources) 'mq' ~)

  =/  effects=(list card)
  :~  [%pass /ballot %agent [our.bowl %ballot] %poke %initialize !>(~)]
      ::   setup route for direct http request/response handling
      [%pass /bind-route %arvo %e %connect `/'ballot'/'api'/'booths' %ballot]
  ==

  ::  send out cards to bind all resource agents
  =/  resource-effects=(list card)
        %-  ~(rep by resources)
          |=  [[p=@t q=json] acc=(list card)]
            (snoc acc [%pass /bind-resource %agent [our.bowl %ballot] %poke %bind !>(q)])

  :_  this(authentication 'enable', store store)

  (weld effects resource-effects)

::
++  on-save
  ^-  vase
  !>(state)

::
++  on-load
  |=  old-state=vase
  ^-  (quip card _this)
  =/  old  !<(versioned-state old-state)
  ?-  -.old
    %0  `this(state old)
  ==

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
          (initialize-booths ~)
        [cards this]

      :: %json can either come from eyre or direct agent pokes
      %json
        =^  cards  state
          =/  jon  !<(json vase)
          (handle-resource-action-poke jon)
        [cards this]

      :: direct http interface w/ eyre
      %handle-http-request
        =^  cards  state
          (on-http-request !<((pair @ta inbound-request:eyre) vase))
        [cards this]

    ==

    ++  set-authentication-mode
      |=  [mode=@t]
      %-  (slog leaf+"ballot: setting authentication {<mode>}..." ~)
      `state(authentication mode)

    ::
    ::  ARM:  ++  initialize-booths
    ::
    ::   Called when the agent is initialized (on-init). Perform
    ::     one-time initialization; mainly setting up the ship's default
    ::     booth and subscribing to the ship's group store to sync booths
    ::     with groups.
    ::
    ++  initialize-booths
      |=  [jon=json]

      %-  (slog leaf+"ballot: initializing..." ~)

      ::  initialization affects the booth and participant stores
      :: =/  booth-store  ((om json):dejs:format (~(got by store.state) 'booth'))
      :: =/  participant-store  ((om json):dejs:format (~(got by store.state) 'participant'))

      :: ::  add the default booth for our ship
      :: =/  owner  `@t`(scot %p our.bowl)
      :: ::  friendly epoch timestamp as cord
      :: =/  timestamp  (crip (en-json:html (time:enjs:format now.bowl)))

      :: =/  booth-key   (crip "{<our.bowl>}")
      :: =/  booth-name  (crip "{<our.bowl>}")

      :: ::  optional metadata to be associated with the booth
      :: =/  meta=json
      :: %-  pairs:enjs:format
      :: :~
      ::   ['tag' ~]
      :: ==

      :: =/  booth=json
      :: %-  pairs:enjs:format
      :: :~
      ::   ['type' s+'ship']
      ::   ['key' s+booth-key]
      ::   ['name' s+booth-name]
      ::   ['image' ~]
      ::   ['owner' s+owner]
      ::   ['created' s+timestamp]
      ::   ['policy' s+'invite-only']
      ::   ['status' s+'active']
      ::   ['meta' meta]
      :: ==

      :: =.  booth-store  (~(put by booth-store) booth-key booth)

      :: ::  add this ship as the default booth's owner and as a participant
      :: =/  participant-key  (crip "{<our.bowl>}")

      :: =/  participant=json
      :: %-  pairs:enjs:format
      :: :~
      ::   ['key' s+participant-key]
      ::   ['name' s+participant-key]
      ::   ['status' s+'active']
      ::   ['role' s+'owner']
      ::   ['created' s+timestamp]
      :: ==

      :: =|  participants=(map @t json)
      :: =.  participants  (~(put by participants) participant-key participant)

      :: =.  participant-store  (~(put by participant-store) booth-key participants)

      :: =/  new-store  (~(put by store.state) 'booth' booth-store)
      :: =/  new-store  (~(put by store.state) 'participant' participant-store)

      :: ~&  >  'ballot: context initialized!'

      :: :_  state(store new-store)

      :: :~  [%pass /ballot %agent [our.bowl %ballot] %watch /booths/(scot %tas booth-key)]
      ::     [%pass /group %agent [our.bowl %group-store] %watch /groups]
      :: ==

      `state

    ::
    ::  ARM:  ++  on-http-request
    ::
    ::   Called when http request received from Eyre. All actions come into
    ::    our agent as POST requests.
    ::
    ++  on-http-request
      |=  [req=(pair @ta inbound-request:eyre)]

      ?:  ?&  =(authentication.state 'enable')
              !authenticated.q.req
          ==
          ~&  >>>  "ballot: authentication is enabled. request is not authenticated"
          (send-api-error req 'not authenticated')

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

        (handle-resource-action payload)

      ++  handle-resource-action-poke
        |=  [payload=json]
        ^-  (quip card _state)

        (handle-resource-action payload)

      ++  handle-resource-action
        |=  [data=json]

        :: =/  payload  ((om json):dejs:format data)
        :: =/  context  ((om json):dejs:format (~(got by payload) 'context'))
        :: =/  action  (so:dejs:format (~(got by payload) 'action'))
        :: =/  resource  (so:dejs:format (~(got by payload) 'resource'))

        :: =/  handler  (~(get by handlers) (spat /(scot %tas resource)/(scot %tas action)))
        :: ?~  handler  (send-api-error req 'ballot: handler not found')
        :: =/  handler  ((om json):dejs:format (need handler))

        :: =/  stores  (~(get by store.handler) 'stores')
        :: ?~  stores  (send-api-error req 'ballot: handler stores not found')

        :: ::  intersect the handler stores map with ALL this agent's stores
        :: ::    what will be returned is only those entries that exist in both
        :: ::    maps with stores.state entries taking priority
        :: =/  stores  (~(int by stores) stores.state)

        :: =/  core  (~(get by core))

        :: =/  result=[effects=(list card) state=(map @t json)]
        ::       (~(on-action core [bowl stores]) payload)

        :: ::  update the store map with results from the action handler
        :: =/  stores  (~(int by stores.state) state.result)

        :: :_  state(stores stores)

        :: [effects.result]

        `state

      ::  send an error as poke back to calling agent
      ++  send-error
        |=  [jon=json]
        ::  ensure action: 'error' in json for this to be recognized
        ::   on the remote agent
        :_  state
        :~  [%pass /errors %agent [src.bowl %ballot] %poke %json !>(jon)]
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

        :_  state
        :~
          [%give %fact [/http-response/[p.req]]~ %http-response-header !>(response-header)]
          [%give %fact [/http-response/[p.req]]~ %http-response-data !>(`data)]
          [%give %kick [/http-response/[p.req]]~ ~]
        ==
    --

++  on-watch
  |=  =path
  ^-  (quip card _this)

  :: =/  watch  (~(get by watches.state) (spat path))
  :: ?~  watch  (send-api-error req 'ballot: watch not found')
  :: =/  watch  ((om json):dejs:format (need handler))

  :: =/  stores  (~(get by watch) 'stores')
  :: ?~  stores  (send-api-error req 'ballot: watch {<path>} stores not found')

  :: ::  intersect the handler stores map with ALL this agent's stores
  :: ::    what will be returned is only those entries that exist in both
  :: ::    maps with stores.state entries taking priority
  :: =/  stores  (~(int by stores) stores.state)

  :: =/  core  (~(get by core))

  :: =/  result=[effects=(list card) state=(map @t json)]
  ::       (~(on-watch core [bowl stores]) payload)

  :: ::  update the store map with results from the action handler
  :: =/  stores  (~(int by stores.state) state.result)

  :: :_  this(stores stores)

  :: [effects.result]

  `this

::
++  on-leave  on-leave:def

::
::  ARM:  on-peek
::
::   Scries
::    examples:
::
::       -  ~/scry/ballot/booths
::       -  ~/scry/ballot/booths/<key>/proposals
::
::  reference: https://urbit-org-j1prh9inz-urbit.vercel.app/docs/userspace/gall-guide/10-scry
::
++  on-peek
  |=  =path
  ^-  (unit (unit cage))

  %-  (slog leaf+"ballot: scry called with {<path>}..." ~)

  :: =/  scry  (~(get by scries.state) (spat path))
  :: ?~  scry  (send-api-error req 'ballot: scry not found')
  :: =/  scry  ((om json):dejs:format (need scry))

  :: =/  stores  (~(get by scry) 'stores')
  :: ?~  stores  (send-api-error req 'ballot: scry {<path>} stores not found')

  :: ::  intersect the handler stores map with ALL this agent's stores
  :: ::    what will be returned is only those entries that exist in both
  :: ::    maps with stores.state entries taking priority
  :: =/  stores  (~(int by stores) stores.state)

  :: =/  core  (~(get by core))

  :: =/  result=[effects=(list card) state=(map @t json)]
  ::       (~(on-scry core [bowl stores]) payload)

  :: ::  update the store map with results from the action handler
  :: =/  stores  (~(int by stores.state) state.result)

  :: :_  this(stores stores)

  :: [effects.result]

  ``json+!>(s+'not implemented')

::
++  on-agent
  |=  [=wire =sign:agent:gall]
  ^-  (quip card _this)

  =/  wirepath  `path`wire
  %-  (slog leaf+"ballot: on-agent {<wirepath>} data received..." ~)

  :: =/  wry  (~(get by wires.state) (spat path))
  :: ?~  wry  (send-api-error req 'ballot: scry not found')
  :: =/  wry  ((om json):dejs:format (need wry))

  :: =/  stores  (~(get by wry) 'stores')
  :: ?~  stores  (send-api-error req 'ballot: scry {<path>} stores not found')

  :: ::  intersect the handler stores map with ALL this agent's stores
  :: ::    what will be returned is only those entries that exist in both
  :: ::    maps with stores.state entries taking priority
  :: =/  stores  (~(int by stores) stores.state)

  :: =/  core  (~(get by core))

  :: =/  result=[effects=(list card) state=(map @t json)]
  ::       (~(on-wire core [bowl stores]) payload)

  :: ::  update the store map with results from the action handler
  :: =/  stores  (~(int by stores.state) state.result)

  :: :_  this(stores stores)

  :: [effects.result]

  `this

++  on-arvo
  |=  [=wire =sign-arvo]
  ^-  (quip card _this)
  ?.  ?=([%bind-route ~] wire)
    (on-arvo:def [wire sign-arvo])
  ?>  ?=([%eyre %bound *] sign-arvo)
  ?:  accepted.sign-arvo
    ~&  >  [wire sign-arvo]
    `this
    ~&  >>>  "ballot: binding route failed"
  `this

++  on-fail   on-fail:def
--