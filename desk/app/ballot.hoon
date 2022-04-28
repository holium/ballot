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
/-  *group, group-store, ballot-store, *plugin
/+  store=group-store, default-agent, act=action-agent, dbug, resource, pill, log=log-core

|%
+$  card  card:agent:gall
+$  versioned-state
  $%  state-0
  ==
::  'main' agent store is a tree (map) of stores
+$  state-0  [%0 store=json]
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

  =/  result=action-result  (~(initialize act [bowl store.state]) ~)

  ?:  success.result
    :_  this(store data.result)  effects.result
  :_  this  ~

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

  =/  result=[effects=(list card) state=json]  (~(poke act [bowl store.state]) mark vase)

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

  :: if there's two more path segments after the resource (e.g. delegate),
  ::   assume it's an action on a specific resource (e.g. delegate-key); however
  ::   if there's only a single segment after the resource, assume it's a "view"
  ::   action where the action is 'view-delegates'
  =/  result  (~(peek act [bowl store.state]) path)
  ?~  result  (on-peek:def path)

  result

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