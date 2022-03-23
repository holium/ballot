^?
|%
::
::  Has config data for various blockchains supported
::
+$  blockchain  
  $%  [%ethereum =ethereum-networks]
      [%uqbar =uqbar-networks] 
  ==
+$  ethereum-networks  
  $%  [%mainnet rpc=@ta chain-id=@s block-explorer=@ta]
      [%testnet rcp=@ta chain-id=@s block-explorer=@ta]
  ==
+$  uqbar-networks  
  $%  [%mainnet helix-id=@s block-explorer=@ta]
      [%testnet helix-id=@s block-explorer=@ta]
  ==
+$  address
  $%  [%base58 @uc]
      [%bech32 cord]
  ==
--