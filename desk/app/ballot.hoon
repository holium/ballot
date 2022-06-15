:: ***********************************************************
::
::  @author  : ~lodlev-migdev (p.james)
::  @purpose :
::    Ballot app agent for contexts, booths, proposals, and participants.
::
:: ***********************************************************
/-  *group, group-store, ballot, plugin
/+  store=group-store, default-agent, dbug, resource, pill, util=ballot-util, sig=ballot-signature, view=ballot-views, drv=ballot-driver, perm=ballot-perm
|%
+$  card  card:agent:gall
+$  versioned-state
  $%  state-0:ballot
      state-1:ballot
  ==
--
=|  state-1:ballot
=*  state  -
%-  agent:dbug
^-  agent:gall
=<
  |_  =bowl:gall
  +*  this  .
      def   ~(. (default-agent this %.n) bowl)

  ++  on-init
    ^-  (quip card _this)

    %-  (log:util %info "ballot: on-init...")

    :_  this(authentication 'enable')

        ::  initialize agent booths (ship, groups, etc...)
    :~  [%pass /ballot %agent [our.bowl %ballot] %poke %initialize !>(~)]
        ::   setup route for direct http request/response handling
        [%pass /bind-route %arvo %e %connect `/'ballot'/'api'/'booths' %ballot]
    ==
  ::
  ++  on-save
    ^-  vase
    !>(state)

  ::
  ++  on-load
    |=  old-state=vase
    ^-  (quip card _this)
    |^
    =/  old  !<(versioned-state old-state)
    ?-  -.old
      %1
        =/  new-state  (load-custom-actions old)
        =/  upgrade-effects  (get-upgrade-effects new-state)

        :_  this(state new-state)

        upgrade-effects

      %0
        =/  upgraded-state  (upgrade-0-to-1 old)
        =/  upgrade-effects  (get-upgrade-effects upgraded-state)

        :_  this(state upgraded-state)

        upgrade-effects
    ==
    ++  get-upgrade-effects
      |=  [old=state-1:ballot]
      =/  effects
        %-  ~(rep by booths.old)
          |=  [[key=@t jon=json] acc=(list card)]
            ~&  >>  "{<dap.bowl>}: processing upgrade {<key>}, {<jon>}..."
            =/  data  ?:(?=([%o *] jon) p.jon ~)
            =/  owner  (~(get by data) 'owner')
            ?~  owner
              ~&  >>  "{<dap.bowl>}: warning. booth {<key>} owner not found"
              acc
            =/  booth-ship=@p  `@p`(slav %p (so:dejs:format (need owner)))
            =/  context=json
            %-  pairs:enjs:format
            :~
              ['booth' s+key]
            ==
            =/  action=json
            %-  pairs:enjs:format
            :~
              ['action' s+'request-custom-actions']
              ['context' context]
              ['data' ~]
            ==
          (snoc acc [%pass /booths/(scot %tas key) %agent [booth-ship %ballot] %poke %json !>(action)])
      effects
    ++  load-custom-actions
      |=  [old=state-1:ballot]
      =/  custom-actions
      %-  ~(rep in booths.old)
        |=  [[key=@t jon=json] acc=(map @t json)]
          =/  booth  ?:(?=([%o *] jon) p.jon ~)
          =/  owner  (~(get by booth) 'owner')
          ?~  owner  acc
          =/  owner  (so:dejs:format (need owner))
          =/  booth-ship=@p  `@p`(slav %p owner)
          ::  if we are the owner of the booth, add our custom-actions
          ?:  =(booth-ship our.bowl)
            =/  custom-actions=(map @t json)  ~
            =/  lib-file  /(scot %p our.bowl)/(scot %tas dap.bowl)/(scot %da now.bowl)/lib/(scot %tas dap.bowl)/custom-actions/config/json
            ?.  .^(? %cu lib-file)
              ~&  >>  "{<dap.bowl>}: warning. custom actions file not found"
              acc
            =/  data  .^(json %cx lib-file)
            (~(put by acc) key data)
          acc
      =/  upgraded-booths
        %-  ~(rep in booths.old)
          |=  [[key=@t jon=json] acc=(map @t json)]
            =/  booth  ?:(?=([%o *] jon) p.jon ~)
            =/  defaults
            %-  pairs:enjs:format
            :~
              ['support' n+'50']
              ['duration' n+'7']
            ==
            =/  permissions
            :~  s+'member'
                s+'admin'
            ==
            =/  admin-permissions
            :~  s+'read-proposal'
                s+'vote-proposal'
                s+'create-proposal'
                s+'edit-proposal'
                s+'delete-proposal'
                s+'invite-member'
                s+'remove-member'
                s+'change-settings'
            ==
            =/  member-permissions
            :~  s+'read-proposal'
                s+'vote-proposal'
                s+'create-proposal'
            ==
            =/  booth  (~(put by booth) 'defaults' defaults)
            =/  booth  (~(put by booth) 'permissions' [%a permissions])
            =/  booth  (~(put by booth) 'adminPermissions' [%a admin-permissions])
            =/  booth  (~(put by booth) 'memberPermissions' [%a member-permissions])
            (~(put by acc) key [%o booth])
      [%1 authentication=authentication.old mq=mq.old polls=polls.old booths=upgraded-booths proposals=proposals.old participants=participants.old invitations=invitations.old votes=votes.old delegates=delegates.old custom-actions=custom-actions]
    ::  ensure new delegates map is set to null ~
    ::  ensure all members with pariticipant role (or no role) are given member role
    ++  upgrade-0-to-1
      |=  [old=state-0:ballot]
      ^-  state-1:ballot
      =/  upgraded-booths
        %-  ~(rep in booths.old)
          |=  [[key=@t jon=json] acc=(map @t json)]
            =/  booth  ?:(?=([%o *] jon) p.jon ~)
            =/  defaults
            %-  pairs:enjs:format
            :~
              ['support' n+'50']
              ['duration' n+'7']
            ==
            =/  admin-permissions
            :~  s+'read-proposal'
                s+'vote-proposal'
                s+'create-proposal'
                s+'edit-proposal'
                s+'delete-proposal'
                s+'invite-member'
                s+'remove-member'
                s+'change-settings'
            ==
            =/  member-permissions
            :~  s+'read-proposal'
                s+'vote-proposal'
                s+'create-proposal'
            ==
            =/  booth  (~(put by booth) 'defaults' defaults)
            =/  booth  (~(put by booth) 'adminPermissions' [%a admin-permissions])
            =/  booth  (~(put by booth) 'memberPermissions' [%a member-permissions])
            (~(put by acc) key [%o booth])
      =/  upgraded-participants
        %-  ~(rep in participants.old)
          |=  [[key=@t m=(map @t json)] acc-outer=(map @t (map @t json))]
          :: =/  members  ?:(?=([%o *] jon) p.jon ~)
          =/  result  %-  ~(rep in m)
            |=  [[key=@t jon=json] acc-inner=(map @t json)]
            =/  member  ?:(?=([%o *] jon) p.jon ~)
            =/  role  (~(get by member) 'role')
            =/  role  ?~(role 'member' (so:dejs:format (need role)))
            =/  role  ?:(=(role 'participant') 'member' role)
            =/  member  (~(put by member) 'role' s+role)
            (~(put by acc-inner) key [%o member])
          (~(put by acc-outer) key result)
      =/  custom-actions
        %-  ~(rep in booths.old)
          |=  [[key=@t jon=json] acc=(map @t json)]
            =/  booth  ?:(?=([%o *] jon) p.jon ~)
            =/  owner  (~(get by booth) 'owner')
            ?~  owner  acc
            =/  owner  (so:dejs:format (need owner))
            =/  booth-ship=@p  `@p`(slav %p owner)
            ::  if we are the owner of the booth, add our custom-actions
            ?:  =(booth-ship our.bowl)
              =/  custom-actions=(map @t json)  ~
              =/  lib-file  /(scot %p our.bowl)/(scot %tas dap.bowl)/(scot %da now.bowl)/lib/(scot %tas dap.bowl)/custom-actions/config/json
              ?.  .^(? %cu lib-file)
                ~&  >>  "{<dap.bowl>}: warning. custom actions file not found"
                acc
              =/  data  .^(json %cx lib-file)
              (~(put by acc) key data)
            acc
      [%1 authentication=authentication.old mq=mq.old polls=polls.old booths=upgraded-booths proposals=proposals.old participants=upgraded-participants invitations=invitations.old votes=votes.old delegates=~ custom-actions=custom-actions]
    --
  ::
  ++  on-poke
    |=  [=mark =vase]
    ^-  (quip card _this)
    |^

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

          =/  req-args
                (my q:(need `(unit (pair pork:eyre quay:eyre))`(rush url.request.q.req ;~(plug apat:de-purl:html yque:de-purl:html))))

            (handle-resource-action req req-args)

          [cards this]
      ==

      ++  set-authentication-mode
        |=  [mode=@t]
        %-  (log:util %info "ballot: setting authentication {<mode>}...")
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
        %-  (log:util %warn "ballot: subscribing to {<destpath>}...")
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

        %-  (log:util %warn "ballot: initializing ballot...")

        =/  owner  `@t`(scot %p our.bowl)
        =/  timestamp  (crip (en-json:html (time:enjs:format now.bowl)))

        =/  booth-key  (crip "{<our.bowl>}")
        =/  booth-name  (crip "{<our.bowl>}")
        =/  booth-slug  (spat /(scot %p our.bowl))

        =|  booths=booths:ballot

        =/  defaults
        %-  pairs:enjs:format
        :~
          ['support' n+'50']
          ['duration' n+'7']
        ==
        =/  permissions
        :~  s+'member'
            s+'admin'
        ==
        =/  admin-permissions
        :~  s+'read-proposal'
            s+'vote-proposal'
            s+'create-proposal'
            s+'edit-proposal'
            s+'delete-proposal'
            s+'invite-member'
            s+'remove-member'
            s+'change-settings'
        ==
        =/  member-permissions
        :~  s+'read-proposal'
            s+'vote-proposal'
            s+'create-proposal'
        ==

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
          ['defaults' defaults]
          ['permissions' [%a permissions]]
          ['adminPermissions' [%a admin-permissions]]
          ['memberPermissions' [%a member-permissions]]
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

        =/  custom-actions=(map @t json)  ~
        =/  lib-file  /(scot %p our.bowl)/(scot %tas dap.bowl)/(scot %da now.bowl)/lib/(scot %tas dap.bowl)/custom-actions/config/json
        =/  custom-actions  ?.  .^(? %cu lib-file)
          ~&  >>  "{<dap.bowl>}: warning. custom actions file not found"
          ~
        .^(json %cx lib-file)

        %-  (log:util %good "ballot: context initialized!")

        =/  effects  (booths-to-subscriptions booths)

        %-  (log:util %info "subscribing to /groups...")
        =/  effects  (snoc effects [%pass /group %agent [our.bowl %group-store] %watch /groups])

        :_  state(booths booths, participants (~(put by participants.state) booth-key booth-participants), custom-actions (~(put by custom-actions.state) booth-key custom-actions))

        [effects]

      ++  handle-resource-action
        |=  [req=(pair @ta inbound-request:eyre) args=(map @t @t)]
        ^-  (quip card _state)

        ::  all POST payloads are action contracts (see ARM comments)
        =/  payload  (extract-payload req)

        ?:  ?&  =(authentication.state 'enable')
                !authenticated.q.req
            ==
            %-  (log:util %error "ballot: authentication is enabled. request is not authenticated")
            (send-api-error req payload 'not authenticated')

        :: =/  req-args
              :: (my q:(need `(unit (pair pork:eyre quay:eyre))`(rush url.request.q.req ;~(plug apat:de-purl:html yque:de-purl:html))))

        %-  (log:util %info "ballot: [on-poke] => processing request at endpoint {<(stab url.request.q.req)>}")

        =/  path  (stab url.request.q.req)

        ?+    method.request.q.req  (send-api-error req payload 'unsupported')

              %'POST'
                ?+  path   (send-api-error req payload 'route not found')

                  [%ballot %api %booths ~]
                    =/  context  ((om json):dejs:format (~(got by payload) 'context'))
                    =/  action  (so:dejs:format (~(got by payload) 'action'))
                    =/  resource  (so:dejs:format (~(got by payload) 'resource'))

                    ?+  [resource action]  (send-api-error req payload 'resource/action not found')

                          [%booth %invite]
                            (invite-api req payload)

                          [%booth %accept]
                            (accept-api req payload)

                          [%booth %save-booth]
                            (save-booth-api req payload)

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

                ==

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
              (send-error contract (crip "{<dap.bowl>}: error. action attribute required. {<jon>}"))

        =/  act  (~(got by contract) 'action')

        ?+    p.+.act  (mean leaf+"{<dap.bowl>}: error. unrecognized action. {<jon>}" ~)

          %ping
            ::  this one comes in from the initial poke that sets up the channel in the UI
            `state

          %save-booth
            %-  (log:util %info "{<dap.bowl>}: save-booth received...")
            (save-booth-wire contract)

          ::  errors come via poke as reactions. successfully handled pokes are
          ::  distributed as gifts. here we simply pass the errors to the UI of the ship
          ::  where the api call (http request from UI) originated
          %save-booth-reaction
            %-  (log:util %info "ballot: %save-booth-reaction from {<src.bowl>}...")
            :_  state
            :~  [%give %fact [/booths]~ %json !>([%o contract])]
            ==

          %invite
            %-  (log:util %info "ballot: %invite action received...")
            (invite-wire contract)

          %invite-reaction
            %-  (log:util %info "ballot: %invite-reaction action received...")
            (invite-reaction-wire contract)

          %accept
            %-  (log:util %info "ballot: %accept from {<src.bowl>}...")
            (accept-wire contract)

          %save-proposal
            %-  (log:util %info "ballot: %save-proposal from {<src.bowl>}...")
            (save-proposal-wire contract)

          ::  errors come via poke as reactions. successfully handled pokes are
          ::  distributed as gifts. here we simply pass the errors to the UI of the ship
          ::  where the api call (http request from UI) originated
          %save-proposal-reaction
            %-  (log:util %info "ballot: %save-proposal-reaction from {<src.bowl>}...")
            :_  state
            :~  [%give %fact [/booths]~ %json !>([%o contract])]
            ==

          %delete-proposal
            %-  (log:util %info "ballot: %delete-proposal from {<src.bowl>}...")
            (delete-proposal-wire contract)

          ::  errors come via poke as reactions. successfully handled pokes are
          ::  distributed as gifts. here we simply pass the errors to the UI of the ship
          ::  where the api call (http request from UI) originated
          %delete-proposal-reaction
            %-  (log:util %info "ballot: %delete-proposal-reaction from {<src.bowl>}...")
            :_  state
            :~  [%give %fact [/booths]~ %json !>([%o contract])]
            ==

          %delete-participant
            %-  (log:util %info "ballot: %delete-participant from {<src.bowl>}...")
            (delete-participant-wire contract)

          %cast-vote
            %-  (log:util %info "ballot: %cast-vote from {<src.bowl>}...")
            (cast-vote-wire contract)

          %delegate
            (delegate-wire contract)

          %undelegate
            (undelegate-wire contract)

          %request-custom-actions
            (request-custom-actions-wire contract)
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

        ++  test-permission
          |=  [booth-key=@t role=@t permission=@t]
          ^-  ?

          =/  booth  (~(get by booths.state) booth-key)
          =/  booth  ?~(booth ~ (need booth))
          =/  booth  ?:(?=([%o *] booth) p.booth ~)

          =/  permission-key  (crip (weld (trip role) "Permissions"))
          ~&  >>  "{<dap.bowl>}: grabbing both permissions {<permission-key>}"

          =/  permissions  (~(get by booth) permission-key)
          =/  permissions  ?~(permissions ~ (need permissions))
          =/  permissions  ?:(?=([%a *] permissions) p.permissions ~)
          ~&  >>  "{<dap.bowl>}: permissions => {<permissions>}"

          =/  matches
          %-  skim
          :-  permissions
          |=  a=json
            =/  perm  ?:(?=([%s *] a) p.a ~)
            ~&  >>  "{<dap.bowl>}: test {<a>} = {<permission>}..."
            =(perm permission)

          ~&  >>  "{<dap.bowl>}: {<matches>}"
          (gth (lent matches) 0)

        ++  check-permission
          |=  [booth-key=@t member-key=@t permission=@t]
          ^-  [? @t]

          ~&  >>  "{<dap.bowl>}: checking permissions..."
          =/  booth-members  (~(get by participants.state) booth-key)
          =/  booth-members  ?~(booth-members ~ (need booth-members))

          =/  member  (~(get by booth-members) member-key)
          ?~  member  [%.n 'member not found']
          =/  member  ?:(?=([%o *] u.member) p.u.member ~)

          =/  role  (~(get by member) 'role')
          ?~  role  [%.n 'member role not found']
          =/  role  (so:dejs:format (need role))

          ::  owners can do anything in a booth
          ?:  =(role 'owner')  [%.y 'no error']

          ::  so if this member's role has the permission OR
          ::    the member was the proposal creator, allow the action
          =/  granted  (test-permission booth-key role permission)
          ?.  granted
              [%.n 'insufficient privileges']
          [%.y 'no error']

        ++  request-custom-actions-wire
          |=  [payload=(map @t json)]
          =/  context  (~(get by payload) 'context')
          ?~  context
            ~&  >>>  "{<dap.bowl>}: error. action on wire missing context"
            `state
          =/  context  (need context)
          =/  context  ?:(?=([%o *] context) p.context ~)
          =/  booth-key  (~(get by context) 'booth')
          ?~  booth-key
            ~&  >>>  "{<dap.bowl>}: error. booth key not found in context"
            `state
          =/  booth-key  (so:dejs:format (need booth-key))
          =/  custom-actions  (~(get by custom-actions.state) booth-key)
          ?~  custom-actions
            `state
          =/  custom-actions  (need custom-actions)

          =/  custom-action-effect=json
          %-  pairs:enjs:format
          :~
            ['resource' s+'custom-action']
            ['effect' s+'initial']
            ['key' s+booth-key]
            ['data' custom-actions]
          ==
          =/  effect-list  [custom-action-effect ~]
          =/  effects=json
          %-  pairs:enjs:format
          :~
            ['action' s+'request-custom-actions-reaction']
            ['context' [%o context]]
            ['effects' [%a effect-list]]
          ==

          :_  state

          :~
            [%give %fact [/booths]~ %json !>(effects)]
            [%give %fact [/booths/(scot %tas booth-key)]~ %json !>(effects)]
          ==

        ::  if we get this, bad news we've been kicked from the booth
        ++  delete-participant-wire
          |=  [payload=(map @t json)]

          %-  (log:util %info "ballot: delete-participant-wire received from {<src.bowl>}...")

          =/  timestamp  (en-json:html (time:enjs:format now.bowl))

          =/  context  ((om json):dejs:format (~(got by payload) 'context'))
          =/  booth-key  (so:dejs:format (~(got by context) 'booth'))
          =/  booth  (~(get by booths.state) booth-key)
          ?~  booth  !!
          =/  booth  ((om json):dejs:format (need booth))
          =/  booth-ship  `@p`(slav %p (so:dejs:format (~(got by booth) 'owner')))
          =/  participant-key  (so:dejs:format (~(got by context) 'participant'))

          ::  check the permissions of this ship..the one trying to invite
          =/  member-key  (crip "{<our.bowl>}")

          ::  is this ship allowed to remove members
          =/  tst=[success=? msg=@t]  (check-permission booth-key member-key 'remove-member')

          ?.  success.tst  (send-error payload (crip "insufficient privileges. missing remove-member permission"))

          =/  booth-participants  (~(get by participants.state) booth-key)
          =/  booth-participants  ?~(booth-participants ~ (need booth-participants))
          =/  participant  (~(get by booth-participants) participant-key)
          ?~  participant  (send-error payload (crip "participant not found"))
          =/  participant  (need participant)
          =/  participant-ship  `@p`(slav %p participant-key)

          =/  participant-effect=json
          %-  pairs:enjs:format
          :~
            ['resource' s+'participant']
            ['effect' s+'delete']
            ['key' s+participant-key]
            ['data' participant]
          ==

          =/  effect-list  [participant-effect ~]
          =/  effects=json
          %-  pairs:enjs:format
          :~
            ['action' s+'delete-participant-reaction']
            ['context' [%o context]]
            ['effects' [%a effect-list]]
          ==

          =/  remote-agent-wire=path  `path`/booths/(scot %tas booth-key)

          :_  state

          :~ ::  for remote subscribers, indicate over booth specific wire
            [%give %fact [remote-agent-wire]~ %json !>(effects)]
          ==

        ++  cast-vote-wire
          |=  [contract=(map @t json)]

          %-  (log:util %warn "{<(en-json:html [%o contract])>}")

          =/  context  ((om json):dejs:format (~(got by contract) 'context'))

          =/  booth-key  (so:dejs:format (~(got by context) 'booth'))
          =/  proposal-key  (so:dejs:format (~(got by context) 'proposal'))
          =/  participant-key  (so:dejs:format (~(got by context) 'participant'))

          =/  vote  ((om json):dejs:format (~(got by contract) 'data'))
          =/  vote  (~(put by vote) 'status' s+'recorded')

          =/  j-sig  (~(get by vote) 'sig')
          =/  j-sig  ?~(j-sig ~ ((om json):dejs:format (need j-sig)))
          =/  hash  (~(get by j-sig) 'hash')
          ?~  hash  !!  :: %-  (log:util %error "ballot: invalid vote signature. hash not found.")  !!
          =/  hash  `@ux`((se %ux):dejs:format (need hash))
          =/  voter-ship  (~(get by j-sig) 'voter')
          ?~  voter-ship  !! :: %-  (log:util %error "ballot: invalid vote signature. voter not found.")  !!
          =/  voter-ship  ((se %p):dejs:format (need voter-ship))
          =/  life  (~(get by j-sig) 'life')
          ?~  life  !! :: %-  (log:util %error "ballot: invalid vote signature. life not found.")  !!
          =/  life  (ni:dejs:format (need life))
          =/  sign=signature:ballot  [p=hash q=voter-ship r=life]
          %-  (log:util %warn "{<[sign]>}")
          %-  (log:util %info "ballot: verifying vote signature {<sign>}...")
          =/  verified  (verify:sig our.bowl now.bowl sign)
          ?~  verified  !!
                :: %-  (log:util %error "ballot: vote could not be verified")  !!
          %-  (log:util %info "ballot: signature verified")

          =/  booth-proposals  (~(get by votes.state) booth-key)
          =/  booth-proposals  ?~(booth-proposals ~ (need booth-proposals))
          =/  proposal-votes  (~(get by booth-proposals) proposal-key)
          =/  proposal-votes  ?~(proposal-votes ~ ((om json):dejs:format (need proposal-votes)))

          =/  participant-vote  (~(get by proposal-votes) participant-key)
          ?.  =(participant-vote ~)
                %-  (log:util %error "participant vote already cast")
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

          %-  (log:util %warn "cast-vote-wire: {<our.bowl>} {<src.bowl>}")

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

          %-  (log:util %warn "invite-accepted-wire: {<our.bowl>} {<src.bowl>}")

          ::  add the participant that accepted the invite/enlistment to the
          ::   payload sent out to subscribers
          =/  payload  (~(put by contract) 'data' [%o participant])

          :_  state(participants (~(put by participants.state) booth-key booth-participants))
          :~  [%give %fact [/booths]~ %json !>(effects)]
          ::  for remote subscribers, indicate over booth specific wire
              [%give %fact [/booths/(scot %tas booth-key)]~ %json !>([%o payload])]
          ==

        ++  send-error
          |=  [payload=(map @t json) msg=@t]

          ~&  >>>  msg

          =/  ctx  (~(get by payload) 'context')
          =/  ctx  ?~(ctx ~ (need ctx))
          =/  ctx  ?:(?=([%o *] ctx) p.ctx ~)

          =/  booth-key  (~(get by ctx) 'booth')
          ?~  booth-key  (mean leaf+"{<dap.bowl>}: booth key not found in context" ~)
          =/  booth-key  (so:dejs:format (need booth-key))

          =/  res  (~(get by payload) 'resource')
          =/  res  ?~(res '?' (so:dejs:format (need res)))
          =/  action  (~(get by payload) 'action')
          =/  action  ?~(action '?' (so:dejs:format (need action)))
          =/  payload  (~(put by payload) 'action' s+(crip (weld (trip action) "-reaction")))
          =/  payload  (~(put by payload) 'ack' s+'nack')

          =/  error-data=json
          %-  pairs:enjs:format
          :~
            ['error' s+msg]
          ==

          =/  error-effect=json
          %-  pairs:enjs:format
          :~
            ['resource' s+res]
            ['effect' s+'error']
            ['data' error-data]
          ==

          =/  payload  (~(put by payload) 'effects' [%a [error-effect]~])

          :_  state

          :~  [%pass /booths/(scot %tas booth-key) %agent [src.bowl %ballot] %poke %json !>([%o payload])]
          :: :~  [%give %fact [/booths]~ %json !>([%o payload])]
          ::     ::  for remote subscribers, indicate over booth specific wire
          ::     [%give %fact [/booths/(scot %tas booth-key)]~ %json !>([%o payload])]
          ==

        ++  send-api-error
          |=  [req=(pair @ta inbound-request:eyre) payload=(map @t json) msg=@t]

          ~&  >>>  msg

          :: =/  payload  ?~(payload [%o ~] payload)
          :: =/  payload  ?:(?=([%o *] payload) p.payload ~)
          =/  res  (~(get by payload) 'resource')
          =/  res  ?~(res '?' (so:dejs:format (need res)))
          =/  action  (~(get by payload) 'action')
          =/  action  ?~(action '?' (so:dejs:format (need action)))
          =/  payload  (~(put by payload) 'action' s+(crip (weld (trip action) "-reaction")))

          =/  error-data=json
          %-  pairs:enjs:format
          :~
            ['error' s+msg]
          ==

          =/  error-effect=json
          %-  pairs:enjs:format
          :~
            ['resource' s+res]
            ['effect' s+'error']
            ['data' error-data]
          ==

          =/  payload  (~(put by payload) 'effects' [%a [error-effect]~])

          =/  =response-header:http
            :-  500
            :~  ['Content-Type' 'application/json']
            ==

          ::  convert the string to a form that arvo will understand
          =/  data=octs
                (as-octs:mimes:html (crip (en-json:html [%o payload])))

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
          ?~  context  (send-api-error req payload 'missing context')
          =/  context  ((om json):dejs:format (need context))

          =/  booth-key  (~(get by context) 'booth')
          ?~  booth-key  (send-api-error req payload 'missing context key. booth key')
          =/  booth-key  (so:dejs:format (need booth-key))

          =/  booth  (~(get by booths.state) booth-key)
          =/  booth  ?~(booth ~ (need booth))
          =/  booth  ?:(?=([%o *] booth) p.booth ~)
          =/  booth-owner  (~(get by booth) 'owner')
          ?~  booth-owner  (send-api-error req payload 'booth {<booth-key>} has no owner')
          =/  booth-owner  `@p`(slav %p (so:dejs:format (need booth-owner)))

          =/  participant-key  (~(get by context) 'participant')
          ?~  participant-key  (send-api-error req payload 'missing context key. participant key')
          =/  participant-key  (so:dejs:format (need participant-key))

          %-  (log:util %warn "deleting participant {<booth-key>}, {<participant-key>}")

          ::  check the permissions of this ship..the one trying to invite
          =/  member-key  (crip "{<our.bowl>}")

          ::  is this ship allowed to remove members
          =/  tst=[success=? msg=@t]  (check-permission booth-key member-key 'remove-member')

          ?.  success.tst  (send-api-error req payload 'insufficient privileges. missing remove-member permission')

          =/  booth-participants  (~(get by participants.state) booth-key)
          =/  booth-participants  ?~(booth-participants ~ (need booth-participants))
          =/  participant  (~(get by booth-participants) participant-key)
          ?~  participant  (send-api-error req payload 'participant not found')
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
                    %-  (log:util %info "removing vote by {<participant-key>} from {<p>}...")
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
          %-  (log:util %warn "sending delete-participant to {<remote-agent-wire>}...")

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
            [%pass /booths/(scot %tas booth-key) %agent [booth-owner %ballot] %poke %json !>([%o payload])]
          ==

        ++  delete-proposal-api
          |=  [req=(pair @ta inbound-request:eyre) payload=(map @t json)]
          ^-  (quip card _state)

          :: =/  payload  ?:(=([%o *] payload) p.payload ~)

          %-  (log:util %info leaf+"{<dap.bowl>}: delete-proposal-api {<payload>}...")

          =/  context  (~(get by payload) 'context')
          ?~  context  (send-api-error req payload 'missing context')
          =/  context  (need context)
          =/  context  ?:  ?=([%o *] context)  p.context  ~

          =/  booth-key  (~(get by context) 'booth')
          ?~  booth-key  (send-api-error req payload 'missing context key. booth key')
          =/  booth-key  (so:dejs:format (need booth-key))

          =/  booth  (~(get by booths.state) booth-key)
          ?~  booth  (send-api-error req payload 'unexpected error. booth {<booth-key>} not found in store')
          =/  booth  (need booth)

          =/  booth  ?:  ?=([%o *] booth)  p.booth  ~
          =/  booth-owner  (~(get by booth) 'owner')
          ?~  booth-owner  (send-api-error req payload 'booth owner not found')
          =/  booth-owner  (need booth-owner)
          =/  booth-owner  `@p`(slav %p (so:dejs:format booth-owner))

          =/  remote-agent-wire=path  `path`/booths/(scot %tas booth-key)
          %-  (log:util %warn "sending {<booth-owner>} delete-proposal action to {<remote-agent-wire>}...")

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
            [%pass remote-agent-wire %agent [booth-owner %ballot] %poke %json !>([%o payload])]
          ==

      ++  delete-proposal-wire
          |=  [payload=(map @t json)]
          ^-  (quip card _state)

          =/  context  (~(get by payload) 'context')
          ?~  context  ~&  >>>  "missing context"  !!
          =/  context  ((om json):dejs:format (need context))

          =/  booth-key  (~(get by context) 'booth')
          ?~  booth-key  ~&  >>>  "missing context key. booth key"  !!
          =/  booth-key  (so:dejs:format (need booth-key))

          =/  proposal-key  (~(get by context) 'proposal')
          ?~  proposal-key  (send-error payload (crip "missing context key. proposal key"))
          =/  proposal-key  (so:dejs:format (need proposal-key))

          =/  booth-proposals  (~(get by proposals.state) booth-key)
          =/  booth-proposals  ?~(booth-proposals ~ (need booth-proposals))
          =/  proposal  (~(get by booth-proposals) proposal-key)
          ?~  proposal  (send-error payload (crip "proposal not found"))
          =/  proposal  ?:(?=([%o *] u.proposal) p.u.proposal ~)
          =/  proposal-owner  (~(get by proposal) 'owner')
          ?~  proposal-owner  (send-error payload (crip "proposal missing owner"))
          =/  proposal-owner  (so:dejs:format (need proposal-owner))
          =/  proposal-owner  `@p`(slav %p proposal-owner)

          =/  member-key  (crip "{<src.bowl>}")

          =/  tst=[success=? msg=@t]  (check-permission booth-key member-key 'delete-proposal')

          ::  for proposals, in addition to baseline permission check, allow
          ::   edit/delete if the member is the author (was given create-proposal permission)
          =/  tst=[success=? msg=@t]
          ?.  success.tst
            =/  proposal-owner  (~(get by proposal) 'owner')
            ?~  proposal-owner  [%.n 'proposal owner not found']
            =/  proposal-owner  (so:dejs:format (need proposal-owner))
            =/  proposal-owner  `@p`(slav %p proposal-owner)
            ?.  ?|(success.tst ?&(?!(success.tst) =(proposal-owner member-key)))
              [%.n 'insufficient privileges']
            [%.y 'no error']
          [%.y 'no error']

          ?.  success.tst  (send-error payload msg.tst)

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

          =/  reaction=json
          %-  pairs:enjs:format
          :~
            ['action' s+'delete-proposal-reaction']
            ['context' [%o context]]
            ['effects' [%a [proposal-effect]~]]
          ==

          =/  remote-agent-wire=path  `path`/booths/(scot %tas booth-key)
          %-  (log:util %warn "sending delete-proposal to {<remote-agent-wire>}...")

          ::  delete any timers that have been created to handle start/end actions
          =/  booth-polls  (~(get by polls.state) booth-key)
          =/  booth-polls  ?~(booth-polls ~ (need booth-polls))
          =/  poll  (~(get by booth-polls) proposal-key)
          =/  poll  ?~(poll ~ ((om json):dejs:format (need poll)))
          =/  booth-polls  (~(del by booth-polls) proposal-key)

          =/  effects=(list card)
          :~
            ::  for clients (e.g. UI) and "our" agent, send to generic /booths path
            [%give %fact [/booths]~ %json !>(reaction)]
            ::  for remote subscribers, indicate over booth specific wire
            [%give %fact [remote-agent-wire]~ %json !>(reaction)]
          ==

          ::  kill any timers that were set when the proposal was created
          =/  effects  ?.  =(~ poll)
            =/  poll-start-date  (~(get by poll) 'start')
            =/  poll-start-date  ?~(poll-start-date ~ (du:dejs:format (need poll-start-date)))
            =/  effects  ?.  =(~ poll-start-date)
              %-  (log:util %info leaf+"ballot: killing start timer {<poll-start-date>}...")
              (snoc effects [%pass /timer/(scot %tas booth-key)/(scot %tas proposal-key)/start %arvo %b %rest `@da`poll-start-date])
            effects
            =/  poll-end-date  (~(get by poll) 'end')
            =/  poll-end-date  ?~(poll-end-date ~ (du:dejs:format (need poll-end-date)))
            =/  effects  ?.  =(~ poll-end-date)
                %-  (log:util %info leaf+"ballot: killing end timer {<poll-end-date>}...")
                (snoc effects [%pass /timer/(scot %tas booth-key)/(scot %tas proposal-key)/end %arvo %b %rest `@da`poll-end-date])
              effects
            effects
          effects

          ::  no changes to state. state will change when poke ack'd
          :_  state(proposals (~(put by proposals.state) booth-key booth-proposals), votes (~(put by votes.state) booth-key booth-votes), polls (~(put by polls.state) booth-key booth-polls))

          effects

        ++  save-booth-api
          |=  [req=(pair @ta inbound-request:eyre) payload=(map @t json)]
          ^-  (quip card _state)

          =/  context  (~(get by payload) 'context')
          ?~  context  (send-api-error req payload 'missing context element')
          =/  context  (need context)
          =/  context  ?:(?=([%o *] context) p.context ~)

          =/  booth-key  (~(get by context) 'booth')
          ?~  booth-key  (send-api-error req payload 'context missing booth')
          =/  booth-key  (so:dejs:format (need booth-key))

          =/  booth  (~(get by booths.state) booth-key)
          ?~  booth  (send-api-error req payload 'booth not found')
          =/  booth  (need booth)
          =/  booth  ?:(?=([%o *] booth) p.booth ~)

          =/  booth-owner  (~(get by booth) 'owner')
          ?~  booth-owner  (send-api-error req payload 'booth owner not found')
          =/  booth-owner  (need booth-owner)
          =/  booth-owner  `@p`(slav %p (so:dejs:format booth-owner))

          =/  =response-header:http
            :-  200
            :~  ['Content-Type' 'application/json']
            ==

          :: =/  payload  (~(put by payload) 'data' [%o booth])

          ::  encode the proposal as a json string
          =/  body  (crip (en-json:html [%o payload]))

          ::  convert the string to a form that arvo will understand
          =/  data=octs
                (as-octs:mimes:html body)

          ::  no changes to state. state will change when poke ack'd
          :_  state

          :~
            [%give %fact [/http-response/[p.req]]~ %http-response-header !>(response-header)]
            [%give %fact [/http-response/[p.req]]~ %http-response-data !>(`data)]
            [%give %kick [/http-response/[p.req]]~ ~]
            [%pass /booths/(scot %tas booth-key) %agent [booth-owner %ballot] %poke %json !>([%o payload])]
          ==

        ++  save-booth-wire
          |=  [payload=(map @t json)]
          ^-  (quip card _state)

          %-  (log:util %warn "save-booth-wire {<payload>}...")

          =/  data  (~(get by payload) 'data')
          ?~  data  (send-error payload (crip "{<dap.bowl>}: missing data element"))
          =/  data  (need data)
          =/  data  ?:(?=([%o *] data) p.data ~)

          =/  context  (~(get by payload) 'context')
          ?~  context  (send-error payload (crip "{<dap.bowl>}: missing context element"))
          =/  context  (need context)
          =/  context  ?:(?=([%o *] context) p.context ~)

          =/  booth-key  (~(get by context) 'booth')
          ?~  booth-key  (send-error payload (crip "{<dap.bowl>}: context missing booth"))
          =/  booth-key  (so:dejs:format (need booth-key))

          =/  booth  (~(get by booths.state) booth-key)
          ?~  booth  (send-error payload (crip "{<dap.bowl>}: booth not found"))
          =/  booth  (need booth)
          =/  booth  ?:(?=([%o *] booth) p.booth ~)

          =/  member-key  (crip "{<src.bowl>}")

          ::  check if the ship requesting changes has proper privileges to perform this action
          =/  tst=[success=? msg=@t]  (check-permission booth-key member-key 'change-settings')

          ?.  success.tst  (send-error payload msg.tst)

          =/  booth  (~(gas by booth) ~(tap by data))

          =/  booth-effect=json
          %-  pairs:enjs:format
          :~
            ['resource' s+'booth']
            ['effect' s+'update']
            ['key' s+booth-key]
            ['data' [%o booth]]
          ==

          =/  effects=json
          %-  pairs:enjs:format
          :~
            ['action' s+'booth-reaction']
            ['context' [%o context]]
            ['effects' [%a [booth-effect]~]]
          ==

          :_  state(booths (~(put by booths.state) booth-key [%o booth]))

          :~
            ::  for clients (e.g. UI) and "our" agent, send to generic /booths path
            [%give %fact [/booths]~ %json !>(effects)]
            ::  for remote subscribers, indicate over booth specific wire
            [%give %fact [/booths/(scot %tas booth-key)]~ %json !>(effects)]
          ==

        ++  save-proposal-api
          |=  [req=(pair @ta inbound-request:eyre) payload=(map @t json)]
          ^-  (quip card _state)

          :: =/  payload  ?:(=([%o *] payload) p.payload ~)

          %-  (log:util %info leaf+"{<dap.bowl>}: save-proposal-api {<payload>}...")

          =/  context  (~(get by payload) 'context')
          ?~  context  (send-api-error req payload 'missing context')
          =/  context  (need context)
          =/  context  ?:  ?=([%o *] context)  p.context  ~

          =/  booth-key  (~(get by context) 'booth')
          ?~  booth-key  (send-api-error req payload 'missing context key. booth key')
          =/  booth-key  (so:dejs:format (need booth-key))

          =/  booth  (~(get by booths.state) booth-key)
          ?~  booth  (send-api-error req payload 'unexpected error. booth {<booth-key>} not found in store')
          =/  booth  (need booth)

          =/  booth  ?:  ?=([%o *] booth)  p.booth  ~
          =/  booth-owner  (~(get by booth) 'owner')
          ?~  booth-owner  (send-api-error req payload 'booth owner not found')
          =/  booth-owner  (need booth-owner)
          =/  booth-owner  `@p`(slav %p (so:dejs:format booth-owner))

          =/  remote-agent-wire=path  `path`/booths/(scot %tas booth-key)
          %-  (log:util %warn "sending {<booth-owner>} save-proposal action to {<remote-agent-wire>}...")

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
            [%pass remote-agent-wire %agent [booth-owner %ballot] %poke %json !>([%o payload])]
          ==

      ++  save-proposal-wire
          |=  [payload=(map @t json)]
          ^-  (quip card _state)

          %-  (log:util %warn "save-proposal-wire {<payload>}...")

          =/  context  (~(get by payload) 'context')
          ::  this is a massive failure. not sure how to gracefully handle if can't
          ::   give gift back to src.bowl booth
          ?~  context  ~&  >>>  "{<dap.bowl>}: missing context element"  !!
          =/  context  (need context)
          =/  context  ?:(?=([%o *] context) p.context ~)

          =/  booth-key  (~(get by context) 'booth')
          ?~  booth-key  ~&  >>>  "{<dap.bowl>}: context missing booth"  !!
          =/  booth-key  (so:dejs:format (need booth-key))

          =/  booth  (~(get by booths.state) booth-key)
          ?~  booth  (send-error payload (crip "{<dap.bowl>}: booth {<booth-key>} not found"))
          =/  booth  ((om json):dejs:format (need booth))
          =/  booth-owner  (~(get by booth) 'owner')
          ?~  booth-owner  (send-error payload (crip "{<dap.bowl>}: booth {<booth-key>} missing owner"))
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
          =/  proposal  ?~(proposal ~ ?:(?=([%o *] proposal) p.proposal ~))

          =/  member-key  (crip "{<src.bowl>}")

          ::  anyone can create a proposal; however only booth owner, admin
          ::    or proposal creator can edit
          =/  tst=[success=? msg=@t]  ?:  is-update
            =/  tst=[success=? msg=@t]  (check-permission booth-key member-key 'edit-proposal')
            =/  proposal-owner  (~(get by proposal) 'owner')
            ?~  proposal-owner  [%.n 'proposal owner not found']
            =/  proposal-owner  (so:dejs:format (need proposal-owner))
            =/  proposal-owner  `@p`(slav %p proposal-owner)
            ::  for proposals, in addition to baseline permission check, allow
            ::   edit/delete if the member is the author (was given create-proposal permission)
            ?.  ?|(success.tst ?&(?!(success.tst) =(proposal-owner member-key)))
              [%.n 'insufficient privileges']
            [%.y 'no error']
          (check-permission booth-key member-key 'create-proposal')

          ?.  success.tst  (send-error payload msg.tst)

          =/  threshold  (~(get by data) 'support')
          ?~  threshold  (send-error payload (crip "{<dap.bowl>}: missing voter support value"))
          =/  threshold  (ne:dejs:format (need threshold))
          %-  (log:util %info "{<dap.bowl>}: {<threshold>}")
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

          =/  remote-agent-wire=path  `path`/booths/(scot %tas booth-key)
          %-  (log:util %warn "sending proposal update to {<remote-agent-wire>}...")

          :_  state(proposals (~(put by proposals.state) booth-key booth-proposals))

              ::  for clients (e.g. UI) and "our" agent, send to generic /booths path
          :~  [%give %fact [/booths]~ %json !>(effects)]
              ::  for remote subscribers, indicate over booth specific wire
              [%give %fact [remote-agent-wire]~ %json !>(effects)]
          ==

        ++  accept-api
          |=  [req=(pair @ta inbound-request:eyre) payload=(map @t json)]
          ^-  (quip card _state)

          =/  timestamp  (en-json:html (time:enjs:format now.bowl))

          =/  context  (~(get by payload) 'context')
          ?~  context  (send-api-error req payload 'missing context')
          =/  context  ((om json):dejs:format (need context))

          =/  booth-key  (~(get by context) 'booth')
          ?~  booth-key  (send-api-error req payload 'missing booth key')
          =/  booth-key  (so:dejs:format (need booth-key))

          =/  booth  (~(get by booths.state) booth-key)
          ?~  booth  (send-api-error req payload 'booth not found in store')

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
                      ['role' s+'member']
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

          %-  (log:util %warn "accept-api: {<our.bowl>} poking {<hostship>}, {<msg-id>}...")

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
          ?~  context  (send-api-error req payload 'missing context')
          =/  context  ((om json):dejs:format (need context))
          =/  booth-key  (so:dejs:format (~(got by context) 'booth'))
          =/  proposal-key  (so:dejs:format (~(got by context) 'proposal'))

          =/  booth  (~(get by booths.state) booth-key)
          ?~  booth  (send-api-error req payload 'booth not found in store')

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
            (send-api-error req payload 'participant delegated vote')

          =/  participant-vote  (~(get by proposal-votes) participant-key)
          ?.  =(participant-vote ~)
                (send-api-error req payload 'participant vote already cast')

          =/  payload-data  (~(get by payload) 'data')
          ?~  payload-data
                (send-api-error req payload 'missing data')

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
          %-  (log:util %info "ballot: signing vote payload...")
          =/  signature  (sign:sig our.bowl now.bowl [%o payload-data])
          %-  (log:util %warn "{<[signature]>}")
          %-  (log:util %info "ballot: {<signature>}")

          =/  j-sig=json
          %-  pairs:enjs:format
          :~
            ['hash' s+`@t`(scot %ux p.signature)]
            ['voter' s+(crip "{<q.signature>}")]
            ['life' (numb:enjs:format r.signature)]
          ==

          =/  payload-data  (~(put by payload-data) 'sig' j-sig)

          ::  get the list of participants that have delegated to this voter
          =/  delegators=(map @t json)
          %-  ~(rep by booth-delegates)
          |=  [[key=@t jon=json] acc=(map @t json)]
            =/  voter  ?:(?=([%o *] jon) p.jon ~)
            =/  delg  (~(get by voter) 'delegate')
            ?~  delg  acc
            =/  delg  (so:dejs:format (need delg))
            ?:  =(delg participant-key)
              (~(put by acc) key [%o voter])
            acc

          %-  (log:util %info "{<dap.bowl>}: voter delegators {<delegators>}")
          =/  payload-data
          ?.  =(~ delegators)
            (~(put by payload-data) 'delegators' [%o delegators])
          payload-data

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
          %-  (log:util %info "sending cast-vote updates on {<sub-wire>}...")

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
                %-  (log:util %info "poking remote ship on wire `path`/booths/{<(scot %tas booth-key)>}...")
                (snoc effects [%pass /booths/(scot %tas booth-key) %agent [hostship %ballot] %poke %json !>(wire-payload)])
              effects

          ::  no changes to state. state will change when poke ack'd
          :_  state(votes (~(put by votes.state) booth-key booth-votes))

          [effects]

        ++  invite-api
          |=  [req=(pair @ta inbound-request:eyre) payload=(map @t json)]
          ^-  (quip card _state)

          %-  (log:util %info "{<dap.bowl>}: invite-api called. {<payload>}...")

          =/  context  (~(get by payload) 'context')
          =/  context  ?~(context ~ (need context))
          =/  context  ?:(?=([%o *] context) p.context ~)

          =/  booth-key  (~(get by context) 'booth')
          ?~  booth-key  (send-api-error req payload 'bad context. booth missing.')
          =/  booth-key  (so:dejs:format (need booth-key))

          =/  participant-key  (~(get by context) 'participant')
          ?~  participant-key  (send-api-error req payload 'bad context. participant missing.')
          =/  participant-key  (so:dejs:format (need participant-key))
          =/  invitee  `@p`(slav %p participant-key)

          ::  check the permissions of this ship..the one trying to invite
          =/  member-key  (crip "{<our.bowl>}")

          ::  are we even a member of this booth?
          =/  booth-participants  (~(get by participants.state) booth-key)
          =/  booth-participants  ?~(booth-participants ~ (need booth-participants))
          :: =/  booth-participants  ?:(?=([%o *] booth-participants) p.booth-participants ~)
          ?.  (~(has by booth-participants) member-key)
            (send-api-error req payload (crip "error. {<member-key>} is not a member of {<booth-key>}"))

          ::  is this ship allowed to invite members
          =/  tst=[success=? msg=@t]  (check-permission booth-key member-key 'invite-member')

          ?.  success.tst  (send-api-error req payload 'insufficient privileges. missing invite-member permission')

          =/  participant  (~(get by booth-participants) participant-key)

          =/  participant
                ?~  participant
                  ~
                ((om json):dejs:format (need participant))

          ::  update participant record to indicated invited
          =/  participant-data=json
          %-  pairs:enjs:format
          :~
            ['key' s+participant-key]
            ['name' s+participant-key]
            ['status' s+'pending']
            ['role' s+'member']
            ['created' (time:enjs:format now.bowl)]
          ==
          ::  convert to (map @t json)
          =/  participant-data  ?:(?=([%o *] participant-data) p.participant-data ~)

          ::  apply updates to participant by overlaying updates map
          =/  participant  (~(gas by participant) ~(tap by participant-data))

          ::  save the updated partcipant to the participants map
          =/  booth-participants  (~(put by booth-participants) participant-key [%o participant])

          ::  stuff the booth information into the payload. the invitee will need this to
          ::  add the booth to its local store
          =/  booth  (~(get by booths.state) booth-key)
          =/  booth  ?~(booth ~ (need booth))

          =/  payload-data=json
          %-  pairs:enjs:format
          :~
            ['booth' booth]
            ['participant' [%o participant]]
          ==

          =/  invitee-payload  (~(put by payload) 'data' payload-data)

          ::  create the response
          =/  =response-header:http
            :-  200
            :~  ['Content-Type' 'application/json']
            ==

          ::  encode the proposal as a json string
          =/  body  (crip (en-json:html [%o (~(put by payload) 'data' [%o participant])]))

          ::  convert the string to a form that arvo will understand
          =/  data=octs
                (as-octs:mimes:html body)

          ::  commit the changes to the store
          %-  (log:util %info "{<dap.bowl>}: invite-api - sending {<invitee>} {<[%o invitee-payload]>}...")

          :_  state(participants (~(put by participants.state) booth-key booth-participants))

          :~
            [%give %fact [/http-response/[p.req]]~ %http-response-header !>(response-header)]
            [%give %fact [/http-response/[p.req]]~ %http-response-data !>(`data)]
            [%give %kick [/http-response/[p.req]]~ ~]
            [%pass /booths/(scot %tas booth-key) %agent [invitee %ballot] %poke %json !>([%o invitee-payload])]
          ==

        ++  invite-wire
          |=  [payload=(map @t json)]

          %-  (log:util %info "{<dap.bowl>}: invite-wire called. {<payload>}...")

          =/  timestamp  (en-json:html (time:enjs:format now.bowl))

          =/  context  ((om json):dejs:format (~(got by payload) 'context'))
          =/  booth-key  (so:dejs:format (~(got by context) 'booth'))

          =/  participant-key  (crip "{<our.bowl>}")

          =/  data  (~(get by payload) 'data')
          =/  data  ?~(data ~ (need data))
          =/  data  ?:(?=([%o *] data) p.data ~)

          =/  booth  (~(get by data) 'booth')
          =/  booth  ?~(booth ~ (need booth))
          =/  booth  ?:(?=([%o *] booth) p.booth ~)

          =/  participant-data  (~(get by data) 'participant')
          =/  participant-data  ?~(participant-data ~ (need participant-data))
          =/  participant-data  ?:(?=([%o *] participant-data) p.participant-data ~)

          =/  booth-owner  (~(get by booth) 'owner')
          ?~  booth-owner  (send-error payload 'booth data missing owner')
          =/  booth-owner  (so:dejs:format (need booth-owner))
          =/  booth-owner  `@p`(slav %p booth-owner)

          ::  update booth status because on receiving ship (this ship), the booth
          ::    is being added; therefore status is 'invited'
          =/  booth  (~(put by booth) 'status' s+'invited')

          =/  booth-participants  (~(get by participants.state) booth-key)
          =/  booth-participants  ?~(booth-participants ~ (need booth-participants))

          =/  participant  (~(get by booth-participants) participant-key)
          =/  participant  ?~(participant ~ (need participant))
          =/  participant  ?:(?=([%o *] participant) p.participant ~)

          =/  participant  (~(gas by participant) ~(tap by participant-data))
          =/  participant  (~(put by participant) 'status' s+'invited')

          =/  booth-effect=json
          %-  pairs:enjs:format
          :~
            ['resource' s+'booth']
            ['effect' s+'add']
            ['key' s+booth-key]
            ['data' [%o booth]]
          ==

          =/  participant-effect=json
          %-  pairs:enjs:format
          :~
            ['resource' s+'participant']
            ['effect' s+'add']
            ['key' s+participant-key]
            ['data' [%o participant]]
          ==

          =/  effects=json
          %-  pairs:enjs:format
          :~
            ['action' s+'invite-reaction']
            ['context' [%o context]]
            ['effects' [%a :~(booth-effect participant-effect)]]
          ==

          %-  (log:util %warn "invite-wire: sending {<booth-owner>} effects {<effects>}...")

          :_  state(booths (~(put by booths.state) booth-key [%o booth]), participants (~(put by participants.state) booth-key booth-participants))

          :~  [%give %fact [/booths]~ %json !>(effects)]
              [%pass /booths/(scot %tas booth-key) %agent [booth-owner %ballot] %poke %json !>(effects)]
          ==

        ::
        ++  invite-reaction-wire
          |=  [payload=(map @t json)]
          ^-  (quip card _state)

          %-  (log:util %info leaf+"{<dap.bowl>}: invite-reaction-wire {<payload>}...")

          =/  context  (~(get by payload) 'context')
          =/  context  ?~(context ~ (need context))
          =/  context  ?:(?=([%o *] context) p.context ~)

          =/  booth-key  (~(get by context) 'booth')
          ?~  booth-key  (send-error payload 'bad context. booth missing')
          =/  booth-key  (so:dejs:format (need booth-key))

          =/  participant-key  (~(get by context) 'participant')
          ?~  participant-key  (send-error payload 'bad context. participant missing.')
          =/  participant-key  (so:dejs:format (need participant-key))

          =/  effects  (~(get by payload) 'effects')
          =/  effects  ?~(effects ~ (need effects))
          =/  effects  ?:(?=([%a *] effects) p.effects ~)

          ::  extract the participant effect. the booth effect goes out to UI and agents,
          ::  but agents should ignore the booth effect
          =/  effects
          %-  skim
          :-  effects
            |=  [effect=json]
            =/  jon  ?:(?=([%o *] effect) p.effect ~)
            =/  res  (~(get by jon) 'resource')
            ?~  res  %.n
            =/  res  (so:dejs:format (need res))
            ?:  =(res 'participant')  %.y  %.n

          =/  effect  (snag 0 effects)
          =/  effect  ?:(?=([%o *] effect) p.effect ~)
          =/  participant-data  (~(get by effect) 'data')
          =/  participant-data  ?~(participant-data ~ (need participant-data))
          =/  participant-data  ?:(?=([%o *] participant-data) p.participant-data ~)

          =/  booth-participants  (~(get by participants.state) booth-key)
          =/  booth-participants  ?~(booth-participants ~ (need booth-participants))
          :: =/  booth-participants  ?:(?=([%o *] booth-participants) p.booth-participants ~)

          =/  participant  (~(get by booth-participants) participant-key)
          =/  participant  ?~(participant ~ (need participant))
          =/  participant  ?:(?=([%o *] participant) p.participant ~)

          =/  participant  (~(gas by participant) ~(tap by participant-data))

          =/  booth-participants  (~(put by booth-participants) participant-key [%o participant])

          %-  (log:util %warn "invite-reaction-wire: giving effects {<[%o payload]>}...")

          =/  payload  (~(put by payload) 'effects' [%a effects])

          :_  state(participants (~(put by participants.state) booth-key booth-participants))

          :~  ::  send effects to UI
              [%give %fact [/booths]~ %json !>([%o payload])]
              ::  send effects to all booth subscribers
              [%give %fact [/booths/(scot %tas booth-key)]~ %json !>([%o payload])]
          ==


        ++  delegate-api
          |=  [req=(pair @ta inbound-request:eyre) payload=(map @t json)]
          ^-  (quip card _state)

          :: =/  payload  ?:(=([%o *] payload) p.payload ~)

          %-  (log:util %info leaf+"{<dap.bowl>}: delegate-api {<payload>}...")

          =/  context  (~(get by payload) 'context')
          ?~  context  (send-api-error req payload 'missing context')
          =/  context  (need context)
          =/  context  ?:  ?=([%o *] context)  p.context  ~

          =/  booth-key  (~(get by context) 'booth')
          ?~  booth-key  (send-api-error req payload 'missing context key. booth key')
          =/  booth-key  (so:dejs:format (need booth-key))

          =/  booth  (~(get by booths.state) booth-key)
          ?~  booth  (send-api-error req payload 'unexpected error. booth {<booth-key>} not found in store')
          =/  booth  (need booth)

          =/  booth  ?:  ?=([%o *] booth)  p.booth  ~
          =/  booth-owner  (~(get by booth) 'owner')
          ?~  booth-owner  (send-api-error req payload 'booth owner not found')
          =/  booth-owner  (need booth-owner)
          =/  booth-owner  `@p`(slav %p (so:dejs:format booth-owner))

          =/  data  (~(get by payload) 'data')
          ?~  data  (send-api-error req payload 'payload data not found')
          =/  data  ?:(?=([%o *] u.data) p.u.data ~)
          =/  delegate  (~(get by data) 'delegate')
          ?~  delegate  (send-api-error req payload 'delegate element not found')
          =/  delegate  (so:dejs:format (need delegate))

          =/  delegate-ship  `@p`(slav %p delegate)
          ?:  =(delegate-ship our.bowl)  (send-api-error req payload 'cannot delegate to yourself')

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
          %-  (log:util %warn "sending {<booth-owner>} delegate to {<remote-agent-wire>}...")

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

          %-  (log:util %info leaf+"{<dap.bowl>}: delegate-wire {<payload>}...")
          :: =/  payload  ?:(=([%o *] payload) p.payload ~)

          =/  context  (~(get by payload) 'context')
          ?~  context  (mean leaf+"{<dap.bowl>}: delegate wire error. payload missing context" ~)
          =/  context  (need context)
          =/  context  ?:  ?=([%o *] context)  p.context  ~

          =/  booth-key  (~(get by context) 'booth')
          ?~  booth-key  (mean leaf+"{<dap.bowl>}: delegate wire error. context missing booth" ~)
          =/  booth-key  (so:dejs:format (need booth-key))

          =/  booth  (~(get by booths.state) booth-key)
          ?~  booth  (mean leaf+"{<dap.bowl>}: delegate wire error. {<booth-key>} not found in booth store" ~)
          =/  booth  (need booth)

          =/  booth  ?:  ?=([%o *] booth)  p.booth  ~
          =/  booth-owner  (~(get by booth) 'owner')
          ?~  booth-owner  (mean leaf+"{<dap.bowl>}: delegate wire error. {<booth-key>} missing owner" ~)
          =/  booth-owner  (need booth-owner)
          =/  booth-owner  `@p`(slav %p (so:dejs:format booth-owner))

          =/  data  (~(get by payload) 'data')
          ?~  data  (mean leaf+"{<dap.bowl>}: delegate wire error. payload missing data" ~)
          =/  data  (need data)
          =/  data  ?:  ?=([%o *] data)  p.data  ~

          =/  delegate-key  (~(get by data) 'delegate')
          ?~  delegate-key  (mean leaf+"{<dap.bowl>}: delegate wire error. payload data missing delegate" ~)
          =/  delegate-key  (so:dejs:format (need delegate-key))

          ::  is the delegate actually a member of the group?
          =/  booth-members  (~(get by participants.state) booth-key)
          ?~  booth-members  (mean leaf+"{<dap.bowl>}: delegate wire error. booth member store not found" ~)
          =/  booth-members  (need booth-members)
          =/  member  (~(get by booth-members) delegate-key)
          ?~  member  (mean leaf+"{<dap.bowl>}: delegate wire error. {<delegate-key>} is not a booth participant" ~)

          =/  sgn  (~(get by data) 'sig')
          ?~  sgn  (mean leaf+"{<dap.bowl>}: delegate wire error. payload data missing sig" ~)
          =/  sgn  (need sgn)

          =/  verified  (ver:sig bowl sgn ~)
          ?~  verified  (mean leaf+"{<dap.bowl>}: delegate wire error. unable to validate signature" ~)

          =/  participant-key  (crip "{<src.bowl>}")
          =/  booth-participants  (~(get by delegates.state) booth-key)
          =/  booth-participants  ?~(booth-participants ~ (need booth-participants))
          =/  participant  (~(get by booth-participants) participant-key)
          ?.  =(~ participant)  (mean leaf+"{<dap.bowl>}: delegate wire error. {<participant-key>} already delegated vote" ~)

          ::  check to see if the one attempting to delegate is themselves a delegate. do not allow this.
          =/  values  ~(val by booth-participants)
          =/  matches
            %-  skim
            :-  values
              |=  [a=json]
              =/  data  ?:(?=([%o *] a) p.a ~)
              =/  delegate  (~(get by data) 'delegate')
              ?~  delegate  %.n
              ?:  =(participant-key (so:dejs:format (need delegate)))
                %.y
              %.n
          ::  is the member attempting to delegate already a delegate?
          ?:  (gth 0 (lent matches))
            (mean leaf+"{<dap.bowl>}: delegate wire error. {<participant-key>} is a delegate and therefore cannot delegate" ~)

          =/  context  (~(put by context) 'participant' s+participant-key)

          =/  booth-votes  (~(get by votes.state) booth-key)
          =/  booth-votes  ?~(booth-votes ~ (need booth-votes))
          =/  participant  (~(get by booth-votes) participant-key)
          ?.  =(~ participant)  (mean leaf+"{<dap.bowl>}: delegate wire error. {<participant-key>} already voted" ~)

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
          %-  (log:util %info leaf+"sending {<booth-owner>} delegate to {<remote-agent-wire>}...")

          :_  state(delegates (~(put by delegates.state) booth-key booth-participants))

          :~
            [%give %fact [/booths]~ %json !>(effects)]
            [%give %fact [remote-agent-wire]~ %json !>(effects)]
          ==

        ++  undelegate-api
          |=  [req=(pair @ta inbound-request:eyre) payload=(map @t json)]
          ^-  (quip card _state)

          :: =/  payload  ?:(=([%o *] payload) p.payload ~)

          %-  (log:util %info leaf+"{<dap.bowl>}: undelegate-api {<payload>}...")

          =/  context  (~(get by payload) 'context')
          ?~  context  (send-api-error req payload 'missing context')
          =/  context  (need context)
          =/  context  ?:  ?=([%o *] context)  p.context  ~

          =/  booth-key  (~(get by context) 'booth')
          ?~  booth-key  (send-api-error req payload 'missing context key. booth key')
          =/  booth-key  (so:dejs:format (need booth-key))

          =/  booth  (~(get by booths.state) booth-key)
          ?~  booth  (send-api-error req payload 'unexpected error. booth {<booth-key>} not found in store')
          =/  booth  (need booth)

          =/  booth  ?:(?=([%o *] booth) p.booth ~)
          =/  booth-owner  (~(get by booth) 'owner')
          ?~  booth-owner  (send-api-error req payload 'booth owner not found')
          =/  booth-owner  (need booth-owner)
          =/  booth-owner  `@p`(slav %p (so:dejs:format booth-owner))

          =/  data  (~(get by payload) 'data')
          ?~  data  (send-api-error req payload 'payload data not found')
          =/  data  ?:(?=([%o *] u.data) p.u.data ~)
          =/  delegate  (~(get by data) 'delegate')
          ?~  delegate  (send-api-error req payload 'delegate element not found')
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
          %-  (log:util %warn "sending {<booth-owner>} delegate to {<remote-agent-wire>}...")

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

          %-  (log:util %info leaf+"{<dap.bowl>}: delegate-wire {<payload>}...")
          :: =/  payload  ?:(=([%o *] payload) p.payload ~)

          =/  context  (~(get by payload) 'context')
          ?~  context  (mean leaf+"{<dap.bowl>}: delegate wire error. payload missing context" ~)
          =/  context  (need context)
          =/  context  ?:  ?=([%o *] context)  p.context  ~

          =/  booth-key  (~(get by context) 'booth')
          ?~  booth-key  (mean leaf+"{<dap.bowl>}: delegate wire error. context missing booth" ~)
          =/  booth-key  (so:dejs:format (need booth-key))

          =/  booth  (~(get by booths.state) booth-key)
          ?~  booth  (mean leaf+"{<dap.bowl>}: delegate wire error. {<booth-key>} not found in booth store" ~)
          =/  booth  (need booth)

          =/  booth  ?:  ?=([%o *] booth)  p.booth  ~
          =/  booth-owner  (~(get by booth) 'owner')
          ?~  booth-owner  (mean leaf+"{<dap.bowl>}: delegate wire error. {<booth-key>} missing owner" ~)
          =/  booth-owner  (need booth-owner)
          =/  booth-owner  `@p`(slav %p (so:dejs:format booth-owner))

          =/  data  (~(get by payload) 'data')
          ?~  data  (mean leaf+"{<dap.bowl>}: delegate wire error. payload missing data" ~)
          =/  data  (need data)
          =/  data  ?:  ?=([%o *] data)  p.data  ~

          =/  delegate-key  (~(get by data) 'delegate')
          ?~  delegate-key  (mean leaf+"{<dap.bowl>}: delegate wire error. payload data missing delegate" ~)
          =/  delegate-key  (so:dejs:format (need delegate-key))

          ::  is the delegate actually a member of the group?
          =/  booth-members  (~(get by participants.state) booth-key)
          ?~  booth-members  (mean leaf+"{<dap.bowl>}: delegate wire error. booth member store not found" ~)
          =/  booth-members  (need booth-members)
          =/  member  (~(get by booth-members) delegate-key)
          ?~  member  (mean leaf+"{<dap.bowl>}: delegate wire error. {<delegate-key>} is not a booth participant" ~)

          =/  sgn  (~(get by data) 'sig')
          ?~  sgn  (mean leaf+"{<dap.bowl>}: delegate wire error. payload data missing sig" ~)
          =/  sgn  (need sgn)

          =/  verified  (ver:sig bowl sgn ~)
          ?~  verified  (mean leaf+"{<dap.bowl>}: delegate wire error. unable to validate signature" ~)

          =/  participant-key  (crip "{<src.bowl>}")
          =/  booth-participants  (~(get by delegates.state) booth-key)
          =/  booth-participants  ?~(booth-participants ~ (need booth-participants))
          =/  participant  (~(get by booth-participants) participant-key)
          ?:  =(~ participant)  (mean leaf+"{<dap.bowl>}: delegate wire error. {<participant-key>} has not delegated" ~)

          =/  context  (~(put by context) 'participant' s+participant-key)

          =/  booth-votes  (~(get by votes.state) booth-key)
          =/  booth-votes  ?~(booth-votes ~ (need booth-votes))
          =/  participant  (~(get by booth-votes) participant-key)
          ?.  =(~ participant)  (mean leaf+"{<dap.bowl>}: delegate wire error. {<participant-key>} already voted" ~)

          =/  booth-participants  (~(del by booth-participants) participant-key)
          =/  participant-effect=json
          %-  pairs:enjs:format
          :~
            ['resource' s+'delegate']
            ['effect' s+'delete']
            ['key' s+participant-key]
            ['data' ~]
          ==

          =/  effects=json
          %-  pairs:enjs:format
          :~
            ['action' s+'delegate-reaction']
            ['context' [%o context]]
            ['effects' [%a [participant-effect]~]]
          ==

          =/  remote-agent-wire=path  `path`/booths/(scot %tas booth-key)
          %-  (log:util %info leaf+"sending {<booth-owner>} undelegate to {<remote-agent-wire>}...")

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
          :: %-  (log:util %good "ballot: client subscribed to {(spud path)}.")
          `this

        [%booths ~]
          ?:  =(our.bowl src.bowl)
            :: %-  (log:util %warn "remote ships not allowed to watch /booths")
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
          :: %-  (log:util %good "ballot: client subscribed to {(spud path)}.")
          =/  booth-key  (spud (oust [0 1] `(list @ta)`path))
          =/  booth-key  (crip `tape`(oust [0 1] `(list @)`booth-key))
          %-  (log:util %info "ballot: extracted booth key => {<booth-key>}...")

          =/  booth  (~(get by booths.state) booth-key)
          =/  booth  ?~(booth ~ (need booth))

          =/  booth-participants  (~(get by participants.state) booth-key)
          =/  booth-participants  ?~(booth-participants ~ (need booth-participants))
          =/  participant  (~(get by booth-participants) (crip "{<src.bowl>}"))
          ?~  participant  (mean leaf+"subscription request rejected. {<src.bowl>} not a participant of the booth." ~)

          =/  booth-proposals  (~(get by proposals.state) booth-key)
          =/  booth-proposals  ?~(booth-proposals ~ (need booth-proposals))
          =/  booth-votes  (~(get by votes.state) booth-key)
          =/  booth-votes  ?~(booth-votes ~ (need booth-votes))

          ::  only booth owner should be concerned with polls
          :: =/  booth-polls  (~(get by polls.state) booth-key)
          :: =/  booth-polls  ?~(booth-polls ~ (need booth-polls))

          =/  booth-delegates  (~(get by delegates.state) booth-key)
          =/  booth-delegates  ?~(booth-delegates ~ (need booth-delegates))

          =/  lib-file  /(scot %p our.bowl)/(scot %tas dap.bowl)/(scot %da now.bowl)/lib/(scot %tas dap.bowl)/custom-actions/config/json
          =/  booth-custom-actions  .^(json %cx lib-file)

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
              :: ['polls' [%o booth-polls]]
              ['delegates' [%o booth-delegates]]
              ['custom-actions' booth-custom-actions]
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
          %-  (log:util %good "ballot: client subscribed to {(spud path)}.")
          `this

        ::  ~lodlev-migdev - print message when eyre subscribes to our http-response path
        ::  TODO: Do not allow anything other than Eyre to suscribe to this path.
        [%http-response *]
          %-  (log:util %good "ballot: client subscribed to {(spud path)}.")
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

    :: %-  (log:util %info "ballot: scry called with {<path>}...")

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
          %-  (log:util %warn leaf+"ballot: extracting proposals for booth {<key>}...")
          =/  member-key  (crip "{<our.bowl>}")
          =/  tst  (~(chk perm [bowl booths.state participants.state]) key member-key 'read-proposal')
          ?.  -.tst
              =/  context
              %-  pairs:enjs:format
              :~
                ['booth' s+key]
              ==
              =/  error-data
              %-  pairs:enjs:format
              :~
                ['error' s+'insufficient privileges. member role does not have read-proposal permission']
              ==
              =/  error-effect
              %-  pairs:enjs:format
              :~
                ['resource' s+'proposal']
                ['effect' s+'error']
                ['data' error-data]
              ==
              =/  response
              %-  pairs:enjs:format
              :~
                ['action' s+'read-proposal-reaction']
                ['context' context]
                ['effects' [%a :~(error-effect)]]
              ==
              ``json+!>(response)
          =/  booth-proposals  (~(get by proposals.state) key)
          ?~  booth-proposals  ``json+!>(~)
          ``json+!>([%o (need booth-proposals)])

        [%x %booths @ @ @ %proposals ~]
          =/  segments  `(list @ta)`path
          =/  key  (crip (oust [0 1] (spud /(snag 2 segments)/(snag 3 segments)/(snag 4 segments))))
          ::=/  key  (crip (oust [0 1] (spud /(snag 2 `(list @)`path)/(snag 3 `(list @)`path)/(snag 4 `(list @)`path))))
          %-  (log:util %warn "ballot: extracting proposals for booth {<key>}...")
          =/  member-key  (crip "{<our.bowl>}")
          =/  tst  (~(chk perm [bowl booths.state participants.state]) key member-key 'read-proposal')
          ?.  -.tst
              =/  context
              %-  pairs:enjs:format
              :~
                ['booth' s+key]
              ==
              =/  error-data
              %-  pairs:enjs:format
              :~
                ['error' s+'insufficient privileges. member role does not have read-proposal permission']
              ==
              =/  error-effect
              %-  pairs:enjs:format
              :~
                ['resource' s+'proposal']
                ['effect' s+'error']
                ['data' error-data]
              ==
              =/  response
              %-  pairs:enjs:format
              :~
                ['action' s+'read-proposal-reaction']
                ['context' context]
                ['effects' [%a :~(error-effect)]]
              ==
              ``json+!>(response)
            =/  booth-proposals  (~(get by proposals.state) key)
            ?~  booth-proposals  ``json+!>(~)
            ``json+!>([%o (need booth-proposals)])

        [%x %booths @ %proposals @ %votes ~]
          =/  segments  `(list @ta)`path
          =/  booth-key  (crip (oust [0 1] (spud /(snag 2 segments))))
          =/  proposal-key  (key-from-path:util i.t.t.t.t.path)
          %-  (log:util %warn "ballot: extracting votes for booth {<booth-key>}, proposal {<proposal-key>}...")
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
          %-  (log:util %warn "ballot: extracting votes for booth {<booth-key>}, proposal {<proposal-key>}...")
          =/  booth-proposals  (~(get by votes.state) booth-key)
          ?~  booth-proposals  ``json+!>(~)
          =/  booth-proposals  (need booth-proposals)
          =/  proposal-votes  (~(get by booth-proposals) proposal-key)
          ?~  proposal-votes  ``json+!>(~)
          ``json+!>((need proposal-votes))

        [%x %booths @ %votes ~]
          =/  segments  `(list @ta)`path
          =/  booth-key  (crip (oust [0 1] (spud /(snag 2 segments))))
          %-  (log:util %warn "ballot: extracting votes for booth {<booth-key>}...")
          =/  booth-proposals  (~(get by votes.state) booth-key)
          ?~  booth-proposals  ``json+!>(~)
          ``json+!>([%o (need booth-proposals)])

        [%x %booths @ @ @ %votes ~]
          =/  segments  `(list @ta)`path
          =/  booth-key  (crip (oust [0 1] (spud /(snag 2 segments)/(snag 3 segments)/(snag 4 segments))))
          %-  (log:util %warn "ballot: extracting votes for booth {<booth-key>}...")
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
          %-  (log:util %warn "ballot: extracting participants for booth {<key>}...")
          =/  participants  (~(get by participants.state) key)
          ?~  participants  ``json+!>(~)
          ``json+!>([%o (need participants)])

        [%x %booths @ @ @ %participants ~]
          =/  segments  `(list @ta)`path
          =/  key  (crip (oust [0 1] (spud /(snag 2 segments)/(snag 3 segments)/(snag 4 segments))))
          %-  (log:util %warn "ballot: extracting participants for booth {<key>}...")
          =/  participants  (~(get by participants.state) key)
          ?~  participants  ``json+!>(~)
          ``json+!>([%o (need participants)])

        [%x %booths @ %delegates ~]
          =/  segments  `(list @ta)`path
          =/  key  (crip (oust [0 1] (spud /(snag 2 segments))))
          %-  (log:util %info leaf+"ballot: extracting participants for booth {<key>}...")
          =/  delegate-view  (~(dlg view [bowl delegates.state]) key)
          ``json+!>(delegate-view)

        [%x %booths @ @ @ %delegates ~]
          =/  segments  `(list @ta)`path
          =/  key  (crip (oust [0 1] (spud /(snag 2 segments)/(snag 3 segments)/(snag 4 segments))))
          %-  (log:util %warn "ballot: extracting participants for booth {<key>}...")
          =/  delegate-view  (~(dlg view [bowl delegates.state]) key)
          ``json+!>(delegate-view)

        [%x %booths @ %custom-actions ~]
          =/  segments  `(list @ta)`path
          =/  key  (crip (oust [0 1] (spud /(snag 2 segments))))
          %-  (log:util %info leaf+"ballot: extracting custom-actions for booth {<key>}...")
          =/  custom-actions  (~(get by custom-actions.state) key)
          =/  custom-actions  ?~(custom-actions ~ (need custom-actions))
          ``json+!>(custom-actions)

        [%x %booths @ @ @ %custom-actions ~]
          =/  segments  `(list @ta)`path
          =/  key  (crip (oust [0 1] (spud /(snag 2 segments)/(snag 3 segments)/(snag 4 segments))))
          %-  (log:util %warn "ballot: extracting custom-actions for booth {<key>}...")
          =/  custom-actions  (~(get by custom-actions.state) key)
          =/  custom-actions  ?~(custom-actions ~ (need custom-actions))
          ``json+!>(custom-actions)

    ==

  ::
  ++  on-agent
    |=  [=wire =sign:agent:gall]
    ^-  (quip card _this)

    |^
    =/  wirepath  `path`wire
    %-  (log:util %info "ballot: {<wirepath>} data received...")

    ?+    wire  (on-agent:def wire sign)

      :: handle updates coming in from group store
      [%group ~]
        ?+    -.sign  (on-agent:def wire sign)
          %watch-ack
            ?~  p.sign
              %-  (log:util %info "ballot: group subscription succeeded")
              `this
            %-  (log:util %info "ballot: group subscription failed")
            `this
      ::
          %kick
            %-  (log:util %info "ballot: group kicked us, resubscribing...")
            :_  this
            :~  [%pass /group %agent [our.bowl %group-store] %watch /groups]
            ==
      ::
          %fact
            %-  (log:util %info "ballot: received fact from group => {<p.cage.sign>}")
            ?+    p.cage.sign  (on-agent:def wire sign)
                %group-update-0
                  =/  action  !<(=update:group-store q.cage.sign)
                  %-  (log:util %info "ballot: group action => {<action>}")
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
                %-  (log:util %error "ballot: %poke-ack msg {<msg-id>} not found")
                `this
              (handle-message-ack msg-id ack (need msg))
          ==

      [%booths *]
        =/  segments  `(list @ta)`wirepath
        =/  booth-key  (snag 1 segments)
        ?-    -.sign
          %poke-ack
            ?~  p.sign
              ((log:util %info "ballot: {<wirepath>} poke succeeded") `this)
            ((log:util %info "ballot: {<wirepath>} poke failed") `this)

          %watch-ack
            ?~  p.sign
              ((log:util %info "ballot: subscribed to {<wirepath>}") `this)
            ((log:util %info "ballot: {<wirepath>} subscription failed") `this)

          %kick
            %-  (log:util %info "ballot: {<wirepath>} got kick, resubscribing...")
            :_  this
            :~  [%pass /booths/(scot %tas booth-key) %agent [src.bowl %ballot] %watch /booths/(scot %tas booth-key)]
            ==

          %fact
            ?+    p.cage.sign  (on-agent:def wire sign)

              %json
                =/  jon  !<(json q.cage.sign)
                %-  (log:util %good "{<jon>}")

                =/  payload  ?:(?=([%o *] jon) p.jon ~)

                =/  action  (~(get by payload) 'action')
                ?~  action
                      %-  (log:util %error "null action in on-agent handler => {<payload>}")
                      `this

                =/  action  (so:dejs:format (need action))

                ::  if ack exists and is set to nack, this is an error
                ::  simply pass errors to the UI on the ship that receives them
                =/  ack  (~(get by payload) 'ack')
                ::  assume ack if ack element not present
                =/  ack  ?~(ack 'ack' (so:dejs:format (need ack)))
                ?:  =(ack 'nack')
                  ~&  >>>  "{<dap.bowl>}: on-agent received error gift {<jon>}..."
                  :_  this
                  :~  [%give %fact [/booths]~ %json !>(jon)]
                  ==

                ::  no need to gift ourselves. if this ship generated the gift, the action
                ::    has already occurred
                ?:  =(our.bowl src.bowl)
                  :: %-  (log:util %warn "skipping gift to ourselves..."  `this
                  ?+  action  %-  (log:util %warn "skipping gift to ourselves {<jon>}...")  `this
                    %save-proposal-reaction
                      %-  (log:util %info "ballot: [set-booth-timer] => proposal updates. setting timers...")
                      (handle-save-proposal-reaction booth-key payload)
                  ==

                ?+  action  `this

                  %initial
                    (handle-initial payload)

                  %request-custom-actions-reaction
                    (handle-custom-actions-reaction payload)

                  %save-proposal-reaction
                    (handle-save-proposal-reaction booth-key payload)

                  %delete-proposal-reaction
                    (handle-delete-proposal-reaction booth-key payload)

                  %delete-participant-reaction
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

      %-  (log:util %info "ballot: poll-started-reaction received...")

      =/  context  ((om json):dejs:format (~(got by payload) 'context'))
      =/  booth-key  (so:dejs:format (~(got by context) 'booth'))

      ::  generate an booth-reaction with a delete effect on the booth resource
      =/  context  ((om json):dejs:format (~(got by payload) 'context'))
      =/  booth-key  (so:dejs:format (~(got by context) 'booth'))

      =/  effects  ((ar json):dejs:format (~(got by payload) 'effects'))
      =/  effect  ((om json):dejs:format (snag 0 effects))

      =/  data  (~(get by effect) 'data')
      =/  data=json  ?~(data ~ (need data))
      :: =/  data  ?:(?=([%o *] data) p.data ~)

      =/  effect-name  (so:dejs:format (~(got by effect) 'effect'))

      ?+  effect-name  !!  :: %-  (log:util %error "ballot: unknown effect type")  !!

        %delete
          :_  this(booths (~(del by booths.state) booth-key))
          :~  [%give %fact [/booths]~ %json !>([%o payload])]
          ==

        %update
          :_  this(booths (~(put by booths.state) booth-key data))
          :~  [%give %fact [/booths]~ %json !>([%o payload])]
          ==

        %add
          :_  this(booths (~(put by booths.state) booth-key data))
          :~  [%give %fact [/booths]~ %json !>([%o payload])]
          ==

      ==

    ++  handle-delegate-reaction
      |=  [payload=(map @t json)]

      %-  (log:util %info leaf+"{<dap.bowl>}: handle-delegate-reaction received. {<payload>}...")

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

      %-  (log:util %info "ballot: poll-started-reaction received...")

      =/  context  ((om json):dejs:format (~(got by payload) 'context'))
      =/  booth-key  (so:dejs:format (~(got by context) 'booth'))
      =/  proposal-key  (so:dejs:format (~(got by context) 'proposal'))
      =/  poll-key  (so:dejs:format (~(got by context) 'poll'))

      :: =/  effects  (~(get by payload) 'effects')
      :: ?~  effects  %-  (log:util %error "ballot: effects not found"  !!
      :: =/  effects=(list json)  ((as json):dejs:format (need effects))
      :: %-  run
      :: :-  effects
      :: |=  [jon=json]
      ::   (dispatch-effect payload jon)

      =/  effects  (~(get by payload) 'effects')
      ?~  effects  !!  ::  %-  (log:util %error "ballot: effects not found" ~)  !!
      %-  (log:util %info "ballot: extracting effects data...")
      =/  effects=(list json)  ~(tap in ((as json):dejs:format (need effects)))
      %-  (log:util %info "ballot: extracting effect data...")
      =/  effect  ((om json):dejs:format (snag 0 effects))
      %-  (log:util %info "ballot: extracting poll data...")
      =/  data  ((om json):dejs:format (~(got by effect) 'data'))
      %-  (log:util %info "ballot: done")

      =/  poll-proposals  (~(get by polls.state) booth-key)
      =/  poll-proposals  ?~(poll-proposals ~ (need poll-proposals))
      =/  poll-proposal  (~(get by poll-proposals) proposal-key)
      =/  poll-proposal  ?~(poll-proposal ~ ((om json):dejs:format (need poll-proposal)))
      =/  poll-proposal  (~(gas by poll-proposal) ~(tap by data))
      =/  poll-proposals  (~(put by poll-proposals) proposal-key [%o poll-proposal])

      %-  (log:util %info "ballot: committing poll changes...")
      %-  (log:util %warn "{<(crip (en-json:html [%o data]))>}")
      %-  (log:util %warn "{<(crip (en-json:html [%o poll-proposal]))>}")

      :_  this(polls (~(put by polls.state) booth-key poll-proposals))

      :~  [%give %fact [/booths]~ %json !>([%o payload])]
      ==

    ++  handle-poll-ended-reaction
      |=  [payload=(map @t json)]

      %-  (log:util %info "ballot: poll-ended-reaction received...")
      %-  (log:util %warn "{<(crip (en-json:html [%o payload]))>}")

      =/  context  ((om json):dejs:format (~(got by payload) 'context'))
      =/  booth-key  (so:dejs:format (~(got by context) 'booth'))
      =/  proposal-key  (so:dejs:format (~(got by context) 'proposal'))
      =/  poll-key  (so:dejs:format (~(got by context) 'poll'))

      =/  effects  (~(get by payload) 'effects')
      ?~  effects  !! ::  %-  (log:util %error "ballot: effects not found")  !!
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

      %-  (log:util %info "ballot: received ack ({<ack>}) {<msg-id>}...")

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

      =|  custom-actions=(map @t json)
      =/  custom-actions  ?.  =(our.bowl entity.resource.action)  ~
        =/  lib-file  /(scot %p our.bowl)/(scot %tas dap.bowl)/(scot %da now.bowl)/lib/(scot %tas dap.bowl)/custom-actions/config/json
        ?.  .^(? %cu lib-file)
          ~&  >>  "{<dap.bowl>}: warning. custom actions file not found"
          ~
        (~(put by custom-actions) key.booth .^(json %cx lib-file))

      %-  (log:util %info "ballot: on-group-added. adding group booth {<key.booth>}...")

      ::  generate a participant from the resource
      =/  participant-key  (crip "{<our.bowl>}")
      =/  participant=json
      %-  pairs:enjs:format
      :~
        ['key' s+participant-key]
        ['name' s+participant-key]
        ['status' s+?:(=(our.bowl entity.resource.action) 'active' 'enlisted')]
        ['created' (time:enjs:format now.bowl)]
        ['role' s+?:(=(our.bowl entity.resource.action) 'owner' 'member')]
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

      :_  this(booths (~(put by booths.state) key.booth data.booth), participants (~(put by participants.state) key.booth booth-participants), custom-actions (~(gas by custom-actions.state) ~(tap by custom-actions)))

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
      %-  (log:util %info "on-group-member-added {<booth-key>}")
      =/  booth-participants  (~(get by participants.state) booth-key)
      ?~  booth-participants
            %-  (log:util %info "booth {<booth-key>} participants not found...")
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
          ['role' s+'member']
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

      %-  (log:util %info "on-group-member-removed {<booth-key>}")
      =/  booth-participants  (~(get by participants.state) booth-key)
      ?~  booth-participants
            %-  (log:util %info "booth {<booth-key>} participants not found...")
            `this
      =/  booth-participants  (need booth-participants)

      =/  art=(quip card _state)  (delete-participants 'group-remove-members' booth-key ships.action)

      :_  this(state +.art)

      [-.art]

    ++  booth-from-resource
      |=  [=resource]
      ^-  [key=@t status=@t data=json]

      =/  timestamp  (crip (en-json:html (time:enjs:format now.bowl)))
      =/  key  (crip (weld (weld "{<entity.resource>}" "-groups-") (trip `@t`name.resource)))
      =/  slug  (crip (weld (weld "{<entity.resource>}" "/groups/") (trip `@t`name.resource)))

      =/  group-name  (trip name.resource)

      ::  if this ship is the owner of the group, set them as the owner of the booth
      =/  status=@t  ?:(=(our.bowl entity.resource) 'active' 'enlisted')

      =/  defaults
      %-  pairs:enjs:format
      :~
        ['support' n+'50']
        ['duration' n+'7']
      ==
      =/  permissions
      :~  s+'member'
          s+'admin'
      ==
      =/  admin-permissions
      :~  s+'read-proposal'
          s+'vote-proposal'
          s+'create-proposal'
          s+'edit-proposal'
          s+'delete-proposal'
          s+'invite-member'
          s+'remove-member'
          s+'change-settings'
      ==
      =/  member-permissions
      :~  s+'read-proposal'
          s+'vote-proposal'
          s+'create-proposal'
      ==
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
        ['defaults' defaults]
        ['permissions' [%a permissions]]
        ['adminPermissions' [%a admin-permissions]]
        ['memberPermissions' [%a member-permissions]]
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
        ^-  [effects=(list card) booths=(map @t json) participants=(map @t (map @t json)) custom-actions=(map @t json)] :: participants=(map @t (map @t json))]
        ::  loop thru groups, creating a new booth (status='initial') for each
        ::    group in the map
        %-  ~(rep in groups.initial)
        ::  each map key/value pair is a resource => group. acc is an
        ::   accumulator which is used to store the final result
        |=  [[=resource =group] acc=[effects=(list card) booths=(map @t json) participants=(map @t (map @t json)) custom-actions=(map @t json)]]  :: participants=(map @t (map @t json))]]
          ^-  [effects=(list card) booths=(map @t json) participants=(map @t (map @t json)) custom-actions=(map @t json)] :: participants=(map @t (map @t json))]
          =/  booth  (booth-from-resource resource)
          ?:  (~(has by booths.state) key.booth)
                %-  (log:util %warn "cannot add booth {<key.booth>} to store. already exists...")
                [effects.acc booths.acc participants.acc custom-actions.acc]
          =/  effects
                ?:  =(status.booth 'active')
                  %-  (log:util %info "activating booth {<key.booth>} on {<our.bowl>}...")
                  (snoc effects.acc [%pass /booths/(scot %tas key.booth) %agent [our.bowl %ballot] %watch /booths/(scot %tas key.booth)])
                [effects.acc]
          =/  participants
                ?:  =(status.booth 'active')
                  =/  members  (members-to-participants resource group)
                  (~(put by participants.acc) key.booth members)
                [participants.acc]
          =/  custom-actions  ?.  =(our.bowl entity.resource)  custom-actions.acc
            =/  lib-file  /(scot %p our.bowl)/(scot %tas dap.bowl)/(scot %da now.bowl)/lib/(scot %tas dap.bowl)/custom-actions/config/json
            ?.  .^(? %cu lib-file)
              ~&  >>  "{<dap.bowl>}: warning. custom actions file not found"
              custom-actions.acc
            (~(put by custom-actions.acc) key.booth .^(json %cx lib-file))

            [effects (~(put by booths.acc) key.booth data.booth) participants custom-actions]
      :_  this(booths (~(gas by booths.state) ~(tap by booths.data)), participants (~(gas by participants.state) ~(tap by participants.data)), custom-actions (~(gas by custom-actions.state) ~(tap by custom-actions.data)))
      [effects.data]

    ++  on-group-initial-group
      |=  [=initial:group-store]
      ?>  ?=(%initial-group -.initial)

      =/  new-booth  (booth-from-resource resource.initial)

      =|  custom-actions=(map @t json)
      =/  custom-actions  ?.  =(our.bowl entity.resource.initial)  ~
        =/  lib-file  /(scot %p our.bowl)/(scot %tas dap.bowl)/(scot %da now.bowl)/lib/(scot %tas dap.bowl)/custom-actions/config/json
        ?.  .^(? %cu lib-file)
          ~&  >>  "{<dap.bowl>}: warning. custom actions file not found"
          ~
        (~(put by custom-actions) key.new-booth .^(json %cx lib-file))

      =/  booth  (~(get by booths.state) key.new-booth)
      ?.  =(booth ~)
          %-  (log:util %warn "cannot add booth {<key.new-booth>} to store. already exists...")
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
        ['role' s+?:(=(our.bowl entity.resource.initial) 'owner' 'member')]
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

      :_  this(booths (~(put by booths.state) key.new-booth data.new-booth), participants (~(put by participants.state) key.new-booth booth-participants), custom-actions (~(gas by custom-actions.state) ~(tap by custom-actions)))

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
              ['role' s+'member']
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

    ++  handle-save-proposal-reaction
      |=  [booth-key=@t payload=(map @t json)]
      ^-  (quip card _this)

      =/  timestamp  (crip (en-json:html (time:enjs:format now.bowl)))

      =/  context  ((om json):dejs:format (~(got by payload) 'context'))
      =/  booth-key  (so:dejs:format (~(got by context) 'booth'))

      =/  booth  (~(get by booths.state) booth-key)
      =/  booth  ?~(booth ~ (need booth))
      =/  booth  ?:(?=([%o *] booth) p.booth ~)
      =/  booth-owner  (~(get by booth) 'owner')
      ?~  booth-owner
        ~&  >>>  "{<dap.bowl>}: error. booth has no owner"
        `this  ::  if can't find owner nothing to do
      =/  booth-owner  (so:dejs:format (need booth-owner))
      =/  hostship=@p  `@p`(slav %p booth-owner)

      =/  effects  (~(get by payload) 'effects')
      =/  effects  ?~(effects ~ (need effects))
      =/  effects  ?:(?=([%a *] effects) p.effects ~)

      =/  effect  (snag 0 effects)
      =/  effect  ?:(?=([%o *] effect) p.effect ~)
      =/  proposal-key  (so:dejs:format (~(got by effect) 'key'))
      =/  proposal-data  (~(get by effect) 'data')
      =/  proposal-data  ?~(proposal-data ~ (need proposal-data))
      =/  proposal-data  ?:(?=([%o *] proposal-data) p.proposal-data ~)
      =/  effect-type  (~(get by effect) 'effect')
      =/  effect-type  ?~(effect-type ~ (so:dejs:format (need effect-type)))

      :: =/  results
      :: %-  roll
      :: :-  effects
      :: |=  [effect=json acc=?)

      =/  booth-proposals  (~(get by proposals.state) booth-key)
      =/  booth-proposals  ?~(booth-proposals ~ (need booth-proposals))
      =/  proposal  (~(get by booth-proposals) proposal-key)
      =/  proposal  ?~(proposal ~ ((om json):dejs:format (need proposal)))
      =/  proposal  (~(gas by proposal) ~(tap by proposal-data))
      =/  booth-proposals  (~(put by booth-proposals) proposal-key [%o proposal])

      ::  poll and timers only pertain to booth host. if not booth host, nothing to do
      ?.  =(hostship our.bowl)
        :_  this(proposals (~(put by proposals.state) booth-key booth-proposals))
        :~  [%give %fact [/booths]~ %json !>([%o payload])]  ==

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

      =/  proposal-start-date  (~(get by proposal-data) 'start')
      =.  result  ?.  ?=(~ proposal-start-date)
        :: ::  did the start date of the poll change?
        =/  proposal-start-date=@da  (du:dejs:format (need proposal-start-date))
        =.  result
              ?.  =(proposal-start-date poll-start-date)
                    %-  (log:util %info "ballot: proposal {<proposal-key>} start date changed. rescheduling...")
                    =/  effects
                      ?.  =(~ poll-start-date)
                        %-  (log:util %warn "ballot: poll-start-date {<poll-start-date>}. %rest.")
                        (snoc effects [%pass /timer/(scot %tas booth-key)/(scot %tas proposal-key)/start %arvo %b %rest `@da`poll-start-date])
                      effects
                    %-  (log:util %info "ballot: proposal-start-date {<proposal-start-date>}. %wait.")
                    =/  effects  (snoc effects [%pass /timer/(scot %tas booth-key)/(scot %tas proposal-key)/start %arvo %b %wait `@da`proposal-start-date])
                    =/  poll  (~(put by poll) 'start' (sect:enjs:format proposal-start-date))
                    [effects poll]
                  %-  (log:util %info "ballot: proposal {<proposal-key>} start date unchanged. no need to reschedule.")
                  [effects poll]
            [effects.result poll.result]
          %-  (log:util %info "ballot: start date not found in payload. no need to reschedule poll start.")
          [effects poll]

      =/  effects  effects.result
      =/  poll  poll.result

      =/  poll-end-date  (~(get by poll) 'end')
      =/  poll-end-date  ?~(poll-end-date ~ (du:dejs:format (need poll-end-date)))

      =/  proposal-end-date  (~(get by proposal-data) 'end')
      =.  result  ?.  ?=(~ proposal-end-date)
        :: ::  did the end date of the poll change?
        =/  proposal-end-date=@da  (du:dejs:format (need proposal-end-date))
        =.  result
            ?.  =(proposal-end-date poll-end-date)
                  %-  (log:util %info "ballot: proposal {<proposal-key>} end date changed. rescheduling...")
                    =/  effects
                      ?.  =(~ poll-end-date)
                        %-  (log:util %warn "ballot: poll-end-date {<poll-end-date>}. %rest.")
                        (snoc effects [%pass /timer/(scot %tas booth-key)/(scot %tas proposal-key)/end %arvo %b %rest `@da`poll-end-date])
                      effects
                    %-  (log:util %info "ballot: proposal-end-date {<proposal-end-date>}. %wait.")
                    =/  effects  (snoc effects [%pass /timer/(scot %tas booth-key)/(scot %tas proposal-key)/end %arvo %b %wait `@da`proposal-end-date])
                  =/  poll  (~(put by poll) 'end' (sect:enjs:format proposal-end-date))
                  [effects poll]
                %-  (log:util %info "ballot: proposal {<proposal-key>} end date unchanged. no need to reschedule.")
                [effects poll]
            [effects.result poll.result]
          %-  (log:util %info "ballot: end date not found in payload. no need to reschedule poll end.")
          [effects poll]

      =/  poll-key  (crip (weld "poll-" (trip timestamp)))
      =/  poll  (~(put by poll.result) 'key' s+poll-key)
      =/  poll  (~(put by poll) 'status' s+'scheduled')
      =/  booth-polls  (~(put by booth-polls) proposal-key [%o poll])

      ::  make sure to inform this ship's UI that the proposal was updated
      =/  effects  (snoc effects.result [%give %fact [/booths]~ %json !>([%o payload])])

      ::  in case of scheduling change:
      ::
      ::  1) generate cards to kill any existing start/end times that have changed
      ::  2) generate cards to start new schedules based on changes to start/end times
      ::

      ::  for more information on how to setup/start a thread from Gall agent,
      ::    see:  https://urbit.org/docs/userspace/threads/reference#start-thread

      ::  commit any scheduling changes to the polls store
      :_  this(polls (~(put by polls.state) booth-key booth-polls), proposals (~(put by proposals.state) booth-key booth-proposals))

      ::  send out effects to reschedule the poll
      [effects]

    ++  handle-cast-vote
      |=  [booth-key=@t payload=(map @t json)]

      =/  context  (~(get by payload) 'context')
      =/  context  ?~(context ~ ((om json):dejs:format (need context)))

      =/  data  (~(get by payload) 'data')
      =/  data  ?~(data ~ ((om json):dejs:format (need data)))

      =/  proposal-key  (so:dejs:format (~(got by context) 'proposal'))
      =/  participant-key  (so:dejs:format (~(got by context) 'participant'))

      %-  (log:util %info "on-agent:handling-cast-vote => {<participant-key>} voted...")

      ::  does proposal exist?
      =/  booth-proposals  (~(get by proposals.state) booth-key)
      =/  booth-proposals  ?~(booth-proposals ~ (need booth-proposals))
      =/  proposal  (~(get by booth-proposals) proposal-key)
      ?~  proposal
            %-  (log:util %error "cast-vote error: proposal {<proposal-key>} not found")
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
            %-  (log:util %error "handle-initial missing data")
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
      =/  custom-actions  (~(get by data) 'custom-actions')
      =/  custom-actions  ?~(custom-actions ~ (need custom-actions))
      =/  custom-actions  ?:  ?=([%o *] custom-actions)  p.custom-actions  ~

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

      ::  only booth owner should be concerned with polls
      :: =/  booth-polls  (~(get by polls.state) booth-key)
      :: =/  booth-polls  ?~(booth-polls ~ (need booth-polls))
      :: =/  booth-polls  (~(gas by booth-polls) ~(tap by polls))

      =/  booth-delegates  (~(get by delegates.state) booth-key)
      =/  booth-delegates  ?~(booth-delegates ~ (need booth-delegates))
      =/  booth-delegates  (~(gas by booth-delegates) ~(tap by delegates))

      =/  booth-custom-actions  (~(get by custom-actions.state) booth-key)
      =/  booth-custom-actions  ?~(booth-custom-actions ~ (need booth-custom-actions))
      =/  booth-custom-actions  ?:  ?=([%o *] booth-custom-actions)  p.booth-custom-actions  ~
      =/  booth-custom-actions  (~(gas by booth-custom-actions) ~(tap by custom-actions))

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

      :_  this(booths (~(put by booths.state) booth-key [%o booth]), proposals (~(put by proposals.state) booth-key booth-proposals), participants (~(put by participants.state) booth-key booth-participants), votes (~(put by votes.state) booth-key booth-votes), delegates (~(put by delegates.state) booth-key booth-delegates), custom-actions (~(put by custom-actions.state) booth-key [%o custom-actions]))

      :~
        ::  for clients (e.g. UI) and "our" agent, send to generic /booths path
        [%give %fact [/booths]~ %json !>(effects)]
      ==

    ++  handle-custom-actions-reaction
      |=  [payload=(map @t json)]

      :: =/  custom-action-effect
      :: %-  pairs:enjs:format
      :: :~
      ::   ['resource' s+'custom-action']
      ::   ['effect' s+'initial']
      ::   ['key' s+booth-key]
      ::   ['data' custom-actions]
      :: ==
      :: =/  effect-list  [custom-action-effect ~]
      :: =/  effects=json
      :: %-  pairs:enjs:format
      :: :~
      ::   ['action' s+'request-custom-actions-reaction']
      ::   ['context' [%o context]]
      ::   ['effects' [%a effect-list]]
      :: ==

      =/  context  (~(get by payload) 'context')
      =/  context  ?~(context ~ (need context))
      =/  context  ?:  ?=([%o *] context)  p.context  ~

      =/  booth-key  (~(get by context) 'booth')
      ?~  booth-key
        ~&  >>>  "{<dap.bowl>}: error. context missing booth key"
        `this
      =/  booth-key  (so:dejs:format (need booth-key))

      =/  effects  (~(get by payload) 'effects')
      ?~  effects
        ~&  >>>  "{<dap.bowl>}: error. reaction payload missing effects"
        `this
      =/  effects  (need effects)
      =/  effects  ?:  ?=([%a *] effects)  p.effects  ~
      =/  initial-effect  (snag 0 effects)
      =/  initial-effect  ?:(?=([%o *] initial-effect) p.initial-effect ~)

      :: %-  roll
      :: :-  effects
      :: |=  [jon=json acc=?]
      ::   =/  effect  ?:(?=([%o *] jon) p.jon ~)
      ::   =/  effect  (~(get by effect) 'effect')
      ::   ?~  effect  !acc
      ::   =/  effect  (so:dejs:format (need effect))
      ::   ?-  effect
      ::     %initial
      ::   ==

      =/  custom-actions  (~(get by initial-effect) 'data')
      ?~  custom-actions
            %-  (log:util %error "handle-initial missing data")
            `this
      =/  custom-actions  (need custom-actions)

      `this(custom-actions (~(put by custom-actions.state) booth-key custom-actions))

    :: ++  handle-save-proposal-reaction
    ::   |=  [payload=(map @t json)]

    ::   %-  (log:util %info "ballot: handle-save-proposal-reaction {<payload>}...")

    ::   =/  context  ((om json):dejs:format (~(got by payload) 'context'))
    ::   =/  booth-key  (so:dejs:format (~(got by context) 'booth'))

    ::   =/  effects  (~(get by payload) 'effects')
    ::   =/  effects  ?~(effects ~ (need effects))
    ::   =/  effects  ?:(?=([%s *] effects) p.effects ~)

    ::   =/  effect  (snag 0 effects)
    ::   =/  effect  ?:(?=([%o *] effect) p.effect ~)
    ::   =/  proposal-key  (~(get by effect) 'key')
    ::   =/  proposal-key  ?~(proposal-key ~ (so:dejs:format (need proposal-key)))
    ::   =/  proposal-data  (~(get by effect) 'data')
    ::   =/  proposal-data  ?~(proposal-data ~ (need proposal-data))
    ::   =/  effect-type  (~(get by effect) 'effect')
    ::   =/  effect-type  ?~(effect-type ~ (so:dejs:format (need effect-type)))

    ::   :: =/  results
    ::   :: %-  roll
    ::   :: :-  effects
    ::   :: |=  [effect=json acc=?)

    ::   =/  booth-proposals  (~(get by proposals.state) booth-key)
    ::   =/  booth-proposals  ?~(booth-proposals ~ (need booth-proposals))
    ::   =/  proposal  (~(get by booth-proposals) proposal-key)
    ::   =/  proposal  ?~(proposal ~ ((om json):dejs:format (need proposal)))
    ::   =/  proposal  (~(gas by proposal) ~(tap by proposal-data))
    ::   =/  booth-proposals  (~(put by booth-proposals) proposal-key [%o proposal])

    ::   ::  no changes to state. state will change when poke ack'd
    ::   :_  this(proposals (~(put by proposals.state) booth-key booth-proposals))

    ::   :~
    ::     ::  for clients (e.g. UI) and "our" agent, send to generic /booths path
    ::     [%give %fact [/booths]~ %json !>(effects)]
    ::   ==

    ++  handle-delete-proposal-reaction
      |=  [booth-key=@t payload=(map @t json)]

      =/  context  ((om json):dejs:format (~(got by payload) 'context'))

      =/  effects  (~(get by payload) 'effects')
      =/  effects  ?~(effects ~ (need effects))
      =/  effects  ?:(?=([%a *] effects) p.effects ~)

      =/  effect  (snag 0 effects)
      =/  effect  ?:(?=([%o *] effect) p.effect ~)
      =/  proposal-key  (so:dejs:format (~(got by effect) 'key'))
      =/  proposal-data  (~(get by effect) 'data')
      =/  proposal-data  ?~(proposal-data ~ (need proposal-data))
      =/  proposal-data  ?:(?=([%o *] proposal-data) p.proposal-data ~)
      =/  effect-type  (~(get by effect) 'effect')
      =/  effect-type  ?~(effect-type ~ (so:dejs:format (need effect-type)))

      =/  booth-proposals  (~(get by proposals.state) booth-key)
      =/  booth-proposals  ?~(booth-proposals ~ (need booth-proposals))
      =/  booth-proposals  (~(del by booth-proposals) proposal-key)

      ::  no changes to state. state will change when poke ack'd
      :_  this(proposals (~(put by proposals.state) booth-key booth-proposals))

      :~
        ::  for clients (e.g. UI) and "our" agent, send to generic /booths path
        [%give %fact [/booths]~ %json !>([%o payload])]
      ==

    ++  handle-delete-participant
      |=  [booth-key=@t payload=(map @t json)]

      =/  action  (so:dejs:format (~(got by payload) 'action'))
      =/  context  ((om json):dejs:format (~(got by payload) 'context'))
      =/  booth-key  (so:dejs:format (~(got by context) 'booth'))
      =/  participant-key  (so:dejs:format (~(got by context) 'participant'))

      =/  effects  (~(get by payload) 'effects')
      =/  effects  ?~(effects ~ (need effects))
      =/  effects  ?:(?=([%a *] effects) p.effects ~)

      ::  if this ship is the one being deleted, remove all remnants of the booth
      ::   and send out a booth delete effect
      =/  participant-ship  `@p`(slav %p participant-key)
      =/  participants=(set ship)  (silt ~[participant-ship])

      =/  art=(quip card _state)  (delete-participants action booth-key participants)

      :_  this(state +.art)

      [-.art]
    --

  ++  on-arvo
    |=  [=wire =sign-arvo]
    ^-  (quip card _this)

    %-  (log:util %warn "ballot: on-arvo called {<wire>}, {<sign-arvo>}...")

    |^

    ?+  wire  (on-arvo:def wire sign-arvo)

      [%bind-route ~]
        ?>  ?=([%eyre %bound *] sign-arvo)
        ?:  accepted.sign-arvo
          %-  (log:util %good "{<[wire sign-arvo]>}")
          `this
          %-  (log:util %error "ballot: binding route failed")
        `this

      [%timer @ @ %start ~]
        %-  (log:util %info "ballot: poll started...")
        ?.  ?=([%behn %wake *] sign-arvo)  (on-arvo:def wire sign-arvo)
        ?^  error.sign-arvo                (on-arvo:def wire sign-arvo)
        =/  segments  `(list @ta)`wire
        =/  booth-key  (snag 1 segments)
        =/  proposal-key  (snag 2 segments)
        %-  (log:util %info "ballot: on-start-poll {<booth-key>}, {<proposal-key>}...")
        (on-start-poll booth-key proposal-key)

      [%timer @ @ %end ~]
        %-  (log:util %info "ballot: poll ended.")
        ?.  ?=([%behn %wake *] sign-arvo)  (on-arvo:def wire sign-arvo)
        ?^  error.sign-arvo                (on-arvo:def wire sign-arvo)
        =/  segments  `(list @ta)`wire
        =/  booth-key  (snag 1 segments)
        =/  proposal-key  (snag 2 segments)
        %-  (log:util %info "ballot: on-end-poll {<booth-key>}, {<proposal-key>}...")
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
      =/  poll-key  ?~  poll-key  (mean leaf+"ballot: error. poll key not found." ~)

        :: %-  (log:util %error "poll not found")  !!
      (so:dejs:format (need poll-key))

      =/  poll  (~(put by poll) 'status' s+'opened')
      =/  booth-polls  (~(put by booth-polls) proposal-key [%o poll])

      %-  (log:util %info leaf+"on-start-poll called {<poll>}...")

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

      %-  (log:util %info "sending poll started effect to subcribers => {<effects>}...")

      :_  this(proposals (~(put by proposals.state) booth-key booth-proposals), polls (~(put by polls.state) booth-key booth-polls))
      :~  [%give %fact [/booths]~ %json !>(effects)]
          [%give %fact [/booths/(scot %tas booth-key)]~ %json !>(effects)]
      ==

    ++  on-end-poll
      |=  [booth-key=@t proposal-key=@t]
      ^-  (quip card _this)

      %-  (log:util %info leaf+"on-end-poll called")
      =/  booth-polls  (~(get by polls.state) booth-key)
      =/  booth-polls  ?~(booth-polls ~ (need booth-polls))
      =/  poll  (~(get by booth-polls) proposal-key)
      =/  poll  ?~(poll ~ ((om json):dejs:format (need poll)))

      =/  poll-key  (~(get by poll) 'key')
      =/  poll-key  ?~  poll-key  (mean leaf+"ballot: error. poll key not found" ~)

        :: %-  (log:util %error "poll not found")  !!
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

      %-  (log:util %info "poll results are in!!! => {<poll-results>}")

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

      %-  (log:util %info "sending poll results to subcribers => {<effects>}...")

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

      %-  (log:util %info "tally-results called. [booth-key={<booth-key>}, proposal-key={<proposal-key>}]")

      =/  booth-proposals  (~(get by proposals.state) booth-key)
      =/  booth-proposals  ?~(booth-proposals ~ (need booth-proposals))
      =/  proposal  (~(get by booth-proposals) proposal-key)
      =/  proposal  ?~(proposal ~ ((om json):dejs:format (need proposal)))
      =/  threshold  (~(get by proposal) 'support')
      ?~  threshold
        ~&  >>>  "ballot: error. missing voter support value"
        :: %-  (log:util %error "ballot: missing voter support value")
        !!
      =/  choices  (~(get by proposal) 'choices')
      =/  choices  ?~(choices ~ (need choices))
      =/  choices  ?:(?=([%a *] choices) p.choices ~)

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
      :: =/  vote-count  ?~(proposal-votes 0 (lent votes))

      :: =/  turnout  (div:rd (sun:rd vote-count) (sun:rd participant-count))
      :: %-  (log:util %info "ballot: {<turnout>}, {<threshold>}")
      =/  tallies=(map @t json)
            :: ?:  (gte turnout threshold)
            :: ?:  (gte:ma:rd turnout threshold)
              %-  roll
              :-  votes
              |:  [vote=`[@t json]`[%null ~] results=`(map @t json)`~]
              ::  has this voter delegated? if so skip...
              %-  (log:util %info leaf+"{<dap.bowl>}: processing {<-.vote>}...")
              =/  delegate  (~(get by booth-delegates) -.vote)
              ?.  =(~ delegate)
                %-  (log:util %info leaf+"{<dap.bowl>}: voter {<-.vote>} delegated. skipping...")
                results
              =/  vote-data  ?:(?=([%o *] +.vote) p.+.vote ~)
              ::  if this member's vote has no delegators data, assume vote weight of 1
              =/  num-votes
              ?.  (~(has by vote-data) 'delegators')  1
                ::  otherwise get a count of delegator entries
                =/  delegators  (~(got by vote-data) 'delegators')
                =/  delegators  ?:(?=([%o *] delegators) p.delegators ~)
                (add 1 (lent ~(val by delegators)))
              :: =/  num-votes
              ::   %-  roll
              ::   :-  ~(tap by booth-delegates)
              ::   |=  [[voter=@t d=json] total=@ud]
              ::     %-  (log:util %info leaf+"{<dap.bowl>}: calc vote count {<[-.vote voter d]>}")
              ::     =/  d  ?:  ?=([%o *] d)  p.d  ~
              ::     =/  deleg  (so:dejs:format (~(got by d) 'delegate'))
              ::     ?:  =(-.vote deleg)  (add total 1)  total
              ::  1 + num of times delegated to
              :: =/  num-votes  (add 1 num-votes)
              %-  (log:util %info leaf+"{<dap.bowl>}: {<-.vote>} choice counted {<num-votes>} times...")
              (count-vote participant-count num-votes vote results)

            :: %-  (log:util %info "ballot: voter turnout not sufficient. not enough voter support.")
            :: ~

      %-  (slog leaf+"{<dap.bowl>}: vote-count => {<tallies>}..." ~)
      =/  vote-count
        %-  ~(rep by tallies)
          |=  [[key=@t jon=json] acc=@ud]
          =/  data  ?:(?=([%o *] jon) p.jon ~)
          =/  count  (~(get by data) 'count')
          =/  count  ?~(count 0 (ni:dejs:format (need count)))
          (add acc count)
      =/  turnout  (div:rd (sun:rd vote-count) (sun:rd participant-count))
      %-  (log:util %info "ballot: {<turnout>}, {<threshold>}")
      ?.  (gte:ma:rd turnout threshold)
        %-  (log:util %info "ballot: voter turnout not sufficient. not enough voter support.")
        =/  results
        %-  pairs:enjs:format
        :~
          ['status' s+'failed']
          ['reason' s+'voter turnout not sufficient. not enough voter support.']
          ['voteCount' (numb:enjs:format `@ud`vote-count)]
          ['participantCount' (numb:enjs:format `@ud`participant-count)]
        ==
        [results ~]

      %-  (log:util %warn "ballot: tally => {<tallies>}")

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
                =/  custom-action  ?~(custom-action ~ (so:dejs:format (need custom-action)))
                %-  (log:util %info "{<dap.bowl>}: searching for {<custom-action>} in {<choices>}...")
                =/  choice-data=(list json)
                %-  skim
                :-  choices
                |=  [data=json]
                  =/  choice  ?:(?=([%o *] data) p.data ~)
                  =/  choice-action  (~(get by choice) 'action')
                  =/  choice-action  ?~(choice-action ~ (so:dejs:format (need choice-action)))
                  %-  (log:util %info "{<dap.bowl>}: comparing {<custom-action>} to {<choice-action>}...")
                  ?:  =(custom-action choice-action)  %.y  %.n
                ::  grab the first match
                =/  choice-data=json  (snag 0 choice-data)
                =/  custom-action  ?~(custom-action ~ (some custom-action))
                [(some label) custom-action choice-data ~]
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
        =/  car  (~(eca drv [bowl state]) [booth-key proposal-key] (need custom-action.result) data.result results)
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
      =/  action  (~(get by choice) 'action')
      =/  action  ?~(action ~ (need action))
      =/  action=(unit @t)  ?~(action ~ (some (so:dejs:format action)))
      :: =/  action  (so:dejs:format (~(got by choice) 'action'))

      ::  label, count, percentage
      =/  result  (~(get by results) label)
      =/  result  ?~(result ~ ((om json):dejs:format (need result)))

      =/  choice-count  (~(get by result) 'count')
      =/  choice-count  ?~(choice-count 0 (ni:dejs:format (need choice-count)))
      =/  choice-count  (add choice-count count) :: plug in delegate count here

      =/  percentage  (mul:rd (div:rd (sun:rd choice-count) (sun:rd voter-count)) (sun:rd 100))
      :: =/  percentage  (div choice-count `@ud`voter-count)

      =.  result  (~(put by result) 'label' s+label)
      =.  result  (~(put by result) 'action' ?~(action ~ s+(need action)))
      =.  result  (~(put by result) 'count' (numb:enjs:format choice-count))
      =.  result  (~(put by result) 'percentage' n+(crip "{(r-co:co (drg:rd percentage))}"))

      =.  results  (~(put by results) label [%o result])
      results
    --
  ++  on-fail   on-fail:def
  --
::  gall agent extension helper arms
|_  =bowl:gall
::
++  delete-participants
  |=  [action=@t booth-key=@t participants=(set ship)]
  ^-  (quip card _state)

  ::  loop thru all participants in the set, generating effects
  ::    and new update state
  =/  result=[effects=(list json) cards=(list card) =_state]
  %-  ~(rep in participants)
  |=  [=ship acc=[effects=(list json) cards=(list card) =_state]]
    ::  delete the participant from state and generate effects/cards
    (delete-participant booth-key ship)

  =/  context=json
  %-  pairs:enjs:format
  :~
    ['booth' s+booth-key]
  ==

  =/  effects=json
  %-  pairs:enjs:format
  :~
    ['action' s+(crip (weld "{<action>}" "-reaction"))]
    ['context' context]
    ['effects' [%a effects.result]]
  ==

  :_  state.result

  ::  in addition to any cards that were generated during the removal process,
  ::    %give an addition %fact card to the UI that includes all resource effects
  (snoc cards.result [%give %fact [/booths]~ %json !>(effects)])
::
++  delete-participant
  |=  [booth-key=@t participant-ship=@p]
  ^-  [effects=(list json) cards=(list card) =_state]

  =/  participant-key  (crip "{<participant-ship>}")

  =/  booth-participants  (~(get by participants.state) booth-key)
  =/  booth-participants  ?~(booth-participants ~ (need booth-participants))
  =/  booth-participants  (~(del by booth-participants) participant-key)

  =/  participant  (~(get by booth-participants) participant-key)
  =/  participant  ?~(participant ~ (need participant))

  =/  participant-effect=json
  %-  pairs:enjs:format
  :~
    ['resource' s+'participant']
    ['effect' s+'delete']
    ['data' participant]
  ==

  =/  effects  ~[participant-effect]

  ?:  =(participant-ship our.bowl)
    ::  for the ship being deleted, an additional booth delete effect needs to be sent
    =/  booth  (~(get by booths.state) booth-key)
    =/  booth  ?~(booth ~ (need booth))
    =/  booth-effect=json
    %-  pairs:enjs:format
    :~
      ['resource' s+'booth']
      ['effect' s+'delete']
      ['data' booth]
    ==
    ::  clear all booth information from the ship being deleted
    =.  participants.state  (~(del by participants.state) booth-key)
    =.  votes.state  (~(del by votes.state) booth-key)
    =.  proposals.state  (~(del by proposals.state) booth-key)
    =.  polls.state  (~(del by polls.state) booth-key)
    =.  invitations.state  (~(del by invitations.state) booth-key)

    =/  cards
    :~  [%give %kick ~[/booths/(scot %tas booth-key)] (some participant-ship)]  ==

    [(snoc effects booth-effect) cards state]
  ::  else
  =/  result  (clear-delegation booth-key participant-ship)
  [?~(effects.result effects (weld effects effects.result)) cards.result state.result]
::
++  clear-delegation
  |=  [booth-key=@t participant-ship=@p]
  ^-  [effects=(list json) cards=(list card) =_state]

  =/  participant-key  (crip "{<participant-ship>}")

  ::  participant is some other ship
  =/  booth-participants  (~(get by participants.state) booth-key)
  =/  booth-participants  ?~(booth-participants ~ (need booth-participants))
  :: =/  booth-participants  ?:(?=([%o *] booth-participants) p.booth-participants ~)
  =/  booth-participants  (~(del by booth-participants) participant-key)

  ::  is this participant a delegate?
  =/  booth-delegates  (~(get by delegates.state) booth-key)
  =/  booth-delegates  ?~(booth-delegates ~ (need booth-delegates))
  :: =/  booth-delegates  ?:(?=([%o *] booth-delegates) p.booth-delegates ~)

  ::  does the participant have a delegate record
  =/  delegate  (~(get by booth-delegates) participant-key)
  =/  delegate  ?~(delegate ~ (need delegate))

  ::  remove any record from the delegates.state store where the
  ::    delegate key is the participant being removed OR if the delegate
  ::    data contains a reference to the participant being deleted
  =/  booth-delegates=(map @t json)
  ?:  =(delegate ~)
    =/  booth-delegates=(map @t json)
    %-  ~(rep by booth-delegates)
    |=  [[key=@t jon=json] result=(map @t json)]
      =/  data  ?:(?=([%o *] jon) p.jon ~)
      =/  delegate  (~(get by data) 'delegate')
      ?~  delegate  result
      =/  delegate  (so:dejs:format (need delegate))
      ?.  =(delegate participant-key)
        (~(put by result) key jon)
      result
    booth-delegates
  ::  this participant is a delegate
  (~(del by booth-delegates) participant-key)
  ::

  =/  booth-proposals  (~(get by proposals.state) booth-key)
  =/  booth-proposals  ?~(booth-proposals ~ (need booth-proposals))
  :: =/  booth-proposals  ?:(?=([%o *] booth-proposals) p.booth-proposals ~)
  ::  get a list of all active proposals (status != 'closed')
  =/  active-proposals=(map @t json)
  %-  ~(rep by booth-proposals)
  |=  [[key=@t jon=json] result=(map @t json)]
    =/  data  ?:(?=([%o *] jon) p.jon ~)
    =/  status  (~(get by data) 'status')
    ?~  status
      ~&  >>  "{<dap.bowl>}: warning. proposal {<key>} has no status"
      result
    =/  status  (so:dejs:format (need status))
    ?.  =(status 'poll-closed')
      (~(put by result) key jon)
    result

  =/  booth-votes  (~(get by votes.state) booth-key)
  =/  booth-votes  ?~(booth-votes ~ (need booth-votes))

  %-  (log:util %info "{<dap.bowl>}: processing active proposals: {<active-proposals>}")
  =/  booth-votes
  %-  ~(rep by active-proposals)
  |:  [`[proposal-key=@t jon=json]`['' ~] booth-votes=`(map @t json)`booth-votes]
    =/  data  ?:(?=([%o *] jon) p.jon ~)
    =/  proposal-votes  (~(get by booth-votes) proposal-key)
    =/  proposal-votes  ?~(proposal-votes ~ (need proposal-votes))
    =/  proposal-votes  ?:(?=([%o *] proposal-votes) p.proposal-votes ~)
    =/  proposal-votes
    %-  ~(rep by proposal-votes)
    |:  [`[voter-key=@t jon=json]`['' ~] proposal-votes=`(map @t json)`proposal-votes]
      ?:  =(participant-key voter-key)
        (~(del by proposal-votes) voter-key)
      =/  vote-data  ?:(?=([%o *] jon) p.jon ~)
      =/  delegators  (~(get by vote-data) 'delegators')
      =/  delegators  ?~(delegators ~ (need delegators))
      =/  delegators  ?:(?=([%o *] delegators) p.delegators ~)
      ?:  (~(has by delegators) participant-key)
          (~(del by proposal-votes) voter-key)
        proposal-votes
    (~(put by booth-votes) proposal-key [%o proposal-votes])

  [~ ~ state(participants (~(put by participants.state) booth-key booth-participants), delegates (~(put by delegates.state) booth-key booth-delegates), votes (~(put by votes.state) booth-key booth-votes))]
--