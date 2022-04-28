/-  *plugin
|%                                      ::  The |% rune produces a core

++  return-error
  |=  [store=json data=json]
  ^-  action-result
  `action-result`[success=%.n data=data store=store effects=~]

++  to-map
  |=  [jon=json]
  ^-  (map @t json)
  ?~  jon  ~
  ?>  ?=(%o -.jon)
  p.jon
--