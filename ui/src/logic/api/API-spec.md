## vote api

Record (cast) a vote by the ship on a booth/proposal.

#### Request signature:

note: key values are part of each object returned by API and/or scry calls. Check the payload for the key attribute.

```
/ballot/api/booths/<booth-key>/proposals/<proposal-key>/vote

booth-key - booth key value
proposal-key - proposal key value
```

Response signature - JSON contract with following elements

```json
{
  "participant": "<parcipant-key>",
  // the label of the choice the participant made
  //   (e.g. 'Yes' or 'No')
  "choiceLabel": "<choice label>", // e.g. 'Yes' | 'No'
  //  epoch time of vote (unsigned integer)
  "caston": "<timestamp>"
}
```
