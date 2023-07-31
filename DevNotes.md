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