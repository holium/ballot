|%

+$  booths  (map @t json)

+$  proposals  (map @t (map @t json))

+$  participants  (map @t (map @t json))

+$  mq  (map @t json)

+$  invitations  (map @t (set @p))

+$  state-0  [%0 authentication=@t mq=(map @t json) polls=(map @t (map @t json)) booths=(map @t json) proposals=(map @t (map @t json)) participants=(map @t (map @t json)) invitations=(map @t (set @p)) votes=(map @t (map @t json))]
+$  state-1  [%1 authentication=@t mq=(map @t json) polls=(map @t (map @t json)) booths=(map @t json) proposals=(map @t (map @t json)) participants=(map @t (map @t json)) invitations=(map @t (set @p)) votes=(map @t (map @t json)) delegates=(map @t (map @t json)) custom-actions=(map @t json)]

+$  base-data
  $:  remote=?(%.y %.n)
      =ship
  ==

+$  booth-action
  $:  action=?(%create %update %delete %join %leave)
      data=base-data
  ==

+$  proposal-action
  $:  action=?(%create %update %delete)
      data=base-data
  ==

+$  participant-action
  $:  action=?(%create %update %delete)
      data=base-data
  ==

+$  resource-action
  $:  action=?(booth-action proposal-action participant-action)
      resource=@t
      key=@t
  ==

--