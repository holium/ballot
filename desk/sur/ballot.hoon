|%

+$  choice  [label=@t description=@t action=@t]
+$  signature  [p=@ux q=@p r=@ud] :: [p=signature q=ship r=life]
+$  vote
  $:  status=?(%pending %recorded %counted)
      voter=ship
      choices=(list choice)
      created=@t
      =signature
  ==
--
