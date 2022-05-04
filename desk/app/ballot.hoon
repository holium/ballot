:: ***********************************************************
::
::  @author  : ~lodlev-migdev (p.james)
::  @purpose :
::    Ball app agent for contexts, booths, proposals, and participants.
::
:: ***********************************************************
/-  *group, group-store, ballot-store, ballot, plugin
/+  store=group-store, default-agent, dbug, resource, pill, util=ballot-util, core=ballot-core, reactor=ballot-booth-reactor, sig=ballot-signature, view=ballot-views, plugin=ballot-plugin, drv=ballot-driver
|%
+$  card  card:agent:gall
+$  versioned-state
  $%  state-0:ballot-store
  ==
:: +$  state-0  [%0 authentication=@t mq=(map @t json) polls=(map @t (map @t json)) booths=booths:ballot-store proposals=proposals:ballot-store participants=participants:ballot-store invitations=invitations:ballot-store votes=(map @t (map @t json)) delegates=(map @t (map @t json))]
--
%-  agent:dbug
=|  state-0:ballot-store
=*  state  -
^-  agent:gall
|_  =bowl:gall
+*  this  .
    def   ~(. (default-agent this %.n) bowl)
++  on-init
  ^-  (quip card _this)

  %-  (log:core %info "ballot: on-init...")

  :_  this(authentication 'enable')

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

      %initialize
         =^  cards  state

          (initialize-booths ~)

         [cards this]

      %auth
      =^  cards  state
        =/  val  !<(@t vase)
        (set-authentication-mode val)
      [cards this]

      %json
        =^  cards  state

        =/  jon  !<(json vase)

          (handle-channel-poke jon)

        [cards this]

      %handle-http-request
        =^  cards  state

        =/  req  !<((pair @ta inbound-request:eyre) vase)

        ?:  ?&  =(authentication.state 'enable')
                !authenticated.q.req
            ==
            %-  (log:core %error "ballot: authentication is enabled. request is not authenticated")
            (send-api-error req 'not authenticated')

        =/  req-args
              (my q:(need `(unit (pair pork:eyre quay:eyre))`(rush url.request.q.req ;~(plug apat:de-purl:html yque:de-purl:html))))

        %-  (log:core %info "ballot: [on-poke] => processing request at endpoint {<(stab url.request.q.req)>}")

        =/  path  (stab url.request.q.req)

        ?+    method.request.q.req  (send-api-error req 'unsupported')

              %'POST'
                ?+  path  (send-api-error req 'route not found')

                  [%ballot %api %booths ~]
                    (handle-resource-action req req-args)

                ==

        ==
        [cards this]
    ==

    ++  set-authentication-mode
      |=  [mode=@t]
      %-  (log:core %info "ballot: setting authentication {<mode>}...")
      `state(authentication mode)

    ++  to-booth-sub
      |=  [jon=json]
      ^-  card
      =/  booth  ((om json):dejs:format jon)
      =/  booth-key  (so:dejs:format (~(got by booth) 'key'))
      =/  owner  (so:dejs:format (~(got by booth) 'owner'))
      =/  booth-ship=@p  `@p`(slav %p owner)
      ::  send out notifications to all subscribers of this booth
      =/  destpath=path  `path`/booths/(scot %tas booth-key)
      %-  (log:core %warn "ballot: subscribing to {<destpath>}...")
      :: convert json to [%pass /booth/<booth-key> ... /booth/<booth-key>] subscription
      [%pass destpath %agent [booth-ship %ballot] %watch destpath]

    ++  booths-to-subscriptions
      |=  [m=(map @t json)]
      ^-  (list card)
      =/  l  ~(val by m)
      =/  r=(list card)  (turn l to-booth-sub)
      [r]

    ++  initialize-booths
      |=  [jon=json]

      %-  (log:core %warn "ballot: initializing ballot-store...")

      =/  owner  `@t`(scot %p our.bowl)
      =/  timestamp  (crip (en-json:html (time:enjs:format now.bowl)))

      :: =/  booth-key  (spat /(scot %p our.bowl))
      =/  booth-key  (crip "{<our.bowl>}")
      =/  booth-name  (crip "{<our.bowl>}")
      =/  booth-slug  (spat /(scot %p our.bowl))

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
        ['name' s+booth-name]
        ['slug' s+booth-slug]
        ['image' ~]
        ['owner' s+owner]
        ['created' (time:enjs:format now.bowl)]
        ['policy' s+'invite-only']
        ['status' s+'active']
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
        ['created' (time:enjs:format now.bowl)]
      ==

      =.  booth-participants  (~(put by booth-participants) participant-key participant)

      %-  (log:core %good "ballot: context initialized!")

      =/  effects  (booths-to-subscriptions booths)

      %-  (log:core %info "subscribing to /groups...")
      =/  effects  (snoc effects [%pass /group %agent [our.bowl %group-store] %watch /groups])

      :_  state(booths booths, participants (~(put by participants.state) booth-key booth-participants))

      [effects]

    ++  handle-resource-action
      |=  [req=(pair @ta inbound-request:eyre) args=(map @t @t)]
      ^-  (quip card _state)

      ::  all POST payloads are action contracts (see ARM comments)
      =/  payload  (extract-payload req)

      =/  context  ((om json):dejs:format (~(got by payload) 'context'))
      =/  action  (so:dejs:format (~(got by payload) 'action'))
      =/  resource  (so:dejs:format (~(got by payload) 'resource'))

      ?+  [resource action]  `state

            [%booth %invite]
              (invite-api req payload)

            [%booth %accept]
              (accept-api req payload)

            [%proposal %save-proposal]
              (save-proposal-api req payload)

            [%proposal %delete-proposal]
              (delete-proposal-api req payload)

            [%proposal %cast-vote]
              (cast-vote-api req payload)

            [%participant %delete-participant]
              (delete-participant-api req payload)

            [%delegate %delegate]
              (delegate-api req payload)

            [%delegate %undelegate]
              (undelegate-api req payload)

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

        %invite
          %-  (log:core %info "ballot: %invite action received...")
          (invite-wire contract)

        %invite-response
          %-  (log:core %info "ballot: %invite-response action received...")
          (invite-wire-response contract)

        %accept
          %-  (log:core %info "ballot: %accept from {<src.bowl>}...")
          (accept-wire contract)

        %delete-proposal
          %-  (log:core %info "ballot: %delete-proposal from {<src.bowl>}...")
          (delete-proposal-wire contract)

        %delete-participant
          %-  (log:core %info "ballot: %delete-participant from {<src.bowl>}...")
          (delete-participant-wire contract)

        %cast-vote
          %-  (log:core %info "ballot: %cast-vote from {<src.bowl>}...")
          (cast-vote-wire contract)

        %delegate
          (delegate-wire contract)

        %undelegate
          (undelegate-wire contract)

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

      ::  if we get this, bad news we've been kicked from the booth
      ++  delete-participant-wire
        |=  [payload=(map @t json)]

        %-  (log:core %info "ballot: delete-participant-wire received from {<src.bowl>}...")

        =/  timestamp  (en-json:html (time:enjs:format now.bowl))

        =/  context  ((om json):dejs:format (~(got by payload) 'context'))
        =/  booth-key  (so:dejs:format (~(got by context) 'booth'))
        =/  booth  (~(get by booths.state) booth-key)
        ?~  booth  !!
        =/  booth  ((om json):dejs:format (need booth))
        =/  booth-ship  `@p`(slav %p (so:dejs:format (~(got by booth) 'owner')))
        =/  participant-key  (so:dejs:format (~(got by context) 'participant'))

        :: this should never happen. we shouldn't get poke if participant-key is not our ship
        ?.  =(participant-key (crip "{<our.bowl>}"))
          :: %-  (log:core %error "ballot: delete-participant-wire received unexpectedly. {<participant-key>}...")
          !!

        =/  booth-participants  (~(get by participants.state) booth-key)
        =/  booth-participants  ?~(booth-participants ~ (need booth-participants))
        =/  participant  (~(get by booth-participants) participant-key)
        =/  participant  ?~(participant ~ (need participant))

        =/  booth-participants  (~(del by participants.state) booth-key)
        =/  booth-votes  (~(del by votes.state) booth-key)
        =/  booth-proposals  (~(del by proposals.state) booth-key)
        =/  booth-polls  (~(del by polls.state) booth-key)
        =/  booth-invitations  (~(del by invitations.state) booth-key)

        =/  new-booths
          ?.  =(our.bowl booth-ship)
            (~(del by booths.state) booth-key)
          booths.state

        =/  booth-effect=json
        %-  pairs:enjs:format
        :~
          ['resource' s+'booth']
          ['effect' s+'delete']
          ['key' s+booth-key]
          ['data' [%o booth]]
        ==

        =/  participant-effect=json
        %-  pairs:enjs:format
        :~
          ['resource' s+'participant']
          ['effect' s+'delete']
          ['key' s+participant-key]
          ['data' participant]
        ==

        =/  effect-list  [booth-effect participant-effect ~]
        =/  effects=json
        %-  pairs:enjs:format
        :~
          ['action' s+'delete-participant-reaction']
          ['context' [%o context]]
          ['effects' [%a effect-list]]
        ==

        =/  remote-agent-wire=path  `path`/booths/(scot %tas booth-key)
        %-  (log:core %warn "sending delete-participant effect to subscribers...")
        %-  (log:core %warn "sending %leave to {<remote-agent-wire>}...")

        ::  no changes to state. state will change when poke ack'd
        :_  state(booths new-booths, proposals booth-proposals, participants booth-participants, votes booth-votes, polls booth-polls, invitations booth-invitations)

        :~
          ::  for clients (e.g. UI) and "our" agent, send to generic /booths path
          [%give %fact [/booths]~ %json !>(effects)]
          [%pass remote-agent-wire %agent [booth-ship %ballot] %leave ~]
        ==

      ++  delete-proposal-wire
        |=  [payload=(map @t json)]

        =/  timestamp  (en-json:html (time:enjs:format now.bowl))

        =/  context  ((om json):dejs:format (~(got by payload) 'context'))
        =/  booth-key  (so:dejs:format (~(got by context) 'booth'))
        =/  proposal-key  (so:dejs:format (~(got by context) 'proposal'))

        =/  booth-proposals  (~(get by proposals.state) booth-key)
        =/  booth-proposals  ?~(booth-proposals ~ (need booth-proposals))
        =/  proposal  (~(get by booth-proposals) proposal-key)
        ?~  proposal  `state
        =/  proposal  (need proposal)
        =/  booth-proposals  (~(del by booth-proposals) proposal-key)

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
          ['action' s+'delete-proposal-reaction']
          ['context' [%o context]]
          ['effects' [%a [proposal-effect]~]]
        ==

        =/  remote-agent-wire=path  `path`/booths/(scot %tas booth-key)
        %-  (log:core %warn "sending delete-proposal effect to subscribers...")

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

        %-  (log:core %warn "{<(en-json:html [%o contract])>}")

        =/  context  ((om json):dejs:format (~(got by contract) 'context'))

        =/  booth-key  (so:dejs:format (~(got by context) 'booth'))
        =/  proposal-key  (so:dejs:format (~(got by context) 'proposal'))
        =/  participant-key  (so:dejs:format (~(got by context) 'participant'))

        =/  vote  ((om json):dejs:format (~(got by contract) 'data'))
        =/  vote  (~(put by vote) 'status' s+'recorded')

        =/  j-sig  (~(get by vote) 'sig')
        =/  j-sig  ?~(j-sig ~ ((om json):dejs:format (need j-sig)))
        =/  hash  (~(get by j-sig) 'hash')
        ?~  hash  !!  :: %-  (log:core %error "ballot: invalid vote signature. hash not found.")  !!
        =/  hash  `@ux`((se %ux):dejs:format (need hash))
        =/  voter-ship  (~(get by j-sig) 'voter')
        ?~  voter-ship  !! :: %-  (log:core %error "ballot: invalid vote signature. voter not found.")  !!
        =/  voter-ship  ((se %p):dejs:format (need voter-ship))
        =/  life  (~(get by j-sig) 'life')
        ?~  life  !! :: %-  (log:core %error "ballot: invalid vote signature. life not found.")  !!
        =/  life  (ni:dejs:format (need life))
        =/  sign=signature:ballot  [p=hash q=voter-ship r=life]
        %-  (log:core %warn "{<[sign]>}")
        %-  (log:core %info "ballot: verifying vote signature {<sign>}...")
        =/  verified  (verify:sig our.bowl now.bowl sign)
        ?~  verified  !!
              :: %-  (log:core %error "ballot: vote could not be verified")  !!
        %-  (log:core %info "ballot: signature verified")

        =/  booth-proposals  (~(get by votes.state) booth-key)
        =/  booth-proposals  ?~(booth-proposals ~ (need booth-proposals))
        =/  proposal-votes  (~(get by booth-proposals) proposal-key)
        =/  proposal-votes  ?~(proposal-votes ~ ((om json):dejs:format (need proposal-votes)))

        =/  participant-vote  (~(get by proposal-votes) participant-key)
        ?.  =(participant-vote ~)
              %-  (log:core %error "participant vote already cast")
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
          ['action' s+'cast-vote-reaction']
          ['context' [%o context]]
          ['effects' [%a [vote-effect]~]]
        ==

        %-  (log:core %warn "cast-vote-wire: {<our.bowl>} {<src.bowl>}")

        =/  booth-path  /booths/(scot %tas booth-key)

        :_  state(votes (~(put by votes.state) booth-key booth-proposals))
        :~  [%give %fact [/booths]~ %json !>(effects)]
            [%give %fact [booth-path]~ %json !>([%o vote-update])]
        ==

      ::  ARM:  ++  invite-accepted-wire
      ::   Sent by a remote ship when they've accepted an invite we sent to them
      ::     at an earlier time.
      ++  accept-wire
        |=  [contract=(map @t json)]

        =/  context  ((om json):dejs:format (~(got by contract) 'context'))
        ::  grab the booth key from the action payload
        =/  booth-key  (so:dejs:format (~(got by context) 'booth'))
        =/  booth  ((om json):dejs:format (~(got by booths.state) booth-key))
        =/  booth-type  (so:dejs:format (~(got by booth) 'type'))

        ::  use it to extract the booth participant list
        =/  booth-participants  (~(get by participants.state) booth-key)
        =/  booth-participants  ?~(booth-participants ~ (need booth-participants))

        ::  the participant key is the remote ship that sent the poke
        =/  participant-key  (crip "{<src.bowl>}")

        ::  if this is a group acceptance, the payload will contain the participant
        ::    data; otherwise, we already know if it since in all other cases, we must
        ::    invite them first
        =/  participant
              ?:  =(booth-type 'group')
                ((om json):dejs:format (~(got by contract) 'data'))
              ::  get the participant from the booth participant list
              =/  participant  (~(get by booth-participants) participant-key)
              =/  participant  ?~(participant ~ ((om json):dejs:format (need participant)))
              [participant]

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
          ['action' s+'accept-reaction']
          ['context' [%o context]]
          ['effects' [%a [participant-effect]~]]
        ==

        %-  (log:core %warn "invite-accepted-wire: {<our.bowl>} {<src.bowl>}")

        ::  add the participant that accepted the invite/enlistment to the
        ::   payload sent out to subscribers
        =/  payload  (~(put by contract) 'data' [%o participant])

        :_  state(participants (~(put by participants.state) booth-key booth-participants))
        :~  [%give %fact [/booths]~ %json !>(effects)]
        ::  for remote subscribers, indicate over booth specific wire
            [%give %fact [/booths/(scot %tas booth-key)]~ %json !>([%o payload])]
        ==

      ++  invite-wire-response
        |=  [contract=(map @t json)]

        =/  context  ((om json):dejs:format (~(got by contract) 'context'))
        =/  booth-key  (so:dejs:format (~(got by context) 'booth'))
        =/  participant-key  (so:dejs:format (~(got by context) 'participant'))

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
          ['action' s+'invite-reaction']
          ['context' [%o context]]
          ['effects' [%a [participant-effect]~]]
        ==

        %-  (log:core %warn "invite-wire-response: {<our.bowl>} {<src.bowl>}")

        :_  state(participants (~(put by participants.state) booth-key booth-participants))
        :~  [%give %fact [/booths]~ %json !>(effects)]
        ==

      ++  invite-wire
        |=  [payload=(map @t json)]

        =/  timestamp  (en-json:html (time:enjs:format now.bowl))

        =/  context  ((om json):dejs:format (~(got by payload) 'context'))
        =/  booth-key  (so:dejs:format (~(got by context) 'booth'))

        =/  participant-key  (crip "{<our.bowl>}")
        =/  data  ((om json):dejs:format (~(got by payload) 'data'))
        =/  booth  ((om json):dejs:format (~(got by data) 'booth'))

        ::  update booth status because on receiving ship (this ship), the booth
        ::    is being added; therefore status is 'invited'
        =/  booth  (~(put by booth) 'status' s+'invited')

        =/  response-payload  (~(put by payload) 'action' s+'invite-response')
        =/  response-payload  (~(put by response-payload) 'reaction' s+'ack')

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
          ['action' s+'invite-reaction']
          ['context' [%o context]]
          ['effects' [%a [booth-effect]~]]
        ==

        %-  (log:core %warn "invite-wire: {<our.bowl>} poking {<src.bowl>}")

        :_  state(booths (~(put by booths.state) booth-key [%o booth]))

        :~  [%give %fact [/booths]~ %json !>(effect)]
            [%pass /booths/(scot %tas booth-key) %agent [src.bowl %ballot] %poke %json !>([%o response-payload])]
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
        |=  [req=(pair @ta inbound-request:eyre) payload=(map @t json)]
        ^-  (quip card _state)

        =/  context  (~(get by payload) 'context')
        ?~  context  (send-api-error req 'missing context')
        =/  context  ((om json):dejs:format (need context))

        =/  booth-key  (~(get by context) 'booth')
        ?~  booth-key  (send-api-error req 'missing context key. booth key')
        =/  booth-key  (so:dejs:format (need booth-key))


        =/  participant-key  (~(get by context) 'participant')
        ?~  participant-key  (send-api-error req 'missing context key. participant key')
        =/  participant-key  (so:dejs:format (need participant-key))

        %-  (log:core %warn "deleting participant {<booth-key>}, {<participant-key>}")

        =/  booth-participants  (~(get by participants.state) booth-key)
        =/  booth-participants  ?~(booth-participants ~ (need booth-participants))
        =/  participant  (~(get by booth-participants) participant-key)
        ?~  participant  (send-api-error req 'participant not found')
        =/  participant  (need participant)
        =/  participant-ship  `@p`(slav %p participant-key)
        =/  booth-participants  (~(del by booth-participants) participant-key)

        ::  remove their votes also
        =/  booth-votes  (~(get by votes.state) booth-key)
        =/  booth-votes  ?~(booth-votes ~ (need booth-votes))

        =/  booth-votes
              %-  ~(rep in booth-votes)
                |=  [[p=@t q=json] rslt=(map @t json)]
                  =/  votes  ((om json):dejs:format q)
                  =/  votes  [%o (~(del by votes) participant-key)]
                  %-  (log:core %info "removing vote by {<participant-key>} from {<p>}...")
                  (~(put by rslt) p votes)

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
          ['action' s+'delete-participant-reaction']
          ['context' [%o context]]
          ['effects' [%a [participant-effect]~]]
        ==

        =/  remote-agent-wire=path  `path`/booths/(scot %tas booth-key)
        %-  (log:core %warn "sending delete-participant to {<remote-agent-wire>}...")

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

        :_  state(participants (~(put by participants.state) booth-key booth-participants), votes (~(put by votes.state) booth-key booth-votes))

        :~
          [%give %fact [/http-response/[p.req]]~ %http-response-header !>(response-header)]
          [%give %fact [/http-response/[p.req]]~ %http-response-data !>(`data)]
          [%give %kick [/http-response/[p.req]]~ ~]
          ::  for clients (e.g. UI) and "our" agent, send to generic /booths path
          [%give %fact [/booths]~ %json !>(effects)]
          ::  for remote subscribers, indicate over booth specific wire
          [%give %fact [remote-agent-wire]~ %json !>([%o payload])]
          [%pass remote-agent-wire %agent [participant-ship %ballot] %poke %json !>([%o payload])]
          [%give %kick ~[remote-agent-wire] (some participant-ship)]
        ==

      ++  delete-proposal-api
        |=  [req=(pair @ta inbound-request:eyre) payload=(map @t json)]
        ^-  (quip card _state)

        =/  context  (~(get by payload) 'context')
        ?~  context  (send-api-error req 'missing context')
        =/  context  ((om json):dejs:format (need context))

        =/  booth-key  (~(get by context) 'booth')
        ?~  booth-key  (send-api-error req 'missing context key. booth key')
        =/  booth-key  (so:dejs:format (need booth-key))

        =/  proposal-key  (~(get by context) 'proposal')
        ?~  proposal-key  (send-api-error req 'missing context key. proposal key')
        =/  proposal-key  (so:dejs:format (need proposal-key))

        =/  booth-proposals  (~(get by proposals.state) booth-key)
        =/  booth-proposals  ?~(booth-proposals ~ (need booth-proposals))
        =/  proposal  (~(get by booth-proposals) proposal-key)
        ?~  proposal  (send-api-error req 'proposal not found')
        =/  proposal  ?:(?=([%o *] u.proposal) p.u.proposal ~)
        =/  proposal-owner  (~(get by proposal) 'owner')
        ?~  proposal-owner  (send-api-error req 'proposal missing owner')
        =/  proposal-owner  (so:dejs:format (need proposal-owner))
        =/  proposal-owner  `@p`(slav %p proposal-owner)

        ::  anyone can create a proposal; however only booth owner, admin
        ::    or proposal creator can delete
        =/  member-key  (crip "{<our.bowl>}")
        =/  booth-members  (~(get by participants.state) booth-key)
        =/  booth-members  ?~(booth-members ~ (need booth-members))
        =/  member  (~(get by booth-members) member-key)
        ?~  member  (send-api-error req 'member not found')
        =/  member  ?:(?=([%o *] u.member) p.u.member ~)
        =/  role  (~(get by member) 'role')
        ?~  role  (send-api-error req 'member role not found')
        =/  role  (so:dejs:format (need role))
        ?.  ?|  =(role 'owner')
                =(role 'admin')
                =(proposal-owner our.bowl)
            ==
            (send-api-error req 'insufficient privileges')

        =/  booth-proposals  (~(del by booth-proposals) proposal-key)

        =/  booth-votes  (~(get by votes.state) booth-key)
        =/  booth-votes  ?~(booth-votes ~ (need booth-votes))
        =/  booth-votes  (~(del by booth-votes) proposal-key)

        =/  proposal-effect=json
        %-  pairs:enjs:format
        :~
          ['resource' s+'proposal']
          ['effect' s+'delete']
          ['key' s+proposal-key]
          ['data' [%o proposal]]
        ==

        =/  effects=json
        %-  pairs:enjs:format
        :~
          ['action' s+'delete-proposal-reaction']
          ['context' [%o context]]
          ['effects' [%a [proposal-effect]~]]
        ==

        =/  remote-agent-wire=path  `path`/booths/(scot %tas booth-key)
        %-  (log:core %warn "sending delete-proposal to {<remote-agent-wire>}...")

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

        ::  delete any timers that have been created to handle start/end actions
        =/  booth-polls  (~(get by polls.state) booth-key)
        =/  booth-polls  ?~(booth-polls ~ (need booth-polls))
        =/  poll  (~(get by booth-polls) proposal-key)
        =/  poll  ?~(poll ~ ((om json):dejs:format (need poll)))
        =/  booth-polls  (~(del by booth-polls) proposal-key)

        =/  effects=(list card)
        :~
          [%give %fact [/http-response/[p.req]]~ %http-response-header !>(response-header)]
          [%give %fact [/http-response/[p.req]]~ %http-response-data !>(`data)]
          [%give %kick [/http-response/[p.req]]~ ~]
          ::  for clients (e.g. UI) and "our" agent, send to generic /booths path
          [%give %fact [/booths]~ %json !>(effects)]
          ::  for remote subscribers, indicate over booth specific wire
          [%give %fact [remote-agent-wire]~ %json !>([%o payload])]
        ==

        ::  kill any timers that were set when the proposal was created
        =/  effects  ?.  =(~ poll)
          =/  poll-start-date  (~(get by poll) 'start')
          =/  poll-start-date  ?~(poll-start-date ~ (du:dejs:format (need poll-start-date)))
          =/  effects  ?.  =(~ poll-start-date)
            %-  (slog leaf+"ballot: killing start timer {<poll-start-date>}..." ~)
            (snoc effects [%pass /timer/(scot %tas booth-key)/(scot %tas proposal-key)/start %arvo %b %rest `@da`poll-start-date])
          effects
          =/  poll-end-date  (~(get by poll) 'end')
          =/  poll-end-date  ?~(poll-end-date ~ (du:dejs:format (need poll-end-date)))
          =/  effects  ?.  =(~ poll-end-date)
              %-  (slog leaf+"ballot: killing end timer {<poll-end-date>}..." ~)
              (snoc effects [%pass /timer/(scot %tas booth-key)/(scot %tas proposal-key)/end %arvo %b %rest `@da`poll-end-date])
            effects
          effects
        effects

        ::  no changes to state. state will change when poke ack'd
        :_  state(proposals (~(put by proposals.state) booth-key booth-proposals), votes (~(put by votes.state) booth-key booth-votes), polls (~(put by polls.state) booth-key booth-polls))

        effects

      ++  save-proposal-api
        |=  [req=(pair @ta inbound-request:eyre) payload=(map @t json)]
        ^-  (quip card _state)

        =/  context  (~(get by payload) 'context')
        ?~  context  (send-api-error req 'missing context element')
        =/  context  ((om json):dejs:format (need context))

        =/  booth-key  (~(get by context) 'booth')
        ?~  booth-key  (send-api-error req 'context missing booth')
        =/  booth-key  (so:dejs:format (need booth-key))

        =/  booth  (~(get by booths.state) booth-key)
        ?~  booth  !! :: %-  (log:core %error "ballot: booth {<booth-key>} not found")  !!
        =/  booth  ((om json):dejs:format (need booth))
        =/  booth-owner  (~(get by booth) 'owner')
        ?~  booth-owner  !! :: %-  (log:core %error "ballot: booth {<booth-key>} missing owner")  !!
        =/  booth-owner  (so:dejs:format (need booth-owner))
        =/  booth-ship=@p  `@p`(slav %p booth-owner)

        =/  data  (~(get by payload) 'data')
        =/  data  ?~(data ~ ((om json):dejs:format (need data)))

        =/  timestamp  (en-json:html (time:enjs:format now.bowl))

        =/  is-update  (~(has by context) 'proposal')

        =/  proposal-key
              ?:  is-update
                    (so:dejs:format (~(got by context) 'proposal'))
                  (crip (weld "proposal-" timestamp))

        =/  booth-proposals  (~(get by proposals.state) booth-key)
        =/  booth-proposals  ?~(booth-proposals ~ (need booth-proposals))
        =/  proposal  (~(get by booth-proposals) proposal-key)
        =/  proposal  ?~(proposal ~ (need proposal))
        :: ?~  proposal  (send-api-error req 'proposal not found')
        =/  proposal  ?~(proposal ~ ?:(?=([%o *] proposal) p.proposal ~))

        =/  member-key  (crip "{<our.bowl>}")

        ::  anyone can create a proposal; however only booth owner, admin
        ::    or proposal creator can edit
        =/  tst=[success=? msg=@t]  ?:  is-update
          =/  proposal-owner  (~(get by proposal) 'owner')
          ?~  proposal-owner  [%.n 'proposal owner not found']
          =/  proposal-owner  (so:dejs:format (need proposal-owner))
          =/  proposal-owner  `@p`(slav %p proposal-owner)

          =/  booth-members  (~(get by participants.state) booth-key)
          =/  booth-members  ?~(booth-members ~ (need booth-members))
          =/  member  (~(get by booth-members) member-key)
          ?~  member  [%.n 'member not found']
          =/  member  ?:(?=([%o *] u.member) p.u.member ~)
          =/  role  (~(get by member) 'role')
          ?~  role  [%.n 'member role not found']
          =/  role  (so:dejs:format (need role))
          ?.  ?|  =(role 'owner')
                  =(role 'admin')
                  =(proposal-owner our.bowl)
              ==
              [%.n 'insuffficient privileges']
          [%.y 'no error']
        [%.y 'no error']

        ?.  success.tst  (send-api-error req msg.tst)

        =/  threshold  (~(get by data) 'support')
        ?~  threshold  !!
          :: %-  (log:core %error "ballot: missing voter support value")  !!
        =/  threshold  (ne:dejs:format (need threshold))
        %-  (log:core %info "ballot: {<threshold>}")
        =/  proposal  (~(gas by proposal) ~(tap by data))
        =/  proposal  (~(put by proposal) 'key' s+proposal-key)
        =/  proposal  (~(put by proposal) 'owner' s+member-key)
        =/  proposal  ?:(is-update proposal (~(put by proposal) 'created' (time:enjs:format now.bowl)))
        =/  booth-proposals  (~(put by booth-proposals) proposal-key [%o proposal])

        =/  proposal-effect=json
        %-  pairs:enjs:format
        :~
          ['resource' s+'proposal']
          ['effect' s+?:(is-update 'update' 'add')]
          ['key' s+proposal-key]
          ['data' [%o proposal]]
        ==

        ::  add proposal to the context before sending out updates
        =/  context  (~(put by context) 'proposal' s+proposal-key)

        =/  effects=json
        %-  pairs:enjs:format
        :~
          ['action' s+'save-proposal-reaction']
          ['context' [%o context]]
          ['effects' [%a [proposal-effect]~]]
        ==

        =/  wire-payload  (~(put by payload) 'context' [%o context])
        =/  wire-payload  (~(put by wire-payload) 'data' [%o proposal])

        =/  remote-agent-wire=path  `path`/booths/(scot %tas booth-key)
        %-  (log:core %warn "sending proposal update to {<remote-agent-wire>}...")

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
          [%give %fact [remote-agent-wire]~ %json !>([%o wire-payload])]
        ==

      ++  accept-api
        |=  [req=(pair @ta inbound-request:eyre) payload=(map @t json)]
        ^-  (quip card _state)

        =/  timestamp  (en-json:html (time:enjs:format now.bowl))

        =/  context  (~(get by payload) 'context')
        ?~  context  (send-api-error req 'missing context')
        =/  context  ((om json):dejs:format (need context))

        =/  booth-key  (~(get by context) 'booth')
        ?~  booth-key  (send-api-error req 'missing booth key')
        =/  booth-key  (so:dejs:format (need booth-key))

        =/  booth  (~(get by booths.state) booth-key)
        ?~  booth  (send-api-error req 'booth not found in store')

        =/  booth  ((om json):dejs:format (need booth))
        =/  booth  (~(put by booth) 'status' s+'pending')

        =/  booth-type  (so:dejs:format (~(got by booth) 'type'))

        =/  payload  (~(put by payload) 'data' [%o booth])

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

        ::  if the booth is a group booth, the participant will need to be added/created
        ::    to the booth.  add this ship's data to the payload sent to the booth host
        ::    so this ship can be added as a participant
        =/  wire-payload
              ?:  =(booth-type 'group')
                =/  participant-data=json
                %-  pairs:enjs:format
                :~  ['created' (time:enjs:format now.bowl)]
                    ['key' s+(crip "{<our.bowl>}")]
                    ['name' s+(crip "{<our.bowl>}")]
                    ['status' s+'active']
                ==
                (~(put by wire-payload) 'data' participant-data)
              wire-payload

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
          ['action' s+'accept-reaction']
          ['context' [%o context]]
          ['effects' [%a [booth-effect]~]]
        ==

        =/  booth-ship  (so:dejs:format (~(got by booth) 'owner'))
        =/  hostship=@p  `@p`(slav %p booth-ship)

        =/  msg-id  (crip (weld "msg-" timestamp))

        %-  (log:core %warn "accept-api: {<our.bowl>} poking {<hostship>}, {<msg-id>}...")

        ::  no changes to state. state will change when poke ack'd
        :_  state(mq (~(put by mq) msg-id [%o wire-payload]), booths (~(put by booths.state) booth-key [%o booth]))

        :~
          [%give %fact [/http-response/[p.req]]~ %http-response-header !>(response-header)]
          [%give %fact [/http-response/[p.req]]~ %http-response-data !>(`data)]
          [%give %kick [/http-response/[p.req]]~ ~]
          [%give %fact [/booths]~ %json !>(effects)]
          [%pass /booths/(scot %tas booth-key)/msg/(scot %tas msg-id) %agent [hostship %ballot] %poke %json !>([%o wire-payload])]
        ==

      ++  cast-vote-api :: req payload booth-key
        |=  [req=(pair @ta inbound-request:eyre) payload=(map @t json)]
        ^-  (quip card _state)

        =/  timestamp  (crip (en-json:html (time:enjs:format now.bowl)))

        =/  context  (~(get by payload) 'context')
        ?~  context  (send-api-error req 'missing context')
        =/  context  ((om json):dejs:format (need context))
        =/  booth-key  (so:dejs:format (~(got by context) 'booth'))
        =/  proposal-key  (so:dejs:format (~(got by context) 'proposal'))

        =/  booth  (~(get by booths.state) booth-key)
        ?~  booth  (send-api-error req 'booth not found in store')

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

        ::  has this participant delegated? if so, do not allow the vote
        =/  booth-delegates  (~(get by delegates.state) booth-key)
        =/  booth-delegates  ?~(booth-delegates ~ (need booth-delegates))
        ?:  (~(has by booth-delegates) participant-key)
          (send-api-error req 'participant delegated vote')

        =/  participant-vote  (~(get by proposal-votes) participant-key)
        ?.  =(participant-vote ~)
              (send-api-error req 'participant vote already cast')

        =/  payload-data  (~(get by payload) 'data')
        ?~  payload-data
              (send-api-error req 'missing data')

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
        =/  payload-data  (~(put by payload-data) 'created' (time:enjs:format now.bowl))

        ::  TODO sign the vote here
        %-  (log:core %info "ballot: signing vote payload...")
        =/  signature  (sign:sig our.bowl now.bowl [%o payload-data])
        %-  (log:core %warn "{<[signature]>}")
        %-  (log:core %info "ballot: {<signature>}")

        =/  j-sig=json
        %-  pairs:enjs:format
        :~
          ['hash' s+`@t`(scot %ux p.signature)]
          ['voter' s+(crip "{<q.signature>}")]
          ['life' (numb:enjs:format r.signature)]
        ==

        =/  payload-data  (~(put by payload-data) 'sig' j-sig)

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

        ::  add the participant that is voting (this ship) to the context
        ::   before sending off vote
        =/  context  (~(put by context) 'participant' s+participant-key)

        =/  wire-payload=json
        %-  pairs:enjs:format
        :~
          ['context' [%o context]]
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
          ['action' s+'cast-vote-reaction']
          ['context' [%o context]]
          ['effects' [%a [vote-effect]~]]
        ==

        =/  sub-wire  /booths/(scot %tas booth-key)
        %-  (log:core %info "sending cast-vote updates on {<sub-wire>}...")

        =/  effects=(list card)
          :~  [%give %fact [/http-response/[p.req]]~ %http-response-header !>(response-header)]
              [%give %fact [/http-response/[p.req]]~ %http-response-data !>(`data)]
              [%give %kick [/http-response/[p.req]]~ ~]
              :: ui-updates
              [%give %fact [/booths]~ %json !>(effects)]
              :: remote agent/client updates
              [%give %fact [sub-wire]~ %json !>(wire-payload)]
          ==

        ::  no need for poke if casting ballot from our own ship. this method has already
        ::  updated its store
        =/  effects  ?.  =(our.bowl hostship)
              %-  (log:core %info "poking remote ship on wire `path`/booths/{<(scot %tas booth-key)>}...")
              (snoc effects [%pass /booths/(scot %tas booth-key) %agent [hostship %ballot] %poke %json !>(wire-payload)])
            effects

        ::  no changes to state. state will change when poke ack'd
        :_  state(votes (~(put by votes.state) booth-key booth-votes))

        [effects]

      ++  invite-api
        |=  [req=(pair @ta inbound-request:eyre) payload=(map @t json)]
        ^-  (quip card _state)

        =/  context  (~(get by payload) 'context')

        =/  context  ?~(context ~ ((om json):dejs:format (need context)))
        =/  booth-key  (~(get by context) 'booth')
        ?~  booth-key  (send-api-error req 'bad context. booth missing.')
        =/  booth-key  (so:dejs:format (need booth-key))

        =/  participant-key  (~(get by context) 'participant')
        ?~  participant-key  (send-api-error req 'bad data. key missing')
        =/  participant-key  (so:dejs:format (need participant-key))

        %-  (log:core %info "ballot: invite-api called. {<booth-key>}, {<participant-key>}...")

        =/  timestamp  (en-json:html (time:enjs:format now.bowl))

        ::  only support ship invites currently
        =/  participant-ship  `(unit @p)`((slat %p) participant-key)
        ?~  participant-ship  !!  :: only ship invites
        =/  participant-ship=ship  (need participant-ship)

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
          ['role' s+'participant']
          ['created' (time:enjs:format now.bowl)]
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
          ['action' s+'invite-reaction']
          ['context' [%o context]]
          ['effects' [%a [participant-effect]~]]
        ==

        ::  merge booth data into data element
        =|  payload-data=(map @t json)
        =.  payload-data  (~(put by payload-data) 'booth' booth)
        =/  wire-payload  (~(put by payload) 'data' [%o payload-data])

        =/  msg-id  (crip (weld "msg-" timestamp))

        %-  (log:core %warn "invite-api: {<our.bowl>} poking {<participant-ship>}, {<msg-id>}...")

        ::  commit the changes to the store
        :_  state(mq (~(put by mq) msg-id [%o wire-payload]), participants (~(put by participants.state) booth-key booth-participants))

        :~
          [%give %fact [/http-response/[p.req]]~ %http-response-header !>(response-header)]
          [%give %fact [/http-response/[p.req]]~ %http-response-data !>(`data)]
          [%give %kick [/http-response/[p.req]]~ ~]
          [%give %fact [/booths]~ %json !>(updates)]
          [%pass /booths/(scot %tas booth-key)/msg/(scot %tas msg-id) %agent [participant-ship %ballot] %poke %json !>([%o wire-payload])]
        ==

      ++  delegate-api
        |=  [req=(pair @ta inbound-request:eyre) payload=(map @t json)]
        ^-  (quip card _state)

        :: =/  payload  ?:(=([%o *] payload) p.payload ~)

        %-  (slog leaf+"{<dap.bowl>}: delegate-api {<payload>}..." ~)

        =/  context  (~(get by payload) 'context')
        ?~  context  (send-api-error req 'missing context')
        =/  context  (need context)
        =/  context  ?:  ?=([%o *] context)  p.context  ~

        =/  booth-key  (~(get by context) 'booth')
        ?~  booth-key  (send-api-error req 'missing context key. booth key')
        =/  booth-key  (so:dejs:format (need booth-key))

        =/  booth  (~(get by booths.state) booth-key)
        ?~  booth  (send-api-error req 'unexpected error. booth {<booth-key>} not found in store')
        =/  booth  (need booth)

        =/  booth  ?:  ?=([%o *] booth)  p.booth  ~
        =/  booth-owner  (~(get by booth) 'owner')
        ?~  booth-owner  (send-api-error req 'booth owner not found')
        =/  booth-owner  (need booth-owner)
        =/  booth-owner  `@p`(slav %p (so:dejs:format booth-owner))

        =/  data  (~(get by payload) 'data')
        ?~  data  (send-api-error req 'payload data not found')
        =/  data  ?:(?=([%o *] u.data) p.u.data ~)
        =/  delegate  (~(get by data) 'delegate')
        ?~  delegate  (send-api-error req 'delegate element not found')
        =/  delegate  (so:dejs:format (need delegate))

        =/  delegation=json
        %-  pairs:enjs:format
        :~
          ['delegate' s+delegate]
        ==

        =/  signature  (sign:sig our.bowl now.bowl delegation)

        =/  sig-data=json
        %-  pairs:enjs:format
        :~
          ['hash' s+`@t`(scot %ux p.signature)]
          ['voter' s+(crip "{<q.signature>}")]
          ['life' (numb:enjs:format r.signature)]
        ==
        =/  sig-payload=json
        %-  pairs:enjs:format
        :~
          ['sig' sig-data]
          ['delegate' s+delegate]
        ==

        =/  payload-data  (~(put by payload) 'data' sig-payload)

        =/  remote-agent-wire=path  `path`/booths/(scot %tas booth-key)
        %-  (log:core %warn "sending {<booth-owner>} delegate to {<remote-agent-wire>}...")

        =/  =response-header:http
          :-  200
          :~  ['Content-Type' 'application/json']
          ==

        ::  encode the proposal as a json string
        =/  body  (crip (en-json:html [%o payload]))

        ::  convert the string to a form that arvo will understand
        =/  data=octs
              (as-octs:mimes:html body)

        :_  state

        :~
          [%give %fact [/http-response/[p.req]]~ %http-response-header !>(response-header)]
          [%give %fact [/http-response/[p.req]]~ %http-response-data !>(`data)]
          [%give %kick [/http-response/[p.req]]~ ~]
          [%pass remote-agent-wire %agent [booth-owner %ballot] %poke %json !>([%o payload-data])]
        ==

      ++  delegate-wire
        |=  [payload=(map @t json)]
        ^-  (quip card _state)

        %-  (slog leaf+"{<dap.bowl>}: delegate-wire {<payload>}..." ~)
        :: =/  payload  ?:(=([%o *] payload) p.payload ~)

        =/  context  (~(get by payload) 'context')
        ?~  context
          ~&  >>>  "{<dap.bowl>}: delegate wire error. payload missing context"
          !!
        =/  context  (need context)
        =/  context  ?:  ?=([%o *] context)  p.context  ~

        =/  booth-key  (~(get by context) 'booth')
        ?~  booth-key
          ~&  >>>  "{<dap.bowl>}: delegate wire error. context missing booth"
          !!
        =/  booth-key  (so:dejs:format (need booth-key))

        =/  booth  (~(get by booths.state) booth-key)
        ?~  booth
          ~&  >>>  "{<dap.bowl>}: delegate wire error. {<booth-key>} not found in booth store"
          !!
        =/  booth  (need booth)

        =/  booth  ?:  ?=([%o *] booth)  p.booth  ~
        =/  booth-owner  (~(get by booth) 'owner')
        ?~  booth-owner
          ~&  >>>  "{<dap.bowl>}: delegate wire error. {<booth-key>} missing owner"
          !!
        =/  booth-owner  (need booth-owner)
        =/  booth-owner  `@p`(slav %p (so:dejs:format booth-owner))

        =/  data  (~(get by payload) 'data')
        ?~  data
          ~&  >>>  "{<dap.bowl>}: delegate wire error. payload missing data"
          !!
        =/  data  (need data)
        =/  data  ?:  ?=([%o *] data)  p.data  ~

        =/  delegate-key  (~(get by data) 'delegate')
        ?~  delegate-key
          ~&  >>>  "{<dap.bowl>}: delegate wire error. payload data missing delegate"
          !!
        =/  delegate-key  (so:dejs:format (need delegate-key))

        ::  is the delegate actually a member of the group?
        =/  booth-members  (~(get by participants.state) booth-key)
        ?~  booth-members
          ~&  >>>  "{<dap.bowl>}: delegate wire error. booth member store not found"
          !!
        =/  booth-members  (need booth-members)
        =/  member  (~(get by booth-members) delegate-key)
        ?~  member
          ~&  >>>  "{<dap.bowl>}: delegate wire error. {<delegate-key>} is not a booth participant"
          !!

        =/  sgn  (~(get by data) 'sig')
        ?~  sgn
          ~&  >>>  "{<dap.bowl>}: delegate wire error. payload data missing sig"
          !!
        =/  sgn  (need sgn)

        =/  verified  (ver:sig bowl sgn ~)
        ?~  verified
          ~&  >>>  "{<dap.bowl>}: delegate wire error. unable to validate signature"
          !!

        =/  participant-key  (crip "{<src.bowl>}")
        =/  booth-participants  (~(get by delegates.state) booth-key)
        =/  booth-participants  ?~(booth-participants ~ (need booth-participants))
        =/  participant  (~(get by booth-participants) participant-key)
        ?.  =(~ participant)
          ~&  >>  "{<dap.bowl>}: delegate wire error. {<participant-key>} already delegated vote"
          !!

        =/  booth-votes  (~(get by votes.state) booth-key)
        =/  booth-votes  ?~(booth-votes ~ (need booth-votes))
        =/  participant  (~(get by booth-votes) participant-key)
        ?.  =(~ participant)
          ~&  >>  "{<dap.bowl>}: delegate wire error. {<participant-key>} already voted"
          !!

        =/  delegation=json
        %-  pairs:enjs:format
        :~
          ['delegate' s+delegate-key]
          ['sig' sgn]
          ['created' (time:enjs:format now.bowl)]
        ==

        =/  booth-participants  (~(put by booth-participants) participant-key delegation)
        =/  participant-effect=json
        %-  pairs:enjs:format
        :~
          ['resource' s+'delegate']
          ['effect' s+'add']
          ['key' s+participant-key]
          ['data' delegation]
        ==

        =/  effects=json
        %-  pairs:enjs:format
        :~
          ['action' s+'delegate-reaction']
          ['context' [%o context]]
          ['effects' [%a [participant-effect]~]]
        ==

        =/  remote-agent-wire=path  `path`/booths/(scot %tas booth-key)
        %-  (slog leaf+"sending {<booth-owner>} delegate to {<remote-agent-wire>}..." ~)

        :_  state(delegates (~(put by delegates.state) booth-key booth-participants))

        :~
          [%give %fact [/booths]~ %json !>(effects)]
          [%give %fact [remote-agent-wire]~ %json !>(effects)]
        ==

      ++  undelegate-api
        |=  [req=(pair @ta inbound-request:eyre) payload=(map @t json)]
        ^-  (quip card _state)

        %-  (slog leaf+"{<dap.bowl>}: delegate-api {<payload>}..." ~)

        =/  context  (~(get by payload) 'context')
        ?~  context  (send-api-error req 'missing context')
        =/  context  (need context)
        =/  context  ?:  ?=([%o *] context)  p.context  ~

        =/  booth-key  (~(get by context) 'booth')
        ?~  booth-key  (send-api-error req 'missing context key. booth key')
        =/  booth-key  (so:dejs:format (need booth-key))

        =/  booth  (~(get by booths.state) booth-key)
        ?~  booth  (send-api-error req 'unexpected error. booth {<booth-key>} not found in store')
        =/  booth  (need booth)

        =/  booth  ?:  ?=([%o *] booth)  p.booth  ~
        =/  booth-owner  (~(get by booth) 'owner')
        ?~  booth-owner  (send-api-error req 'booth owner not found')
        =/  booth-owner  (need booth-owner)
        =/  booth-owner  `@p`(slav %p (so:dejs:format booth-owner))

        =/  data  (~(get by payload) 'data')
        ?~  data  (send-api-error req 'payload data not found')
        =/  data  ?:(?=([%o *] u.data) p.u.data ~)
        =/  delegate  (~(get by data) 'delegate')
        ?~  delegate  (send-api-error req 'delegate element not found')
        =/  delegate  (so:dejs:format (need delegate))

        =/  delegation=json
        %-  pairs:enjs:format
        :~
          ['delegate' s+delegate]
        ==

        =/  signature  (sign:sig our.bowl now.bowl delegation)

        =/  sig-data=json
        %-  pairs:enjs:format
        :~
          ['hash' s+`@t`(scot %ux p.signature)]
          ['voter' s+(crip "{<q.signature>}")]
          ['life' (numb:enjs:format r.signature)]
        ==
        =/  sig-payload=json
        %-  pairs:enjs:format
        :~
          ['sig' sig-data]
          ['delegate' s+delegate]
        ==

        =/  payload-data  (~(put by payload) 'data' sig-payload)

        =/  remote-agent-wire=path  `path`/booths/(scot %tas booth-key)
        %-  (log:core %warn "sending {<booth-owner>} delegate to {<remote-agent-wire>}...")

        =/  =response-header:http
          :-  200
          :~  ['Content-Type' 'application/json']
          ==

        ::  encode the proposal as a json string
        =/  body  (crip (en-json:html [%o payload]))

        ::  convert the string to a form that arvo will understand
        =/  data=octs
              (as-octs:mimes:html body)

        :_  state

        :~
          [%give %fact [/http-response/[p.req]]~ %http-response-header !>(response-header)]
          [%give %fact [/http-response/[p.req]]~ %http-response-data !>(`data)]
          [%give %kick [/http-response/[p.req]]~ ~]
          [%pass remote-agent-wire %agent [booth-owner %ballot] %poke %json !>([%o payload-data])]
        ==

      ++  undelegate-wire
        |=  [payload=(map @t json)]
        ^-  (quip card _state)

        %-  (slog leaf+"{<dap.bowl>}: undelegate-wire {<payload>}..." ~)
        :: =/  payload  ?:(=([%o *] payload) p.payload ~)

        =/  context  (~(get by payload) 'context')
        ?~  context
          ~&  >>>  "{<dap.bowl>}: undelegate wire error. payload missing context"
          !!
        =/  context  (need context)
        =/  context  ?:  ?=([%o *] context)  p.context  ~

        =/  booth-key  (~(get by context) 'booth')
        ?~  booth-key
          ~&  >>>  "{<dap.bowl>}: undelegate wire error. context missing booth"
          !!
        =/  booth-key  (so:dejs:format (need booth-key))

        =/  booth  (~(get by booths.state) booth-key)
        ?~  booth
          ~&  >>>  "{<dap.bowl>}: undelegate wire error. {<booth-key>} not found in booth store"
          !!
        =/  booth  (need booth)

        =/  booth  ?:  ?=([%o *] booth)  p.booth  ~
        =/  booth-owner  (~(get by booth) 'owner')
        ?~  booth-owner
          ~&  >>>  "{<dap.bowl>}: undelegate wire error. {<booth-key>} missing owner"
          !!
        =/  booth-owner  (need booth-owner)
        =/  booth-owner  `@p`(slav %p (so:dejs:format booth-owner))

        =/  data  (~(get by payload) 'data')
        ?~  data
          ~&  >>>  "{<dap.bowl>}: undelegate wire error. payload missing data"
          !!
        =/  data  (need data)
        =/  data  ?:  ?=([%o *] data)  p.data  ~

        =/  delegate-key  (~(get by data) 'delegate')
        ?~  delegate-key
          ~&  >>>  "{<dap.bowl>}: undelegate wire error. payload data missing delegate"
          !!
        =/  delegate-key  (so:dejs:format (need delegate-key))

        ::  is the delegate actually a member of the group?
        =/  booth-members  (~(get by participants.state) booth-key)
        ?~  booth-members
          ~&  >>>  "{<dap.bowl>}: undelegate wire error. booth member store not found"
          !!
        =/  booth-members  (need booth-members)
        =/  member  (~(get by booth-members) delegate-key)
        ?~  member
          ~&  >>>  "{<dap.bowl>}: undelegate wire error. {<delegate-key>} is not a booth participant"
          !!

        =/  sgn  (~(get by data) 'sig')
        ?~  sgn
          ~&  >>>  "{<dap.bowl>}: undelegate wire error. payload data missing sig"
          !!
        =/  sgn  (need sgn)

        =/  verified  (ver:sig bowl sgn ~)
        ?~  verified
          ~&  >>>  "{<dap.bowl>}: undelegate wire error. unable to validate signature"
          !!

        =/  participant-key  (crip "{<src.bowl>}")
        =/  booth-participants  (~(get by delegates.state) booth-key)
        =/  booth-participants  ?~(booth-participants ~ (need booth-participants))
        =/  participant  (~(get by booth-participants) participant-key)
        ?:  =(~ participant)
          ~&  >>  "{<dap.bowl>}: undelegate wire error. {<participant-key>} not found"
          !!

        =/  booth-votes  (~(get by votes.state) booth-key)
        =/  booth-votes  ?~(booth-votes ~ (need booth-votes))
        =/  participant  (~(get by booth-votes) participant-key)
        ?.  =(~ participant)
          ~&  >>  "{<dap.bowl>}: undelegate wire error. {<participant-key>} already voted"
          !!

        =/  delegation=json
        %-  pairs:enjs:format
        :~
          ['delegate' s+delegate-key]
          ['sig' sgn]
          ['created' (time:enjs:format now.bowl)]
        ==

        =/  booth-participants  (~(del by booth-participants) participant-key)

        =/  participant-effect=json
        %-  pairs:enjs:format
        :~
          ['resource' s+'delegate']
          ['effect' s+'delete']
          ['key' s+participant-key]
          ['data' delegation]
        ==

        =/  effects=json
        %-  pairs:enjs:format
        :~
          ['action' s+'undelegate-reaction']
          ['context' [%o context]]
          ['effects' [%a [participant-effect]~]]
        ==

        =/  remote-agent-wire=path  `path`/booths/(scot %tas booth-key)
        %-  (slog leaf+"sending {<booth-owner>} delegate to {<remote-agent-wire>}..." ~)

        :_  state(delegates (~(put by delegates.state) booth-key booth-participants))

        :~
          [%give %fact [/booths]~ %json !>(effects)]
          [%give %fact [remote-agent-wire]~ %json !>(effects)]
        ==
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
        :: %-  (log:core %good "ballot: client subscribed to {(spud path)}.")
        `this

      [%booths ~]
        ?:  =(our.bowl src.bowl)
          :: %-  (log:core %warn "remote ships not allowed to watch /booths")
          `this
        !!

      :: crash on booth any of the following:
      ::   !! booth not found in store
      ::   !! booth not found in participants store
      ::   !! participant not found in participants store
      :: according to docs...
      ::    "The (unit tang) in the %watch-ack will be null if processing succeeded,
      ::       and non-null if it crashed, with a stack trace in the tang."
      ::  see:  https://urbit.org/docs/userspace/gall-guide/8-subscriptions
      [%booths *]
        :: %-  (log:core %good "ballot: client subscribed to {(spud path)}.")
        =/  booth-key  (spud (oust [0 1] `(list @ta)`path))
        =/  booth-key  (crip `tape`(oust [0 1] `(list @)`booth-key))
        %-  (log:core %info "ballot: extracted booth key => {<booth-key>}...")

        =/  booth  (~(get by booths.state) booth-key)
        =/  booth  ?~(booth ~ (need booth))

        =/  booth-participants  (~(get by participants.state) booth-key)
        =/  booth-participants  ?~(booth-participants ~ (need booth-participants))
        =/  participant  (~(get by booth-participants) (crip "{<src.bowl>}"))
        ?~  participant
              :: %-  (log:core %error "subscription request rejected. {<src.bowl>} not a participant of the booth.")
              !!

        =/  booth-proposals  (~(get by proposals.state) booth-key)
        =/  booth-proposals  ?~(booth-proposals ~ (need booth-proposals))
        =/  booth-votes  (~(get by votes.state) booth-key)
        =/  booth-votes  ?~(booth-votes ~ (need booth-votes))

        =/  booth-polls  (~(get by polls.state) booth-key)
        =/  booth-polls  ?~(booth-polls ~ (need booth-polls))

        =/  booth-delegates  (~(get by delegates.state) booth-key)
        =/  booth-delegates  ?~(booth-delegates ~ (need booth-delegates))

        =/  context=json
          %-  pairs:enjs:format
          :~
            ['booth' s+booth-key]
          ==

        =/  data
          %-  pairs:enjs:format
          :~
            ['booth' booth]
            ['proposals' [%o booth-proposals]]
            ['participants' [%o booth-participants]]
            ['votes' [%o booth-votes]]
            ['polls' [%o booth-polls]]
            ['delegates' [%o booth-delegates]]
          ==

        ::  https://urbit.org/docs/userspace/gall-guide/8-subscriptions#incoming-subscriptions
        ::  when there's a new subscription, you can send a %fact back with an empty (list path),
        ::    and it'll only go to the new subscriber. This is most useful when you want to give the
        ::    subscriber some initial state, which you otherwise couldn't do without sending it to everyone.
        =/  action-payload
          %-  pairs:enjs:format
          :~
            ['action' s+'initial']
            ['context' context]
            ['data' data]
          ==

        :_  this
        :~  [%give %fact ~ %json !>(action-payload)]
        ==

      ::  ~lodlev-migdev - allow external agents (including UI clients) to subscribe
      ::    to the /notifications channel.
      [%notifications *]
        %-  (log:core %good "ballot: client subscribed to {(spud path)}.")
        `this

      ::  ~lodlev-migdev - print message when eyre subscribes to our http-response path
      ::  TODO: Do not allow anything other than Eyre to suscribe to this path.
      [%http-response *]
        %-  (log:core %good "ballot: client subscribed to {(spud path)}.")
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

  %-  (log:core %info "ballot: scry called with {<path>}...")

  ?+    path  (on-peek:def path)
      [%x %ship ~]
        =/  res=json
        %-  pairs:enjs:format
        :~
          ['ship' s+(crip "{<our.bowl>}")]
        ==
        ``json+!>(res)

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
        =/  segments  `(list @ta)`path
        =/  key  (crip (oust [0 1] (spud /(snag 2 segments))))
        %-  (log:core %warn "ballot: extracting proposals for booth {<key>}...")
        =/  booth-proposals  (~(get by proposals.state) key)
        ?~  booth-proposals  ``json+!>(~)
        ``json+!>([%o (need booth-proposals)])

      [%x %booths @ @ @ %proposals ~]
        =/  segments  `(list @ta)`path
        =/  key  (crip (oust [0 1] (spud /(snag 2 segments)/(snag 3 segments)/(snag 4 segments))))
        ::=/  key  (crip (oust [0 1] (spud /(snag 2 `(list @)`path)/(snag 3 `(list @)`path)/(snag 4 `(list @)`path))))
        %-  (log:core %warn "ballot: extracting proposals for booth {<key>}...")
        =/  booth-proposals  (~(get by proposals.state) key)
        ?~  booth-proposals  ``json+!>(~)
        ``json+!>([%o (need booth-proposals)])

      [%x %booths @ %proposals @ %votes ~]
        =/  segments  `(list @ta)`path
        =/  booth-key  (crip (oust [0 1] (spud /(snag 2 segments))))
        =/  proposal-key  (key-from-path:util i.t.t.t.t.path)
        %-  (log:core %warn "ballot: extracting votes for booth {<booth-key>}, proposal {<proposal-key>}...")
        =/  booth-proposals  (~(get by votes.state) booth-key)
        ?~  booth-proposals  ``json+!>(~)
        =/  booth-proposals  (need booth-proposals)
        =/  proposal-votes  (~(get by booth-proposals) proposal-key)
        ?~  proposal-votes  ``json+!>(~)
        ``json+!>((need proposal-votes))

      [%x %booths @ @ @ %proposals @ %votes ~]
        =/  segments  `(list @ta)`path
        =/  booth-key  (crip (oust [0 1] (spud /(snag 2 segments)/(snag 3 segments)/(snag 4 segments))))
        =/  proposal-key  (crip (oust [0 1] (spud /(snag 6 segments))))
        %-  (log:core %warn "ballot: extracting votes for booth {<booth-key>}, proposal {<proposal-key>}...")
        =/  booth-proposals  (~(get by votes.state) booth-key)
        ?~  booth-proposals  ``json+!>(~)
        =/  booth-proposals  (need booth-proposals)
        =/  proposal-votes  (~(get by booth-proposals) proposal-key)
        ?~  proposal-votes  ``json+!>(~)
        ``json+!>((need proposal-votes))

      [%x %booths @ %votes ~]
        =/  segments  `(list @ta)`path
        =/  booth-key  (crip (oust [0 1] (spud /(snag 2 segments))))
        %-  (log:core %warn "ballot: extracting votes for booth {<booth-key>}...")
        =/  booth-proposals  (~(get by votes.state) booth-key)
        ?~  booth-proposals  ``json+!>(~)
        ``json+!>([%o (need booth-proposals)])

      [%x %booths @ @ @ %votes ~]
        =/  segments  `(list @ta)`path
        =/  booth-key  (crip (oust [0 1] (spud /(snag 2 segments)/(snag 3 segments)/(snag 4 segments))))
        %-  (log:core %warn "ballot: extracting votes for booth {<booth-key>}...")
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
        =/  segments  `(list @ta)`path
        =/  key  (crip (oust [0 1] (spud /(snag 2 segments))))
        %-  (log:core %warn "ballot: extracting participants for booth {<key>}...")
        =/  participants  (~(get by participants.state) key)
        ?~  participants  ``json+!>(~)
        ``json+!>([%o (need participants)])

      [%x %booths @ @ @ %participants ~]
        =/  segments  `(list @ta)`path
        =/  key  (crip (oust [0 1] (spud /(snag 2 segments)/(snag 3 segments)/(snag 4 segments))))
        %-  (log:core %warn "ballot: extracting participants for booth {<key>}...")
        =/  participants  (~(get by participants.state) key)
        ?~  participants  ``json+!>(~)
        ``json+!>([%o (need participants)])

      [%x %booths @ %delegates ~]
        =/  segments  `(list @ta)`path
        =/  key  (crip (oust [0 1] (spud /(snag 2 segments))))
        %-  (slog leaf+"ballot: extracting participants for booth {<key>}..." ~)
        =/  delegate-view  (~(dlg view [bowl delegates.state]) key)
        ``json+!>(delegate-view)

      [%x %booths @ @ @ %delegates ~]
        =/  segments  `(list @ta)`path
        =/  key  (crip (oust [0 1] (spud /(snag 2 segments)/(snag 3 segments)/(snag 4 segments))))
        %-  (log:core %warn "ballot: extracting participants for booth {<key>}...")
        =/  delegate-view  (~(dlg view [bowl delegates.state]) key)
        ``json+!>(delegate-view)

      [%x %custom-actions ~]
        =/  lib-file  /(scot %p our.bowl)/(scot %tas dap.bowl)/(scot %da now.bowl)/lib/(scot %tas dap.bowl)/custom-actions/config/json
        =/  data  .^(json %cx lib-file)
        ``json+!>(data)

  ==

::
++  on-agent
  |=  [=wire =sign:agent:gall]
  ^-  (quip card _this)

  |^
  =/  wirepath  `path`wire
  %-  (log:core %info "ballot: {<wirepath>} data received...")

  ?+    wire  (on-agent:def wire sign)

    :: handle updates coming in from group store
    [%group ~]
      ?+    -.sign  (on-agent:def wire sign)
        %watch-ack
          ?~  p.sign
            %-  (log:core %info "ballot: group subscription succeeded")
            `this
          %-  (log:core %info "ballot: group subscription failed")
          `this
    ::
        %kick
          %-  (log:core %info "ballot: group kicked us, resubscribing...")
          :_  this
          :~  [%pass /group %agent [our.bowl %group-store] %watch /groups]
          ==
    ::
        %fact
          %-  (log:core %info "ballot: received fact from group => {<p.cage.sign>}")
          ?+    p.cage.sign  (on-agent:def wire sign)
              %group-update-0
                =/  action  !<(=update:group-store q.cage.sign)
                ?+  -.action  (on-agent:def wire sign)
                  %initial
                    (on-group-initial action)

                  %initial-group
                    (on-group-initial-group action)

                  %add-group
                    (on-group-added action)

                  %add-members
                    (on-group-member-added action)

                  %remove-members
                    (on-group-member-removed action)

                  %remove-group
                    (on-group-removed action)
                ==
          ==
      ==

    [%booths @ %msg @ ~]

        ?+  -.sign  (on-agent:def wire sign)
          %poke-ack
            =/  ack  ?~(p.sign 'ack' 'nack')
            =/  segments  `(list @ta)`wirepath
            =/  msg-id  (snag 3 segments)
            =/  msg  (~(get by mq.state) msg-id)
            ?~  msg
              %-  (log:core %error "ballot: %poke-ack msg {<msg-id>} not found")
              `this
            (handle-message-ack msg-id ack (need msg))
        ==

    :: [%timer @ @ %start ~]
    ::   ?+    -.sign  (on-agent:def wire sign)
    ::       %poke-ack
    ::         ?~  p.sign
    ::               %-  (log:core %info "start-poll timer started successfully")
    ::               `this
    ::             %-  (log:core %info "start-poll timer failed to start" u.p.sign)
    ::             `this
    ::   ==

    :: [%booths @ @ @ %start-poll ~]
    ::   =/  segments  `(list @ta)`wirepath
    ::   =/  booth-key  (snag 1 segments)
    ::   =/  proposal-key  (snag 2 segments)
    ::   ?+    -.sign  (on-agent:def wire sign)
    ::       %poke-ack
    ::         ?~  p.sign
    ::               %-  (log:core %info "start-poll thread started successfully")
    ::               `this
    ::             %-  (log:core %info "start-poll failed to start" u.p.sign)
    ::             `this

    ::       %fact
    ::         ?+  p.cage.sign  (on-agent:def wire sign)
    ::               %thread-fail
    ::                 =/  err  !<  (pair term tang)  q.cage.sign
    ::                 %-  (log:core %info "start-poll thread failed: {(trip p.err)}" q.err)
    ::                 `this
    ::               %thread-done
    ::                 (on-start-poll booth-key proposal-key)
    ::         ==
    ::   ==

    :: [%booths @ @ @ %end-poll ~]
    ::   =/  segments  `(list @ta)`wirepath
    ::   =/  booth-key  (snag 1 segments)
    ::   =/  proposal-key  (snag 2 segments)
    ::   ?+    -.sign  (on-agent:def wire sign)
    ::       %poke-ack
    ::         ?~  p.sign
    ::           %-  (log:core %info "end-poll thread started successfully")
    ::           `this
    ::         %-  (log:core %info "end-poll failed to start" u.p.sign)
    ::         `this

    ::       %fact
    ::         ?+  p.cage.sign  (on-agent:def wire sign)
    ::               %thread-fail
    ::                 =/  err  !<  (pair term tang)  q.cage.sign
    ::                 %-  (log:core %info "end-poll thread failed: {(trip p.err)}" q.err)
    ::                 `this
    ::               %thread-done
    ::                 (on-end-poll booth-key proposal-key)
    ::         ==
    ::   ==

    [%booths *]
      =/  segments  `(list @ta)`wirepath
      =/  booth-key  (snag 1 segments)
      ?-    -.sign
        %poke-ack
          ?~  p.sign
            ((log:core %info "ballot: {<wirepath>} poke succeeded") `this)
          ((log:core %info "ballot: {<wirepath>} poke failed") `this)

        %watch-ack
          ?~  p.sign
            ((log:core %info "ballot: subscribed to {<wirepath>}") `this)
          ((log:core %info "ballot: {<wirepath>} subscription failed") `this)

        %kick
          %-  (log:core %info "ballot: {<wirepath>} got kick, resubscribing...")
          :_  this
          :~  [%pass /booths/(scot %tas booth-key) %agent [src.bowl %ballot] %watch /booths/(scot %tas booth-key)]
          ==

        %fact
          ?+    p.cage.sign  (on-agent:def wire sign)

            %json
              =/  jon  !<(json q.cage.sign)
              %-  (log:core %good "{<jon>}")

              =/  payload  ((om json):dejs:format jon)

              =/  action  (~(get by payload) 'action')
              ?~  action
                    %-  (log:core %error "null action in on-agent handler => {<payload>}")
                    `this

              =/  action  (so:dejs:format (need action))

              ::  no need to gift ourselves. if this ship generated the gift, the action
              ::    has already occurred
              ?:  =(our.bowl src.bowl)
                :: %-  (log:core %warn "skipping gift to ourselves..."  `this
                ?+  action  %-  (log:core %warn "skipping gift to ourselves...")  `this
                   %save-proposal
                    %-  (log:core %info "ballot: [set-booth-timer] => proposal updates. setting timers...")
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

                %accept
                  (handle-accept booth-key payload)

                %poll-started-reaction
                  (handle-poll-started-reaction payload)

                %poll-ended-reaction
                  (handle-poll-ended-reaction payload)

                %booth-reaction
                  (handle-booth-reaction payload)

                %delegate-reaction
                  (handle-delegate-reaction payload)

              ==

          ==
      ==
  ==

  ++  handle-booth-reaction
    |=  [payload=(map @t json)]

    %-  (log:core %info "ballot: poll-started-reaction received...")

    =/  context  ((om json):dejs:format (~(got by payload) 'context'))
    =/  booth-key  (so:dejs:format (~(got by context) 'booth'))

    ::  generate an booth-reaction with a delete effect on the booth resource
    =/  context  ((om json):dejs:format (~(got by payload) 'context'))
    =/  booth-key  (so:dejs:format (~(got by context) 'booth'))

    =/  effects  ((ar json):dejs:format (~(got by payload) 'effects'))
    =/  effect  ((om json):dejs:format (snag 0 effects))

    =/  effect-name  (so:dejs:format (~(got by effect) 'effect'))

    ?+  effect-name  !!  :: %-  (log:core %error "ballot: unknown effect type")  !!

      %delete
        :_  this(booths (~(del by booths.state) booth-key))
        :~  [%give %fact [/booths]~ %json !>([%o payload])]
        ==

    ==

  ++  handle-delegate-reaction
    |=  [payload=(map @t json)]

    %-  (slog leaf+"{<dap.bowl>}: handle-delegate-reaction received. {<payload>}..." ~)

    =/  context  (~(get by payload) 'context')
    =/  context  ?~(context ~ (need context))
    =/  context  ?:  ?=([%o *] context)  p.context  ~
    =/  booth-key  (so:dejs:format (~(got by context) 'booth'))
    =/  participant-key  (so:dejs:format (~(got by context) 'participant'))

    =/  effects  ((ar json):dejs:format (~(got by payload) 'effects'))
    =/  effect  (snag 0 effects)
    =/  effect  ?:  ?=([%o *] effect)  p.effect  ~

    =/  effect-name  (so:dejs:format (~(got by effect) 'effect'))

    ?+  effect-name  (mean leaf+"{<dap.bowl>}: unknown effect type" ~)

      %add
        =/  booth-participants  (~(get by delegates.state) booth-key)
        =/  booth-participants  ?~(booth-participants ~ (need booth-participants))
        =/  participant  (~(get by booth-participants) participant-key)
        =/  participant  ?~(participant ~ (need participant))
        =/  participant  ?:  ?=([%o *] participant)  p.participant  ~
        =/  effect-data  (~(get by effect) 'data')
        ?~  effect-data  (mean leaf+"{<dap.bowl>}: no data" ~)
        =/  booth-participants  (~(put by booth-participants) participant-key (need effect-data))
        :_  this(delegates (~(put by delegates.state) booth-key booth-participants))
        :~  [%give %fact [/booths]~ %json !>([%o payload])]
        ==

      %delete
        =/  booth-participants  (~(get by delegates.state) booth-key)
        =/  booth-participants  ?~(booth-participants ~ (need booth-participants))
        =/  participant  (~(get by booth-participants) participant-key)
        =/  booth-participants  (~(del by booth-participants) participant-key)
        :_  this(delegates (~(put by delegates.state) booth-key booth-participants))
        :~  [%give %fact [/booths]~ %json !>([%o payload])]
        ==

    ==

  ++  handle-poll-started-reaction
    |=  [payload=(map @t json)]

    %-  (log:core %info "ballot: poll-started-reaction received...")

    =/  context  ((om json):dejs:format (~(got by payload) 'context'))
    =/  booth-key  (so:dejs:format (~(got by context) 'booth'))
    =/  proposal-key  (so:dejs:format (~(got by context) 'proposal'))
    =/  poll-key  (so:dejs:format (~(got by context) 'poll'))

    :: =/  effects  (~(get by payload) 'effects')
    :: ?~  effects  %-  (log:core %error "ballot: effects not found"  !!
    :: =/  effects=(list json)  ((as json):dejs:format (need effects))
    :: %-  run
    :: :-  effects
    :: |=  [jon=json]
    ::   (dispatch-effect payload jon)

    =/  effects  (~(get by payload) 'effects')
    ?~  effects  !!  ::  %-  (log:core %error "ballot: effects not found" ~)  !!
    %-  (log:core %info "ballot: extracting effects data...")
    =/  effects=(list json)  ~(tap in ((as json):dejs:format (need effects)))
    %-  (log:core %info "ballot: extracting effect data...")
    =/  effect  ((om json):dejs:format (snag 0 effects))
    %-  (log:core %info "ballot: extracting poll data...")
    =/  data  ((om json):dejs:format (~(got by effect) 'data'))
    %-  (log:core %info "ballot: done")

    =/  poll-proposals  (~(get by polls.state) booth-key)
    =/  poll-proposals  ?~(poll-proposals ~ (need poll-proposals))
    =/  poll-proposal  (~(get by poll-proposals) proposal-key)
    =/  poll-proposal  ?~(poll-proposal ~ ((om json):dejs:format (need poll-proposal)))
    =/  poll-proposal  (~(gas by poll-proposal) ~(tap by data))
    =/  poll-proposals  (~(put by poll-proposals) proposal-key [%o poll-proposal])

    %-  (log:core %info "ballot: committing poll changes...")
    %-  (log:core %warn "{<(crip (en-json:html [%o data]))>}")
    %-  (log:core %warn "{<(crip (en-json:html [%o poll-proposal]))>}")

    :_  this(polls (~(put by polls.state) booth-key poll-proposals))

    :~  [%give %fact [/booths]~ %json !>([%o payload])]
    ==

  ++  handle-poll-ended-reaction
    |=  [payload=(map @t json)]

    %-  (log:core %info "ballot: poll-ended-reaction received...")
    %-  (log:core %warn "{<(crip (en-json:html [%o payload]))>}")

    =/  context  ((om json):dejs:format (~(got by payload) 'context'))
    =/  booth-key  (so:dejs:format (~(got by context) 'booth'))
    =/  proposal-key  (so:dejs:format (~(got by context) 'proposal'))
    =/  poll-key  (so:dejs:format (~(got by context) 'poll'))

    =/  effects  (~(get by payload) 'effects')
    ?~  effects  !! ::  %-  (log:core %error "ballot: effects not found")  !!
    =/  effects=(list json)  ~(tap in ((as json):dejs:format (need effects)))
    =/  effect  ((om json):dejs:format (snag 0 effects))
    =/  data  ((om json):dejs:format (~(got by effect) 'data'))

    =/  poll-proposals  (~(get by polls.state) booth-key)
    =/  poll-proposals  ?~(poll-proposals ~ (need poll-proposals))
    =/  poll-proposal  (~(get by poll-proposals) proposal-key)
    =/  poll-proposal  ?~(poll-proposal ~ ((om json):dejs:format (need poll-proposal)))
    =/  poll-proposal  (~(gas by poll-proposal) ~(tap by data))
    =/  poll-proposals  (~(put by poll-proposals) proposal-key [%o poll-proposal])

    =/  booth-proposals  (~(get by proposals.state) booth-key)
    =/  booth-proposals  ?~(booth-proposals ~ (need booth-proposals))
    =/  booth-proposal  (~(get by booth-proposals) proposal-key)
    =/  booth-proposal  ?~(booth-proposal ~ ((om json):dejs:format (need booth-proposal)))
    =/  booth-proposal  (~(gas by booth-proposal) ~(tap by data))
    =/  booth-proposals  (~(put by booth-proposals) proposal-key [%o booth-proposal])

    :_  this(polls (~(put by polls.state) booth-key poll-proposals), proposals (~(put by proposals.state) booth-key booth-proposals))

    :~  [%give %fact [/booths]~ %json !>([%o payload])]
    ==

  ++  handle-message-ack
    |=  [msg-id=@t ack=@t msg=json]

    %-  (log:core %info "ballot: received ack ({<ack>}) {<msg-id>}...")

    =/  msg  ((om json):dejs:format msg)

    =/  action  (so:dejs:format (~(got by msg) 'action'))

    ?+  action  `this(mq (~(del by mq.state) msg-id))

      %accept
        (handle-accept-ack msg-id msg)

    ==

  ++  on-group-added
    |=  =action:group-store

    ::  generate a booth from the resource
    =/  booth  (booth-from-resource resource.action)

    %-  (log:core %info "ballot: on-group-added. adding group booth {<key.booth>}...")

    ::  generate a participant from the resource
    =/  participant-key  (crip "{<our.bowl>}")
    =/  participant=json
    %-  pairs:enjs:format
    :~
      ['key' s+participant-key]
      ['name' s+participant-key]
      ['status' s+?:(=(our.bowl entity.resource.action) 'active' 'enlisted')]
      ['created' (time:enjs:format now.bowl)]
      ['role' s+?:(=(our.bowl entity.resource.action) 'owner' 'participant')]
    ==

    =/  context=json
    %-  pairs:enjs:format
    :~
      ['booth' s+key.booth]
    ==

    =/  booth-effect=json
    %-  pairs:enjs:format
    :~
      ['resource' s+'booth']
      ['effect' s+'add']
      ['data' data.booth]
    ==

    =/  participant-effect=json
    %-  pairs:enjs:format
    :~
      ['resource' s+'participant']
      ['effect' s+'add']
      ['data' participant]
    ==

    =/  effects=json
    %-  pairs:enjs:format
    :~
      ['action' s+'group-added-reaction']
      ['context' context]
      ['effects' [%a [booth-effect participant-effect ~]]]
    ==

    =/  booth-participants  (~(get by participants.state) key.booth)
    =/  booth-participants  ?~(booth-participants ~ (need booth-participants))
    =/  booth-participants  (~(put by booth-participants) participant-key participant)

    :_  this(booths (~(put by booths.state) key.booth data.booth), participants (~(put by participants.state) key.booth booth-participants))

    :~  [%give %fact [/booths]~ %json !>(effects)]
        [%pass /booths/(scot %tas key.booth) %agent [our.bowl %ballot] %watch /booths/(scot %tas key.booth)]
    ==

  ++  on-group-removed
    |=  =action:group-store

    =/  key  (crip (weld (weld "{<entity.resource.action>}" "-groups-") (trip `@t`name.resource.action)))

    ::  generate an booth-reaction with a delete effect on the booth resource

    =/  context=json
    %-  pairs:enjs:format
    :~
      ['booth' s+key]
    ==

    =/  effect=json
    %-  pairs:enjs:format
    :~
      ['resource' s+'booth']
      ['effect' s+'delete']
      ['data' ~]
    ==

    =/  effects=json
    %-  pairs:enjs:format
    :~
      ['action' s+'booth-reaction']
      ['context' context]
      ['effects' [%a [effect]~]]
    ==

    :_  this(booths (~(del by booths.state) key), proposals (~(del by proposals.state) key), participants (~(del by participants.state) key), votes (~(del by votes.state) key), polls (~(del by polls.state) key))

    :~  [%give %fact [/booths]~ %json !>(effects)]
    ==

  ++  extract-booth
    |=  [res=resource eff=@t p=@p acc=[effects=(list card) data=(map @t json)]]
    ^-  [effects=(list card) data=(map @t json)]
    =/  timestamp  (crip (en-json:html (time:enjs:format now.bowl)))
    =/  key  (crip "{<p>}")
    =/  participant=json
    %-  pairs:enjs:format
    :~
      ['key' s+key]
      ['name' s+key]
      ['slug' s+(spat /(scot %t key))]
      ['status' s+'enlisted']
      ['image' ~]
      ['created' (time:enjs:format now.bowl)]
    ==
    ?:  =(our.bowl p)
      %-  (log:core %info "ballot: this ship {<our.bowl>} has been added to the group. mounting booth...")
      =/  booth  (booth-from-resource res)
      [(snoc effects.acc (send-new-booth-effect eff key data.booth)) (~(put by data.acc) key.booth data.booth)]
    [effects.acc data.acc]

  ++  send-new-booth-effect
    |=  [eff=@t key=@t booth=json]
    ^-  card

    =/  context=json
    %-  pairs:enjs:format
    :~
      ['booth' s+key]
    ==

    =/  status-effect=json
    %-  pairs:enjs:format
    :~
      ['resource' s+'booth']
      ['effect' s+eff]
      ['data' booth]
    ==

    =/  effects=json
    %-  pairs:enjs:format
    :~
      ['action' s+'booth-reaction']
      ['context' context]
      ['effects' [%a [status-effect]~]]
    ==

    [%give %fact [/booths]~ %json !>(effects)]

  ++  on-group-member-added
    |=  =action:group-store
    ?>  ?=(%add-members -.action)
    =/  booth-key  (crip (weld (weld "{<entity.resource.action>}" "-groups-") (trip `@t`name.resource.action)))
    %-  (log:core %info "on-group-member-added {<booth-key>}")
    =/  booth-participants  (~(get by participants.state) booth-key)
    ?~  booth-participants
          %-  (log:core %info "booth {<booth-key>} participants not found...")
          `this
    =/  booth-participants  (need booth-participants)

    =/  data=[effects=(list card) participants=(map @t json)]
      ^-  [effects=(list card) participants=(map @t json)]
      %-  ~(rep in ships.action)
      |=  [p=@p acc=[effects=(list card) data=(map @t json)]]
      =/  participant-key  (crip "{<p>}")

      =/  new-participant=json
      %-  pairs:enjs:format
      :~
        ['key' s+participant-key]
        ['name' s+participant-key]
        ['status' s+'enlisted']
        ['role' s+'participant']
        ['created' (time:enjs:format now.bowl)]
      ==

      =/  booth-participants  (~(put by booth-participants) participant-key new-participant)

      =/  context=json
      %-  pairs:enjs:format
      :~
        ['booth' s+booth-key]
      ==

      =/  effect=json
      %-  pairs:enjs:format
      :~
        ['resource' s+'participant']
        ['effect' s+'add']
        ['data' new-participant]
      ==

      =/  effects=json
      %-  pairs:enjs:format
      :~
        ['action' s+'group-add-members-reaction']
        ['context' context]
        ['effects' [%a [effect]~]]
      ==

      =/  effects=(list card)
      :~  [%give %fact [/booths]~ %json !>(effects)]
          [%give %fact [/booths/(scot %tas booth-key)]~ %json !>(effects)]
      ==
      [(weld effects.acc effects) booth-participants]

    :_  this(participants (~(put by participants.state) booth-key participants.data))

    [effects.data]

  ++  on-group-member-removed
    |=  =action:group-store
    ?>  ?=(%remove-members -.action)

    =/  booth-key  (crip (weld (weld "{<entity.resource.action>}" "-groups-") (trip `@t`name.resource.action)))
    =/  booth  (~(get by booths.state) booth-key)
    =/  booth  ?~(booth ~ (need booth))
    :: =/  booth-ship  (~(got by booth) 'owner')
    :: =/  hostship=@p  `@p`(slav %p booth-ship)

    %-  (log:core %info "on-group-member-removed {<booth-key>}")
    =/  booth-participants  (~(get by participants.state) booth-key)
    ?~  booth-participants
          %-  (log:core %info "booth {<booth-key>} participants not found...")
          `this
    =/  booth-participants  (need booth-participants)

    =/  data=[effects=(list card) participants=(map @t json)]
      %-  ~(rep in ships.action)
      |=  [p=@p acc=[effects=(list card) data=(map @t json)]]
      =/  participant-key  (crip "{<p>}")
      =/  participant  (~(get by booth-participants) participant-key)
      =/  participant  ?~(participant ~ (need participant))
      =/  booth-participants  (~(del by booth-participants) participant-key)

      =/  context=json
      %-  pairs:enjs:format
      :~
        ['booth' s+booth-key]
        ['participant' s+participant-key]
      ==

      =/  effect-list=(list json)
        ?:  =(p our.bowl)
          =/  booth-effect=json
          %-  pairs:enjs:format
          :~
            ['resource' s+'booth']
            ['effect' s+'delete']
            ['data' booth]
          ==
          [booth-effect ~]
        [~]

      =/  participant-effect=json
      %-  pairs:enjs:format
      :~
        ['resource' s+'participant']
        ['effect' s+'delete']
        ['data' participant]
      ==

      =/  effect-list  (snoc effect-list participant-effect)
      =/  effects=json
      %-  pairs:enjs:format
      :~
        ['action' s+'group-remove-members-reaction']
        ['context' context]
        ['effects' [%a effect-list]]
      ==

      =/  effects=(list card)
      :~  [%give %fact [/booths]~ %json !>(effects)]
          [%give %kick ~[/booths/(scot %tas booth-key)] (some p)]
      ==
      [(weld effects.acc effects) booth-participants]

    :_  this(participants (~(put by participants.state) booth-key participants.data))

    [effects.data]

  ++  booth-from-resource
    |=  [=resource]
    ^-  [key=@t status=@t data=json]

    =/  timestamp  (crip (en-json:html (time:enjs:format now.bowl)))
    =/  key  (crip (weld (weld "{<entity.resource>}" "-groups-") (trip `@t`name.resource)))
    =/  slug  (crip (weld (weld "{<entity.resource>}" "/groups/") (trip `@t`name.resource)))

    =/  group-name  (trip name.resource)

    ::  if this ship is the owner of the group, set them as the owner of the booth
    =/  status=@t  ?:(=(our.bowl entity.resource) 'active' 'enlisted')

    ::  create booth metadata
    =/  data=json
    %-  pairs:enjs:format
    :~
      ['type' s+'group']
      ['key' s+key]
      ['name' s+(crip group-name)]
      ['slug' s+slug]
      ['image' ~]
      ['status' s+status]
      ['owner' s+(crip "{<entity.resource>}")]
      ['created' (time:enjs:format now.bowl)]
      ['policy' s+'invite-only']
    ==

    [key status data]

  ::  ARM:  ++  on-group-initial
  ::   This is called when the /groups subscription succeeds. The group-store
  ::      passes us an initial list of groups we are members of. Use this map
  ::      to initial group booths in the ballot store.
  ++  on-group-initial
    |=  [=initial:group-store]
    ?>  ?=(%initial -.initial)
    =/  data
      ^-  [effects=(list card) booths=(map @t json) participants=(map @t (map @t json))] :: participants=(map @t (map @t json))]
      ::  loop thru groups, creating a new booth (status='initial') for each
      ::    group in the map
      %-  ~(rep in groups.initial)
      ::  each map key/value pair is a resource => group. acc is an
      ::   accumulator which is used to store the final result
      |=  [[=resource =group] acc=[effects=(list card) booths=(map @t json) participants=(map @t (map @t json))]]  :: participants=(map @t (map @t json))]]
        ^-  [effects=(list card) booths=(map @t json) participants=(map @t (map @t json))] :: participants=(map @t (map @t json))]
        =/  booth  (booth-from-resource resource)
        ?:  (~(has by booths.state) key.booth)
              %-  (log:core %warn "cannot add booth {<key.booth>} to store. already exists...")
              [effects.acc booths.acc participants.acc]
        =/  effects
              ?:  =(status.booth 'active')
                %-  (log:core %info "activating booth {<key.booth>} on {<our.bowl>}...")
                (snoc effects.acc [%pass /booths/(scot %tas key.booth) %agent [our.bowl %ballot] %watch /booths/(scot %tas key.booth)])
              [effects.acc]
        =/  participants
              ?:  =(status.booth 'active')
                =/  members  (members-to-participants resource group)
                (~(put by participants.acc) key.booth members)
              [participants.acc]
            [effects (~(put by booths.acc) key.booth data.booth) participants]
    :_  this(booths (~(gas by booths.state) ~(tap by booths.data)), participants (~(gas by participants.state) ~(tap by participants.data)))
    [effects.data]

  ++  on-group-initial-group
    |=  [=initial:group-store]
    ?>  ?=(%initial-group -.initial)

    =/  new-booth  (booth-from-resource resource.initial)

    =/  booth  (~(get by booths.state) key.new-booth)
    ?.  =(booth ~)
        %-  (log:core %warn "cannot add booth {<key.new-booth>} to store. already exists...")
        `this

    =/  booth-participants  (~(get by participants.state) key.new-booth)
    =/  booth-participants  ?~(booth-participants ~ (need booth-participants))

    =/  participant-key  (crip "{<our.bowl>}")

    =/  new-participant=json
    %-  pairs:enjs:format
    :~
      ['key' s+participant-key]
      ['name' s+participant-key]
      ['status' s+'enlisted']
      ['role' s+?:(=(our.bowl entity.resource.initial) 'owner' 'participant')]
      ['created' (time:enjs:format now.bowl)]
    ==

    =/  booth-participants  (~(put by booth-participants) participant-key new-participant)

    =/  context=json
    %-  pairs:enjs:format
    :~
      ['booth' s+key.new-booth]
    ==

    =/  booth-effect
    %-  pairs:enjs:format
    :~
      ['resource' s+'booth']
      ['effect' s+'add']
      ['data' data.new-booth]
    ==

    =/  participant-effect
    %-  pairs:enjs:format
    :~
      ['resource' s+'participant']
      ['effect' s+'add']
      ['data' new-participant]
    ==

    =/  effect-list=(list json)  [booth-effect participant-effect ~]
    =/  effects=json
    %-  pairs:enjs:format
    :~
      ['action' s+'group-added-reaction']
      ['context' context]
      ['effects' [%a effect-list]]
    ==

    :_  this(booths (~(put by booths.state) key.new-booth data.new-booth), participants (~(put by participants.state) key.new-booth booth-participants))

    :~  [%give %fact [/booths]~ %json !>(effects)]
    ==

  ++  members-to-participants
    |=  [=resource =group]
    ^-  (map @t json)
    =/  timestamp  (crip (en-json:html (time:enjs:format now.bowl)))
    ::  add all other members
    =/  participants=(map @t json)
      ^-  [participants=(map @t json)]
        %-  ~(rep in members.group)
          |=  [=ship acc=[participants=(map @t json)]]
          ^-  [participants=(map @t json)]
          =/  participant-key  (crip "{<ship>}")
          =/  member=json
          %-  pairs:enjs:format
          :~
            ['key' s+participant-key]
            ['name' s+participant-key]
            ['status' s+'enlisted']
            ['role' s+'participant']
            ['created' (time:enjs:format now.bowl)]
          ==
          =/  member=json
                ?:  =(ship entity.resource)
                  =/  member  ((om json):dejs:format member)
                  =/  member  (~(put by member) 'status' s+'active')
                  =/  member  (~(put by member) 'role' s+'owner')
                  [%o member]
                member
          [(~(put by participants.acc) participant-key member)]
    [participants]

  ++  on-proposal-changed
    |=  [booth-key=@t payload=(map @t json)]
    ^-  (quip card _this)

    =/  timestamp  (crip (en-json:html (time:enjs:format now.bowl)))

    =/  context  ((om json):dejs:format (~(got by payload) 'context'))
    =/  proposal-key  (so:dejs:format (~(got by context) 'proposal'))

    =/  data  ((om json):dejs:format (~(got by payload) 'data'))

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
            ['booth' s+booth-key]
            ['proposal' s+proposal-key]
          ==

          =/  error-key  (crip (weld "poll-started-error-" (trip timestamp)))

          =/  error-data=json
          %-  pairs:enjs:format
          :~
            ['key' s+error-key]
            ['error' s+(crip "cannot change proposal. poll status is {<poll-status>}.")]
          ==

          =/  error-effect=json
          %-  pairs:enjs:format
          :~
            ['resource' s+'poll']
            ['effect' s+'error']
            ['data' error-data]
          ==

          =/  effects=json
          %-  pairs:enjs:format
          :~
            ['action' s+'save-proposal-reaction']
            ['context' context]
            ['effects' [%a [error-effect]~]]
          ==

          :: give an error-effect to any subcribers
          :_  this
          :~  [%give %fact [/booths]~ %json !>(effects)]
          ==

    =|  effects=(list card)

    =/  poll-start-date  (~(get by poll) 'start')
    =/  poll-start-date  ?~(poll-start-date ~ (du:dejs:format (need poll-start-date)))

    =|  result=[effects=(list card) poll=(map @t json)]

    =/  proposal-start-date  (~(get by data) 'start')
    =.  result  ?.  ?=(~ proposal-start-date)
      :: ::  did the start date of the poll change?
      =/  proposal-start-date=@da  (du:dejs:format (need proposal-start-date))
      =.  result
            ?.  =(proposal-start-date poll-start-date)
                  %-  (log:core %info "ballot: proposal {<proposal-key>} start date changed. rescheduling...")
                  =/  effects
                    ?.  =(~ poll-start-date)
                      %-  (log:core %warn "ballot: poll-start-date {<poll-start-date>}. %rest.")
                      (snoc effects [%pass /timer/(scot %tas booth-key)/(scot %tas proposal-key)/start %arvo %b %rest `@da`poll-start-date])
                    effects
                  %-  (log:core %info "ballot: proposal-start-date {<proposal-start-date>}. %wait.")
                  =/  effects  (snoc effects [%pass /timer/(scot %tas booth-key)/(scot %tas proposal-key)/start %arvo %b %wait `@da`proposal-start-date])
                  =/  poll  (~(put by poll) 'start' (sect:enjs:format proposal-start-date))
                  [effects poll]
                %-  (log:core %info "ballot: proposal {<proposal-key>} start date unchanged. no need to reschedule.")
                [effects poll]
          [effects.result poll.result]
        %-  (log:core %info "ballot: start date not found in payload. no need to reschedule poll start.")
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
                %-  (log:core %info "ballot: proposal {<proposal-key>} end date changed. rescheduling...")
                  =/  effects
                    ?.  =(~ poll-end-date)
                      %-  (log:core %warn "ballot: poll-end-date {<poll-end-date>}. %rest.")
                      (snoc effects [%pass /timer/(scot %tas booth-key)/(scot %tas proposal-key)/end %arvo %b %rest `@da`poll-end-date])
                    effects
                  %-  (log:core %info "ballot: proposal-end-date {<proposal-end-date>}. %wait.")
                  =/  effects  (snoc effects [%pass /timer/(scot %tas booth-key)/(scot %tas proposal-key)/end %arvo %b %wait `@da`proposal-end-date])
                =/  poll  (~(put by poll) 'end' (sect:enjs:format proposal-end-date))
                [effects poll]
              %-  (log:core %info "ballot: proposal {<proposal-key>} end date unchanged. no need to reschedule.")
              [effects poll]
          [effects.result poll.result]
        %-  (log:core %info "ballot: end date not found in payload. no need to reschedule poll end.")
        [effects poll]

    =/  poll-key  (crip (weld "poll-" (trip timestamp)))
    =/  poll  (~(put by poll.result) 'key' s+poll-key)
    =/  poll  (~(put by poll) 'status' s+'scheduled')
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

    =/  proposal-key  (so:dejs:format (~(got by context) 'proposal'))
    =/  participant-key  (so:dejs:format (~(got by context) 'participant'))

    %-  (log:core %info "on-agent:handling-cast-vote => {<participant-key>} voted...")

    ::  does proposal exist?
    =/  booth-proposals  (~(get by proposals.state) booth-key)
    =/  booth-proposals  ?~(booth-proposals ~ (need booth-proposals))
    =/  proposal  (~(get by booth-proposals) proposal-key)
    ?~  proposal
          %-  (log:core %error "cast-vote error: proposal {<proposal-key>} not found")
          `this

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
      ['effect' s+'add']
      ['key' s+participant-key]
      ['data' [%o participant-vote]]
    ==

    =/  effects=json
    %-  pairs:enjs:format
    :~
      ['action' s+'cast-vote-reaction']
      ['context' [%o context]]
      ['effects' [%a [vote-effect]~]]
    ==

    ::  no changes to state. state will change when poke ack'd
    :_  this(participants (~(put by participants.state) booth-key booth-participants), votes (~(put by votes.state) booth-key booth-proposals))

    :~
      ::  for clients (e.g. UI) and "our" agent, send to generic /booths path
      [%give %fact [/booths]~ %json !>(effects)]
    ==

  ::  this one is called when our %accept poke succeeds. this is different
  ::   than the handle-accept which is called for a general booth subscription update
  ++  handle-accept-ack
    |=  [msg-id=@t payload=(map @t json)]

    =/  timestamp  (crip (en-json:html (time:enjs:format now.bowl)))

    =/  context  ((om json):dejs:format (~(got by payload) 'context'))
    =/  booth-key  (so:dejs:format (~(got by context) 'booth'))
    =/  booth  ((om json):dejs:format (~(got by booths.state) booth-key))
    =/  booth-ship  (so:dejs:format (~(got by booth) 'owner'))

    =/  participant-key  (crip "{<our.bowl>}")
    =/  participant-ship  our.bowl

    =/  booth  (~(put by booth) 'status' s+'active')

    =/  booth-participants  (~(get by participants.state) booth-key)
    =/  booth-participants  ?~(booth-participants ~ (need booth-participants))
    =/  participant  (~(get by booth-participants) participant-key)
    =/  participant  ?~(participant ~ ((om json):dejs:format (need participant)))
    =/  participant  (~(put by participant) 'status' s+'active')
    =/  booth-participants  (~(put by booth-participants) participant-key [%o participant])

    =/  booth-effect
      %-  pairs:enjs:format
      :~
        ['resource' s+'booth']
        ['effect' s+'update']
        ['key' s+booth-key]
        ['data' [%o booth]]
      ==

    =/  effect  ?:(=(our.bowl participant-ship) 'update' 'add')
    =/  participant-effect
      %-  pairs:enjs:format
      :~
        ['resource' s+'participant']
        ['effect' s+effect]
        ['key' s+participant-key]
        ['data' [%o participant]]
      ==

    =/  effect-list=(list json)  [participant-effect booth-effect ~]
    =/  effects
      %-  pairs:enjs:format
      :~
        ['action' s+'accept-reaction']
        ['context' [%o context]]
        ['effects' [%a effect-list]]
      ==

    =/  hostship=@p  `@p`(slav %p booth-ship)
    ::  send out notifications to all subscribers of this booth
    =/  wirepath=path  /booths/(scot %tas booth-key)

    ::  commit updates to store
    :_  this(mq (~(del by mq.state) msg-id), booths (~(put by booths.state) booth-key [%o booth]), participants (~(put by participants.state) booth-key booth-participants))

    :~  [%give %fact [/booths]~ %json !>(effects)]
        [%give %fact [wirepath]~ %json !>([%o payload])]
        [%pass wirepath %agent [hostship %ballot] %watch wirepath]
    ==

  ::  general broadcast to all subscribers (meaning active booth participants)
  ::    to inform that a new participant has joined the booth
  ++  handle-accept
    |=  [msg-id=@t payload=(map @t json)]

    =/  timestamp  (crip (en-json:html (time:enjs:format now.bowl)))

    =/  context  ((om json):dejs:format (~(got by payload) 'context'))
    =/  data  ((om json):dejs:format (~(got by payload) 'data'))

    =/  booth-key  (so:dejs:format (~(got by context) 'booth'))
    =/  participant-key  (so:dejs:format (~(got by data) 'key'))

    =/  booth-participants  (~(got by participants.state) booth-key)
    =/  participant  (~(get by booth-participants) participant-key)
    =/  participant  ?~(participant ~ ((om json):dejs:format (need participant)))
    =/  participant  (~(gas by participant) ~(tap by data))
    =/  booth-participants  (~(put by booth-participants) participant-key [%o participant])

    =/  participant-effect
      %-  pairs:enjs:format
      :~
        ['resource' s+'participant']
        ['effect' s+'add']
        ['key' s+participant-key]
        ['data' [%o participant]]
      ==

    =/  effect-list=(list json)  [participant-effect ~]
    =/  effects
      %-  pairs:enjs:format
      :~
        ['action' s+'accept-reaction']
        ['context' [%o context]]
        ['effects' [%a effect-list]]
      ==

    ::  commit updates to store
    :_  this(participants (~(put by participants.state) booth-key booth-participants))

    :~  [%give %fact [/booths]~ %json !>(effects)]
    ==

  ++  handle-initial
    |=  [payload=(map @t json)]

    =/  context  (~(got by payload) 'context')

    =/  data  (~(get by payload) 'data')
    ?~  data
          %-  (log:core %error "handle-initial missing data")
          `this

    =/  data=(map @t json)  ((om json):dejs:format (need data))

    =/  booth  (~(get by data) 'booth')
    =/  booth  ?~(booth ~ ((om json):dejs:format (need booth)))
    =/  proposals  (~(get by data) 'proposals')
    =/  proposals  ?~(proposals ~ ((om json):dejs:format (need proposals)))
    =/  participants  (~(get by data) 'participants')
    =/  participants  ?~(participants ~ ((om json):dejs:format (need participants)))
    =/  votes  (~(get by data) 'votes')
    =/  votes  ?~(votes ~ ((om json):dejs:format (need votes)))
    =/  polls  (~(get by data) 'polls')
    =/  polls  ?~(polls ~ ((om json):dejs:format (need polls)))
    =/  delegates  (~(get by data) 'delegates')
    =/  delegates  ?~(delegates ~ (need delegates))
    =/  delegates  ?:  ?=([%o *] delegates)  p.delegates  ~

    =/  booth-key  (so:dejs:format (~(got by booth) 'key'))

    =/  booth-proposals  (~(get by proposals.state) booth-key)
    =/  booth-proposals  ?~(booth-proposals ~ (need booth-proposals))
    =/  booth-proposals  (~(gas by booth-proposals) ~(tap by proposals))

    =/  booth-participants  (~(get by participants.state) booth-key)
    =/  booth-participants  ?~(booth-participants ~ (need booth-participants))
    =/  booth-participants  (~(gas by booth-participants) ~(tap by participants))

    =/  booth-votes  (~(get by votes.state) booth-key)
    =/  booth-votes  ?~(booth-votes ~ (need booth-votes))
    =/  booth-votes  (~(gas by booth-votes) ~(tap by votes))

    =/  booth-polls  (~(get by polls.state) booth-key)
    =/  booth-polls  ?~(booth-polls ~ (need booth-polls))
    =/  booth-polls  (~(gas by booth-polls) ~(tap by polls))

    =/  booth-delegates  (~(get by delegates.state) booth-key)
    =/  booth-delegates  ?~(booth-delegates ~ (need booth-delegates))
    =/  booth-delegates  (~(gas by booth-delegates) ~(tap by delegates))

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
      ['action' s+'initial-reaction']
      ['context' context]
      ['effects' [%a [initial-effect]~]]
    ==

    :_  this(booths (~(put by booths.state) booth-key [%o booth]), proposals (~(put by proposals.state) booth-key booth-proposals), participants (~(put by participants.state) booth-key booth-participants), votes (~(put by votes.state) booth-key booth-votes), polls (~(put by polls.state) booth-key booth-polls))

    :~
      ::  for clients (e.g. UI) and "our" agent, send to generic /booths path
      [%give %fact [/booths]~ %json !>(effects)]
    ==

  ++  handle-save-proposal
    |=  [payload=(map @t json)]

    %-  (log:core %info "ballot: handle-save-proposal {<payload>}...")

    =/  context  ((om json):dejs:format (~(got by payload) 'context'))
    =/  booth-key  (so:dejs:format (~(got by context) 'booth'))
    =/  proposal-key  (so:dejs:format (~(got by context) 'proposal'))

    =/  data  ((om json):dejs:format (~(got by payload) 'data'))

    =/  timestamp  (en-json:html (time:enjs:format now.bowl))

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
      ['action' s+'save-proposal-reaction']
      ['context' [%o context]]
      ['effects' [%a [proposal-effect]~]]
    ==

    =/  payload  (~(put by payload) 'data' [%o proposal])

    %-  (log:core %info "handle-save-proposal => committing to store...")

    ::  no changes to state. state will change when poke ack'd
    :_  this(proposals (~(put by proposals.state) booth-key booth-proposals))

    :~
      ::  for clients (e.g. UI) and "our" agent, send to generic /booths path
      [%give %fact [/booths]~ %json !>(effects)]
    ==

  ++  handle-delete-proposal
    |=  [booth-key=@t payload=(map @t json)]

    =/  context  ((om json):dejs:format (~(got by payload) 'context'))
    =/  proposal-key  (so:dejs:format (~(got by context) 'proposal'))

    =/  booth-proposals  (~(get by proposals.state) booth-key)
    =/  booth-proposals  ?~(booth-proposals ~ (need booth-proposals))
    =/  booth-proposals  (~(del by booth-proposals) proposal-key)

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
      ['action' s+'delete-proposal-reaction']
      ['context' [%o context]]
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

    =/  context  ((om json):dejs:format (~(got by payload) 'context'))
    =/  participant-key  (so:dejs:format (~(got by context) 'participant'))

    =/  our-ship  (crip "{<our.bowl>}")
    ::  if "we" (this ship) is the one being deleted, ignore this update and
    ::    let the poke we receive take care of the rest
    ?:  =(our-ship participant-key)  `this

    ::  otherwise it was some other participant and we can remove them from our store
    =/  booth-participants  (~(get by participants.state) booth-key)
    =/  booth-participants  ?~(booth-participants ~ (need booth-participants))
    =/  booth-participants  (~(del by booth-participants) participant-key)

    ::  otherwise it was some other participant and we can remove them from our store
    =/  booth-votes  (~(get by votes.state) booth-key)
    =/  booth-votes  ?~(booth-votes ~ (need booth-votes))
    =/  booth-votes  (~(del by booth-votes) participant-key)

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
      ['action' s+'delete-participant-reaction']
      ['context' [%o context]]
      ['effects' [%a [participant-effect]~]]
    ==

    :_  this(participants (~(put by participants.state) booth-key booth-participants), votes (~(put by votes.state) booth-key booth-votes))

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

  =/  context  ((om json):dejs:format (~(got by payload) 'context'))
  =/  booth-key  (so:dejs:format (~(got by context) 'booth'))
  =/  data  (~(get by payload) 'data')
  =/  data  ?~(data ~ ((om json):dejs:format (need data)))

  =/  timestamp  (en-json:html (time:enjs:format now.bowl))

  =/  is-update  (~(has by context) 'proposal')
  =/  proposal-key
        ?:  is-update
              (so:dejs:format (~(got by context) 'proposal'))
            (crip (weld "proposal-" timestamp))

  =/  booth-proposals  (~(get by proposals.state) booth-key)
  =/  booth-proposals  ?~(booth-proposals ~ (need booth-proposals))
  =/  proposal  (~(get by booth-proposals) booth-key)
  =/  proposal  ?~(proposal ~ ((om json):dejs:format (need proposal)))
  =/  proposal  (~(gas by proposal) ~(tap by data))
  =/  booth-proposals  (~(put by booth-proposals) proposal-key [%o proposal])

  ::  no changes to state. state will change when poke ack'd
  `this(proposals (~(put by proposals.state) booth-key booth-proposals))

  --

++  on-arvo
  |=  [=wire =sign-arvo]
  ^-  (quip card _this)

  %-  (log:core %warn "ballot: on-arvo called {<wire>}, {<sign-arvo>}...")

  |^

  ?+  wire  (on-arvo:def wire sign-arvo)

    [%bind-route ~]
      ?>  ?=([%eyre %bound *] sign-arvo)
      ?:  accepted.sign-arvo
        %-  (log:core %good "{<[wire sign-arvo]>}")
        `this
        %-  (log:core %error "ballot: binding route failed")
      `this

    [%timer @ @ %start ~]
      %-  (log:core %info "ballot: poll started...")
      ?.  ?=([%behn %wake *] sign-arvo)  (on-arvo:def wire sign-arvo)
      ?^  error.sign-arvo                (on-arvo:def wire sign-arvo)
      =/  segments  `(list @ta)`wire
      =/  booth-key  (snag 1 segments)
      =/  proposal-key  (snag 2 segments)
      %-  (log:core %info "ballot: on-start-poll {<booth-key>}, {<proposal-key>}...")
      (on-start-poll booth-key proposal-key)

    [%timer @ @ %end ~]
      %-  (log:core %info "ballot: poll ended.")
      ?.  ?=([%behn %wake *] sign-arvo)  (on-arvo:def wire sign-arvo)
      ?^  error.sign-arvo                (on-arvo:def wire sign-arvo)
      =/  segments  `(list @ta)`wire
      =/  booth-key  (snag 1 segments)
      =/  proposal-key  (snag 2 segments)
      %-  (log:core %info "ballot: on-end-poll {<booth-key>}, {<proposal-key>}...")
      (on-end-poll booth-key proposal-key)

  ==

  ++  on-start-poll
    |=  [booth-key=@t proposal-key=@t]
    ^-  (quip card _this)

    =/  booth-proposals  (~(get by proposals.state) booth-key)
    =/  booth-proposals  ?~(booth-proposals ~ (need booth-proposals))
    =/  proposal  (~(get by booth-proposals) proposal-key)
    =/  proposal  ?~(proposal ~ ((om json):dejs:format (need proposal)))
    =/  proposal  (~(put by proposal) 'status' s+'poll-opened')
    =/  booth-proposals  (~(put by booth-proposals) proposal-key [%o proposal])

    =/  booth-polls  (~(get by polls.state) booth-key)
    =/  booth-polls  ?~(booth-polls ~ (need booth-polls))
    =/  poll  (~(get by booth-polls) proposal-key)
    =/  poll  ?~(poll ~ ((om json):dejs:format (need poll)))

    =/  poll-key  (~(get by poll) 'key')
    =/  poll-key  ?~  poll-key
      ~&  >>>  "ballot: error. poll key not found."
      !!
      :: %-  (log:core %error "poll not found")  !!
    (so:dejs:format (need poll-key))

    =/  poll  (~(put by poll) 'status' s+'opened')
    =/  booth-polls  (~(put by booth-polls) proposal-key [%o poll])

    %-  (slog leaf+"on-start-poll called {<poll>}..." ~)

    =/  context=json
    %-  pairs:enjs:format
    :~
      ['booth' s+booth-key]
      ['proposal' s+proposal-key]
      ['poll' s+poll-key]
    ==

    =/  status-data=json
    %-  pairs:enjs:format
    :~
      ['status' s+'poll-opened']
    ==

    =/  status-effect=json
    %-  pairs:enjs:format
    :~
      ['resource' s+'proposal']
      ['key' s+proposal-key]
      ['effect' s+'update']
      ['data' status-data]
    ==

    :: =/  effect-list=(list json)  [booth-effect participant-effect ~]
    =/  effects=json
    %-  pairs:enjs:format
    :~
      ['action' s+'poll-started-reaction']
      ['context' context]
      ['effects' [%a [status-effect]~]]
    ==

    %-  (log:core %info "sending poll started effect to subcribers => {<effects>}...")

    :_  this(proposals (~(put by proposals.state) booth-key booth-proposals), polls (~(put by polls.state) booth-key booth-polls))
    :~  [%give %fact [/booths]~ %json !>(effects)]
        [%give %fact [/booths/(scot %tas booth-key)]~ %json !>(effects)]
    ==

  ++  on-end-poll
    |=  [booth-key=@t proposal-key=@t]
    ^-  (quip card _this)

    %-  (slog leaf+"on-end-poll called" ~)
    =/  booth-polls  (~(get by polls.state) booth-key)
    =/  booth-polls  ?~(booth-polls ~ (need booth-polls))
    =/  poll  (~(get by booth-polls) proposal-key)
    =/  poll  ?~(poll ~ ((om json):dejs:format (need poll)))

    =/  poll-key  (~(get by poll) 'key')
    =/  poll-key  ?~  poll-key
      ~&  >>>  "ballot: error. poll key not found"
      !!
      :: %-  (log:core %error "poll not found")  !!
    (so:dejs:format (need poll-key))

    =/  poll-results=[data=json effects=(list card)]  (tally-results booth-key proposal-key)

    =/  poll  (~(put by poll) 'status' s+'closed')
    =/  poll  (~(put by poll) 'results' data.poll-results)
    =/  booth-polls  (~(put by booth-polls) proposal-key [%o poll])

    =/  booth-proposals  (~(get by proposals.state) booth-key)
    =/  booth-proposals  ?~(booth-proposals ~ (need booth-proposals))
    =/  proposal  (~(get by booth-proposals) proposal-key)
    =/  proposal  ?~(proposal ~ ((om json):dejs:format (need proposal)))
    =/  proposal  (~(put by proposal) 'status' s+'poll-closed')
    =/  proposal  (~(put by proposal) 'tally' data.poll-results)
    =/  booth-proposals  (~(put by booth-proposals) proposal-key [%o proposal])

    %-  (log:core %info "poll results are in!!! => {<poll-results>}")

    =/  context=json
    %-  pairs:enjs:format
    :~
      ['booth' s+booth-key]
      ['proposal' s+proposal-key]
      ['poll' s+poll-key]
    ==

    =/  results-data=json
    %-  pairs:enjs:format
    :~
      ['status' s+'poll-closed']
      ['tally' data.poll-results]
    ==

    =/  results-effect=json
    %-  pairs:enjs:format
    :~
      ['resource' s+'proposal']
      ['key' s+proposal-key]
      ['effect' s+'update']
      ['data' results-data]
    ==

    =/  effects=json
    %-  pairs:enjs:format
    :~
      ['action' s+'poll-ended-reaction']
      ['context' context]
      ['effects' [%a [results-effect]~]]
    ==

    %-  (log:core %info "sending poll results to subcribers => {<effects>}...")

    =/  effects=(list card)
    :~  [%give %fact [/booths]~ %json !>(effects)]
        [%give %fact [/booths/(scot %tas booth-key)]~ %json !>([effects])]
    ==
    =/  effects  (weld effects effects.poll-results)

    :_  this(polls (~(put by polls.state) booth-key booth-polls), proposals (~(put by proposals.state) booth-key booth-proposals))
    effects

  ++  tally-results
    |=  [booth-key=@t proposal-key=@t]
    ^-  [json (list card)]

    %-  (log:core %info "tally-results called. [booth-key={<booth-key>}, proposal-key={<proposal-key>}]")

    =/  booth-proposals  (~(get by proposals.state) booth-key)
    =/  booth-proposals  ?~(booth-proposals ~ (need booth-proposals))
    =/  proposal  (~(get by booth-proposals) proposal-key)
    =/  proposal  ?~(proposal ~ ((om json):dejs:format (need proposal)))
    =/  threshold  (~(get by proposal) 'support')
    ?~  threshold
      ~&  >>>  "ballot: error. missing voter support value"
      :: %-  (log:core %error "ballot: missing voter support value")
      !!
    ::  value comes in from UI as a "whole" percentage (e.g. 50%); conver
    ::    to decimal representation (e.g. 0.5)
    =/  threshold  (div:rd (ne:dejs:format (need threshold)) (sun:rd 100))

    =/  booth-delegates  (~(get by delegates.state) booth-key)
    =/  booth-delegates  ?~(booth-delegates ~ (need booth-delegates))

    =/  booth-participants  (~(get by participants.state) booth-key)
    =/  booth-participants  ?~(booth-participants ~ (need booth-participants))

    =/  booth-proposals  (~(get by votes.state) booth-key)
    =/  booth-proposals  ?~(booth-proposals ~ (need booth-proposals))

    =/  proposal-votes  (~(get by booth-proposals) proposal-key)
    =/  proposal-votes  ?~(proposal-votes ~ ((om json):dejs:format (need proposal-votes)))

    =/  participants  ~(val by booth-participants)
    =/  participant-count  ?~(participants 0 (lent participants))

    =/  votes  `(list [@t json])`~(tap by proposal-votes)
    =/  vote-count  ?~(proposal-votes 0 (lent votes))

    =/  turnout  (div:rd (sun:rd vote-count) (sun:rd participant-count))
    %-  (log:core %info "ballot: {<turnout>}, {<threshold>}")
    =/  tallies=(map @t json)
          :: ?:  (gte turnout threshold)
          ?:  (gte:ma:rd turnout threshold)
            %-  roll
            :-  votes
            |:  [vote=`[@t json]`[%null ~] results=`(map @t json)`~]
            ::  has this voter delegated? if so skip...
            %-  (slog leaf+"{<dap.bowl>}: processing {<-.vote>}..." ~)
            =/  delegate  (~(get by booth-delegates) -.vote)
            ?.  =(~ delegate)
              %-  (slog leaf+"{<dap.bowl>}: voter {<-.vote>} delegated. skipping..." ~)
              results
            =/  num-votes
              %-  roll
              :-  ~(tap by booth-delegates)
              |=  [[voter=@t d=json] total=@ud]
                %-  (slog leaf+"{<dap.bowl>}: calc vote count {<[-.vote voter d]>}" ~)
                =/  d  ?:  ?=([%o *] d)  p.d  ~
                =/  deleg  (so:dejs:format (~(got by d) 'delegate'))
                ?:  =(-.vote deleg)  (add total 1)  total
            ::  1 + num of times delegated to
            =/  num-votes  (add 1 num-votes)
            %-  (slog leaf+"{<dap.bowl>}: {<-.vote>} choice counted {<num-votes>} times..." ~)
            (count-vote participant-count num-votes vote results)

          %-  (log:core %info "ballot: voter turnout not sufficient. not enough voter support.")
          ~

    %-  (log:core %warn "ballot: tally => {<tallies>}")

    ::  sort list by choice/vote count
    =/  tallies  ~(val by tallies)
    :: =/  tallies  ?~(tallies ~ (sort tallies get-vote-count))
    =/  tallies
          ?.  =(tallies ~)
            %-  sort
            :-  tallies
            |=  [a=json b=json]
            =/  a  ((om json):dejs:format a)
            =/  b  ((om json):dejs:format b)
            =/  val-a  (~(get by a) 'count')
            =/  val-a  ?~(val-a 0 (ni:dejs:format (need val-a)))
            =/  val-b  (~(get by b) 'count')
            =/  val-b  ?~(val-b 0 (ni:dejs:format (need val-b)))
            (gth val-a val-b)
          ~

    =/  result=[choice=(unit @t) custom-action=(unit @t) data=json reason=(unit @t)]
        ?:  ?&  !=(~ tallies)
                (gth (lent tallies) 0)
            ==
              =/  choice-1  ((om json):dejs:format (snag 0 tallies))
              =/  top-choice
                    ?:  (gth (lent tallies) 1)
                      =/  choice-2  ((om json):dejs:format (snag 1 tallies))
                      =/  val-1  (~(get by choice-1) 'count')
                      =/  val-1  ?~(val-1 0 (ni:dejs:format (need val-1)))
                      =/  val-2  (~(get by choice-2) 'count')
                      =/  val-2  ?~(val-2 0 (ni:dejs:format (need val-2)))
                      ?:  (gth val-1 val-2)
                        choice-1
                      ~
                    choice-1
              ?~  top-choice  [~ ~ ~ (some 'tied')]
              =/  label  (~(get by choice-1) 'label')
              =/  label  ?~(label '?' (so:dejs:format (need label)))
              =/  custom-action  (~(get by choice-1) 'action')
              =/  custom-action  ?~(custom-action ~ (some (so:dejs:format (need custom-action))))
              =/  data  (~(get by choice-1) 'data')
              =/  data  ?~(data ~ (need data))
              [(some label) custom-action data ~]
            [~ ~ ~ (some 'support')]

    ::  after list is sorted, top choice will be first item in list

    =/  results  ?.  =(choice.result ~)
        %-  pairs:enjs:format
        :~
          ['status' s+'counted']
          ['voteCount' (numb:enjs:format `@ud`vote-count)]
          ['participantCount' (numb:enjs:format `@ud`participant-count)]
          ['topChoice' s+(need choice.result)]
          ['tallies' ?~(tallies ~ [%a tallies])]
        ==
      %-  pairs:enjs:format
      :~
        ['status' s+'failed']
        ['reason' s+(need reason.result)]
        ['voteCount' (numb:enjs:format `@ud`vote-count)]
        ['participantCount' (numb:enjs:format `@ud`participant-count)]
      ==

    =/  custom-action-effects=(list card)  ?:  ?&  !=(custom-action.result ~)
            !=(choice.result ~)
        ==
      =/  car  (~(eca drv [bowl state]) [booth-key proposal-key] (need custom-action.result) results)
      :: =/  custom-action-result  (execute-custom-action:drv [booth-key proposal-key] (need custom-action.result) results)
      ?:(success.car effects.car ~)
    ~

    [results custom-action-effects]

  ++  count-vote
    |:  [voter-count=`@ud`1 count=`@ud`1 vote=`[@t json]`[%null ~] results=`(map @t json)`~]

    ::  no voters? move on
    ?:  =(voter-count 0)  results
    :: ::  move on if vote is null
    ?:  =(-.vote %null)  results

    =/  v  ((om json):dejs:format +.vote)
    =/  choice  ((om json):dejs:format (~(got by v) 'choice'))
    =/  label  (so:dejs:format (~(got by choice) 'label'))
    =/  action  (so:dejs:format (~(got by choice) 'action'))

    ::  label, count, percentage
    =/  result  (~(get by results) label)
    =/  result  ?~(result ~ ((om json):dejs:format (need result)))

    =/  choice-count  (~(get by result) 'count')
    =/  choice-count  ?~(choice-count 0 (ni:dejs:format (need choice-count)))
    =/  choice-count  (add choice-count count) :: plug in delegate count here

    =/  percentage  (mul:rd (div:rd (sun:rd choice-count) (sun:rd voter-count)) (sun:rd 100))
    :: =/  percentage  (div choice-count `@ud`voter-count)

    =.  result  (~(put by result) 'label' s+label)
    =.  result  (~(put by result) 'action' s+action)
    =.  result  (~(put by result) 'count' (numb:enjs:format choice-count))
    =.  result  (~(put by result) 'percentage' n+(crip "{(r-co:co (drg:rd percentage))}"))

    =.  results  (~(put by results) label [%o result])
    results
  --

  :: ?.  ?=([%bind-route ~] wire)
  ::   (on-arvo:def [wire sign-arvo])
  :: ?>  ?=([%eyre %bound *] sign-arvo)
  :: ?:  accepted.sign-arvo
  ::   %-  (log:core %good [wire sign-arvo]
  ::   `this
  ::   %-  (log:core %error "ballot: binding route failed"
  :: `this

  :: ?.  ?=([@ @ %timer ~] wire)          (on-arvo:def wire sign-arvo)
  :: ?.  ?=([%behn %wake *] sign-arvo)  (on-arvo:def wire sign-arvo)
  :: ?^  error.sign-arvo                (on-arvo:def wire sign-arvo)
  :: ::

  :: ?~  poll=(~(get by peck) (slav %uv i.wire))  `this
  :: ?+  wire  (on-arvo:def wire sign-arvo)

  ::   [@ @ %timer ~]
  ::     =/  segments  `(list @ta)`wirepath
  ::     =/  booth-key  (snag 1 segments)
  ::     =/  proposal-key  (snag 2 segments)
  ::     (on-end-poll booth-key proposal-key)

  :: ==

++  on-fail   on-fail:def
--