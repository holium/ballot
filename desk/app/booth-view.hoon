::
::  %ballot %booths: the client side of the ballot app.
::
::    Usage:
::    |install ~bus %ballot
::    |rein %ballot [& %booth-view]
::  
::    :booth-view [%booth ~zod]
::    :booth-view [%leave-booth ~zod]
::
/-  booth-store, *group
/+  default-agent, dbug
|%
::
::  State 
::
+$  versioned-state
  $%  state-0
  ==
+$  state-0  [%0 state-0:booth-store]
::
+$  card  card:agent:gall
--
%-  agent:dbug
=|  state-0
=*  state  -
=<                                                              ::  =< "tisgal", needed to use gall to helper core section. Composes two expressions, inverted.
^-  agent:gall
|_  =bowl:gall
+*  this  .
    def   ~(. (default-agent this %.n) bowl)
    hc    ~(. +> bowl)                                          ::  helper cores
    :: io    ~(. agentio bowl)
::
++  on-init
  ^-  (quip card _this)
  `this
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
  ?>  =(src.bowl our.bowl)
  ?+    mark  (on-poke:def mark vase)
      %booth
    =/  request  !<(?(request:booth-store) vase)  :: request actions
    ?-    -.request
        %watch-booth                                       ::  :_ construct a cell, inverted.
      =/  ship          -.+.request
      =/  watch-type    +.+.request
      ?-    -.watch-type
          %ship
        :_  this 
        =/  wire           /ship/(scot %p ship)
        =/  path           /booth/(scot %p ship)
        :~  [%pass wire %agent [ship %booth-store] %watch path]
        ==
          %custom
        :_  this
        =/  bth-name      name.+.watch-type 
        =/  path          /booth/(scot %p ship)/[bth-name]
        :~  [%pass /(scot %p ship) %agent [ship %booth-store] %watch path]
        ==    
      ==

        %leave-booth
      =/  ship          -.+.request
      =/  watch-type    +.+.request
      ?-    -.watch-type
            %ship
          :_  this 
          ~&  >>  ['leaving ship booth']
          =/  wir           /booth/(scot %p ship)
          :~  [%pass wir %agent [ship %booth-store] %leave ~]
          ==  
            %custom
          :_  this 
          =/  bth-name      name.+.watch-type 
          =/  wir           /booth/(scot %p ship)/[bth-name]
          :~  [%pass wir %agent [ship %booth-store] %leave ~]
          ==
      ==
      :: :_  this                                       
      :: =/  booth-name    +.request
      :: =/  wir           /booth/(scot %p booth-name)
      :: :~  [%pass /booth-store %agent [+.request %booth-store] %leave ~]
      :: ==
    ==
  ==
::
++  on-watch  on-watch:def
++  on-leave  on-leave:def
++  on-peek   on-peek:def
++  on-agent
  |=  [=wire =sign:agent:gall]
  ^-  (quip card _this)
  ~&  >>  [wire]
  ?+    wire  (on-agent:def wire sign)
      [%ship @ ~]
    ?+    -.sign  (on-agent:def wire sign)
          %watch-ack
        ?~  p.sign
          ::  Watch was successful
          ~&  >>  [sign]
          ((slog '%booths: Subscribe succeeded!' ~) `this)
        ((slog '%booths: Subscribe failed!' ~) `this)
    ::
        %kick
      %-  (slog '%booths: Got kick, resubscribing...' ~)
      :_  this
      :~  [%pass /ballot %agent [src.bowl %booth-store] %watch /booth] :: %pass card is a request your agent initiates.
      ==
    ::
        %fact
        ?+    p.cage.sign  (on-agent:def wire sign)
            %booth-store-update
          =/  host     src.bowl
          =/  updated  !<(update:booth-store q.cage.sign)    :: +: returns the tail of the subject, -: would return the head
          ~&  >>  [updated]
          :: =/  new-state  `(map @p state-0:booth-store)`(~(put by state) [host +.updated])
          :: ~&  >>  [new-state]
          :: ~&  >>  [~ (~(put by +.state) [host +.updated])]

          :: ~&  >>  ['updated: ' (handle-incoming-updates:hc updated host)]
          :: ~&  !<(update:booth-store q.cage.sign)
          :: :~  [%pass /ballot %agent [src.bowl %booth-store] %watch /updates]
          :: `state(booths booths.updated)
          `this
          ::
            %booth-store-response
          =/  host     src.bowl
          =/  updated  !<(response:booth-store q.cage.sign)    :: +: returns the tail of the subject, -: would return the head
          ~&  >>  [-.updated]
          =/  updated-state  (handle-incoming-response:hc updated host)
          `this(state +.updated-state)
          
        ==
      :: [cards this]
    ==
  ==
::
++  on-arvo   on-arvo:def
++  on-fail   on-fail:def
--
::
::  Start helper cores
::
|_  bowl=bowl:gall
++  handle-incoming-response
  ::
  ::  updates state of a client ship watching a host's booth
  ::
  |=  [=response:booth-store host=@p]
  ^-  (quip card _state)
  =^  cards  state
  ?-    -.response
      %initial
    =/  bth               booth.+.response
    =/  bth-name          name.bth
    =.  booths.state  (~(put by booths.state) [bth-name bth])
    `state 
    ::
      %response-booth
    =/  bth               booth.+.response
    =/  bth-name          name.bth
    =.  booths.state  (~(put by booths.state) [bth-name bth])
    `state
    ::
      %response-proposal
    =/  bth-name           booth-name.+.response
    =/  prop               proposal.+.response
    =.  proposals.state  %+  ~(put by proposals.state)  bth-name
      %.  [title.prop prop]
      %~  put  by
      (~(gut by proposals.state) bth-name ~)
    `state
      :: %create-booth
      :: %booth
      :: %booths
      :: %proposals
      :: %ballots
  ==
  [cards state]
::
:: ++  handle-incoming-update
::   ::
::   ::  any action that triggers an update is handled here
::   ::
::   |=  [=response:booth-store host=@p]
::   ^-  (quip card _state)
::   =^  cards  state
::   ?-    -.response  
::     ::   %response-booth
::     :: =/  bth               booth.+.response
::     :: =/  bth-name          name.bth
::     :: =.  booths.state  (~(put by booths.state) [bth-name bth])
::     :: `state
::       :: %create-booth
::       :: %booth
::       :: %booths
::       :: %proposals
::       :: %ballots
::   ==
::   [cards state]
::
:: ++  sub-to-booth
::   |=  [request=request:booth-store host=ship group=group]
::   ^-  card
::   %-  some  group
::   =/  wir  /request-booth/(scot %p host)/
::   [%pass /booth-store %agent [host %booth-store] %watch /updates]

++  is-host
  ::
  :: checks to see if a ship is the host
  ::
  |=  [=ship]
  =(our.bowl ship)
::
--