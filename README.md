# NewWave Protocol v0.0.3

A decentralized protocol to store and manage a form of hyperlinks between all different kinds of nodes.

This protocol, which enables everyone to create and retrieve connections, build applications on top of it and together establish a wide-spanning network of connections between different kinds of nodes, will serve as a fundamental building block of proof-of-concept applications building on top (e.g. Personal NFT Gallery).

Version 0.0.3 implements the same functionality as v0.0.2 but does so with a mono-canister architecture (versus v0.0.2's multi-canister approach resembling a microservices architecture) sacrificing an arguably superior protocol design in favor of practicality. While v0.0.2's architecture was chosen to allow the protocol to scale out automatically if needed (e.g. by spinning up new Entity or Bridge storage canisters) and aimed to improve throughput by utilizing a collection of dedicated canisters for the different functions supported, inter-canister query calls not being supported yet by the IC (and logical query calls thus having to be executed like update calls) rendered this design unusable in practice as of now as the time it takes to retrieve data from the protocol appeared too long for any meaningful user-interaction-based application. While users probably have a slightly higher tolerance in terms of responsiveness of update calls, the multi-level canister approach as developed (i.e. a create operation involves 7 canisters for Entities and up to 9 canisters for Bridges) would still be too slow for a reasonable user experience. v0.0.3 thus aims to speed up the protocol's response times significantly by circumventing any inter-canister calls and relying on a single canister to provide all functionality.

The protocol's functionality includes creating and retrieving an Entity (node), creating and retrieving a Bridge (connection) and retrieving Bridges attached to an Entity. The file main.mo defines these respective functions along others and serves as the central entry point to the protocol. 

The goal of these implementation efforts and different versions is to achieve a production-scale protocol version which may be used by different applications building on top and support their respective use cases reliably.

## Running the project locally

If you want to test your project locally, you can use the following commands:

```bash
# Starts the replica, running in the background
dfx start --background

# Deploys your canisters to the replica and generates your candid interface
dfx deploy
```

Once the job completes, your application will be available at `http://localhost:8000?canisterId={asset_canister_id}`.

Additionally, if you are making frontend changes, you can start a development server with

```bash
npm start
```

Which will start a server at `http://localhost:8080`, proxying API requests to the replica at port 8000.

Note: while the protocol doesn't need or have a UI, the asset's canister here serves as a simple way of testing the protocol by simulating how an application might create Entities and connect them via Bridges.

Call from CLI (local):
dfx canister call newwave create_entity "(record { _internalId = null; _creator = null; _entityType = variant {Webasset}; })"
dfx canister call newwave get_entity '("D6C65674-91BE-170D-BCC0-000000000000")'
dfx canister call newwave create_bridge '(record { _internalId = null; _creator = null; _entityType = variant {Webasset}; _bridgeType = variant {OwnerCreated}; _fromEntityId = "20621F98-91B0-170D-B0F5-000000000000"; _toEntityId = "D6C65674-91BE-170D-BCC0-000000000000";  })'
dfx canister call newwave get_bridge '("76CBDF90-9246-170D-9C79-000000000000")'
dfx canister call newwave get_bridge_ids_by_entity_id '("D6C65674-91BE-170D-BCC0-000000000000", true, true, true)'
dfx canister call newwave get_bridges_by_entity_id '("D6C65674-91BE-170D-BCC0-000000000000", true, true, true)'
 dfx canister call newwave create_entity_and_bridge '(record { _internalId = null; _creator = null; _entityType = variant {Webasset}; }, record { _internalId = null; _creator = null; _entityType = variant {Webasset}; _bridgeType = variant {OwnerCreated}; _fromEntityId = "20621F98-91B0-170D-B0F5-000000000000"; _toEntityId = "D6C65674-91BE-170D-BCC0-000000000000";  })'
 dfx canister call newwave get_bridged_entities_by_entity_id '("D6C65674-91BE-170D-BCC0-000000000000", true, true, true)'
 dfx canister call newwave get_entity_and_bridge_ids '("D6C65674-91BE-170D-BCC0-000000000000", true, true, true)'

Call from CLI (IC):
 first deploy to IC mainnet: dfx deploy --network ic
 dfx canister --network ic call newwave create_entity "(record { _internalId = null; _creator = null; _entityType = variant {Webasset}; })"
 dfx canister --network ic call newwave get_entity '("C923CD99-92E1-170D-908C-000000000000")'
 dfx canister --network ic call newwave create_bridge '(record { _internalId = null; _creator = null; _entityType = variant {Webasset}; _bridgeType = variant {OwnerCreated}; _fromEntityId = "01A90437-92F8-170D-9F6C-000000000000"; _toEntityId = "C923CD99-92E1-170D-908C-000000000000";  })'
 dfx canister --network ic call newwave get_bridge '("E64582AA-9302-170D-A43D-000000000000")'
 dfx canister --network ic call newwave get_bridge_ids_by_entity_id '("C923CD99-92E1-170D-908C-000000000000", true, true, true)'
dfx canister --network ic call newwave get_bridges_by_entity_id '("C923CD99-92E1-170D-908C-000000000000", true, true, true)'
dfx canister --network ic call newwave create_entity_and_bridge '(record { _internalId = null; _creator = null; _entityType = variant {Person}; }, record { _internalId = null; _creator = null; _entityType = variant {Webasset}; _bridgeType = variant {OwnerCreated}; _fromEntityId = "C923CD99-92E1-170D-908C-000000000000"; _toEntityId = "";  })'
 dfx canister --network ic call newwave get_bridged_entities_by_entity_id '("C923CD99-92E1-170D-908C-000000000000", true, true, true)'
 dfx canister --network ic call newwave get_entity_and_bridge_ids '("C923CD99-92E1-170D-908C-000000000000", true, true, true)'

Top up cycles:
dfx identity --network=ic get-wallet
dfx wallet --network ic balance
dfx canister --network ic status newwave
dfx canister --network ic --wallet 3v5vy-2aaaa-aaaai-aapla-cai deposit-cycles 3000000000000 newwave

2022-11-15: topped up 3.3T cycles, has balance of 7.2T (2023-02-20: basically hasn't changed)

Fund wallet with cycles (from ICP): https://medium.com/dfinity/internet-computer-basics-part-3-funding-a-cycles-wallet-a724efebd111

## Dev notes

dynamically expand storage canisters: https://github.com/dfinity/examples/tree/master/motoko/classes
work with subaccounts: https://github.com/krpeacock/invoice-canister 

using Entity type cuts other fields from entities -> flexible input and output format needed
with Text? like stringifying object and parsing Text to object of entity type
https://forum.dfinity.org/t/how-do-i-send-a-blob-from-js-frontend-to-motoko-backend/9148/2
https://itnext.io/typescript-utilities-for-candid-bf5bdd92a9a3
https://github.com/dfinity/motoko-base/blob/master/src/Blob.mo
with HashMap? instead of object type use HashMap input and convert key-value pairs to entity type
https://github.com/dfinity/motoko-base/blob/master/src/HashMap.mo
having HashMap<Text,Text> as a field on Entity gives error: is or contains non-shared type Text -> ()
function on Entity to retrieve entityType specific fields (or a static field)
work with JSON: https://github.com/Toniq-Labs/creator-nfts/blob/main/canisters/nft/main.mo
UI sends in JSON encoded as Blob: https://github.com/Toniq-Labs/creator-nfts/blob/main/frontend/src/canisters/nft/minting.ts
potentially String / Text also works (i.e. no en-/decoding) --> work with Text for now, probably change to Blob later (after finding out about its potential benefits)

Generate ID:
Motoko library with example: https://github.com/aviate-labs/uuid.mo/tree/main/example
import with vessel package manager: https://github.com/dfinity/vessel
use synchronous:
private let rr = XorShift.toReader(XorShift.XorShift64(null));
	private let c : [Nat8] = [0, 0, 0, 0, 0, 0]; // Replace with identifier of canister f.e.
	private let se = Source.Source(rr, c);
    let id = se.new();
	UUID.toText(id); 
to get identifier of canister: get canister principal (let canisterId = Principal.fromActor(Invoice);), Principal.toBlob(p), Blob to [Nat8] (https://forum.dfinity.org/t/type-mismatch-in-ledger-canister-and-invoice-canister/13300/4)

## TODOs
TODO: bug in create_entity_and_bridge: Entity's and Bridge's internalIds are the same
TODO: bug in create functions: canister's id is taken as owner and creator
TODO: update and delete functions
TODO: Replace with identifier of canister f.e.
TODO: should bridge id be assignable? probably: always assign random id
TODO: fill as stringified object with fields as listed in listOfEntitySpecificFieldKeys
TODO: state has to be correctly assigned (e.g. Confirmed if created by Entity owner)
TODO: define bridge categories
TODO: determine which category's list/categories' lists in entry to return [multiple]
TODO: potentially update entityToCreate fields (might vary depending on EntityType)
TODO: potentially assign final internal_id to Entity (might vary depending on EntityType)
TODO: possible to return promise? Would this speed up this canister? e.g. try ... : async (async Entity.Entity) [multiple, all files]
