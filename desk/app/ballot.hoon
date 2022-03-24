:: ***********************************************************
::
::  @author  : ~lodlev-migdev (p.james)
::  @purpose :
::    Ball app agent for contexts, booths, proposals, and participants.
::
:: ***********************************************************
/-  *group, group-store, ballot-store
/+  store=group-store, default-agent, dbug, resource, pill, util=ballot-util, core=ballot-core, reactor=ballot-booth-reactor
|%
+$  card  card:agent:gall
+$  versioned-state
  $%  state-0
  ==
+$  state-0  [%0 polls=(map @t (map @t json)) booths=booths:ballot-store proposals=proposals:ballot-store participants=participants:ballot-store mq=mq:ballot-store invitations=invitations:ballot-store votes=(map @t (map @t json))]
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

  :: *************************************************************
  ::  WARNING: DO NOT REMOVE THIS CODE
  ::
  :: @~lodlev-migdev - this code is used to compile/load a lib at runtime
  :: =/  lb=vase  .^(vase %ca /~zod/base/(scot %da now.bowl)/lib/ps-lib/hoon)

  :: @~lodlev-migdev - here we see how to call a method (arm - %limb) in the lib
  ::    using Hoon slam/slap. Note: %say-hi is the name of the arm. In this
  ::    case the say-hi method takes a string as input and echoes the string
  ::    back to the caller as the return value (stored in rs)
  :: =/  rs  (slam (slap lb [%limb %say-hi]) !>('hello from runtime lib!'))
  ::  @p.names - print return value (string in this case)
  ::    ~&  >>  rs
  ::  END OF RUNTIME LIB LOADING BLOCK
  :: *************************************************************

  :_  this

      ::  initialize agent booths (ship, groups, etc...)
  :~  [%pass /ballot %agent [our.bowl %ballot] %poke %initialize !>(~)]
      ::  our ship can watch across all booths
      :: [%pass /booths %agent [our.bowl %ballot] %watch /booths]
      ::   setup route for direct http request/response handling
      [%pass /bind-route %arvo %e %connect `/'ballot'/'api'/'booths' %ballot]
  :: ==
  ==

  :: `this

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
  :: ~&  [mark vase]
  ?+    mark  (on-poke:def mark vase)
      %sub-groups
        =^  cards  state

          (sub-groups ~)

        [cards this]

      %unsub-groups
        =^  cards  state

          (unsub-groups ~)

        [cards this]

      %print-groups
        =^  cards  state

          (print-groups ~)

        [cards this]

      %vote-cast
        =^  cards  state

        =/  jon  !<(json vase)

          (handle-vote-cast jon)

        [cards this]

      %invitation
        =^  cards  state

        =/  jon  !<(json vase)

          (handle-invitation jon)

        [cards this]

      %initialize
         =^  cards  state

          (initialize-booths ~)

         [cards this]

      :: ~lodlev-migdev - if the mark is JSON, it means this is a poke
      ::   from eyre which uses channeling to route responses/acks back
      ::   to the calling client
      %json
        =^  cards  state

        =/  jon  !<(json vase)

          (handle-channel-poke jon)

        ::   =/  effects=(list card)  (~(handle-wire core bowl) jon)

        :: [effects state]

        [cards this]

      %handle-http-request
        =^  cards  state

        =/  req  !<((pair @ta inbound-request:eyre) vase)

        :: =/  effects=(list card)  (~(handle-api-request core bowl) req req-args)

        :: [effects state]

        :: parse query string portion of url into map of arguments (key/value pair)
        =/  req-args
              (my q:(need `(unit (pair pork:eyre quay:eyre))`(rush url.request.q.req ;~(plug apat:de-purl:html yque:de-purl:html))))

        %-  (slog leaf+"ballot: [on-poke] => processing request at endpoint {<(stab url.request.q.req)>}" ~)

        =/  path  (stab url.request.q.req)

        ?+    method.request.q.req
                (send-error req 'unsupported')
              %'PUT'
                ?+    path
                        (send-error req 'route not found')

                  [%ballot %api %booths ~]
                    :: null in last parameter indicates we are creating a booth
                    (handle-save-booth req req-args ~)

                  :: update a particular booth
                  [%ballot %api %booths @ ~]
                    =/  key  (key-from-path:util i.t.t.t.path)
                    (handle-save-booth req req-args key)

                  :: create a proposal in the booth
                  [%ballot %api %booths @ %proposals ~]
                    =/  booth-key  (key-from-path:util i.t.t.t.path)
                    :: null in last parameter indicates we are creating a proposal
                    (handle-save-proposal req req-args booth-key ~)

                  :: update a particular proposal
                  [%ballot %api %booths @ %proposals @t ~]
                    =/  booth-key  (key-from-path:util i.t.t.t.path)
                    =/  proposal-key  i.t.t.t.t.t.path
                    (handle-save-proposal req req-args booth-key proposal-key)

                  :: create a participant in the booth
                  [%ballot %api %booths @ %participants ~]
                    =/  booth-key  (key-from-path:util i.t.t.t.path)
                    :: null in last parameter indicates we are adding a participant
                    (handle-save-participant req req-args booth-key ~)

                  :: update a particular proposal
                  [%ballot %api %booths @ %participants @t ~]
                    =/  booth-key  (key-from-path:util i.t.t.t.path)
                    =/  participant-key  i.t.t.t.t.t.path
                    (handle-save-participant req req-args booth-key participant-key)

                ==

              %'DELETE'
                ?+    path
                        (send-error req 'route not found')

                  :: update a particular booth
                  [%ballot %api %booths @ ~]
                    =/  key  (key-from-path:util i.t.t.t.path)
                    (handle-delete-booth req req-args key)

                  :: update a particular proposal
                  [%ballot %api %booths @ %proposals @t ~]
                    =/  booth-key  (key-from-path:util i.t.t.t.path)
                    =/  proposal-key  i.t.t.t.t.t.path
                    (handle-delete-proposal req req-args booth-key proposal-key)

                  :: update a particular proposal
                  [%ballot %api %booths @ %participants @t ~]
                    =/  booth-key  (key-from-path:util i.t.t.t.path)
                    =/  participant-key  i.t.t.t.t.t.path
                    (handle-delete-participant req req-args booth-key participant-key)

                ==

              :: votes are cast via a http POST
              %'POST'
                ?+    path
                        (send-error req 'route not found')

                  [%ballot %api %booths ~]
                    (handle-resource-action req req-args ~)

                  ::  do booth specific things (e.g. invite a participant)
                  [%ballot %api %booths @ ~]
                    =/  key  (key-from-path:util i.t.t.t.path)
                    (handle-resource-action req req-args key)

                    :: =/  effects=(list card)  (handle-post:core req req-args)
                    :: =/  effects=(list card)  (~(handle-post core bowl) req req-args)

                    :: [effects state]

                  [%ballot %api %booths @ %proposals ~]
                    =/  key  (key-from-path:util i.t.t.t.path)
                    (handle-resource-action req req-args ~)

                  :: update a particular proposal
                  [%ballot %api %booths @ %proposals @t %vote ~]
                    =/  booth-key  (key-from-path:util i.t.t.t.path)
                    =/  proposal-key  i.t.t.t.t.t.path
                    (handle-cast-vote req req-args booth-key proposal-key)

                ==
        ==
        [cards this]
    ==

    ++  scry
      |*  [=mold =path]
      ^-  mold
      ?>  ?=(^ path)
      ?>  ?=(^ t.path)
      .^  mold
        (cat 3 %g i.path)
        (scot %p our.bowl)
        i.t.path
        (scot %da now.bowl)
        t.t.path
      ==

    ++  sub-groups
      |=  [jon=json]
      :_  state
      :~
        [%pass /group %agent [our.bowl %group-store] %watch /groups]
      ==

    ++  unsub-groups
      |=  [jon=json]
      :_  state
      :~
        [%pass /group %agent [our.bowl %group-store] %leave ~]
      ==

    ++  group-to-booth
      |=  [booths=booths:ballot-store r=resource]
      ^-  (map @t json)

      =/  timestamp  (crip (en-json:html (time:enjs:format now.bowl)))

      =/  meta=json
      %-  pairs:enjs:format
      :~
        ['tag' ~]
      ==

      =/  group-name  (trip name.r)

      ::  create booth metadata
      =/  booth=json
      %-  pairs:enjs:format
      :~
        ['type' s+'group']
        ['key' s+(crip group-name)]
        ['name' s+(crip group-name)]
        ['image' ~]
        ['owner' s+(crip "{<our.bowl>}")]
        ['created' s+timestamp]
        ['policy' s+'invite-only']
        ['meta' meta]
      ==

      ::  add the group booth to the map
      =/  result   (~(put by booths) (crip "{group-name}") booth)

      result

    ++  groups-to-booths
      |=  [res=(set resource)]
      %-  ~(rep in res)
      |=  [r=resource o=(map @t json)]
      =.  o  (group-to-booth o r)
      ^-  (map @t json)
      o

    ++  to-booth-sub
      |=  [jon=json]
      ^-  card
      =/  booth  ((om json):dejs:format jon)
      =/  owner  (so:dejs:format (~(got by booth) 'owner'))
      =/  booth-ship=@p  `@p`(slav %p owner)
      ::  send out notifications to all subscribers of this booth
      =/  destpath=path  `path`/booths/(scot %p booth-ship)
      ~&  >>  "ballot: subscribing to {<destpath>}..."
      :: convert json to [%pass /booth/<booth-key> ... /booth/<booth-key>] subscription
      [%pass destpath %agent [booth-ship %ballot] %watch destpath]

    ++  booths-to-subscriptions
      |=  [m=(map @t json)]
      ^-  (list card)
      =/  l  ~(val by m)
      =/  r=(list card)  (turn l to-booth-sub)
      [r]

    ++  print-groups
      |=  [j=json]

      =/  groups=(set resource)  (scry (set resource) /y/group-store/groups)
      =/  c=(map @t json)  (groups-to-booths groups)
      ~&  >>  "ballot: groups => {<c>}"

      `state

    ++  initialize-booths
      |=  [jon=json]

      ~&  >>  'ballot: initializing ballot-store...'

      =/  owner  `@t`(scot %p our.bowl)
      =/  timestamp  (crip (en-json:html (time:enjs:format now.bowl)))

      =/  booth-key  (crip "{<our.bowl>}")

      =/  meta=json
      %-  pairs:enjs:format
      :~
        ['tag' ~]
      ==

      ::  ~lodlev-migdev
      ::   steps:
      ::
      ::    1) create a folder for our ship and add a /booths sub-folder to it
      ::    2) create a default booth for our ship (e.g. ~zod) and add it
      ::          to this ship's booths folder
      ::
      =|  booths=booths:ballot-store

      =/  booth=json
      %-  pairs:enjs:format
      :~
        ['type' s+'ship']
        ['key' s+booth-key]
        ['name' s+booth-key]
        ['image' ~]
        ['owner' s+owner]
        ['created' s+timestamp]
        ['policy' s+'invite-only']
        ['status' s+'active']
        ['meta' meta]
      ==

      =.  booths  (~(put by booths) booth-key booth)

      =/  participant-key  (crip "{<our.bowl>}")
      =|  booth-participants=(map @t json)

      =/  participant=json
      %-  pairs:enjs:format
      :~
        ['key' s+participant-key]
        ['name' s+participant-key]
        ['status' s+'active']
        ['role' s+'owner']
        ['created' s+timestamp]
      ==

      =.  booth-participants  (~(put by booth-participants) participant-key participant)

      ~&  >  'ballot: context initialized!'

      ::  fetch groups from group-store
      =/  groups=(set resource)  (scry (set resource) /y/group-store/groups)
      :: ::  transform group set to context map
      =/  group-booths=(map @t json)  (groups-to-booths groups)
      :: ::  append group contexts to context-store
      =.  booths  (~(gas by booths) ~(tap by group-booths))

      =/  effects  (booths-to-subscriptions booths)

      %-  (slog leaf+"subscribing to /groups..." ~)
      =/  effects  (snoc effects [%pass /group %agent [our.bowl %group-store] %watch /groups])

      :_  state(booths booths, participants (~(put by participants.state) booth-key booth-participants))

      [effects]

      :: :~  [%pass /booths %agent [our.bowl %ballot] %watch /booths]
      :: ==

    ++  dump
      |=  [msg=@t dat=*]
      ~&  >>>  dat
      ~|(msg !!)

    ++  handle-invitation
      |=  [jon=json]
      ^-  (quip card _state)

      ~&  >>  "ballot: handle-invitation => ?"

      =/  booth  ((om json):dejs:format jon)
      =/  booth-key  (so:dejs:format (~(got by booth) 'key'))
      =/  booth-owner  (so:dejs:format (~(got by booth) 'owner'))
      =/  booth-ship=@p  `@p`(slav %p booth-owner)

      ?>  =(src.bowl booth-ship)

      `state(booths (~(put by booths.state) booth-key jon))

    ++  handle-vote-cast
      |=  [jon=json]
      ^-  (quip card _state)

      =/  ballot  ((om json):dejs:format jon)

      :: :: extract the booth key
      =/  booth-key  (so:dejs:format (~(got by ballot) 'booth'))
      =/  proposal-key  (so:dejs:format (~(got by ballot) 'proposal'))
      =/  participant-key  (so:dejs:format (~(got by ballot) 'participant'))
      =/  choice-label  (so:dejs:format (~(got by ballot) 'choice-label'))
      =/  caston-timestamp  (so:dejs:format (~(got by ballot) 'caston'))

      =/  timestamp  (crip (en-json:html (time:enjs:format now.bowl)))

      :: does the booth exist? check agains the booth store.
      =/  booth  (~(get by booths.state) booth-key)

      ?~  booth
        (dump 'booth not found' [%handle-vote-cast jon])

      =/  booth  (need booth)
      =/  booth  ((om json):dejs:format booth)

      :: does this booth have proposals?
      =/  booth-proposals  (~(get by proposals.state) booth-key)
      ?~  booth-proposals
        (dump 'booth proposals not found' [%handle-vote-cast jon])

      =/  booth-proposals  (need booth-proposals)

      :: does this booth have a specific proposal
      =/  proposal  (~(get by booth-proposals) proposal-key)
      ?~  proposal
        (dump 'proposal not found' [%handle-vote-cast jon])

      =/  proposal=json  (need proposal)

      ::  convert the proposal json to (map @t json)
      =/  proposal  ((om json):dejs:format proposal)

      ::  get the current list of votes for this particular booth/proposal
      =/  votes  (~(get by proposal) 'votes')
      =/  votes
            ?~  votes
              [%o ~]
            (need votes)

      ::  convert the votes json to (map @t json)
      =/  votes  ((om json):dejs:format votes)

      ::  this ship is casting the vote
      =/  participant-key  (crip "{<our.bowl>}")
      ::  ensure this ship hasn't already voted
      ?:  (~(has by votes) participant-key)
        :: send error indicating ship has already voted
        (dump 'error: participant vote already casts' [%handle-vote-cast jon])

      =/  vote-meta
        %-  pairs:enjs:format
        :~
          ['proposal' s+proposal-key]
          ['participant' s+participant-key]
          ['choice-label' s+choice-label]
          ['caston' s+caston-timestamp]
          ['recorded' s+timestamp]
        ==

      ::  record this ship's vote
      =/  votes  (~(put by votes) participant-key vote-meta)
      ::  commit the updated votes to the proposal
      =/  proposal  (~(put by proposal) 'votes' [%o votes])
      ::  commit the updated proposal record to the store
      =/  booth-proposals  (~(put by booth-proposals) proposal-key [%o proposal])

      =/  destpath  `path`/booths/(crip "{<booth-key>}")

      :_  state(proposals (~(put by proposals.state) booth-key booth-proposals))
      :~  [%give %fact ~[destpath] %json !>(vote-meta)]
      ==


    ::  ARM: ++  handle-channel-poke
    ::  ~lodlev-migdev - handle actions coming in from eyre channeling mechanism
    ::
    ::   @see: https://urbit-org-j1prh9inz-urbit.vercel.app/docs/arvo/eyre/external-api-ref
    ::    for more information
    ++  handle-channel-poke
      |=  [jon=json]

      =/  contract=(map @t json)  ((om json):dejs:format jon)

      :: :: :: all poke json payloads must include an action (req'd)
      ?.  (~(has by contract) 'action')
            ::   context attribute is required
            (send-channel-error s+'error: action attribute required')

      =/  act  (~(got by contract) 'action')

      ?+    p.+.act  (send-channel-error s+'error: unrecognized action')
        %save-booth
            (save-booth contract)
        %delete-booth
            (delete-booth contract)
        %save-proposal
            (save-proposal contract)

        %receive-invitation
          (receive-invitation contract)

        ::  remote ship is requesting to join a booth in our ship
        %join
          %-  (slog leaf+"ballot: %join action received..." ~)
          (handle-join-booth contract)

        %join-response
          %-  (slog leaf+"ballot: %join-response action received..." ~)
          (handle-join-response contract)

        %invite
          %-  (slog leaf+"ballot: %invite action received..." ~)
          (invite-participant-wire contract)

        %invite-response
          %-  (slog leaf+"ballot: %invite-response action received..." ~)
          (invite-participant-wire-response contract)

        %accept
          %-  (slog leaf+"ballot: %accept from {<src.bowl>}..." ~)
          (invite-accepted-wire contract)

        %delete-proposal
          %-  (slog leaf+"ballot: %delete-proposal from {<src.bowl>}..." ~)
          (delete-proposal-wire contract)

        %delete-participant
          %-  (slog leaf+"ballot: %delete-participant from {<src.bowl>}..." ~)
          (delete-participant-wire contract)

        %cast-vote
          %-  (slog leaf+"ballot: %cast-vote from {<src.bowl>}..." ~)
          (cast-vote-wire contract)
      ==

      ++  send-nack
        |=  [=path m=(map @t json)]
        =/  m  (~(put by m) 'reaction' s+'nack')
        :_  state
        :~  [%give %fact ~[path] %json !>([%o m])]
        ==

      ++  send-channel-error
        |=  [jon=json]
        :_  state
        :~  [%give %fact ~[/errors] %json !>(jon)]
        ==

      ::  ARM:  save-booth
      ::  @author:  ~lodlev-migdev
      ::    Create/update booth in store
      :: {
      ::   action: string, // save-booth
      ::   name: string,   // booth name
      ::   content: {
      ::     name:  string,  // optional
      ::     image: string|null, // optional,
      ::     meta: {
      ::       ...
      ::     }
      ::   }
      :: }
      ++  save-booth
        |=  [contract=(map @t json)]

        ::  does the path key exist in the payload
        ?.  (~(has by contract) 'name')
          :: nope. send error indicating path doesn't exist in payload
          (send-channel-error s+'error: name attribute required')

        =/  key  (so:dejs:format (~(got by contract) 'name'))

        ::  does the context exist in our store?
        ?.  (~(has by booths.state) key)
          :: nope. send error indicating context doesn't exist in store
          (send-channel-error s+'error: booth not found')

        ::  the key was found. use it to extract the map entry
        =/  booth=(map @t json)  ((om json):dejs:format (~(got by booths.state) key))

        ::  get the content
        =/  content
          ?.  (~(has by contract) 'content')
              ~
            ((om json):dejs:format (~(got by contract) 'content'))

        =/  updated-booth  (~(gas by booth) ~(tap by contract))

        :_  state(booths (~(put by booths.state) key [%o updated-booth]))

        :~  [%give %fact ~[/booths] %json !>(s+'booth saved')]
        ==

      ::  ARM:  delete-booth
      ::  @author:  ~lodlev-migdev
      ::    Delete booth from store
      :: {
      ::   action: string, // delete-booth
      ::   name: string   // booth name
      :: }
      ++  delete-booth
        |=  [contract=(map @t json)]

        ::  does the path key exist in the payload
        ?.  (~(has by contract) 'name')
          :: nope. send error indicating path doesn't exist in payload
          (send-channel-error s+'error: name attribute required')

        =/  key  (so:dejs:format (~(got by contract) 'name'))

        ::  does the context exist in our store?
        ?.  (~(has by booths.state) key)
          :: nope. send error indicating context doesn't exist in store
          (send-channel-error s+'error: booth not found')

        :_  state(booths (~(del by booths.state) key))

        :~  [%give %fact ~[/booths] %json !>(s+'booth deleted')]
        ==

      ::  ARM:  save-proposal
      ::  @author:  ~lodlev-migdev
      ::    Create/update proposal in proposal store
      :: {
      ::   action: string, // save-proposal
      ::   booth:  string, // booth name
      ::   name:   string, // proposal name
      ::   content: {
      ::        title: string,
      ::        body: string,
      ::        strategy: 'single-choice'|'multi-choice',
      ::        status: 'draft'|'active'|'complete'|'cancelled',
      ::        published: true|false,
      ::        hideIndividualVote: true|false,
      ::        choices: [{
      ::          label: string,
      ::          description: string,
      ::        }],
      ::        start: timestamp, // epoch (milliseconds since 1970),
      ::        end:   timestamp, // epoch (milliseconds since 1970),
      ::        createdBy: string, // ship (@p)
      ::        createdAt: timestamp, // epoch (milliseconds since 1970),
      ::   }
      :: }
      ++  save-proposal
        |=  [contract=(map @t json)]

        ::  does the path key exist in the payload
        ?.  (~(has by contract) 'booth')
          :: nope. send error indicating path doesn't exist in payload
          (send-channel-error s+'error: booth attribute required')

        ::  does the path key exist in the payload
        ?.  (~(has by contract) 'name')
          :: nope. send error indicating path doesn't exist in payload
          (send-channel-error s+'error: name attribute required')

        =/  booth-key  (so:dejs:format (~(got by contract) 'booth'))
        =/  proposal-key  (so:dejs:format (~(got by contract) 'name'))

        =/  booth-proposals  (~(get by proposals.state) booth-key)
        =/  booth-proposals  ?~(booth-proposals ~ (need booth-proposals))

        =/  proposal  (~(get by booth-proposals) proposal-key)

        =/  proposal
              ?~  proposal
                 ~
              ((om json):dejs:format (need proposal))

        =/  content
          ?.  (~(has by contract) 'content')
              ~
            ((om json):dejs:format (~(got by contract) 'content'))

        =/  updated-proposal  (~(gas by proposal) ~(tap by content))
        =/  updated-booth-proposals  (~(gas by booth-proposals) ~(tap by updated-proposal))

        :_  state(proposals (~(put by proposals) booth-key updated-booth-proposals))

        :~  [%give %fact ~[/updates] %json !>(s+'proposal saved')]
        ==

      ::  ARM:  delete-proposal
      ::  @author:  ~lodlev-migdev
      ::    Delete proposal from proposal store
      :: {
      ::   action: string, // delete-proposal
      ::   booth:  string, // booth name
      ::   name:   string, // proposal name
      :: }
      ++  delete-proposal
        |=  [contract=(map @t json)]

        ::  does the path key exist in the payload
        ?.  (~(has by contract) 'booth')
          :: nope. send error indicating path doesn't exist in payload
          (send-channel-error s+'error: booth attribute required')

        ::  does the path key exist in the payload
        ?.  (~(has by contract) 'name')
          :: nope. send error indicating path doesn't exist in payload
          (send-channel-error s+'error: name attribute required')

        =/  booth-key  (so:dejs:format (~(got by contract) 'booth'))
        =/  proposal-key  (so:dejs:format (~(got by contract) 'name'))

        =/  booth-proposals  (~(get by proposals.state) booth-key)
        =/  booth-proposals  ?~(booth-proposals ~ (need booth-proposals))

        =/  booth-proposals  (~(del by booth-proposals) proposal-key)

        :_  state(proposals (~(put by proposals.state) booth-key booth-proposals))

        :~  [%give %fact ~[/booths] %json !>(s+'proposal deleted')]
        ==

      ::  ARM:  delete-participant
      ::  @author:  ~lodlev-migdev
      ::    Delete participant from participant store
      :: {
      ::   action: string, // delete-participant
      ::   booth:  string, // booth name
      ::   name:   string, // participant name
      :: }
      ++  delete-participant
        |=  [contract=(map @t json)]

        ::  does the path key exist in the payload
        ?.  (~(has by contract) 'booth')
          :: nope. send error indicating path doesn't exist in payload
          (send-channel-error s+'error: booth attribute required')

        ::  does the path key exist in the payload
        ?.  (~(has by contract) 'name')
          :: nope. send error indicating path doesn't exist in payload
          (send-channel-error s+'error: name attribute required')

        =/  booth-key  (so:dejs:format (~(got by contract) 'booth'))
        =/  participant-key  (so:dejs:format (~(got by contract) 'name'))

        =/  booth-participants  (~(get by participants.state) booth-key)
        =/  booth-participants  ?~(booth-participants ~ (need booth-participants))

        =/  booth-participants  (~(del by booth-participants) participant-key)

        :_  state(participants (~(put by participants.state) booth-key booth-participants))

        :~  [%give %fact ~[/booths] %json !>(s+'participant deleted')]
        ==

      ++  handle-join-response
        |=  [contract=(map @t json)]

        =/  timestamp  (crip (en-json:html (time:enjs:format now.bowl)))

        ::  rewrite action back to original requesting action of 'join'
        =/  contract  (~(put by contract) 'action' s+'join')

        :: the join succeeded. the response will have the booth in the data element
        ::  use that to commit the booth to our local store
        =/  booth-key  (so:dejs:format (~(got by contract) 'key'))
        =/  booth  (~(got by contract) 'data')

        ::  send good news out to all this booth's subscribers
        :: =/  booth-ship  `@p`(slav %p booth-key)
        :: =/  destpath=path  `path`/booths
        :_  state(booths (~(put by booths.state) booth-key booth))
        :~  [%give %fact [/booths]~ %json !>([%o contract])]
        ==

      ::  ARM:  invite-participant
      ::  @author:  ~lodlev-migdev
      ::    Invite a participant (e.g. ship) to a booth
      :: {
      ::   action: string, // join
      ::   resource: string, // 'booth'
      ::   key: string, // booth key
      :: }
      ++  handle-join-booth
        |=  [data=(map @t json)]

        =/  timestamp  (crip (en-json:html (time:enjs:format now.bowl)))

        ::=/  requesting-ship=@p  `@p`(slav %p src.bowl)
        ::  send out notifications to all subscribers of this booth
        =/  destpath=path  `path`/booths/(scot %p src.bowl)

        ::  extract booth key (resource key) from the poke data
        =/  booth-key  (so:dejs:format (~(got by data) 'key'))

        ~&  >>  "fetching booth {<booth-key>}..."
        ::  ensure the booth exists
        =/  booth  (~(get by booths.state) booth-key)
        ?~  booth  !!  :: crash if booth not found
        =/  booth  ((om json):dejs:format (need booth))

        ::  is the booth 'invite-only' or public?
        =/  booth-policy  (~(get by booth) 'policy')
        ?~  booth-policy  !!
        =/  booth-policy  (so:dejs:format (need booth-policy))

        =/  allow
              ?+  booth-policy  %.n

                %invite-only
                  =/  inv  (~(get by invitations.state) booth-key)
                  =/  inv  ?~(inv ~ (need inv))
                  :: =/  requesting-ship  `@p`(slav %p src.bowl)

                  ?:((~(has in inv) src.bowl) %.y %.n)

                %public
                  %.y

              ==

        ::  send nack on booth policy violation
        ?.  allow
          =/  err=(list tank)  :~  'booth policy violation. must receive invite.'  ==
          =/  msg=(unit tang)  (some err)
          ~&  >>  "booth policy violation. invite-only {<msg>}"
          :_  state
          :~  [%give %poke-ack msg]
          ==

        ::=/  booth-data  ((om json):dejs:format (~(got by contract) 'data'))
        ::  attempt to get booth participants
        =/  booth-participants  (~(get by participants.state) booth-key)
        =/  booth-participants  ?~(booth-participants ~ (need booth-participants))

        ::  make participant name from the calling ship's identity
        =/  participant-name  (crip "{<src.bowl>}")
        ::  crash if participant already exists
        ?:  (~(has by booth-participants) participant-name)
              (send-nack destpath data)

        =/  participant
              %-  pairs:enjs:format
              :~
                  ['name' s+participant-name]
                  ['created' s+timestamp]
              ==
        ::  add the participant
        =/  booth-participants  (~(put by booth-participants) participant-name participant)

        ~&  >>  "{<destpath>} committing changes and returning..."
        =/  data  (~(put by data) 'action' s+'join-response')
        =/  data  (~(put by data) 'data' [%o booth])
        :: commit changes to participant store
        :_  state(participants (~(put by participants.state) booth-key booth-participants))
        :: send the response back via Eyre
        :~  [%pass destpath %agent [src.bowl %ballot] %poke %json !>([%o data])]
        ==

      ::  ARM:  invite-participant
      ::  @author:  ~lodlev-migdev
      ::    Adds the participant to the local store
      ++  handle-invite-participant
        |=  [booth-key=@t contract=(map @t json)]

        ::  does the booth exist in the payload
        ?.  (~(has by contract) 'key')  !!  ::  participant key required

        =/  participant-key  (so:dejs:format (~(got by contract) 'key'))

        ::  only support ship invites currently
        =/  participant-ship  `(unit @p)`((slat %p) participant-key)
        ?~  participant-ship  !!  :: only ship invites
        =/  participant-ship=ship  (need participant-ship)

        =/  booth  (~(get by booths.state) booth-key)
        ?~  booth  !!  :: booth must exist
        =/  booth-participants  (~(get by participants.state) booth-key)
        =/  booth-participants  ?~(booth-participants ~ (need booth-participants))

        =/  participant  (~(get by booth-participants) participant-key)

        =/  participant
              ?~  participant
                 ~
              ((om json):dejs:format (need participant))

        ::  update participant record to indicated invited
        =/  participant-updates=json
        %-  pairs:enjs:format
        :~
          ['name' s+participant-key]
          ['status' s+'invited']
        ==
        ::  convert to (map @t json)
        =/  participant-updates  ((om json):dejs:format participant-updates)

        ::  apply updates to participant by overlaying updates map
        =/  participant  (~(gas by participant) ~(tap by participant-updates))

        ::  stuff the updated participant data back into the resource action to be
        ::   sent to remote ship and to subscribers
        =/  contract  (~(put by contract) 'data' [%o participant])

        ::  save the updated partcipant to the participants map
        =/  booth-participants  (~(put by booth-participants) participant-key [%o participant])

        ::  commit changes to the store
        :_  state(participants (~(put by participants.state) booth-key booth-participants))

            :: send message out to client that send poke
        :~  [%give %fact ~[/updates] %participant-invited !>(contract)]
        ==

      ::  ARM:  receive-invitation
      ::  @author:  ~lodlev-migdev
      ::    When a ship hosting a booth adds a participant, a %json poke
      ::      with an action of 'receive-invitation' is sent to the participant's ship.
      ::    This is where that poke is handled.
      ::    Here we:
      ::      * Add the booth to our local ship's booth store
      ::      * Add a "remote": true attribute
      ::      * Add a "status": 'invited' attribute
      ::      * Add the booth object to our local store
      :: {
      ::   action: string, // receive-invitation
      ::   booth: json,    // booth object
      :: }
      ::  TODO:  better error handling???
      ++  receive-invitation
        |=  [contract=(map @t json)]

        :: ::  does the booth exist in the payload
        ?.  (~(has by contract) 'booth')
          ~&  >>>  'ballot: [receive-invitation] error: booth attribute required'
          `state

        =/  remote-booth  ((om json):dejs:format (~(got by contract) 'booth'))
        =/  remote-booth-key  (so:dejs:format (~(got by remote-booth) 'key'))
        =/  remote-booth-owner  (so:dejs:format (~(got by remote-booth) 'owner'))
        =/  remote-booth-ship  `@p`(slav %p remote-booth-owner)

        =/  local-ship-booth  remote-booth
        =/  local-ship-booth  (~(put by local-ship-booth) 'remote' b+%.y)
        =/  local-ship-booth  (~(put by local-ship-booth) 'status' s+'invited')

        `state(booths (~(put by booths.state) remote-booth-key [%o local-ship-booth]))

      :: ******************************************************
      ::  REST API implementation
      ::

      ::  ARM: ++  send-error
      ::  ~lodlev-migdev - send a 500 as plain text content back to the
      ::    calling client. The second argument is the body/payload
      ::    as a plain text string (@t).
      ++  send-error
        |=  [req=(pair @ta inbound-request:eyre) msg=@t]
          =/  data=octs
            (as-octs:mimes:html msg)
          =/  =response-header:http
            :-  500
            :~  ['Content-Type' 'text/plain']
            ==
          :_  state
          :~
            [%give %fact [/http-response/[p.req]]~ %http-response-header !>(response-header)]
            [%give %fact [/http-response/[p.req]]~ %http-response-data !>(`data)]
            [%give %kick [/http-response/[p.req]]~ ~]
          ==

      ++  null-map
        |=  [~]
        ^-  (map @t json)
        ~
      ::  ARM:  extract-payload
      ::    Takes in an inbound http request, and extracts the metadata/header
      ::     and data portions of the payload and returns then as (map @t json).
      ++  extract-payload
        |=  [req=(pair @ta inbound-request:eyre)]
        ::  data must be unit since can be null
        ^-  (map @t json)

        =/  til=octs
              (tail body.request.q.req)

        ::  variable to hold request body (as $json)
        =/  payload  (need (de-json:html q.til))

        ::  variable to convert $json (payload) as map : key => json pairs
        ((om json):dejs:format payload)

      ++  delete-participant-wire
        |=  [payload=(map @t json)]

        =/  timestamp  (en-json:html (time:enjs:format now.bowl))

        =/  context  ((om json):dejs:format (~(got by payload) 'context'))
        =/  booth-key  (so:dejs:format (~(got by context) 'key'))

        =/  participant-key  (so:dejs:format (~(got by payload) 'key'))

        =/  booth-participants  (~(get by participants.state) booth-key)
        =/  booth-participants  ?~(booth-participants ~ (need booth-participants))
        =/  participant  (~(get by booth-participants) participant-key)
        ?~  participant  `state
        =/  participant  (need participant)
        =/  booth-participants  (~(del by booth-participants) participant-key)

        =/  context=json
        %-  pairs:enjs:format
        :~
          ['key' s+booth-key]
        ==

        =/  participant-effect=json
        %-  pairs:enjs:format
        :~
          ['resource' s+'participant']
          ['effect' s+'delete']
          ['key' s+participant-key]
          ['data' participant]
        ==

        =/  effects=json
        %-  pairs:enjs:format
        :~
          ['action' s+'delete-participant-effect']
          ['context' context]
          ['effects' [%a [participant-effect]~]]
        ==

        =/  remote-agent-wire=path  `path`/booths/(scot %tas booth-key)
        ~&  >>  "sending delete-participant effect to subscribers..."

        =/  =response-header:http
          :-  200
          :~  ['Content-Type' 'application/json']
          ==

        =/  payload  (~(put by payload) 'data' participant)

        ::  encode the proposal as a json string
        =/  body  (crip (en-json:html [%o payload]))

        ::  convert the string to a form that arvo will understand
        =/  data=octs
              (as-octs:mimes:html body)

        ::  no changes to state. state will change when poke ack'd
        :_  state(participants (~(put by participants.state) booth-key booth-participants))

        :~
          ::  for clients (e.g. UI) and "our" agent, send to generic /booths path
          [%give %fact [/booths]~ %json !>(effects)]
        ==

      ++  delete-proposal-wire
        |=  [payload=(map @t json)]

        =/  timestamp  (en-json:html (time:enjs:format now.bowl))

        =/  context  ((om json):dejs:format (~(got by payload) 'context'))
        =/  booth-key  (so:dejs:format (~(got by context) 'key'))

        =/  proposal-key  (so:dejs:format (~(got by payload) 'key'))

        =/  booth-proposals  (~(get by proposals.state) booth-key)
        =/  booth-proposals  ?~(booth-proposals ~ (need booth-proposals))
        =/  proposal  (~(get by booth-proposals) proposal-key)
        ?~  proposal  `state
        =/  proposal  (need proposal)
        =/  booth-proposals  (~(del by booth-proposals) proposal-key)

        =/  context=json
        %-  pairs:enjs:format
        :~
          ['key' s+booth-key]
        ==

        =/  proposal-effect=json
        %-  pairs:enjs:format
        :~
          ['resource' s+'proposal']
          ['effect' s+'delete']
          ['key' s+proposal-key]
          ['data' proposal]
        ==

        =/  effects=json
        %-  pairs:enjs:format
        :~
          ['action' s+'delete-proposal-effect']
          ['context' context]
          ['effects' [%a [proposal-effect]~]]
        ==

        =/  remote-agent-wire=path  `path`/booths/(scot %tas booth-key)
        ~&  >>  "sending delete-proposal effect to subscribers..."

        =/  =response-header:http
          :-  200
          :~  ['Content-Type' 'application/json']
          ==

        =/  payload  (~(put by payload) 'data' proposal)

        ::  encode the proposal as a json string
        =/  body  (crip (en-json:html [%o payload]))

        ::  convert the string to a form that arvo will understand
        =/  data=octs
              (as-octs:mimes:html body)

        ::  no changes to state. state will change when poke ack'd
        :_  state(proposals (~(put by proposals.state) booth-key booth-proposals))

        :~
          ::  for clients (e.g. UI) and "our" agent, send to generic /booths path
          [%give %fact [/booths]~ %json !>(effects)]
        ==

      ++  cast-vote-wire
        |=  [contract=(map @t json)]

        =/  context  ((om json):dejs:format (~(got by contract) 'context'))

        =/  booth-key  (so:dejs:format (~(got by context) 'booth-key'))
        =/  proposal-key  (so:dejs:format (~(got by context) 'proposal-key'))
        =/  participant-key  (so:dejs:format (~(got by context) 'participant-key'))

        =/  vote  ((om json):dejs:format (~(got by contract) 'data'))
        =/  vote  (~(put by vote) 'status' s+'recorded')

        =/  booth-proposals  (~(get by votes.state) booth-key)
        =/  booth-proposals  ?~(booth-proposals ~ (need booth-proposals))
        =/  proposal-votes  (~(get by booth-proposals) proposal-key)
        =/  proposal-votes  ?~(proposal-votes ~ ((om json):dejs:format (need proposal-votes)))

        =/  participant-vote  (~(get by proposal-votes) participant-key)
        ?.  =(participant-vote ~)
              ~&  >>>  "participant vote already cast"
              `state

        =|  participant-vote=(map @t json)
        =/  participant-vote  (~(gas by participant-vote) ~(tap by vote))
        =/  proposal-votes  (~(put by proposal-votes) participant-key [%o participant-vote])
        =/  booth-proposals  (~(put by booth-proposals) proposal-key [%o proposal-votes])

        =/  vote-update  (~(put by contract) 'data' [%o vote])

        =/  vote-effect=json
        %-  pairs:enjs:format
        :~
          ['resource' s+'vote']
          ['effect' s+'add']
          ['key' s+participant-key]
          ['data' [%o vote]]
        ==

        =/  effects=json
        %-  pairs:enjs:format
        :~
          ['action' s+'cast-vote-effect']
          ['context' [%o context]]
          ['effects' [%a [vote-effect]~]]
        ==

        ~&  >>  "cast-vote-wire: {<our.bowl>} {<src.bowl>}"

        =/  booth-path=path  `path`(stab (crip (weld "/booths/" (trip booth-key))))

        :_  state(votes (~(put by votes.state) booth-key booth-proposals))
        :~  [%give %fact [/booths]~ %json !>(effects)]
            [%give %fact [booth-path]~ %json !>([%o vote-update])]
        ==

      ::  ARM:  ++  invite-accepted-wire
      ::   Sent by a remote ship when they've accepted an invite we sent to them
      ::     at an earlier time.
      ++  invite-accepted-wire
        |=  [contract=(map @t json)]

        ::  grab the booth key from the action payload
        =/  booth-key  (so:dejs:format (~(got by contract) 'key'))
        ::  use it to extract the booth participant list
        =/  booth-participants  (~(get by participants.state) booth-key)
        ::  crash if not found (tbd: better error handling)
        ?~  booth-participants  !!
        ::  get the actual participant list from the unit
        =/  booth-participants  (need booth-participants)

        ::  the participant key is the remote ship that sent the poke
        =/  participant-key  (crip "{<src.bowl>}")

        ::  get the participant from the booth participant list
        =/  participant  (~(get by booth-participants) participant-key)
        ::  crash on participant not found
        ?~  participant  !!
        ::  get the actual participant from the unit while converting to (map @t json)
        =/  participant  ((om json):dejs:format (need participant))
        :: update the participant's status to 'active'
        =/  participant  (~(put by participant) 'status' s+'active')
        :: add the updated participant back to the booth participant list
        =/  booth-participants  (~(put by booth-participants) participant-key [%o participant])

        ::  send out any effects to the UI (or other clients)
        =/  effect-data=json
        %-  pairs:enjs:format
        :~
          ['status' s+'active']
        ==

        =/  participant-effect=json
        %-  pairs:enjs:format
        :~
          ['resource' s+'participant']
          ['effect' s+'update']
          ['key' s+participant-key]
          ['data' effect-data]
        ==

        =/  effects=json
        %-  pairs:enjs:format
        :~
          ['action' s+'accept-effect']
          ['context' [%o contract]]
          ['effects' [%a [participant-effect]~]]
        ==

        ~&  >>  "invite-accepted-wire: {<our.bowl>} {<src.bowl>}"

        :_  state(participants (~(put by participants.state) booth-key booth-participants))
        :~  [%give %fact [/booths]~ %json !>(effects)]
        ==

      ++  invite-participant-wire-response
        |=  [contract=(map @t json)]

        :: the join succeeded. the response will have the booth in the data element
        ::  use that to commit the booth to our local store
        =/  booth-key  (so:dejs:format (~(got by contract) 'key'))
        =/  contract-data  ((om json):dejs:format (~(got by contract) 'data'))
        =/  participant-key  (so:dejs:format (~(got by contract-data) 'key'))

        =/  booth-participants  (~(got by participants.state) booth-key)
        =/  booth-participant  ((om json):dejs:format (~(got by booth-participants) participant-key))
        =/  booth-participant  (~(put by booth-participant) 'status' s+'invited')
        =/  booth-participants  (~(put by booth-participants) participant-key [%o booth-participant])

        =/  effect-data=json
        %-  pairs:enjs:format
        :~
          ['status' s+'invited']
        ==

        =/  participant-effect=json
        %-  pairs:enjs:format
        :~
          ['resource' s+'participant']
          ['effect' s+'update']
          ['key' s+participant-key]
          ['data' effect-data]
        ==

        =/  effects=json
        %-  pairs:enjs:format
        :~
          ['action' s+'invite-effect']
          ['context' [%o contract]]
          ['effects' [%a [participant-effect]~]]
        ==

        ~&  >>  "invite-participant-wire-response: {<our.bowl>} {<src.bowl>}"

        :_  state(participants (~(put by participants.state) booth-key booth-participants))
        :~  [%give %fact [/booths]~ %json !>(effects)]
        ==

      ++  invite-participant-wire
        |=  [payload=(map @t json)]

        =/  timestamp  (en-json:html (time:enjs:format now.bowl))

        =/  participant-key  (crip "{<our.bowl>}")
        =/  booth-key  (so:dejs:format (~(got by payload) 'key'))
        =/  data  (~(get by payload) 'data')
        ?~  data  !!
        =/  data  ((om json):dejs:format (need data))
        =/  booth  (~(get by data) 'booth')
        =/  booth  ?~(booth ~ ((om json):dejs:format (need booth)))
        ::  update booth status because on receiving ship (this ship), the booth
        ::    is being added; therefore status is 'invited'
        =/  booth  (~(put by booth) 'status' s+'invited')

        =/  response-payload  (~(put by payload) 'action' s+'invite-response')
        =/  response-payload  (~(put by response-payload) 'reaction' s+'ack')

        ::  queue the message so that when the poke ack's we can send the nod
        ::    to the UI
        =/  mq-key  (crip (weld "msg-" timestamp))
        =/  mq  (~(put by mq.state) mq-key [%o response-payload])

        =/  booth-effect=json
        %-  pairs:enjs:format
        :~
          ['resource' s+'booth']
          ['effect' s+'add']
          ['key' s+booth-key]
          ['data' [%o booth]]
        ==

        =/  effect=json
        %-  pairs:enjs:format
        :~
          ['action' s+'invite-effect']
          ['context' [%o payload]]
          ['effects' [%a [booth-effect]~]]
        ==

        ~&  >>  "invite-participant-wire: {<our.bowl>} poking {<src.bowl>}"

        =/  destpath=path  `path`/booths/(scot %p src.bowl)/(scot %tas mq-key)

        :_  state(mq mq, booths (~(put by booths.state) booth-key [%o booth]))

        :~  [%give %fact [/booths]~ %json !>(effect)]
            [%pass destpath %agent [src.bowl %ballot] %poke %json !>([%o response-payload])]
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

      ++  delete-participant-api
        |=  [req=(pair @ta inbound-request:eyre) payload=(map @t json) booth-key=@t]
        ^-  (quip card _state)

        =/  participant-key  (so:dejs:format (~(got by payload) 'key'))
        ~&  >>  "deleting participant {<booth-key>}, {<participant-key>}"

        =/  booth-participants  (~(get by participants.state) booth-key)
        =/  booth-participants  ?~(booth-participants ~ (need booth-participants))
        =/  participant  (~(get by booth-participants) participant-key)
        ?~  participant  (send-api-error req 'participant not found')
        =/  participant  (need participant)
        =/  booth-participants  (~(del by booth-participants) participant-key)

        =/  context=json
        %-  pairs:enjs:format
        :~
          ['key' s+booth-key]
        ==

        =/  participant-effect=json
        %-  pairs:enjs:format
        :~
          ['resource' s+'participant']
          ['effect' s+'delete']
          ['key' s+participant-key]
          ['data' participant]
        ==

        =/  effects=json
        %-  pairs:enjs:format
        :~
          ['action' s+'delete-participant-effect']
          ['context' context]
          ['effects' [%a [participant-effect]~]]
        ==

        =/  remote-agent-wire=path  `path`/booths/(scot %tas booth-key)
        ~&  >>  "sending delete-participant to {<remote-agent-wire>}..."

        =/  =response-header:http
          :-  200
          :~  ['Content-Type' 'application/json']
          ==

        =/  payload  (~(put by payload) 'data' participant)

        ::  encode the proposal as a json string
        =/  body  (crip (en-json:html [%o payload]))

        ::  convert the string to a form that arvo will understand
        =/  data=octs
              (as-octs:mimes:html body)

        ::  no changes to state. state will change when poke ack'd
        :_  state(participants (~(put by participants.state) booth-key booth-participants))

        :~
          [%give %fact [/http-response/[p.req]]~ %http-response-header !>(response-header)]
          [%give %fact [/http-response/[p.req]]~ %http-response-data !>(`data)]
          [%give %kick [/http-response/[p.req]]~ ~]
          ::  for clients (e.g. UI) and "our" agent, send to generic /booths path
          [%give %fact [/booths]~ %json !>(effects)]
          ::  for remote subscribers, indicate over booth specific wire
          [%give %fact [remote-agent-wire]~ %json !>([%o payload])]
        ==

      ++  delete-proposal-api
        |=  [req=(pair @ta inbound-request:eyre) payload=(map @t json) booth-key=@t]
        ^-  (quip card _state)

        =/  proposal-key  (so:dejs:format (~(got by payload) 'key'))
        ~&  >>  "deleting proposal {<booth-key>}, {<proposal-key>}"

        =/  booth-proposals  (~(get by proposals.state) booth-key)
        =/  booth-proposals  ?~(booth-proposals ~ (need booth-proposals))
        =/  proposal  (~(get by booth-proposals) proposal-key)
        ?~  proposal  (send-api-error req 'proposal not found')
        =/  proposal  (need proposal)
        =/  booth-proposals  (~(del by booth-proposals) proposal-key)

        =/  context=json
        %-  pairs:enjs:format
        :~
          ['key' s+booth-key]
        ==

        =/  proposal-effect=json
        %-  pairs:enjs:format
        :~
          ['resource' s+'proposal']
          ['effect' s+'delete']
          ['key' s+proposal-key]
          ['data' proposal]
        ==

        =/  effects=json
        %-  pairs:enjs:format
        :~
          ['action' s+'delete-proposal-effect']
          ['context' context]
          ['effects' [%a [proposal-effect]~]]
        ==

        =/  remote-agent-wire=path  `path`/booths/(scot %tas booth-key)
        ~&  >>  "sending delete-proposal to {<remote-agent-wire>}..."

        =/  =response-header:http
          :-  200
          :~  ['Content-Type' 'application/json']
          ==

        =/  payload  (~(put by payload) 'data' proposal)

        ::  encode the proposal as a json string
        =/  body  (crip (en-json:html [%o payload]))

        ::  convert the string to a form that arvo will understand
        =/  data=octs
              (as-octs:mimes:html body)

        ::  no changes to state. state will change when poke ack'd
        :_  state(proposals (~(put by proposals.state) booth-key booth-proposals))

        :~
          [%give %fact [/http-response/[p.req]]~ %http-response-header !>(response-header)]
          [%give %fact [/http-response/[p.req]]~ %http-response-data !>(`data)]
          [%give %kick [/http-response/[p.req]]~ ~]
          ::  for clients (e.g. UI) and "our" agent, send to generic /booths path
          [%give %fact [/booths]~ %json !>(effects)]
          ::  for remote subscribers, indicate over booth specific wire
          [%give %fact [remote-agent-wire]~ %json !>([%o payload])]
        ==

      ::  ARM:  ++  save-proposal-api
      ::
      ::   Steps:
      ::
      ::      1) add/update proposal on booth
      ::      2) respond to POST w/ 200 updated payload (see #1)
      ::      3) poke booth host w/ 'invite-accepted' action
      ::
      ++  save-proposal-api
        |=  [req=(pair @ta inbound-request:eyre) payload=(map @t json)]
        ^-  (quip card _state)

        =/  booth-key  (so:dejs:format (~(got by payload) 'key'))
        =/  data  (~(get by payload) 'data')
        =/  data  ?~(data ~ ((om json):dejs:format (need data)))

        =/  timestamp  (en-json:html (time:enjs:format now.bowl))

        =/  is-update  (~(has by data) 'key')
        =/  proposal-key
              ?:  is-update
                    (so:dejs:format (~(got by data) 'key'))
                  (crip (weld "proposal-" timestamp))

        =/  booth-proposals  (~(get by proposals.state) booth-key)
        =/  booth-proposals  ?~(booth-proposals ~ (need booth-proposals))
        =/  proposal  (~(get by booth-proposals) proposal-key)
        =/  proposal  ?~(proposal ~ ((om json):dejs:format (need proposal)))
        =/  proposal  (~(gas by proposal) ~(tap by data))
        =/  proposal  (~(put by proposal) 'key' s+proposal-key)
        =/  proposal  (~(put by proposal) 'owner' s+(crip "{<our.bowl>}"))
        =/  booth-proposals  (~(put by booth-proposals) proposal-key [%o proposal])

        =/  proposal-effect=json
        %-  pairs:enjs:format
        :~
          ['resource' s+'proposal']
          ['effect' s+?:(is-update 'update' 'add')]
          ['key' s+proposal-key]
          ['data' [%o proposal]]
        ==

        =/  effects=json
        %-  pairs:enjs:format
        :~
          ['action' s+'save-proposal-effect']
          ['context' [%o payload]]
          ['effects' [%a [proposal-effect]~]]
        ==

        =/  remote-agent-wire=path  `path`/booths/(scot %tas booth-key)
        ~&  >>  "sending proposal update to {<remote-agent-wire>}..."

        =/  =response-header:http
          :-  200
          :~  ['Content-Type' 'application/json']
          ==

        =/  payload  (~(put by payload) 'data' [%o proposal])

        ::  encode the proposal as a json string
        =/  body  (crip (en-json:html [%o payload]))

        ::  convert the string to a form that arvo will understand
        =/  data=octs
              (as-octs:mimes:html body)

        ::  no changes to state. state will change when poke ack'd
        :_  state(proposals (~(put by proposals.state) booth-key booth-proposals))

        :~
          [%give %fact [/http-response/[p.req]]~ %http-response-header !>(response-header)]
          [%give %fact [/http-response/[p.req]]~ %http-response-data !>(`data)]
          [%give %kick [/http-response/[p.req]]~ ~]
          ::  for clients (e.g. UI) and "our" agent, send to generic /booths path
          [%give %fact [/booths]~ %json !>(effects)]
          ::  for remote subscribers, indicate over booth specific wire
          [%give %fact [remote-agent-wire]~ %json !>([%o payload])]
        ==

      ::  ARM:  ++  accept-invite-api
      ::
      ::   Steps:
      ::
      ::      1) set payload.data.status to 'waiting'
      ::      2) respond to POST w/ 200 updated payload (see #1)
      ::      3) poke booth host w/ 'invite-accepted' action
      ::
      ++  accept-invite-api
        |=  [req=(pair @ta inbound-request:eyre) payload=(map @t json) booth-key=@t]
        ^-  (quip card _state)

        =/  booth-key  (so:dejs:format (~(got by payload) 'key'))
        =/  booth  (~(get by booths.state) booth-key)
        ?~  booth  !!  :: booth not found

        =/  booth  ((om json):dejs:format (need booth))
        =/  booth  (~(put by booth) 'status' s+'pending')

        ::  create the response
        =/  =response-header:http
          :-  200
          :~  ['Content-Type' 'application/json']
          ==

        ::  encode the proposal as a json string
        =/  body  (crip (en-json:html [%o payload]))

        ::  convert the string to a form that arvo will understand
        =/  data=octs
              (as-octs:mimes:html body)

        ::  pass on original 'accept' to remote ship
        =/  wire-payload  payload

        =/  effect-data=json
        %-  pairs:enjs:format
        :~
          ['status' s+'pending']
        ==

        =/  booth-effect=json
        %-  pairs:enjs:format
        :~
          ['resource' s+'booth']
          ['effect' s+'update']
          ['key' s+booth-key]
          ['data' effect-data]
        ==

        =/  effects=json
        %-  pairs:enjs:format
        :~
          ['action' s+'accept-effect']
          ['context' [%o payload]]
          ['effects' [%a [booth-effect]~]]
        ==

        ::  queue the wire-payload so that we can act accordingly when the poke is ack'd
        =/  timestamp  (en-json:html (time:enjs:format now.bowl))
        =/  mq-key  (crip (weld "msg-" timestamp))

        =/  booth-ship  (so:dejs:format (~(got by payload) 'key'))
        =/  hostship=@p  `@p`(slav %p booth-ship)
        ::  wirepath includes msg queue id so that it can be correlated
        ::    when the poke is ack'd
        =/  destpath=path  `path`/booths/(scot %p our.bowl)/(scot %tas mq-key)

        ::  no changes to state. state will change when poke ack'd
        :_  state(mq (~(put by mq.state) mq-key [%o wire-payload]), booths (~(put by booths.state) booth-key [%o booth]))

        :~
          [%give %fact [/http-response/[p.req]]~ %http-response-header !>(response-header)]
          [%give %fact [/http-response/[p.req]]~ %http-response-data !>(`data)]
          [%give %kick [/http-response/[p.req]]~ ~]
          [%give %fact [/booths]~ %json !>(effects)]
          [%pass destpath %agent [hostship %ballot] %poke %json !>([%o wire-payload])]
        ==

      ++  add-proposal-api
        |=  [req=(pair @ta inbound-request:eyre) payload=(map @t json) booth-key=@t]
        ^-  (quip card _state)

        =/  timestamp  (en-json:html (time:enjs:format now.bowl))
        =/  booth-key  (so:dejs:format (~(got by payload) 'key'))
        =/  data  ((om json):dejs:format (~(got by payload) 'data'))

        =/  destpath=path  `path`/booths/(scot %p our.bowl)

        =/  booth  (~(get by booths.state) booth-key)
        ?~  booth  !!  :: booth must exist
        =/  booth  (need booth)
        =/  booth-proposals  (~(get by proposals.state) booth-key)
        =/  booth-proposals  ?~(booth-proposals ~ (need booth-proposals))

        =/  proposal-key  (crip (weld "proposal-" timestamp))

        ::  update participant record to indicated invited
        =/  proposal=json
        %-  pairs:enjs:format
        :~
          ['key' s+proposal-key]
          ['created' s+(crip timestamp)]
        ==
        =/  proposal  ((om json):dejs:format proposal)
        =/  proposal  (~(put by proposal) 'key' s+proposal-key)
        =/  proposal  (~(put by proposal) 'owner' s+(crip "{<our.bowl>}"))

        ::  layer metadata on top of proposal data
        =/  proposal  (~(gas by proposal) ~(tap by data))
        =/  booth-proposals  (~(put by booth-proposals) proposal-key [%o proposal])

        ::  stuff the updated proposal data back into the payload and send
        ::   that entire action payload out to subscribers
        =/  payload  (~(put by payload) 'data' [%o proposal])

        ::  create the response
        =/  =response-header:http
          :-  200
          :~  ['Content-Type' 'application/json']
          ==

        ::  encode the proposal as a json string
        =/  body  (crip (en-json:html [%o payload]))

        ::  convert the string to a form that arvo will understand
        =/  data=octs
              (as-octs:mimes:html body)

        ::  commit the changes to the store
        :_  state(proposals (~(put by proposals.state) booth-key booth-proposals))

        :~
          [%give %fact [/http-response/[p.req]]~ %http-response-header !>(response-header)]
          [%give %fact [/http-response/[p.req]]~ %http-response-data !>(`data)]
          [%give %kick [/http-response/[p.req]]~ ~]
          [%give %fact [destpath]~ %json !>(payload)]
        ==

      ++  cast-vote-api :: req payload booth-key
        |=  [req=(pair @ta inbound-request:eyre) payload=(map @t json)]
        ^-  (quip card _state)

        =/  timestamp  (crip (en-json:html (time:enjs:format now.bowl)))

        =/  context  (~(get by payload) 'context')
        =/  context  ?~(context ~ ((om json):dejs:format (need context)))
        =/  booth-key  (so:dejs:format (~(got by context) 'booth-key'))
        =/  proposal-key  (so:dejs:format (~(got by context) 'proposal-key'))

        =/  booth  (~(get by booths.state) booth-key)
        ?~  booth  !!  :: booth not found

        =/  booth  ((om json):dejs:format (need booth))

        =/  booth-ship  (so:dejs:format (~(got by booth) 'owner'))
        =/  hostship=@p  `@p`(slav %p booth-ship)

        =/  action  (so:dejs:format (~(got by payload) 'action'))
        =/  resource  (so:dejs:format (~(got by payload) 'resource'))

        =/  booth-proposals  (~(get by votes.state) booth-key)
        =/  booth-proposals  ?~(booth-proposals ~ (need booth-proposals))

        =/  proposal-votes  (~(get by booth-proposals) proposal-key)
        =/  proposal-votes  ?~(proposal-votes ~ ((om json):dejs:format (need proposal-votes)))

        =/  participant-key  (crip "{<our.bowl>}")
        =/  participant-vote  (~(get by proposal-votes) participant-key)
        ?.  =(participant-vote ~)
              (send-error req 'participant vote already cast')

        =/  payload-data  (~(get by payload) 'data')
        ?~  payload-data
              (send-error req 'missing data')

        =/  payload-data  ((om json):dejs:format (need payload-data))

        ::  update the status of the vote to 'pending' for remote ships
        ::    and 'recorded' if we are voting on our own ship
        =/  payload-data
              ?:  =(our.bowl hostship)
                (~(put by payload-data) 'status' s+'recorded')
              (~(put by payload-data) 'status' s+'pending')

        ::  add voter information
        =/  payload-data  (~(put by payload-data) 'voter' s+participant-key)
        ::  timestamp the vote
        =/  payload-data  (~(put by payload-data) 'created-at' s+timestamp)

        =/  proposal-votes  (~(put by proposal-votes) participant-key [%o payload-data])
        =/  booth-votes  (~(put by booth-proposals) proposal-key [%o proposal-votes])

        ::  create the response
        =/  =response-header:http
          :-  200
          :~  ['Content-Type' 'application/json']
          ==

        ::  encode the proposal as a json string
        =/  body  (crip (en-json:html [%o payload]))

        ::  convert the string to a form that arvo will understand
        =/  data=octs
              (as-octs:mimes:html body)

        =/  context=json
        %-  pairs:enjs:format
        :~
          ['booth-key' s+booth-key]
          ['proposal-key' s+proposal-key]
          ['participant-key' s+participant-key]
        ==

        =/  wire-payload=json
        %-  pairs:enjs:format
        :~
          ['context' context]
          ['resource' s+resource]
          ['action' s+action]
          ['data' [%o payload-data]]
        ==

        =/  vote-effect=json
        %-  pairs:enjs:format
        :~
          ['resource' s+'vote']
          ['effect' s+'add']
          ['key' s+participant-key]
          ['data' [%o payload-data]]
        ==

        =/  effects=json
        %-  pairs:enjs:format
        :~
          ['action' s+'cast-vote-effect']
          ['context' context]
          ['effects' [%a [vote-effect]~]]
        ==

        =/  effects=(list card)
          :~  [%give %fact [/http-response/[p.req]]~ %http-response-header !>(response-header)]
              [%give %fact [/http-response/[p.req]]~ %http-response-data !>(`data)]
              [%give %kick [/http-response/[p.req]]~ ~]
              [%give %fact [/booths]~ %json !>(effects)]
          ==

        ::  no need for poke if casting ballot from our own ship. this method has already
        ::  updated its store
        =/  effects  ?.  =(our.bowl hostship)
              %-  (slog leaf+"poking remote ship on wire /booths/{<(scot %p hostship)>}...")
              (snoc effects [%pass /booths/(scot %p hostship) %agent [hostship %ballot] %poke %json !>(wire-payload)])

            effects

        ::  no changes to state. state will change when poke ack'd
        :_  state(votes (~(put by votes.state) booth-key booth-votes))

        [effects]

      ++  invite-participant-api
        |=  [req=(pair @ta inbound-request:eyre) payload=(map @t json) booth-key=@t]
        ^-  (quip card _state)

        =/  booth-key  (so:dejs:format (~(got by payload) 'key'))
        =/  payload-data  ((om json):dejs:format (~(got by payload) 'data'))
        =/  participant-key  (so:dejs:format (~(got by payload-data) 'key'))

        =/  timestamp  (en-json:html (time:enjs:format now.bowl))
        =/  mq-key  (crip (weld "msg-" timestamp))
        =/  mq  (~(put by mq.state) mq-key [%o payload])

        ::  only support ship invites currently
        =/  participant-ship  `(unit @p)`((slat %p) participant-key)
        ?~  participant-ship  !!  :: only ship invites
        =/  participant-ship=ship  (need participant-ship)

        :: =/  booth-ship  `(unit @p)`((slat %p) booth-key)
        =/  destpath=path  `path`/booths/(scot %p our.bowl)/(scot %tas mq-key)

        =/  booth  (~(get by booths.state) booth-key)
        ?~  booth  !!  :: booth must exist
        =/  booth  (need booth)
        =/  booth-participants  (~(get by participants.state) booth-key)
        =/  booth-participants  ?~(booth-participants ~ (need booth-participants))

        =/  participant  (~(get by booth-participants) participant-key)

        =/  participant
              ?~  participant
                 ~
              ((om json):dejs:format (need participant))

        ::  update participant record to indicated invited
        =/  participant-updates=json
        %-  pairs:enjs:format
        :~
          ['key' s+participant-key]
          ['name' s+participant-key]
          ['status' s+'pending']
          ['created' s+(crip timestamp)]
        ==
        ::  convert to (map @t json)
        =/  participant-updates  ((om json):dejs:format participant-updates)

        ::  apply updates to participant by overlaying updates map
        =/  participant  (~(gas by participant) ~(tap by participant-updates))

        ::  save the updated partcipant to the participants map
        =/  booth-participants  (~(put by booth-participants) participant-key [%o participant])

        ::  create the response
        =/  =response-header:http
          :-  200
          :~  ['Content-Type' 'application/json']
          ==

        ::  encode the proposal as a json string
        =/  body  (crip (en-json:html [%o payload]))

        ::  convert the string to a form that arvo will understand
        =/  data=octs
              (as-octs:mimes:html body)

        =/  participant-effect=json
        %-  pairs:enjs:format
        :~
          ['resource' s+'participant']
          ['effect' s+'add']
          ['key' s+participant-key]
          ['data' [%o participant-updates]]
        ==

        =/  updates=json
        %-  pairs:enjs:format
        :~
          ['action' s+'invite-effect']
          ['context' [%o payload]]
          ['effects' [%a [participant-effect]~]]
        ==

        ::  merge booth data into data element
        =/  payload-data  (~(put by payload-data) 'booth' booth)
        =/  wire-payload  (~(put by payload) 'data' [%o payload-data])

        ~&  >>  "invite-participant-api: {<our.bowl>} poking {<participant-ship>}"

        ::  commit the changes to the store
        :_  state(mq mq, participants (~(put by participants.state) booth-key booth-participants))

        :~
          [%give %fact [/http-response/[p.req]]~ %http-response-header !>(response-header)]
          [%give %fact [/http-response/[p.req]]~ %http-response-data !>(`data)]
          [%give %kick [/http-response/[p.req]]~ ~]
          [%give %fact [/booths]~ %json !>(updates)]
          [%pass destpath %agent [participant-ship %ballot] %poke %json !>([%o wire-payload])]
        ==

      ++  join-remote-booth
        |=  [req=(pair @ta inbound-request:eyre) payload=(map @t json)]
        ^-  (quip card _state)

        =/  resource-key  (so:dejs:format (~(got by payload) 'key'))
        =/  remote-booth-ship=@p  `@p`(slav %p resource-key)
        =/  destpath=path  `path`/booths/(scot %p remote-booth-ship)

        =/  timestamp  (en-json:html (time:enjs:format now.bowl))
        =/  mq-key  (crip (weld "msg-" timestamp))
        =/  mq  (~(put by mq.state) mq-key [%o payload])

        ::=/  requesting-ship=@p  `@p`(slav %p src.bowl)
        ::  send out notifications to all subscribers of this booth
        =/  destpath=path  `path`/booths/(scot %p src.bowl)/(scot %tas mq-key)

        ::  create the response
        =/  =response-header:http
          :-  200
          :~  ['Content-Type' 'text/plain']
          ==

        =/  response  (~(put by payload) 'reaction' s+'ack')

        ::  encode the proposal as a json string
        =/  body  (crip (en-json:html [%o response]))

        ::  convert the string to a form that arvo will understand
        =/  data=octs
              (as-octs:mimes:html body)

        ::  commit the changes to the booth store
        :_  state(mq mq)

        :~
          [%give %fact [/http-response/[p.req]]~ %http-response-header !>(response-header)]
          [%give %fact [/http-response/[p.req]]~ %http-response-data !>(`data)]
          [%give %kick [/http-response/[p.req]]~ ~]
          :: [%pass destpath %agent [remote-booth-ship %ballot] %watch destpath]
          [%pass destpath %agent [remote-booth-ship %ballot] %poke %json !>([%o payload])]
        ==

      ++  add-booth
        |=  [data=(map @t json)]
        ^-  [key=@t json]

        =/  timestamp  (crip (en-json:html (time:enjs:format now.bowl)))
        =/  booth-key  (crip (weld "booth-" (trip timestamp)))
        =/  booth  (~(get by booths.state) booth-key)
        ?:  ?~  booth  %.y  %.n  ~|('booth exists' !!)

        =/  new-booth=json
        %-  pairs:enjs:format
        :~
          ['key' s+booth-key]
          ['type' s+'ship']
          ['image' ~]
          ['owner' s+(crip "{<our.bowl>}")]
          ['created' s+timestamp]
          ['policy' s+'invite-only']
        ==

        =/  new-booth=(map @t json)  ((om json):dejs:format new-booth)
        =/  new-booth  (~(gas by new-booth) ~(tap by data))

        [booth-key [%o new-booth]]

      ++  update-booth
        |=  [key=@t data=(map @t json)]
        ^-  [key=@t json]

        =/  timestamp  (crip (en-json:html (time:enjs:format now.bowl)))
        =/  booth  (~(get by booths.state) key)
        ?:  ?~  booth  %.y  %.n  ~|('booth exists' !!)
        =/  booth  ((om json):dejs:format (need booth))
        =/  booth  (~(put by booth) 'updated' s+timestamp)
        =/  booth  (~(gas by booth) ~(tap by data))

        [key [%o booth]]


      ++  handle-save-booth
        |=  [req=(pair @ta inbound-request:eyre) args=(map @t @t) key=@]
        ^-  (quip card _state)

        =/  payload  (extract-payload req)

        =/  booth  ?~  key  (add-booth payload)  (update-booth `@t`key payload)

        ::  encode the proposal as a json string
        =/  body  (crip (en-json:html +.booth))

        ::  convert the string to a form that arvo will understand
        =/  data=octs
              (as-octs:mimes:html body)

        ::  create the response
        =/  =response-header:http
          :-  200
          :~  ['Content-Type' 'application/json']
          ==

        :: =/  booth-ship=@p  `@p`(slav %p booth-key)
        :: ::  send out notifications to all subscribers of this booth
        :: =/  dest-path=path  `path`/booths/(scot %p booth-ship)

        ::  commit updates to the proposals store
        :_  state(booths (~(put by booths.state) -.booth +.booth))
        :~
          [%give %fact [/http-response/[p.req]]~ %http-response-header !>(response-header)]
          [%give %fact [/http-response/[p.req]]~ %http-response-data !>(`data)]
          [%give %kick [/http-response/[p.req]]~ ~]
          :: [%give %fact ~[dest-path] %json !>(notification)]
        ==

      ::  ARM: ++  handle-put-booth
      ::    payload = {
      ::      action: "create | update | delete | join | leave",
      ::      resource: "booth",
      ::      key: "<booth-key>" | null,  e.g. ~zod | ~bus .. or null when action is create
      ::      data: {
      ::        // anything
      ::      },
      ::    };

      ++  handle-save-proposal
        |=  [req=(pair @ta inbound-request:eyre) args=(map @t @t) booth-key=@t pk=@]
        ^-  (quip card _state)

        =/  timestamp  (crip (en-json:html (time:enjs:format now.bowl)))

        :: if key is null (~), create new booth key; otherwise update
        ::   the booth with the specified key
        =/  proposal-key=@t
              ?~  pk
                (crip (weld "proposal-" (trip timestamp)))
              pk

        =/  til=octs
              (tail body.request.q.req)

        ::  variable to hold request body (as $json)
        =/  payload=json  (need (de-json:html q.til))

        :: ::  variable to convert $json (payload) as map : key => json pairs
        =/  contract  ((om json):dejs:format payload)

        ::  does the title key exist in the payload
        ?.  (~(has by contract) 'title')
          :: nope. send error indicating name doesn't exist in payload
          (send-error req 'error: title attribute required')

        ::  extract the name (s+json) as @t
        =/  proposal-title  (so:dejs:format (~(got by contract) 'title'))

        :: does the booth exist? check agains the booth store.
        =/  booth  (~(get by booths.state) booth-key)
        ?~  booth
          (send-error req 'booth not found')

        ::  get a unit that contains the proposals map
        =/  proposals  (~(get by proposals.state) booth-key)
        ::  extract the proposals map from the unit (or null)
        =/  proposals=(map @t json)
              ?~  proposals
                ~
              (need proposals)

        ::  get the proposal (unit) from the booth's proposal store
        =/  proposal  (~(get by proposals) proposal-key)
        ::  extract the actual proposal (json) from the unit (or null)
        =/  proposal=json
            ?~  proposal
              [%o ~]
            (need proposal)

        ::  convert the proposal json to (map @t json)
        =/  proposal  ((om json):dejs:format proposal)
        ::  merge the incoming changes into the proposal
        =/  proposal  (~(gas by proposal) ~(tap by contract))

        =/  proposal  (~(put by proposal) 'key' s+proposal-key)

        ::  if creating a new booth, tag it with some default info; otherwise
        ::    add an updated timestamp to the booth
        =/  proposal-meta
              ?~  pk
                %-  pairs:enjs:format
                :~
                  ['image' ~]
                  ['owner' s+(crip "{<our.bowl>}")]
                  ['created' s+timestamp]
                ==
              %-  pairs:enjs:format
              :~
                ['updated' s+timestamp]
              ==

        ::  merge booth metadata updates
        =/  proposal  (~(gas by proposal) ~(tap by ((om json):dejs:format proposal-meta)))

        ::  convert the proposal back to json
        =/  proposal  [%o proposal]
        ::  save the changes back to the proposals map
        =/  proposals  (~(put by proposals) proposal-key proposal)

        ::  encode the proposal as a json string
        =/  body  (crip (en-json:html proposal))

        ::  convert the string to a form that arvo will understand
        =/  data=octs
              (as-octs:mimes:html body)

        ::  create the response
        =/  =response-header:http
          :-  200
          :~  ['Content-Type' 'application/json']
          ==

        =/  notification=json
          ?~  pk
            %-  pairs:enjs:format
            :~
              ['action' s+'proposal-created']
              ['data' proposal]
            ==
          %-  pairs:enjs:format
          :~
            ['action' s+'proposal-updated']
            ['data' proposal]
          ==

        =/  booth-ship=@p  `@p`(slav %p booth-key)
        ::  send out notifications to all subscribers of this booth
        =/  dest-path=path  `path`/booths/(scot %p booth-ship)

        ::  commit updates to the proposals store
        :_  state(proposals (~(put by proposals.state) booth-key proposals))
        :~
          [%give %fact [/http-response/[p.req]]~ %http-response-header !>(response-header)]
          [%give %fact [/http-response/[p.req]]~ %http-response-data !>(`data)]
          [%give %kick [/http-response/[p.req]]~ ~]
          [%give %fact ~[dest-path] %json !>(notification)]
        ==

      ::  ARM: ++  handle-delete-booth
      ++  handle-delete-booth
        |=  [req=(pair @ta inbound-request:eyre) args=(map @t @t) booth-key=@t]
        ^-  (quip card _state)

        =/  timestamp  (crip (en-json:html (time:enjs:format now.bowl)))

        ::  encode the proposal as a json string
        =/  body  (crip (en-json:html s+booth-key))

        ::  convert the string to a form that arvo will understand
        =/  data=octs
              (as-octs:mimes:html body)

        ::  create the response
        =/  =response-header:http
          :-  200
          :~  ['Content-Type' 'application/json']
          ==

        ::  commit the changes to the booth store
        :_  state(booths (~(del by booths.state) booth-key))

        :~
          [%give %fact [/http-response/[p.req]]~ %http-response-header !>(response-header)]
          [%give %fact [/http-response/[p.req]]~ %http-response-data !>(`data)]
          [%give %kick [/http-response/[p.req]]~ ~]
        ==

      ++  handle-delete-proposal
        |=  [req=(pair @ta inbound-request:eyre) args=(map @t @t) booth-key=@ proposal-key=@]
        ^-  (quip card _state)

        :: does the booth exist? check agains the booth store.
        =/  booth  (~(get by booths.state) booth-key)
        ?~  booth
          (send-error req 'booth not found')

        ::  retrieve proposals from the store (as unit)
        =/  proposals  (~(get by proposals.state) booth-key)
        ::  convert the unit to proposals map
        =/  proposals=(map @t json)
              ?~  proposals
                ~
              (need proposals)

        ::  remove the proposal from the proposals map
        =/  proposals  (~(del by proposals) proposal-key)

        ::  convert the string to a form that arvo will understand
        =/  data=octs
              (as-octs:mimes:html 'proposal deleted')

        ::  create the response
        =/  =response-header:http
          :-  200
          :~  ['Content-Type' 'text/plain']
          ==

        ::  commit the changes to the store
        :_  state(proposals (~(put by proposals.state) booth-key proposals))

        :~
          [%give %fact [/http-response/[p.req]]~ %http-response-header !>(response-header)]
          [%give %fact [/http-response/[p.req]]~ %http-response-data !>(`data)]
          [%give %kick [/http-response/[p.req]]~ ~]
        ==

      ++  handle-resource-action
        |=  [req=(pair @ta inbound-request:eyre) args=(map @t @t) booth-key=@]
        ^-  (quip card _state)

        ::  all POST payloads are action contracts (see ARM comments)
        =/  payload  (extract-payload req)

        ::  booth actions require custom data (additional attributes/elements)
        :: ?.  (~(has by payload) 'data')
        ::   ~&  >>>  "ballot: handle-put-booth http request payload data not found"
        ::   `state

        =/  action  (so:dejs:format (~(got by payload) 'action'))
        =/  resource  (so:dejs:format (~(got by payload) 'resource'))

        ?+  [resource action]  `state

              [%booth %join]
                =/  key  (so:dejs:format (~(got by payload) 'key'))
                %-  (slog leaf+"ballot: join {<resource>}, {<key>}..." ~)
                (join-remote-booth req payload)

              [%booth %invite]
                =/  key  (so:dejs:format (~(got by payload) 'key'))
                %-  (slog leaf+"ballot: invite {<key>}..." ~)
                (invite-participant-api req payload key)

              [%booth %accept]
                =/  key  (so:dejs:format (~(got by payload) 'key'))
                %-  (slog leaf+"ballot: accept {<key>}..." ~)
                (accept-invite-api req payload key)

              [%booth %save-proposal]
                =/  key  (so:dejs:format (~(got by payload) 'key'))
                %-  (slog leaf+"ballot: save-proposal {<key>}..." ~)
                (save-proposal-api req payload)

              [%booth %delete-proposal]
                =/  key  (so:dejs:format (~(got by payload) 'key'))
                %-  (slog leaf+"ballot: delete-proposal {<key>}..." ~)
                (delete-proposal-api req payload booth-key)

              [%booth %delete-participant]
                =/  key  (so:dejs:format (~(got by payload) 'key'))
                %-  (slog leaf+"ballot: delete-participant {<key>}..." ~)
                (delete-participant-api req payload booth-key)

              [%booth %cast-vote]
                %-  (slog leaf+"ballot: cast-vote received over http..." ~)
                (cast-vote-api req payload)

        ==

      ++  handle-save-participant
        |=  [req=(pair @ta inbound-request:eyre) args=(map @t @t) booth-key=@t pk=@]
        ^-  (quip card _state)

        ::  can only save participant data (e.g. invite) from our own ship
        ?.  =(our.bowl src.bowl)
          (send-error req 'remote participant operations not allowed')

        =/  timestamp  (crip (en-json:html (time:enjs:format now.bowl)))

        =/  til=octs
              (tail body.request.q.req)

        ::  variable to hold request body (as $json)
        =/  payload=json  (need (de-json:html q.til))

        :: ::  variable to convert $json (payload) as map : key => json pairs
        =/  contract  ((om json):dejs:format payload)

        ::  does the name exist in the payload
        ?.  (~(has by contract) 'name')
          :: nope. send error indicating name doesn't exist in payload
          (send-error req 'error: name attribute required')

        ::  convert the name (s+json) to @t
        =/  participant-name  (so:dejs:format (~(got by contract) 'name'))

        :: does the booth exist? check agains the booth store.
        =/  booth  (~(get by booths.state) booth-key)
        ?~  booth
          (send-error req 'booth not found')

        =/  booth  (need booth)

        ::  retrieve the participants (unit) from the store
        =/  participants  (~(get by participants.state) booth-key)
        ::  extract the participants map from the unit (or null)
        =/  participants=(map @t json)
              ?~  participants
                ~
              (need participants)

        ::  if a participant key was supplied in the URL, but not found in the participant list
        ::    you can't update
        ?:  ?&  !=(pk ~)
                !(~(has by participants) pk)
            ==
            (send-error req 'error: participant not found')

        :: if key is null (~), create new booth key; otherwise update
        ::   the participant with the specified key
        =/  participant-key
              ?~  pk
                 participant-name
              `@t`pk

        ::  if we're attempting to create a participant record,
        ::   but the participant already exists by name, error
        ?:  ?&  =(pk ~)
                (~(has by participants) participant-name)
            ==
            (send-error req 'error: participant exists by name')

        ?.  =(participant-key participant-name)
              (send-error req 'error: name changes not allowed')

        ::  retrieve the participant (unit) from the participants map
        =/  participant  (~(get by participants) participant-key)

        ::  extract the participant json from the unit
        =/  participant=json
            ?~  participant
              [%o ~]
            (need participant)

        ::  convert the participant (json) to (map @t json)
        =/  participant  ((om json):dejs:format participant)
        ::  merge the existing participant map with the incoming changes
        =/  participant  (~(gas by participant) ~(tap by contract))

        =/  participant  (~(put by participant) 'key' s+participant-key)

        ::  if creating a new booth, tag it with some default info; otherwise
        ::    add an updated timestamp to the booth
        =/  participant-meta
              ?~  pk
                %-  pairs:enjs:format
                :~
                  ['image' ~]
                  ['status' s+'invited']
                  ['owner' s+(crip "{<our.bowl>}")]
                  ['created' s+timestamp]
                ==
              %-  pairs:enjs:format
              :~
                ['updated' s+timestamp]
              ==

        ::  merge booth metadata updates
        =/  participant  (~(gas by participant) ~(tap by ((om json):dejs:format participant-meta)))

        ::  convert the participant back to json
        =/  participant  [%o participant]
        ::  save the changes to the participants map
        =/  participants  (~(put by participants) participant-key participant)

        ::  encode the participant as json string
        =/  body  (crip (en-json:html participant))

        ::  convert the string to a form that arvo will understand
        =/  data=octs
              (as-octs:mimes:html body)

        ::  create the response
        =/  =response-header:http
          :-  200
          :~  ['Content-Type' 'application/json']
          ==

        =/  booth-ship=@p  `@p`(slav %p booth-key)
        ::  send out notifications to all subscribers of this booth
        =/  dest-path=path  `path`/booths/(scot %p booth-ship)
        ::  build notification w/ 'participant-added' action to dispatch
        ::   to all subscribers. include participant information.
        =/  notification
          %-  pairs:enjs:format
          :~
            ['action' s+'participant-added']
            ['participant' participant]
          ==

        =/  effects=(list card)
              :*
                [%give %fact [/http-response/[p.req]]~ %http-response-header !>(response-header)]
                [%give %fact [/http-response/[p.req]]~ %http-response-data !>(`data)]
                [%give %kick [/http-response/[p.req]]~ ~]
                [%give %fact ~[dest-path] %json !>(notification)]
                ~
              ==

        ::  poke participant ship to join this booth
        =/  participant-ship=@p  `@p`(slav %p participant-name)

        =/  effects
              ?~  pk
                =/  notification
                  %-  pairs:enjs:format
                  :~
                    ['action' s+'receive-invitation']
                    ['booth' booth]
                  ==
                (snoc effects [%pass /ballot %agent [participant-ship %ballot] %poke %json !>(notification)])
              effects

        :: ~&  >>  effects

        ::  commit updates to the store
        :_  state(participants (~(put by participants.state) booth-key participants))

        [effects]
        :: :~
        ::   [%give %fact [/http-response/[p.req]]~ %http-response-header !>(response-header)]
        ::   [%give %fact [/http-response/[p.req]]~ %http-response-data !>(`data)]
        ::   [%give %kick [/http-response/[p.req]]~ ~]
        ::   ::  send out notifications to all subscribers of this booth
        ::   [%give %fact ~[dest-path] %json !>(notification)]
        :: ==

      ++  handle-delete-participant
        |=  [req=(pair @ta inbound-request:eyre) args=(map @t @t) booth-key=@ participant-key=@]
        ^-  (quip card _state)

        :: does the booth exist? check agains the booth store.
        =/  booth  (~(get by booths.state) booth-key)
        ?~  booth
          (send-error req 'booth not found')

        ::  retrieve the participants (unit) from the store
        =/  participants  (~(get by participants.state) booth-key)
        ::  extract the participants map from the unit (or null)
        =/  participants=(map @t json)
              ?~  participants
                ~
              (need participants)

        ::  remove the participant from the participants map
        =/  participants  (~(del by participants) participant-key)

        ::  convert the string to a form that arvo will understand
        =/  data=octs
              (as-octs:mimes:html 'participant deleted')

        ::  create the response
        =/  =response-header:http
          :-  200
          :~  ['Content-Type' 'text/plain']
          ==

        ::  commit the changes to the store
        :_  state(participants (~(put by participants.state) booth-key participants))

        :~
          [%give %fact [/http-response/[p.req]]~ %http-response-header !>(response-header)]
          [%give %fact [/http-response/[p.req]]~ %http-response-data !>(`data)]
          [%give %kick [/http-response/[p.req]]~ ~]
        ==

      ++  handle-cast-vote
        |=  [req=(pair @ta inbound-request:eyre) args=(map @t @t) booth-key=@ proposal-key=@]
        ^-  (quip card _state)

        =/  booth  (~(get by booths.state) booth-key)
        ?~  booth
          (send-error req 'booth not found')

        =/  booth  (need booth)
        =/  booth  ((om json):dejs:format booth)

        =/  booth-owner  (~(get by booth) 'owner')
        ?~  booth-owner
          (send-error req 'booth owner not found')

        =/  booth-owner  (need booth-owner)
        =/  booth-owner  `@p`(so:dejs:format booth-owner)

        =/  timestamp  (crip (en-json:html (time:enjs:format now.bowl)))

        =/  til=octs
              (tail body.request.q.req)

        ::  variable to hold request body (as $json)
        =/  payload=json  (need (de-json:html q.til))

        :: ::  variable to convert $json (payload) as map : key => json pairs
        =/  contract  ((om json):dejs:format payload)

        ::  does the label key exist in the payload
        ?.  (~(has by contract) 'label')
          :: nope. send error indicating label doesn't exist in payload
          (send-error req 'error: label attribute required')

        ::  extract the name (s+json) as @t
        =/  choice-label  (so:dejs:format (~(got by contract) 'label'))

        =/  ball
          %-  pairs:enjs:format
          :~
            ['booth' s+booth-key]
            ['proposal' s+proposal-key]
            ['participant' s+(crip "{<our.bowl>}")]
            ['choice-label' s+choice-label]
            ['caston' s+timestamp]
          ==

        ::  encode the vote record as a json string
        =/  body  (crip (en-json:html s+'ballot sent'))

        ::  convert the string to a form that arvo will understand
        =/  data=octs
              (as-octs:mimes:html body)

        ::  create the response
        =/  =response-header:http
          :-  200
          :~  ['Content-Type' 'application/json']
          ==

        :_  state

        :~
          [%give %fact [/http-response/[p.req]]~ %http-response-header !>(response-header)]
          [%give %fact [/http-response/[p.req]]~ %http-response-data !>(`data)]
          [%give %kick [/http-response/[p.req]]~ ~]
          [%pass /ballot %agent [booth-owner %ballot] %poke %vote-cast !>(ball)]
        ==

      ::  END OF REST API
      :: **********************************************
    --

::  ARM:  on-watch
::  @author:  ~lodlev-migdev
::    Allow agents and calling clients (e.g. UI front-ends) to subscribe to
::      various channels. Our ballot agent will write to these channels
::      when voting related events occur (e.g. booth created).
++  on-watch
  |=  =path
  ^-  (quip card _this)

  ?+    path  (on-watch:def path)
      ::  ~lodlev-migdev - allow external agents (including UI clients) to subscribe
      ::    to the /contexts channel.
      [%updates *]
        ~&  >  "ballot: client subscribed to {(spud path)}."
        `this

      [%booths ~]
        ?:  =(our.bowl src.bowl)
          `this
        ~&  >>  "remote ships not allowed to watch /booths"
        !!

      :: crash on booth any of the following:
      ::   !! booth not found in store
      ::   !! booth not found in participants store
      ::   !! participant not found in participants store
      :: according to docs...
      ::    "The (unit tang) in the %watch-ack will be null if processing succeeded,
      ::       and non-null if it crashed, with a stack trace in the tang."
      ::  see:  https://urbit.org/docs/userspace/gall-guide/8-subscriptions
      [%booths @ ~]
        ~&  >  "ballot: client subscribed to {(spud path)}."

        =/  booth-key  (key-from-path:util i.t.path)
        =/  booth  (~(get by booths.state) booth-key)
        =/  booth  ?~(booth ~ (need booth))
        =/  booth-participants  (~(get by participants.state) booth-key)
        =/  booth-participants  ?~(booth-participants ~ (need booth-participants))
        =/  booth-proposals  (~(get by proposals.state) booth-key)
        =/  booth-proposals  ?~(booth-proposals ~ (need booth-proposals))
        =/  booth-votes  (~(get by votes.state) booth-key)
        =/  booth-votes  ?~(booth-votes ~ (need booth-votes))

        =/  data
          %-  pairs:enjs:format
          :~
            ['booth' booth]
            ['proposals' [%o booth-proposals]]
            ['participants' [%o booth-participants]]
            ['votes' [%o booth-votes]]
          ==

        ::  https://urbit.org/docs/userspace/gall-guide/8-subscriptions#incoming-subscriptions
        ::  when there's a new subscription, you can send a %fact back with an empty (list path),
        ::    and it'll only go to the new subscriber. This is most useful when you want to give the
        ::    subscriber some initial state, which you otherwise couldn't do without sending it to everyone.
        =/  action-payload
          %-  pairs:enjs:format
          :~
            ['action' s+'initial']
            ['data' data]
          ==

        :_  this
        :~  [%give %fact ~ %json !>(action-payload)]
        ==

      ::  ~lodlev-migdev - allow external agents (including UI clients) to subscribe
      ::    to the /notifications channel.
      [%notifications *]
        ~&  >  "ballot: client subscribed to {(spud path)}."
        `this

      ::  ~lodlev-migdev - print message when eyre subscribes to our http-response path
      ::  TODO: Do not allow anything other than Eyre to suscribe to this path.
      [%http-response *]
        ~&  >  "ballot: client subscribed to {(spud path)}."
        `this
  ==

::
++  on-leave  on-leave:def

::  ARM:  on-peek
::   Handle scry calls here
::  reference: https://urbit-org-j1prh9inz-urbit.vercel.app/docs/userspace/gall-guide/10-scry
++  on-peek
  |=  =path
  ^-  (unit (unit cage))

  ~&  >>  "ballot: scry called with path = '{<path>}'"

  ?+    path  (on-peek:def path)
      ::  list of booths scry => /x/booths
      [%x %booths ~]
        ``json+!>([%o booths.state])

      ::  ~lodlev-migdev
      ::  list of booths scry => /x/booths/[ship|group]/proposals
      ::  to indicate ship, put tilde (~) in front of ship name; otherwise
      ::  for all other entities (e.g. groups), pass in just the name
      ::    examples:
      ::       /x/booths/~zod/proposals
      ::       /x/booths/my-group/proposals
      [%x %booths @ %proposals ~]
        =/  key  (key-from-path:util i.t.t.path)
        ~&  >>  "ballot: extracting proposals for booth {<key>}..."
        =/  booth-proposals  (~(get by proposals.state) key)
        ?~  booth-proposals  ``json+!>(~)
        ``json+!>([%o (need booth-proposals)])

      [%x %booths @ %proposals @ %votes ~]
        =/  booth-key  (key-from-path:util i.t.t.path)
        =/  proposal-key  (key-from-path:util i.t.t.t.t.path)
        ~&  >>  "ballot: extracting votes for booth {<booth-key>}, proposal {<proposal-key>}..."
        =/  booth-proposals  (~(get by votes.state) booth-key)
        ?~  booth-proposals  ``json+!>(~)
        =/  booth-proposals  (need booth-proposals)
        =/  proposal-votes  (~(get by booth-proposals) proposal-key)
        ?~  proposal-votes  ``json+!>(~)
        ``json+!>((need proposal-votes))

      [%x %booths @ %votes ~]
        =/  booth-key  (key-from-path:util i.t.t.path)
        ~&  >>  "ballot: extracting votes for booth {<booth-key>}..."
        =/  booth-proposals  (~(get by votes.state) booth-key)
        ?~  booth-proposals  ``json+!>(~)
        ``json+!>([%o (need booth-proposals)])

      ::  ~lodlev-migdev
      ::  list of booths scry => /x/booths/[ship|group]/proposals
      ::  to indicate ship, put tilde (~) in front of ship name; otherwise
      ::  for all other entities (e.g. groups), pass in just the name
      ::    examples:
      ::       /x/booths/~zod/participants
      ::       /x/booths/my-group/participants
      [%x %booths @ %participants ~]
        =/  key  (key-from-path:util i.t.t.path)
        ~&  >>  "ballot: extracting participants for booth {<key>}..."
        =/  participants  (~(get by participants.state) key)
        ?~  participants  ``json+!>(~)
        ``json+!>([%o (need participants)])
  ==

::
++  on-agent
  |=  [=wire =sign:agent:gall]
  ^-  (quip card _this)

  |^
  =/  wirepath  `path`wire
  %-  (slog leaf+"ballot: {<wirepath>} data received..." ~)

  ?+    wire  (on-agent:def wire sign)

    :: handle updates coming in from group store
    [%group ~]
      ?+    -.sign  (on-agent:def wire sign)
        %watch-ack
          ?~  p.sign
            %-  (slog leaf+"ballot: group subscription succeeded" ~)
            `this
          %-  (slog leaf+"ballot: group subscription failed" ~)
          `this
    ::
        %kick
          %-  (slog leaf+"ballot: group kicked us, resubscribing..." ~)
          :_  this
          :~  [%pass /group %agent [our.bowl %group-store] %watch /groups]
          ==
    ::
        %fact
          %-  (slog leaf+"ballot: received fact from group => {<p.cage.sign>}" ~)
          ?+    p.cage.sign  (on-agent:def wire sign)
              %group-update-0
                =+  !<(=update:group-store q.cage.sign)
            `this
          ==
      ==

    [%booths @ @ ~]

        ?+  -.sign  (on-agent:def wire sign)
          %poke-ack
            =/  reaction  ?~(p.sign 'nod' 'nack')
            =/  msg-id  (key-from-path:util i.t.t.wire)
            (handle-poke-ack reaction msg-id)
        ==

    [%booths @ @ @ %start-poll ~]
      :: ~&  >>  [wire sign]
      =/  booth-key  (key-from-path:util i.t.wire)
      =/  proposal-key  (key-from-path:util i.t.t.wire)
      ?+    -.sign  (on-agent:def wire sign)
          %poke-ack
            ?~  p.sign
                  %-  (slog leaf+"start-poll thread started successfully" ~)
                  `this
                %-  (slog leaf+"start-poll failed to start" u.p.sign)
                `this

          %fact
            ?+  p.cage.sign  (on-agent:def wire sign)
                  %thread-fail
                    =/  err  !<  (pair term tang)  q.cage.sign
                    %-  (slog leaf+"start-poll thread failed: {(trip p.err)}" q.err)
                    `this
                  %thread-done
                    (on-start-poll booth-key proposal-key)
            ==
      ==

    [%booths @ @ @ %end-poll ~]
      :: ~&  >>  [wire sign]
      =/  booth-key  (key-from-path:util i.t.wire)
      =/  proposal-key  (key-from-path:util i.t.t.wire)
      ?+    -.sign  (on-agent:def wire sign)
          %poke-ack
            ?~  p.sign
              %-  (slog leaf+"end-poll thread started successfully" ~)
              `this
            %-  (slog leaf+"end-poll failed to start" u.p.sign)
            `this

          %fact
            ?+  p.cage.sign  (on-agent:def wire sign)
                  %thread-fail
                    =/  err  !<  (pair term tang)  q.cage.sign
                    %-  (slog leaf+"end-poll thread failed: {(trip p.err)}" q.err)
                    `this
                  %thread-done
                    (on-end-poll booth-key proposal-key)
            ==
      ==

    [%booths @ ~]
      =/  booth-key  (key-from-path:util i.t.wire)
      ?-    -.sign
        %poke-ack
          ?~  p.sign
            ((slog leaf+"ballot: {<wirepath>} poke succeeded" ~) `this)
          ((slog leaf+"ballot: {<wirepath>} poke failed" ~) `this)

        %watch-ack
          ?~  p.sign
            ((slog leaf+"ballot: subscribed to {<wirepath>}" ~) `this)
          ((slog leaf+"ballot: {<wirepath>} subscription failed" ~) `this)

        %kick
          %-  (slog leaf+"ballot: {<wirepath>} got kick, resubscribing..." ~)
          :_  this
          :~  [%pass /booths/(scot %tas booth-key) %agent [src.bowl %ballot] %watch /booths/(scot %tas booth-key)]
          ==

        %fact
          ?+    p.cage.sign  (on-agent:def wire sign)

            %json
              =/  jon  !<(json q.cage.sign)
              ~&  >  jon

              =/  payload  ((om json):dejs:format jon)

              =/  action  (~(get by payload) 'action')
              ?~  action
                    ~&  >>>  "null action in on-agent handler => {<payload>}"
                    `this

              =/  action  (so:dejs:format (need action))

              ::  no need to gift ourselves. if this ship generated the gift, the action
              ::    has already occurred
              ?:  =(our.bowl src.bowl)
                :: ~&  >>  "skipping gift to ourselves..."  `this
                ?+  action  ~&  >>  "skipping gift to ourselves..."  `this
                   %save-proposal
                    %-  (slog leaf+"ballot: [set-booth-timer] => proposal updates. setting timers..." ~)
                    (on-proposal-changed booth-key payload)
                ==

              ?+  action  `this

                %initial
                  (handle-initial payload)

                %save-proposal
                  (handle-save-proposal payload)

                %delete-proposal
                  (handle-delete-proposal booth-key payload)

                %delete-participant
                  (handle-delete-participant booth-key payload)

                %cast-vote
                  (handle-cast-vote booth-key payload)

              ==

          ==
      ==
  ==
  ++  count-vote
    |:  [vote=`json`~ results=`(map @t json)`~]

    %-  (slog leaf+"count-vote called. [vote={<vote>}, results={<results>}]")

    =/  v  ((om json):dejs:format vote)
    =/  choice  ((om json):dejs:format (~(got by v) 'choice'))
    =/  label  (so:dejs:format (~(got by choice) 'label'))
    =/  choice-count=@ud  (ni:dejs:format (~(got by results) label))
    =/  choice-count=@ud  (add choice-count 1) :: plug in delegate count here

    =/  choice-count=@ta  `@ta`choice-count
    =.  results  (~(put by results) label [%n choice-count])

    results

  ++  tally-results
    |=  [booth-key=@t proposal-key=@t]

    %-  (slog leaf+"tally-results called. [booth-key='{<booth-key>}', proposal-key='{<proposal-key>}']")

    =/  booth-proposals  (~(get by votes.state) booth-key)
    =/  booth-proposals  (need booth-proposals)

    =/  proposal-votes  (~(get by booth-proposals) proposal-key)
    =/  proposal-votes  ((om json):dejs:format (need proposal-votes))

    =/  votes  ~(val by proposal-votes)

    =/  results  (roll votes count-vote)

    results

  ++  on-start-poll
    |=  [booth-key=@t proposal-key=@t]
    ^-  (quip card _this)

    %-  (slog leaf+"on-start-poll called" ~)
    =/  context=json
    %-  pairs:enjs:format
    :~
      ['booth-key' s+booth-key]
      ['proposal-key' s+proposal-key]
    ==

    =/  status-data=json
    %-  pairs:enjs:format
    :~
      ['status' s+'started']
    ==

    =/  status-effect=json
    %-  pairs:enjs:format
    :~
      ['resource' s+'booth']
      ['effect' s+'update']
      ['data' status-data]
    ==

    =/  effects=json
    %-  pairs:enjs:format
    :~
      ['action' s+'booth-effect']
      ['context' context]
      ['effects' [%a [status-effect]~]]
    ==

    %-  (slog leaf+"sending poll started effect to subcribers => {<effects>}..." ~)

    :_  this
    :~  [%give %fact [/booths]~ %json !>(effects)]
    ==

  ++  on-end-poll
    |=  [booth-key=@t proposal-key=@t]
    ^-  (quip card _this)

    %-  (slog leaf+"on-end-poll called" ~)

    =/  poll-results  (tally-results booth-key proposal-key)

    %-  (slog leaf+"poll results are in!!! => {<poll-results>}" ~)

    =/  context=json
    %-  pairs:enjs:format
    :~
      ['booth-key' s+booth-key]
      ['proposal-key' s+proposal-key]
    ==

    =/  results-data=json
    %-  pairs:enjs:format
    :~
      ['status' s+'ended']
      ['results' [%o poll-results]]
    ==

    =/  results-effect=json
    %-  pairs:enjs:format
    :~
      ['resource' s+'booth']
      ['effect' s+'update']
      ['data' results-data]
    ==

    =/  effects=json
    %-  pairs:enjs:format
    :~
      ['action' s+'booth-effect']
      ['context' context]
      ['effects' [%a [results-effect]~]]
    ==

    %-  (slog leaf+"sending poll results to subcribers => {<effects>}..." ~)

    :_  this
    :~  [%give %fact [/booths]~ %json !>(effects)]
    ==

  ++  on-proposal-changed
    |=  [booth-key=@t payload=(map @t json)]
    ^-  (quip card _this)

    =/  timestamp  (crip (en-json:html (time:enjs:format now.bowl)))

    =/  data  ((om json):dejs:format (~(got by payload) 'data'))
    =/  proposal-key  (so:dejs:format (~(got by data) 'key'))

    ::  find the existing poll for this proposal (if it exists)
    =/  booth-polls  (~(get by polls.state) booth-key)
    =/  booth-polls  ?~(booth-polls ~ (need booth-polls))
    =/  poll  (~(get by booth-polls) proposal-key)
    =/  poll  ?~(poll ~ ((om json):dejs:format (need poll)))

    =/  poll-status  (~(get by poll) 'status')
    =/  poll-status  ?~(poll-status 'scheduled' (so:dejs:format (need poll-status)))

    ::  anything outside of a scheduled poll cannot be changed (active, in-progress, ended, etc...)
    ::    all of these states mean the poll can no longer be changed.
    ?.  =(poll-status 'scheduled')
          =/  context=json
          %-  pairs:enjs:format
          :~
            ['booth-key' s+booth-key]
            ['proposal-key' s+proposal-key]
          ==

          =/  error-key  (crip (weld "poll-started-error-" (trip timestamp)))

          =/  error-data=json
          %-  pairs:enjs:format
          :~
            ['key' s+error-key]
            ['message' s+(crip "cannot change proposal. poll status is {<poll-status>}.")]
          ==

          =/  error-effect=json
          %-  pairs:enjs:format
          :~
            ['resource' s+'booth']
            ['effect' s+'error']
            ['data' error-data]
          ==

          =/  effects=json
          %-  pairs:enjs:format
          :~
            ['action' s+'save-proposal-effect']
            ['context' context]
            ['effects' [%a [error-effect]~]]
          ==

          :: give an error-effect to any subcribers
          :_  this
          :~  [%give %fact [/booths]~ %json !>(effects)]
          ==

    =|  effects=(list card)
    =.  effects  ~

    =/  poll-start-date  (~(get by poll) 'start')
    =/  poll-start-date  ?~(poll-start-date ~ (du:dejs:format (need poll-start-date)))

    =|  result=[effects=(list card) poll=(map @t json)]

    =/  proposal-start-date  (~(get by data) 'start')
    =.  result  ?.  ?=(~ proposal-start-date)
      :: ::  did the start date of the poll change?
      =/  proposal-start-date=@da  (du:dejs:format (need proposal-start-date))
      =.  result
            ?.  =(proposal-start-date poll-start-date)
                  %-  (slog leaf+"ballot: proposal {<proposal-key>} start date changed. rescheduling..." ~)
                  ::  get the current thread id of the end poll timer so that we can kill it and
                  ::    schedule a new timer under a new thread
                  =/  tid  (~(get by poll) 'tid-start')
                  =/  tis-active  ?~(tid %.n %.y)
                  =/  tid  ?.(tis-active 't000' (so:dejs:format (need tid)))
                  =/  wire  /booths/(scot %tas booth-key)/(scot %tas proposal-key)/(scot %tas tid)/start-poll
                  =/  effects  ?.  tis-active  effects
                        =/  effects  (snoc effects [%pass wire %agent [our.bowl %spider] %poke %spider-stop !>([tid %.y])])
                        =/  effects  (snoc effects [%pass wire %agent [our.bowl %spider] %leave ~])
                        effects
                  ::  add an effect to start a new timer with the updated date/time
                  =/  tid  `@t`(cat 3 'thread_start_' (scot %uv (sham eny.bowl)))
                  =/  targs  [~ `tid byk.bowl %booth-timer !>(proposal-start-date)]
                  =/  wire  /booths/(scot %tas booth-key)/(scot %tas proposal-key)/(scot %tas tid)/start-poll

                  =/  effects  (snoc effects [%pass wire %agent [our.bowl %spider] %watch /thread-result/[tid]])
                  =/  effects  (snoc effects [%pass wire %agent [our.bowl %spider] %poke %spider-start !>(targs)])

                  =/  poll  (~(put by poll) 'start' (sect:enjs:format proposal-start-date))
                  =/  poll  (~(put by poll) 'tid-start' s+tid)
                  [effects poll]
                %-  (slog leaf+"ballot: proposal {<proposal-key>} start date unchanged. no need to reschedule." ~)
                [effects poll]
          [effects.result poll.result]
        %-  (slog leaf+"ballot: start date not found in payload. no need to reschedule poll start." ~)
        [effects poll]

    =/  effects  effects.result
    =/  poll  poll.result

    =/  poll-end-date  (~(get by poll) 'end')
    =/  poll-end-date  ?~(poll-end-date ~ (du:dejs:format (need poll-end-date)))

    =/  proposal-end-date  (~(get by data) 'end')
    =.  result  ?.  ?=(~ proposal-end-date)
      :: ::  did the end date of the poll change?
      =/  proposal-end-date=@da  (du:dejs:format (need proposal-end-date))
      =.  result
          ?.  =(proposal-end-date poll-end-date)
                %-  (slog leaf+"ballot: proposal {<proposal-key>} end date changed. rescheduling..." ~)
                ::  get the current thread id of the end poll timer so that we can kill it and
                ::    schedule a new timer under a new thread
                =/  tid  (~(get by poll) 'tid-end')
                =/  tis-active  ?~(tid %.n %.y)
                =/  tid  ?.(tis-active 't001' (so:dejs:format (need tid)))
                =/  wire  /booths/(scot %tas booth-key)/(scot %tas proposal-key)/(scot %tas tid)/end-poll
                =/  effects  ?.  tis-active  effects
                      =/  effects  (snoc effects [%pass wire %agent [our.bowl %spider] %poke %spider-stop !>([tid %.y])])
                      =/  effects  (snoc effects [%pass wire %agent [our.bowl %spider] %leave ~])
                      effects
                ::  add an effect to start a new timer with the updated date/time
                =/  tid  `@t`(cat 3 'thread_end_' (scot %uv (sham eny.bowl)))
                =/  targs  [~ `tid byk.bowl %booth-timer !>(proposal-end-date)]
                =/  wire  /booths/(scot %tas booth-key)/(scot %tas proposal-key)/(scot %tas tid)/end-poll

                =/  effects  (snoc effects [%pass wire %agent [our.bowl %spider] %watch /thread-result/[tid]])
                =/  effects  (snoc effects [%pass wire %agent [our.bowl %spider] %poke %spider-start !>(targs)])

                =/  poll  (~(put by poll) 'end' (sect:enjs:format proposal-end-date))
                =/  poll  (~(put by poll) 'tid-end' s+tid)
                [effects poll]
              %-  (slog leaf+"ballot: proposal {<proposal-key>} end date unchanged. no need to reschedule." ~)
              [effects poll]
          [effects.result poll.result]
        %-  (slog leaf+"ballot: end date not found in payload. no need to reschedule poll end." ~)
        [effects poll]

    =/  poll  (~(put by poll.result) 'status' s+'scheduled')
    =/  booth-polls  (~(put by booth-polls) proposal-key [%o poll])

    ::  in case of scheduling change:
    ::
    ::  1) generate cards to kill any existing start/end times that have changed
    ::  2) generate cards to start new schedules based on changes to start/end times
    ::

    ::  for more information on how to setup/start a thread from Gall agent,
    ::    see:  https://urbit.org/docs/userspace/threads/reference#start-thread

    ::  commit any scheduling changes to the polls store
    :_  this(polls (~(put by polls.state) booth-key booth-polls))

    ::  send out effects to reschedule the poll
    [effects.result]

  ++  handle-cast-vote
    |=  [booth-key=@t payload=(map @t json)]

    =/  context  (~(get by payload) 'context')
    =/  context  ?~(context ~ ((om json):dejs:format (need context)))

    =/  data  (~(get by payload) 'data')
    =/  data  ?~(data ~ ((om json):dejs:format (need data)))

    =/  proposal-key  (so:dejs:format (~(got by context) 'proposal-key'))
    =/  participant-key  (so:dejs:format (~(got by context) 'participant-key'))

    =/  booth-proposals  (~(get by votes.state) booth-key)
    =/  booth-proposals  ?~(booth-proposals ~ (need booth-proposals))

    =/  proposal-votes  (~(get by booth-proposals) proposal-key)
    =/  proposal-votes  ?~(proposal-votes ~ ((om json):dejs:format (need proposal-votes)))

    =/  participant-vote  (~(get by proposal-votes) participant-key)
    =/  participant-vote  ?~(participant-vote ~ ((om json):dejs:format (need participant-vote)))

    ::  overwrite the current vote with the subscription update version
    =/  participant-vote  (~(gas by participant-vote) ~(tap by data))

    =/  proposal-votes  (~(put by proposal-votes) participant-key [%o participant-vote])
    =/  booth-proposals  (~(put by booth-proposals) proposal-key [%o proposal-votes])

    =/  booth-participants  (~(get by participants.state) booth-key)
    =/  booth-participants  ?~(booth-participants ~ (need booth-participants))
    =/  participant  (~(get by booth-participants) participant-key)
    =/  participant  ?~(participant ~ (need participant))

    =/  booth-participants  (~(put by booth-participants) participant-key participant)

    =/  vote-effect=json
    %-  pairs:enjs:format
    :~
      ['resource' s+'vote']
      ['effect' s+'update']
      ['key' s+participant-key]
      ['data' [%o participant-vote]]
    ==

    =/  effects=json
    %-  pairs:enjs:format
    :~
      ['action' s+'cast-vote-effect']
      ['context' [%o context]]
      ['effects' [%a [vote-effect]~]]
    ==

    ::  no changes to state. state will change when poke ack'd
    :_  this(participants (~(put by participants.state) booth-key booth-participants), votes (~(put by votes.state) booth-key booth-proposals))

    :~
      ::  for clients (e.g. UI) and "our" agent, send to generic /booths path
      [%give %fact [/booths]~ %json !>(effects)]
    ==


  ++  handle-initial
    |=  [payload=(map @t json)]

    =/  data  (~(get by payload) 'data')
    ?~  data
          ~&  >>>  "handle-initial missing data"
          `this

    =/  data=(map @t json)  ((om json):dejs:format (need data))

    =/  booth  (~(get by data) 'booth')
    =/  booth  ?~(booth ~ ((om json):dejs:format (need booth)))
    =/  proposals  (~(get by data) 'proposals')
    =/  proposals  ?~(proposals ~ ((om json):dejs:format (need proposals)))
    =/  participants  (~(get by data) 'participants')
    =/  participants  ?~(participants ~ ((om json):dejs:format (need participants)))

    =/  booth-key  (so:dejs:format (~(got by booth) 'key'))

    =/  booth-proposals  (~(get by proposals.state) booth-key)
    =/  booth-proposals  ?~(booth-proposals ~ (need booth-proposals))
    =/  booth-proposals  (~(gas by booth-proposals) ~(tap by proposals))

    =/  booth-participants  (~(get by participants.state) booth-key)
    =/  booth-participants  ?~(booth-participants ~ (need booth-participants))
    =/  booth-participants  (~(gas by booth-participants) ~(tap by participants))

    =/  context=json
    %-  pairs:enjs:format
    :~
      ['key' s+booth-key]
    ==

    =/  initial-effect=json
    %-  pairs:enjs:format
    :~
      ['resource' s+'booth']
      ['effect' s+'initial']
      ['key' s+booth-key]
      ['data' [%o data]]
    ==

    =/  effects=json
    %-  pairs:enjs:format
    :~
      ['action' s+'initial-effect']
      ['context' context]
      ['effects' [%a [initial-effect]~]]
    ==

    :_  this(booths (~(put by booths.state) booth-key [%o booth]), proposals (~(put by proposals.state) booth-key booth-proposals), participants (~(put by participants.state) booth-key booth-participants))

    :~
      ::  for clients (e.g. UI) and "our" agent, send to generic /booths path
      [%give %fact [/booths]~ %json !>(effects)]
    ==

  ++  handle-save-proposal
    |=  [payload=(map @t json)]

    =/  data  (~(get by payload) 'data')
    ?~  data
          ~&  >>>  "handle-save-proposal missing data"
          `this

    =/  data=(map @t json)  ((om json):dejs:format (need data))
    =/  booth-key  (so:dejs:format (~(got by payload) 'key'))

    =/  timestamp  (en-json:html (time:enjs:format now.bowl))

    =/  proposal-key  (so:dejs:format (~(got by data) 'key'))

    =/  booth-proposals  (~(get by proposals.state) booth-key)
    =/  booth-proposals  ?~(booth-proposals ~ (need booth-proposals))
    =/  proposal  (~(get by booth-proposals) proposal-key)
    =/  is-update  ?~(proposal %.n %.y)
    =/  proposal  ?~(proposal ~ ((om json):dejs:format (need proposal)))
    =/  proposal  (~(gas by proposal) ~(tap by data))
    =/  booth-proposals  (~(put by booth-proposals) proposal-key [%o proposal])

    =/  proposal-effect=json
    %-  pairs:enjs:format
    :~
      ['resource' s+'proposal']
      ['effect' s+?:(is-update 'update' 'add')]
      ['key' s+proposal-key]
      ['data' [%o data]]
    ==

    =/  effects=json
    %-  pairs:enjs:format
    :~
      ['action' s+'save-proposal-effect']
      ['context' [%o payload]]
      ['effects' [%a [proposal-effect]~]]
    ==

    =/  payload  (~(put by payload) 'data' [%o proposal])

    ::  no changes to state. state will change when poke ack'd
    :_  this(proposals (~(put by proposals.state) booth-key booth-proposals))

    :~
      ::  for clients (e.g. UI) and "our" agent, send to generic /booths path
      [%give %fact [/booths]~ %json !>(effects)]
    ==

  ++  handle-delete-proposal
    |=  [booth-key=@t payload=(map @t json)]

    =/  proposal-key  (~(get by payload) 'key')
    ?~  proposal-key  !!
    =/  proposal-key  (so:dejs:format (need proposal-key))

    =/  booth-proposals  (~(get by proposals.state) booth-key)
    =/  booth-proposals  ?~(booth-proposals ~ (need booth-proposals))
    =/  booth-proposals  (~(del by booth-proposals) proposal-key)

    =/  context=json
    %-  pairs:enjs:format
    :~
      ['key' s+booth-key]
    ==

    =/  proposal-effect=json
    %-  pairs:enjs:format
    :~
      ['resource' s+'proposal']
      ['effect' s+'delete']
      ['key' s+proposal-key]
    ==

    =/  effects=json
    %-  pairs:enjs:format
    :~
      ['action' s+'delete-proposal-effect']
      ['context' context]
      ['effects' [%a [proposal-effect]~]]
    ==

    ::  no changes to state. state will change when poke ack'd
    :_  this(proposals (~(put by proposals.state) booth-key booth-proposals))

    :~
      ::  for clients (e.g. UI) and "our" agent, send to generic /booths path
      [%give %fact [/booths]~ %json !>(effects)]
    ==

  ++  handle-delete-participant
    |=  [booth-key=@t payload=(map @t json)]

    =/  participant-key  (~(get by payload) 'key')
    ?~  participant-key  !!
    =/  participant-key  (so:dejs:format (need participant-key))

    =/  booth-participants  (~(get by participants.state) booth-key)
    =/  booth-participants  ?~(booth-participants ~ (need booth-participants))
    =/  booth-participants  (~(del by booth-participants) participant-key)

    =/  context=json
    %-  pairs:enjs:format
    :~
      ['key' s+booth-key]
    ==

    =/  participant-effect=json
    %-  pairs:enjs:format
    :~
      ['resource' s+'participant']
      ['effect' s+'delete']
      ['key' s+participant-key]
    ==

    =/  effects=json
    %-  pairs:enjs:format
    :~
      ['action' s+'delete-participant-effect']
      ['context' context]
      ['effects' [%a [participant-effect]~]]
    ==

    ::  no changes to state. state will change when poke ack'd
    :_  this(participants (~(put by participants.state) booth-key booth-participants))

    :~
      ::  for clients (e.g. UI) and "our" agent, send to generic /booths path
      [%give %fact [/booths]~ %json !>(effects)]
    ==

::  ARM:  ++  save-proposal-api
::
::   Steps:
::
::      1) add/update proposal on booth
::      2) respond to POST w/ 200 updated payload (see #1)
::      3) poke booth host w/ 'invite-accepted' action
::
++  save-proposal-wire
  |=  [payload=(map @t json)]

  =/  booth-key  (so:dejs:format (~(got by payload) 'key'))
  =/  data  (~(get by payload) 'data')
  =/  data  ?~(data ~ ((om json):dejs:format (need data)))

  =/  timestamp  (en-json:html (time:enjs:format now.bowl))

  =/  is-update  (~(has by data) 'key')
  =/  proposal-key
        ?:  is-update
              (so:dejs:format (~(got by data) 'key'))
            (crip (weld "proposal-" timestamp))

  =/  booth-proposals  (~(get by proposals.state) booth-key)
  =/  booth-proposals  ?~(booth-proposals ~ (need booth-proposals))
  =/  proposal  (~(get by booth-proposals) booth-key)
  =/  proposal  ?~(proposal ~ ((om json):dejs:format (need proposal)))
  =/  proposal  (~(gas by proposal) ~(tap by data))
  =/  booth-proposals  (~(put by booth-proposals) proposal-key [%o proposal])

  ::  no changes to state. state will change when poke ack'd
  `this(proposals (~(put by proposals.state) booth-key booth-proposals))

  ++  handle-poke-ack
    |=  [reaction=@t msg-id=@t]

    =/  msg  (~(get by mq.state) msg-id)
    ?~  msg
          ~&  >>  "message {<msg-id>} not found. skipping..."
          `this

    =/  msg  ((om json):dejs:format (need msg))
    =/  msg  (~(put by msg) 'reaction' s+reaction)

    =/  action  (so:dejs:format (~(got by msg) 'action'))

    ?+  `@tas`action  `this

      ::  remote ship received and processed invite poke
      %invite
        (handle-invite-ack reaction msg-id msg)

      ::   remote ship received and processed accept poke
      %accept
        (handle-accept-ack reaction msg-id msg)

      ::   remote ship received and processed invite-response poke
      %invite-response
        (handle-invite-response-ack reaction msg-id msg)

    ==

  ++  handle-invite-ack
    |=  [reaction=@t msg-id=@t msg=(map @t json)]

    ::  for now, ack or nack, just clear the message. technically, here
    ::    means "the ship we tried to invite exists and is running", but in UI
    ::    terms the original invite is still 'pending' until we receive an "invite-response" action
    `this(mq (~(del by mq.state) msg-id))

    ::  forward all nacks to poker as effect
    :: ?:  =(reaction 'nack')
    ::   :_  this(mq (~(del by mq.state) msg-id))
    ::   :~  [%give %fact [/booths]~ %json !>([%o msg])]
    ::   ==

    :: :_  this(mq (~(del by mq.state) msg-id))
    :: :~  [%give %fact [/booths]~ %json !>([%o msg])]
    :: ==

  ++  handle-invite-response-ack
    |=  [reaction=@t msg-id=@t msg=(map @t json)]

    ::  for now, ack or nack, just clear the message. technically, here
    ::    means "the ship we tried to invite exists and is running", but in UI
    ::    terms the original invite is still 'pending' until we receive an "invite-response" action
    `this(mq (~(del by mq.state) msg-id))

  ::  ARM  ++  handle-invite-accepted-ack
  ::   Called when ack on invite-accepted poke is sent to booth host.
  ::
  ::   STEPS:
  ::
  ::     1. update booth status to 'joined'
  ::     2. add ourselves to the partipant list w/ an initial status of 'active'
  ::     3. subscribe to the booth host to get booth updates
  ::     4. notify subscribers (e.g. UI) of effects
  ::
  ++  handle-accept-ack
    |=  [reaction=@t msg-id=@t msg=(map @t json)]

    ::  forward all nacks to poker as effect
    ?:  =(reaction 'nack')
      `this(mq (~(del by mq.state) msg-id))

    =/  booth-key  (so:dejs:format (~(got by msg) 'key'))
    =/  booth  ((om json):dejs:format (~(got by booths.state) booth-key))
    =/  booth  (~(put by booth) 'status' s+'active')
    =/  booth-ship  (so:dejs:format (~(got by booth) 'owner'))

    =/  booth-participants  (~(get by participants.state) booth-key)
    =/  booth-participants  ?~(booth-participants ~ (need booth-participants))

    =/  participant-key  (crip "{<our.bowl>}")

    =/  timestamp  (crip (en-json:html (time:enjs:format now.bowl)))

    =/  participant
      %-  pairs:enjs:format
      :~
        ['key' s+participant-key]
        ['name' s+participant-key]
        ['status' s+'active']
        ['ts-added' s+timestamp]
      ==

    =/  booth-participants  (~(put by booth-participants) participant-key participant)

    =/  booth-effect
      %-  pairs:enjs:format
      :~
        ['resource' s+'booth']
        ['effect' s+'update']
        ['key' s+booth-key]
        ['data' [%o booth]]
      ==

    =/  participant-effect
      %-  pairs:enjs:format
      :~
        ['resource' s+'participant']
        ['effect' s+'add']
        ['key' s+participant-key]
        ['data' participant]
      ==

    =/  effect-list=(list json)  [participant-effect booth-effect ~]
    =/  effects
      %-  pairs:enjs:format
      :~
        ['action' s+'accept-effect']
        ['context' [%o msg]]
        ['effects' [%a effect-list]]
      ==

    =/  hostship=@p  `@p`(slav %p booth-ship)
    ::  send out notifications to all subscribers of this booth
      =/  destpath=path  `path`/booths/(scot %p booth-ship)
    =/  wirepath=path  `path`(stab (crip (weld "/booths/" (trip booth-key))))

    ::  commit updates to store
    :_  this(mq (~(del by mq.state) msg-id), booths (~(put by booths.state) booth-key [%o booth]), participants (~(put by participants.state) booth-key booth-participants))
        ::  notifiy subscribers (e.g. UI) of the effect
    :~  [%give %fact [/booths]~ %json !>(effects)]
        ::  subscribe to booth host messages
        [%pass wirepath %agent [hostship %ballot] %watch wirepath]
    ==

  --

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