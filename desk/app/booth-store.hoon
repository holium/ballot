::
::  %ballot %booth-store: data store that holds proposals and ballots
::    
::    Usage:
::      %booth-store [%create-booth context]
::
::
/-  store=booth-store, *resource, *group                      ::  /- imports structures from /sur
/+  default-agent, dbug, bth-lib=booth-store, *mom            ::  /+ imports gates (functions) from /lib
|%                                                            ::  |% produces a core [battery, payload]
::
::  State 
::
+$  versioned-state
    $%  state-0
    ==
+$  state-0  [%0 base-state-0]
+$  base-state-0
  $:
    booths=booths:store
    proposals=proposals:store
    ballots=ballots:store
    :: watchers=(map proposal ship)   :: I believe I'm going to need to pull out the watchers
    :: delegates=(list [booth=booth-name delegate=ship])
  ==
::
+$  card  card:agent:gall
--
%-  agent:dbug                                                  ::  -% calls a gate (function).
=|  state-0                                                     ::  =| combines a default type value with the subject.
=*  state  -                                                    ::  set name state as state-0
=<
^-  agent:gall                                                  ::  ^- typecasts by explicit type label. It's a good practice to put it at the top of every arm (including gates, loops, etc)
|_  =bowl:gall                                                  ::  |_ produces a door (a core with a sample
+*  this  .                                                     ::  +* defines aliases within doors.
    def   ~(. (default-agent this %|) bowl)
    hc    ~(. +> bowl)                                          ::  helper cores
::
++  on-init
  ^-  (quip card _this)
  ~&  >  '%booth-store started successfully'
  =/  initial-state  (init-state:hc our.bowl now.bowl)          ::  generate the initial booths for your ship and groups
  =.  state  initial-state                                      ::  set initial state
  :-  ~  this 
::
++  on-save                                                     ::  Handles exporting an agent's state. Part of upgrading, suspending, uninstalling, etc. 
  ^-  vase
  !>(state)                                                     ::  Wraps the state in a type and saves state.
::
++  on-load                                                     ::  Handles loading a previously exported agent state.
  |=  old-state=vase
  ^-  (quip card _this)
  ~&  >  '%booth-store recompiled successfully'
  `this(state !<(versioned-state old-state))
::  
++  on-watch
  ::
  ::  The various paths of the booth-store:
  ::    
  ::    /ballot/~bus/booth/~zod
  ::    /ballot/~bus/booth/~zod/proposals                when the host creates new proposals the invitees are notified here
  ::    /ballot/~bus/booth/~zod/proposals/proposal-name  participants will send their ballots and it will be updated at the proposal level  
  ::    /ballot/~bus/booth/~zod/new-booth/proposals
  ::    /ballot/~bus/booth/~zod/groups/group-1/proposals        when the host creates new group proposals the participants is notified here
  ::
  ::  In the future, we will have a DAO context level:
  ::    
  ::    /ballot/~bus/booth/~zod/dao/mars-one
  ::    /ballot/~bus/booth/~zod/dao/mars-one/proposals
  ::
  |=  =path
  ^-  (quip card _this)
  =/  cards=(list card)
  ~&  >  path
    ?+  path        (on-watch:def path)
      ::  When a client requests a booth, we will return a fact.
       [%booth @ ~]  
      =/  booth-name     `@p`(slav %p i.t.path)                     :: get booth-name, todo should check if it's @p, group, or dao
      =/  requestor       src.bowl
      =/  bth             (~(got by booths.state) booth-name)  
      ?<  (is-host:hc src.bowl)                                     ::  don't watch self, ?< negative assertion
      ?>  (is-allowed:bth-lib requestor our.bowl policy.bth)        ::  Check if requestor is invited, ?> positive assertion.
      :: ~&  >  (get-proposals-by-ship:hc booth-name requestor)
          :: ~|("tried to watch booth we don't have access to" !!)
      [%give %fact ~ %booth-store-response !>(`response:store`[%initial host=our.bowl booth=bth])]~

      ::  TODO handle not-invited better
      :: [%give %fact ~ %booth-store-response !>(`response:store`[%response-booth host=our.bowl booth=bth])]~
      :: 
      ::  /booth/~zod/*
      ::
      ::   [%booth @ *]
      :: ?+  t.t.path  (on-watch:def path)
      :: ::     ::
      :: ::     ::  /booth/~zod
      :: ::     ::
      ::     [@ ~] :: give the current state of a booth
      ::       =/  custom-booth      i.t.path
      ::       =/  bth  (~(got by booths.state) custom-booth)
      ::       [%give %fact ~ %booth-store-response !>([%booth bth])]~
      ::     ::
      :: ::     ::  /booth/~zod/proposal
      :: ::     ::
      ::     [%groups ~]
      ::     =/  booth-name     `@p`(slav %p i.t.path) 
      ::     =/  bth             (~(got by booths.state) booth-name)               
      ::       [%give %fact ~ %new-booth !>([%booth bth])]~
      :: ==
      ::     ::
      ::     ::  /booth/~zod/received-ballot
      ::     ::
      ::     :: [%received-ballot ~]
      ::     ::   [%give %fact ~ %ballot-received !>([%booth bth])]~
      ::     ==
    ==  
  [cards this]
::
++  on-poke
  ::
  ::
  ::
  |=  [=mark =vase]
  ^-  (quip card _this)
  =^  cards  state
  ?+  mark  (on-poke:def mark vase)
    ::
    ::  %booth actions
    ::
    ::  Usage: 
    ::    :booth-store &booth [%add-to-booth ~zod ~bus]
    ::    :booth-store &proposal [%add-proposal [...proposal]]
    ::    :booth-store &vote [%add-ballot [...ballot]]
    ::
        %booth
    ?>  (is-host:hc src.bowl)
    =/  booth-action  !<(booth-action:store vase)           ::  =/ combines a named noun with the subject, possibly with type annotation.
    (handle-booth-action:hc booth-action)
    ::
        %proposal
    ?>  (is-host:hc src.bowl)                               :: TODO if they are a group admin, they can revise a proposal
    =/  proposal-action  !<(proposal-action:store vase)
    (handle-proposal-action:hc proposal-action)
    ::
    ::     %vote
    :: =/  vote-action  !<(vote-action:store vase)
    :: (handle-vote-action:hc vote-action)
  ==
  [cards this]
::
++  on-peek  on-peek:def              ::  Handles scries
++  on-arvo   on-arvo:def             ::  Handles subscription updates, request acknowledgements, and responses from vanes.
++  on-agent  on-agent:def            ::  Handles subscription updates and request acknowledgements from other agents.
++  on-leave                          ::  Handles unsubscribe requests from other, currently subscribed entities.
  |=  =path
  ^-  (quip card _this)
  ~&  >>  ["Unsubscribe by:" src.bowl "on:" path]
  `this
::
++  on-fail   on-fail:def             ::  Handles certain kinds of crash reports from Gall.
--
::
::  Start helper cores
::
|_  bowl=bowl:gall
++  handle-booth-action
  |=  [=booth-action:store]
  ^-  (quip card _state)
  =^  cards  state
  ?>  (is-host src.bowl)
  ?-    -.booth-action      ::  Will throw an error if the poke is invalid.
  ::
  ::  %create-booth: creates a new booth with an empty proposals list.
  ::   
  ::    Usage: [%create-booth booth-name=%test-booth booth-policy=[%invited ships=`(set @p)`(sy ~[~zod])]]
  ::
  ::    only used for testing for now, all other booths should be generated
  ::
      %create-booth                 
    =/  bth-name            booth-name.booth-action
    =/  policy              booth-policy.booth-action
    =/  ship                our.bowl
    =/  created-at          now.bowl
    `state(booths (~(put by booths.state) [bth-name [name=bth-name policy=policy created-at=created-at]]))
    ::
    ::  %edit-booth: edit the booth metadata.
    ::  TODO expand values to edit
    ::
      %edit-booth
    =/  bth-name            booth-name.booth-action
    =/  policy              booth-policy.booth-action
    =/  ship                our.bowl
    =/  updated-at          now.bowl
    =/  updated-booths      booths.state
    =/  booth               (~(got by booths.state) bth-name)
    =/  updated-booth       booth(policy policy)
    =.  booths.state        (~(put by booths.state) bth-name updated-booth)
    :_  state
    :~  :*  %give  %fact
            ~[/booth/(scot %p bth-name)]
            [%booth-store-response !>([%response-booth ship updated-booth])]
        ==
    == 
    ::
    ::  %remove-booth: totally removes a booth from state.
    ::
    ::    Only the host can remove a booth. The host cannot remove their 'base-booth'.
    ::    A 'base-booth' would be ~zod
    ::
    ::    Usage: [%remove-booth booth-name=%test-booth]
    ::
      %remove-booth
    =/  bth-name            booth-name.booth-action
    =/  is-owner            our.bowl   
    =.  booths.state        (~(del by booths.state) bth-name)
    :_  state
    :~  :*  %give  %kick
            ~[/booth/(scot %p bth-name)]
            ~
        ==
    ==    
    :: 
    ::  %add-to-booth: adds a ship to a booth as a watcher.
    ::
    ::    Usage: :booth-store &booth [%add-to-booth ~zod ~bus]
    ::
      %add-to-booth
    =/  bth-name          booth-name.booth-action
    =/  is-owner          our.bowl
    =/  bth               (~(got by booths.state) bth-name)
    =/  policy            policy.bth
    =/  ship              ship.booth-action
    ?+    -.policy
        `state
        %invited
      =/  updated-booths  %+  ~(jab by booths)  ::  jab: produce map a with the value at key b ... a way to update nested values
            bth-name
          |=(=booth:store booth(policy [%invited ships=(~(put in ships.+.policy) ship)]))                 
      `state(booths updated-booths)
      ::
    ==
    ::
    ::  %kick-from-booth: kicks a ship from watching a booth
    ::
    ::    Usage: :booth-store :booth-store &booth [%kick-from-booth ~zod ~bus]
    ::
      %kick-from-booth
    =/  bth-name          booth-name.booth-action
    =/  bth               (~(got by booths.state) bth-name)
    =/  policy            policy.bth
    =/  ship              ship.booth-action
    ?<  (is-host ship)                                       ::  Don't kick self
    ?+    -.policy                                                  ::  ?+ branch with a default
        `state  :: default
        %invited
      =/  updated-booths  %+  ~(jab by booths)
              bth-name
            |=(=booth:store booth(policy [%invited ships=(~(del in ships.+.policy) ship)]))                 
      
      :_  state(booths updated-booths)
      :~  :*  %give  %kick
            ~[/booth/(scot %p bth-name)]
            `ship
        ==
      ==
    ==
  ==
  [cards state]
::
++  handle-proposal-action
  |=  =proposal-action:store
  ^-  (quip card _state)
  =^  cards  state
  ?>  (is-host src.bowl)
  ?-    -.proposal-action     ::  Will throw an error if the poke is invalid.
  ::
  ::  %add-proposal: creates a new booth with an empty proposals map.
  ::  
  ::    Usage:
  ::      :booth-store &proposal [%add-proposal ~zod 'Proposal 1']
  ::
      %add-proposal                 
    =/  bth-name            booth-name.proposal-action
    =/  prop-title          title.proposal-action
    =/  ship                our.bowl
    =/  created-at          now.bowl
    =/  new-proposal        (default-proposal bth-name prop-title)
    ::  Nested map put
    =.  proposals.state  %+  ~(put by proposals.state)  bth-name
      %.  [prop-title new-proposal]
      %~  put  by
      (~(gut by proposals.state) bth-name ~)
    :: =/  test                (~(get by (~(gut by proposals.state) bth-name ~)) prop-title) ::[bth-name [prop-title (default-proposal bth-name prop-title)]]
    :_  state
    :~  :*  %give  %fact
            ~[/booth/(scot %p bth-name)]
            [%booth-store-response !>([%response-proposal ship bth-name new-proposal])]
        ==
    == 
    ::  %revise-proposal
          :: =/  test                (~(get by (~(gut by proposals.state) bth-name ~)) prop-title) ::[bth-name [prop-title (default-proposal bth-name prop-title)]]

    :: `state(proposals (~(put by proposals.state) [[bth-name prop-title] (default-proposal bth-name prop-title)]))
    ::
    ::  %remove-proposal: removes a proposal from the proposal map.
    ::                    can only remove if not published
    ::  
    ::    Usage:
    ::      :booth-store &proposal [%remove-proposal ~zod 'Proposal 1']
    ::
      %remove-proposal                 
    =/  bth-name            booth-name.proposal-action
    =/  prop-title          title.proposal-action
    =/  ship                our.bowl
    =/  created-at          now.bowl
    :: =/  proposal            (~(got by proposals.state) [bth-name prop-title])
    :: ?:  (is-active:bth-lib proposal)
      :: `state(proposals (~(del by proposals.state) [bth-name prop-title]))
    ~&  >  'Proposal is active, cannot delete.'
    `state

    ::
      %revise-proposal
    `state
    ::
      %add-voters
    `state
    ::
      %remove-voters
    `state
  ==
  [cards state]
::
:: ++  handle-vote-action
::   |=  =vote-action:store
::   ^-  (quip card _state)
::   =^  cards  state
::   ?>  (is-host src.bowl)
::   ?-    -.vote-action       ::  Will throw an error if the poke is invalid.
::   ::
::   ::  %add-proposal: creates a new booth with an empty proposals list.
::   ::  
::   ::
::       %add-ballot                 
::     =/  bth-name            booth-name.vote-action
::     =/  prop-title          proposal-title.vote-action
::     =/  new-ballot          ballot.vote-action
::     =/  ship                our.bowl
::     =/  created-at          now.bowl
::     :: =/  prop-ballots        (~(get by (~(get by ballots.state) bth-name) prop-title))
::     ~>  %bout
::     :: ~&  >>  [props-ballots]
::     :: TODO check if vote has already been sent, cannot double vote
::     :: `state
::     :: `state(ballots (~(put by ballots.state) [[bth-name prop-title src.bowl] new-ballot]))
::     ::
::     ::   %remove-proposal                 
::     :: =/  bth-name            booth-name.proposal-action
::     :: =/  prop-title          title.proposal-action
::     :: =/  ship                our.bowl
::     :: =/  created-at          now.bowl
::     :: `state(proposals (~(del by proposals.state) [bth-name title.new-proposal]))
::   ==
::   [cards state]
::
:: ++  handle-update
::   |=  =update:store
::   ^-  (quip card _state)
::   =^  cards  state
::   ?>  (is-host src.bowl)
::   ~&  >>  [update]
::   ?+  -.update  ~|(%bad-poke !!)      ::  Will throw an error if the poke is invalid.

::   ::
::   ::  %booths: returns the list of booths, proposals, and ballots
::   ::
::   ::
::       [%booths ~]              
::     [%give %fact ~ %booth-store-update !>(`update:store`[%initial booths=booths.state proposals=proposals.state ballots=ballots.state])]~
::   ==
::   [cards state]
::
++  is-host
  ::
  ::  is-host: checks to see if a ship is the host
  ::
  |=  [=ship]
  =(our.bowl ship)
++  init-state                            ::  initializes the state to the most recent version 
  |=  [=ship now=time]
  =/  default-booth
    [
      name=ship 
      policy=[%public ~] 
      created-at=`time`now
    ]
  =/  initial-booths  `(map booth-name:store booth:store)`(~(put by booths.state) [ship default-booth])
  [%0 booths=initial-booths proposals=[~] ballots=[~]]
::
++  default-proposal                      ::  when a proposal is created, it needs empty values
  |=  [=booth-name:store title=@t]
  =/  proposal  
    [
      title=title
      body=''
      strategy=%single-choice
      tag='draft'
      published=%.n
      hide-individual-vote=%.y
      choices=[~]
      invitees=`(set @p)`(sy ~[our.bowl])
      start=now.bowl
      end=now.bowl
      created-by=our.bowl
      created-at=now.bowl
    ]
  `proposal:store`proposal
::
++  get-proposals-by-ship
  |=  [=booth-name:store ship=ship] 
  =/  props         ~(tap by proposals.state)
  :: ~&  >>  [(~(jab by -.p.props) %z |=(x=@ (pow x 2)))]
  ['bth']
  :: ==
  :: [cards state]
--