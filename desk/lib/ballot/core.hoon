/-  ballot-api
/+  booth-api=ballot-booth-api
|%

+$  card  card:agent:gall

+$  handler
  $:  p=path  :: path to hoon file with handling code
      v=(unit hoon)  :: vase loaded from p
  ==

--

|_  =bowl:gall

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

++  send-response
  |=  [req=(pair @ta inbound-request:eyre) result=action-api-result:ballot-api]
  ^-  (list card)

  ::  encode the proposal as a json string
  =/  body  (crip (en-json:html data.result))

  ::  convert the string to a form that arvo will understand
  =/  data=octs
        (as-octs:mimes:html body)

  ::  create the response
  =/  =response-header:http
    :-  code.result
    :~  ['Content-Type' 'application/json']
    ==

  :~
    [%give %fact [/http-response/[p.req]]~ %http-response-header !>(response-header)]
    [%give %fact [/http-response/[p.req]]~ %http-response-data !>(`data)]
    [%give %kick [/http-response/[p.req]]~ ~]
  ==

++  send-wire-error
  |=  [payload=json]
  ^-  (list card)

  ~&  >>>  "core:ballot => error, {<payload>}"

  `(list card)`~

++  handle-wire
  |=  [payload=json]
  ^-  (list card)

  =/  payload-data  ((om json):dejs:format payload)

  =/  resource  (~(get by payload-data) 'resource')

  :: ?+  resource  (send-wire-error 'resource not found')

  ::   %'booth'  (~(on-wire booth-api bowl) payload)
  ::   :: %'proposal'  (~(on-wire booth-api bowl) payload-data)
  ::   :: %'participant'  (~(on-wire booth-api bowl) payload-data)

  :: ==
  ~

++  handle-api-request
  |=  [req=(pair @ta inbound-request:eyre)]
  ^-  (list card)

  %-  (slog leaf+"ballot: [on-poke] => processing request at endpoint {<(stab url.request.q.req)>}" ~)

  :: parse query string portion of url into map of arguments (key/value pair)
  =/  query-args
        (my q:(need `(unit (pair pork:eyre quay:eyre))`(rush url.request.q.req ;~(plug apat:de-purl:html yque:de-purl:html))))

  =/  path  (stab url.request.q.req)
  =/  payload  (extract-payload req)

  ?+  path  ~ :: (send-response req 'route not found')

    [%ballot %api %booths ~]
      (~(on-request booth-api bowl) req query-args payload)

    [%ballot %api %booths @ ~]
      (~(on-request booth-api bowl) req query-args payload)


    :: [%ballot %api %booths @ %proposals * ~]
    :: [%ballot %api %booths @ %proposals @ ~]
    ::   (on-request:booth-api req query-args payload)

    :: [%ballot %api %booths @ %participants * ~]
    :: [%ballot %api %booths @ %participants @ ~]
    ::   (on-request:booth-api req query-args payload)

    :: [%ballot %api %booths @ ~]
    ::   =/  key  (key-from-path:util i.t.t.t.path)

    ::   ?+  method.request.q.req

    ::     %'PUT'     (on-put:booth-api req query-args payload ?~(key ~ (need key)))
    ::     %'DELETE'  (on-delete:booth-api req query-args payload)
    ::     %'POST'    (on-post:booth-api req query-args payload)

  ==

--