/-  ballot-api
/+  util=ballot-util
|%
+$  card  card:agent:gall
--

|_  =bowl:gall

++  on-wire
  |=  [payload=json]
  ^-  (list card)

  `(list card)`~

++  on-request
  |=  [req=(pair @ta inbound-request:eyre) query-args=(map @t @t) data=(map @t json)]
  ^-  (list card)

  ~

  :: =/  path  (stab url.request.q.req)
  :: =/  key  ~  :: (to-key:util i.t.t.t.path)

  :: ?+  method.request.q.req  (send-api-error 'method not supported')

  ::   %'POST'    (on-post req query-args payload key)

  :: ==

++  on-get
  |=  [req=(pair @ta inbound-request:eyre) args=(map @t @t) data=(map @t json)]
  ^-  action-api-result:ballot-api

  =|  result=action-api-result:ballot-api
  =.  code.result     200
  =.  data.result     ~
  =.  effects.result  ~

  [result]

++  on-put
  |=  [req=(pair @ta inbound-request:eyre) args=(map @t @t) data=(map @t json)]
  ^-  action-api-result:ballot-api

  =|  result=action-api-result:ballot-api
  =.  code.result     200
  =.  data.result     ~
  =.  effects.result  ~

  [result]

++  on-post
  |=  [req=(pair @ta inbound-request:eyre) args=(map @t @t) data=(map @t json) key=(unit @t)]
  ^-  action-api-result:ballot-api

  =|  result=action-api-result:ballot-api
  =.  code.result     200
  =.  data.result     ~
  =.  effects.result  ~

  [result]

++  on-delete
  |=  [req=(pair @ta inbound-request:eyre) args=(map @t @t) data=(map @t json)]
  ^-  action-api-result:ballot-api

  =|  result=action-api-result:ballot-api
  =.  code.result     200
  =.  data.result     ~
  =.  effects.result  ~

  [result]

--