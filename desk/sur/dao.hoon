/-  *blockchain
^?
|%
::
::  dao types for storing metadata from various chains
::
+$  dao
  $:  name=@t
      =address
      =blockchain
      =token
      =governance
      members=(map address ship)
  ==
::
::  proposal types
::
+$  proposal       [deposit=@r reward=@r voting-period=@t daily-limit=@s grace-period=@s]   ::  [deposit=0.01 reward=0.01 voting-period=[period=7 unit=%days] daily-limit=7 grace-period=3]
+$  voting-period  [period=@s unit=?(%hours %days %weeks %months)]                          ::  [period=7 unit=%days]
::
::  treasury types
::
+$  token  [name=@t symbol=@t icon-url=@ta]
+$  token-allocation  ?(%equal-shares %addresses)
::
+$  permissions         (list permissions)
+$  permission-types    ?(%dao-admin %group-admin %proposals %treasury %member %applicant)
::
+$  governance
  $%  [%monarchy monarch=ship =peerage =proposal roles=(map ship peerage-level)]
      [%democracy =support =quorum =representation =proposal]
      :: [%oligarchy =booths]
  ==
::
::  %monarchy governance types
::
+$  peerage-level  
  $%  [%duke alt-name=@t =permissions]
      [%earl alt-name=@t =permissions]
      [%knight alt-name=@t =permissions]
      [%peasant alt-name=@t =permissions]
  ==
+$  peerage             (list peerage-level)
::
::  %democracy governance types
::
+$  support  @r
+$  quorum   @r
+$  representation  ?(%token-stake %one-vote)
::  dao actions:
::    Ideally, we would import dynamically the RPC commands from the contract
::
:: +$  dao-action
::   $%  [%add-member ]
::       [%kick-member ]
::   ==
::  updates
:: 
::  syncs
--






