# NewWave Protocol v0.0.2

A decentralized protocol to store and manage a form of hyperlinks between all different kinds of nodes.

This protocol, which enables everyone to create and retrieve connections, build applications on top of it and together establish a wide-spanning network of connections between different kinds of nodes, will serve as a fundamental building block of proof-of-concept applications building on top (e.g. Personal NFT Gallery).

0.0.2 represents an initial production-scale protocol version; its architecture breaks down responsibilities into different modules which are implemented as separate canisters. Combined, these canisters and their calls amongst each other form the protocol and provide its core envisioned functionality. This includes creating and retrieving an Entity (node), creating and retrieving a Bridge (connection) and retrieving Bridges attached to an Entity. The file main.mo defines these respective functions along others and serves as the central entry point to the protocol. 

This multi-canister architecture was chosen to allow the protocol to scale out automatically if needed (e.g. by spinning up new Entity or Bridge storage canisters) and aims to improve throughput by utilizing a collection of dedicated canisters for the different functions supported. Due to inter-canister query calls not being supported yet by the IC (and logical query calls thus having to be executed like update calls), this design would not be usable in practice as of now as the time it takes to retrieve data from the protocol appears too long for any meaningful user-interaction-based application. While users probably have a slightly higher tolerance in terms of responsiveness of update calls, the multi-level canister approach as developed (i.e. a create operation involves 7 canisters for Entities and up to 9 canisters for Bridges) would still be too slow for a reasonable user experience.

Version 0.0.3 will therefore implement the same functionality with a mono-canister architecture sacrificing an arguably superior protocol design approach in favor of practicality.

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
TODO: Replace with identifier of canister f.e.
TODO: should bridge id be assignable? probably: always assign random id
TODO: fill as stringified object with fields as listed in listOfEntitySpecificFieldKeys
TODO: state has to be correctly assigned (e.g. Confirmed if created by Entity owner)
TODO: define bridge categories
TODO: determine which category's list/categories' lists in entry to return [multiple]
TODO: potentially update entityToCreate fields (might vary depending on EntityType)
TODO: potentially assign final internal_id to Entity (might vary depending on EntityType)
TODO: mark functions as queries (all files) --> no inter-canister queries currently, check back later
TODO: possible to return promise? Would this speed up this canister? e.g. try ... : async (async Entity.Entity) [multiple, all files]
