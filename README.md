# Bebb Protocol
A decentralized protocol to store and manage a form of hyperlinks between all different kinds of nodes.

This protocol, which enables everyone to create and retrieve connections, build applications on top of it and together establish a wide-spanning network of connections between different kinds of nodes, will serve as a fundamental building block of proof-of-concept applications building on top (e.g. Personal NFT Gallery).

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

## Testing Backend Changes
The majority of the changes are tested via the candid backend. To access the Candid backend, after you run
```bash
dfx deploy
```
as shown above. It will provide the URL to the canister backend Candid UI. You can test the API calls through that interface

## Testing Frontend Changes

If you are making frontend changes, you can start a development server with

```bash
npm start
```

Which will start a server at `http://localhost:8080`, proxying API requests to the replica at port 8000.

Note: while the protocol doesn't need or have a UI, the asset's canister here serves as a simple way of testing the protocol by simulating how an application might create Entities and connect them via Bridges.
