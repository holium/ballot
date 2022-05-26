/-  ballot, plugin
|_  [=bowl:gall store=state-1:ballot]
++  eca
  |=  [[booth-key=@t proposal-key=@t] action=@t action-data=json payload=json]
  :: ^-  [(list card) (map @t json)]
  ^-  action-result:plugin

  =/  lib-file=path  /(scot %p our.bowl)/(scot %tas dap.bowl)/(scot %da now.bowl)/lib/(scot %tas dap.bowl)/custom-actions/(scot %tas action)/hoon

  ?.  .^(? %cu lib-file)
    (mean leaf+"{<dap.bowl>}: resource action lib file {<lib-file>} not found" ~)

  =/  action-lib  .^([p=type q=*] %ca lib-file)
  =/  on-func  (slam (slap action-lib [%limb %on]) !>([bowl store [booth-key proposal-key]]))
  =/  result  !<(action-result:plugin (slam (slap on-func [%limb %action]) !>([action-data payload])))

  result
--