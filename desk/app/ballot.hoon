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
/+  store=group-store, default-agent, act=action-agent, dbug, resource, pill, log=log-core

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
    def   ~(. (default-agent this %.n) bowl)

++  on-init
  ^-  (quip card _this)

  %-  (write:log "{<dap.bowl>}: {<dap.bowl>} starting...")

  =/  result=[effects=(list card) state=(map @t json)]  (~(initialize act [bowl store.state]) ~)

  :_  this(store state.result)

  effects.result

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

  =/  result=[effects=(list card) state=(map @t json)]  (~(poke act [bowl store.state]) mark vase)

  :: ?+  mark  :_  this(store state.result)  effects.result

  ::   %initialize
  ::     (initialize-agent ~)
  :: ==

  :_  this(store state.result)  effects.result

++  on-watch
  |=  =path
  ^-  (quip card _this)

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