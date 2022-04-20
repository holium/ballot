::
::  @author  :  ~lodlev-migdev
::
::    -  base action agent with shared functionality/features
::    -  manages direct http interface (API) used by the frontend UI
::    -  agent-to-agent communications (i.e. pokes, subscriptions, etc.)
::
/+  default-agent, dbug, resource, pill

|%
+$  card  card:agent:gall
+$  versioned-state
  $%  state-0
  ==
::  'main' agent store is a tree (map) of stores
+$  state-0  [%0 store=(map @t json)]
--

%-  agent:dbug
=|  state-0
=*  state  -

^-  agent:gall
|_  =bowl:gall

+*  this  .
    def   ~(. (action-agent this %.n) bowl)

::
++  on-init  (on-init:def)
::
++  on-save  (on-save:def)
::
++  on-load  (on-load:def)
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

    ==

    ++  set-authentication-mode
      |=  [mode=@t]
      %-  (slog leaf+"ballot: setting authentication {<mode>}..." ~)
      :: `state(authentication mode)
      `state

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
        |=  [payload=json]

        ::  check store in state to ensure there's configured resources
        =/  resources  (~(get by store.state) 'resources')
        ?~  resources  (send-error "{<dap.bowl>}: invalid agent state. missing resources" ~)
        =/  resources  ((om json):dejs:format (need resources))

        ::  do some initial validation
        =/  action-payload  ((om json):dejs:format payload)

        =/  context  (~(get by action-payload) 'context')
        ?~  context  (send-error "{<dap.bowl>}: invalid payload. missing context element" ~)

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

        ::  is this an action or a reaction?  :: 9 => length of "-reaction"
        =/  chars  (trip action)
        =/  idx  (sub (lent chars) 9)
        =/  result  ?:  =((slag idx chars) "-reaction")
                =/  action  (oust [0 (sub idx 1)] chars)
                (on-reaction context resource-store action data)
              (on-action context resource-store action data)

        ::  commit changes to store
        :_  state(store (~(put by store.state) resource [%o state.result]))

        ::  send out effects (gifts, pokes, etc.)
        :~  effects.result
        ==

      ++  on-action  (on-action:action-agent context store resource action data)

      ++  on-reaction  (on-reaction:action-agent context store resource action data)

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
        :_  state
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

::  scries
++  on-peek
  |=  =path
  ^-  (unit (unit cage))

  |^

  %-  (slog leaf+"ballot: scry called with path => {<path>}..." ~)

  =/  root  (~(get by store.state) 'resources')
  ?~  root
    ~&  >>>  "{<dap.bowl>}: invalid agent state"
    !!
  =/  root  (need root)

  =/  item=json  (find-node `(list @tas)`path root)

  ?~  item  ``json+!>(s+'not found')
  =/  item  ((om json):dejs:format item)
  =/  tag  (~(get by item) 'tag')
  ?~  tag  ``json+!>(s+'invalid resource. missing tag.')
  =/  tag  (so:dejs:format (need tag))

  ?+  tag  ``json+!>(s+'unrecognized tag')

    %f  :: file
      =/  data  (~(get by item) 'data')
      ?~  data  ``json+!>(s+'invalid state')
      =/  data  (need data)
      ``json+!>(data)

    %d  :: directory
      ``json+!>([%a ~(val by item)])

  ==

  ++  find-node
    |=  [items=(list @tas) node=json]
      ^-  json
      |-
        ?:  ?|  =(0 (lent items))
                =(~ node)
            ==
            node
          =/  next-key  (snag 0 items)
          =/  next-node  ((om json):dejs:format node)
          =/  next-node  (~(get by next-node) next-key)
          $(items (oust [0 1] items), node (need next-node))
  --

::
++  on-agent
  |=  [=wire =sign:agent:gall]
  ^-  (quip card _this)

  =/  wirepath  `path`wire
  %-  (slog leaf+"ballot: on-agent {<wirepath>} data received..." ~)

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

++  on-action
  |=  [context=(map @t json) store=(map @t json) resource=@t action=@t data=json]
  ^-  [(list card) (map @t json)]

  =/  lib-file=path  /(scot %p our.bowl)/(scot %tas dap.bowl)/(scot %da now.bowl)/lib/(scot %tas dap.bowl)/resources/(scot %tas resource)/actions/hoon
  ?.  .^(? %cu lib-file)
    (send-error "{<dap.bowl>}: resource action lib file {<lib-file>} not found" ~)
  =/  action-lib  .^([p=type q=*] %ca lib-file)
  (slam (slam (slap action-lib [%limb action]) !>([action data])) !>([bowl=bowl store=store context=context]))

++  on-reaction
  |=  [context=(map @t json) store=(map @t json) resource=@t action=@t data=json]

  =/  lib-file=path  /(scot %p our.bowl)/(scot %tas dap.bowl)/(scot %da now.bowl)/lib/(scot %tas dap.bowl)/resources/(scot %tas resource)/effects/hoon
  ?.  .^(? %cu lib-file)
    (send-error "{<dap.bowl>}: resource effects lib file {<lib-file>} not found" ~)
  =/  effects-lib  .^([p=type q=*] %ca lib-file)

  =/  result  %-  roll
    :-  effects
    |:  [effect=`json`~ acc=`[@f json]`[%.n ~]]
    ?:  -.acc
      =/  effect-data  ((om json):dejs:format effect)
      =/  effect  (so:dejs:format (~(got by effect-data) 'effect'))
      (slam (slam (slap effects-lib [%limb effect]) !>([effect-data])) !>([bowl=bowl store=resource-store context=context]))
    acc

  result
