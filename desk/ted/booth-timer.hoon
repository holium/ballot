:: ************************************************
::
::  @author:  ~lodlev-migdev
::  @purpose:
::    Booth timer thread used to manage a booth start/end poll timer.
::  @args:
::    accepts a date (@da) value used to initialize the wait task
::
::   ref:  https://urbit.org/docs/arvo/behn/examples
::
:: ************************************************
/-  spider
/+  *strandio
=,  strand=strand:spider
^-  thread:spider
|=  arg=vase
=/  m  (strand ,vase)
^-  form:m
::  date/time (@da) value used as timeout (moment in future when timer will notify)
=/  timeout=@da  !<(@da arg)
=/  =task:behn  [%wait timeout]
=/  =card:agent:gall  [%pass /timer %arvo %b task]
;<  ~  bind:m  (send-raw-card card)
;<  res=(pair wire sign-arvo)  bind:m  take-sign-arvo
?>  ?=([%timer ~] p.res)
?>  ?=([%behn %wake *] q.res)
%-  (slog ~[leaf+"Gift: {<+.q.res>}"])
?~  error.q.res
  :: %-  (slog ~[leaf+"Time elapsed: {<`@dr`(sub t2 t1)>}"])
  %-  (slog ~[leaf+"Time elapsed: {<timeout>}"])

  (pure:m !>(~))
%-  (slog u.error.q.res)
(pure:m !>(~))