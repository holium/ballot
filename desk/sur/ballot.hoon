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

+$  effect
  $:  key=@t
      effect=@t
      resource=@t
      data=json
  ==

            [%booth %invite]
              (invite-api req payload)

            [%booth %accept]
              (accept-api req payload)

            [%booth %save]
              (save-booth-api req payload)

            [%proposal %save-proposal]
              (save-proposal-api req payload)

            [%proposal %delete-proposal]
              (delete-proposal-api req payload)

            [%proposal %cast-vote]
              (cast-vote-api req payload)

            [%participant %delete-participant]
              (delete-participant-api req payload)

            [%delegate %delegate]
              (delegate-api req payload)

            [%delegate %undelegate]
+$  booth-action
  $%  [%save]
      [%invite ]
      [%accept ]
  ==

::  proposal
+$  proposal-action-context
  $:  booth=@t
      proposal=@t
  ==
+$  proposal-action
  $%  [%save context=proposal-action-context]
      [%delete ]
      [%vote ]

::  participant
+$  participant-action-context
  $:  booth=@t
      participant=@t
  ==

+$  participant-action
  $%  [%delete context=participant-action-context]
  ==

  $:  context=(map @t json)
      action=@t
      resource=@t
      data=?(delegation)

+$  reaction
  $:  context=(map @t json)
      action=@t
      effects=(list effect)

      {"action":"delegate","resource":"delegate","context":{"booth":"~zod"},"data":{"delegate":"~bus"}}
{
    "json": {
        "context": {
            "participant": "~zod",
            "booth": "~zod"
        },
        "action": "delegate-reaction",
        "effects": [
            {
                "key": "~zod",
                "data": {
                    "delegate": "~bus",
                    "created": 1652274268498,
                    "sig": {
                        "voter": "~zod",
                        "life": 1,
                        "hash": "0x1.4f37.5627.ef81.cf83.95d1.859d.95b1.9593.f00b.bf82.8200.9726.0565.3004.b3bc.e2c5.72b8.9a70.b058.7912.7f56.871f.fa00.b347.e70c.5446.9537.dd63.a2a5.cf1f.3651.da6d.6f88.7c47.783d.334d.abd6.7306.d253.ccc6.e10d.1824.f55f.7001"
                    }
                },
                "effect": "add",
                "resource": "delegate"
            }
        ]
    },
    "id": 2,
    "response": "diff"
}
--
