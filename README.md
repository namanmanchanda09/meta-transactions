# meta-transactions

This is an example of how meta-tx works. Demonstrated how gas-less NFT minting works using OZs `ERC2771Context`.

### Draft

Two contracts have been implemented 
  1. The **Relayer** or the forwarder that implements `EIP712` to verify and execute a structured hash data.
  2. The actual **MinimalBAYC** contract that does the minting. This implements `ERC2771Context` for verifying the relayer.

### Quick Implementation Idea

*The call flow*

Sender (sign's a message to be executed by someone who can pay for gas)

```

Gaspayer --(take the sig and make a Tx)--> Relayer --(verify the sig and mints the NFT)--> BAYC

```


### Tests

Setup project by running `forge build`, followed by -

```

forge test --match-test testExecute

```




