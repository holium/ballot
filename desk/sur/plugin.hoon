^?
|%
+$  call-context
    $:  =bowl:gall
        args=(map @t json)
        store=(map @t json)
        payload=json
    ==

+$  store  (map @t json)

+$  action-result
    $:  success=?
        :: contains error data when success is %.n; otherwise contains response data data
        data=json
        effects=(list card:agent:gall)
    ==
--

