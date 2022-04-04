/-  ballot
|%
::  cast-vote-api - 1022
++  jael-scry
  |*  [=mold our=ship desk=term now=time =path]
  .^  mold
    %j
    (scot %p our)
    desk
    (scot %da now)
    path
  ==
::
++  sign
  |=  [our=ship now=time data=json]
  ^-  signature:ballot
  =/  our-life             (jael-scry ,=life our %life now /(scot %p our))
  =/  our-private-key      (jael-scry ,=ring our %vein now /(scot %ud our-life))
  =/  our-crub             (nol:nu:crub:crypto our-private-key)   :: create a +crub core
  =/  signed               `@ux`(sign:as:our-crub (jam data))     :: signs msg
  ::  should probably handle a null return in the case of bad key
  `signature:ballot`[signed our our-life]
::
++  verify
  ::  TODO handle cases where the life is not found
  |=  [our=ship now=time signature=signature:ballot]
  =/  participant-pub-key      -:+:(jael-scry ,=[life=life pub=pass unit=(unit @ux)] our %deed now /(scot %p q.signature)/(scot %ud r.signature))
  =/  participant-crub         (com:nu:crub:crypto pub.participant-pub-key)  :: create a +crub core
  =/  verified                 +:(sure:as:participant-crub p.signature)  :: should be cast to vote data type
  :: ~&  >>  [verified]
  :: ::  will be null if not valid, so check for that
  verified

--
