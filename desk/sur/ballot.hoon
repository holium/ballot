|%

+$  choice  [label=@t description=@t action=@t]
+$  signature  [p=@ux q=ship r=@u] :: [sig=signature ship=ship life=life]
+$  vote
  $:  status=?(%pending %recorded %counted)
      voter=ship
      choices=(list choice)
      created=@t
      =signature
  ==
--
