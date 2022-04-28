/-  *plugin
|%                                      ::  The |% rune produces a core

++  return-error
  |=  [data=json]
  ^-  (unit action-result)
  (some `action-result`[success=%.n data=data effects=~])

--