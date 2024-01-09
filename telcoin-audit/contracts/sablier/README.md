# Protocol

This contract pertains to the governance structure in a broader sense. Generally speaking, they will not be created with a specific 3rd party contract in mind, but may require specific Telcoin integrations.

## Contracts

### CouncilMember

This NFT represents a seat on the council. It is created to lay atop a Sablier Streaming NFT. This will allow council members to retrieve rewards for their services, as well as granting them voting rights.

### Other Contracts

`TestStream` is a simplified version of the Sablier stream to allow for easy testing.

Both `ISablierV2ProxyTarget` and `IPRBProxy` are interfaces created by external entities. It is included here so that the Telcoin contract can correctly integrate with other systems.

## References

- [Sablier Docs](https://docs.sablier.com)
- [Sablier GitHub](https://github.com/sablier-labs)
