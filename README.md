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
dfx deploy index
dfx deploy bebb
```

## Different Stages
Local:
dfx deploy

Development:
dfx deploy index --network development
In frontend folder: dfx deploy frontend --network development
dfx deploy --network development

Testing:
dfx deploy --network testing

Production:
dfx deploy --network ic

## Testing Backend Changes
The majority of the changes are tested via the candid backend. To access the Candid backend, after you run
```bash
dfx deploy
```
as shown above. It will provide the URL to the canister backend Candid UI. You can test the API calls through that interface

## Testing Frontend Changes

In order for the frontend to talk to the backend, we need to copy over the backend canister candid declaration files. From the root hello-candb directory run
```bash
npm run refresh-declarations
```

Let’s navigate to the frontend directory and install its code dependencies
```bash
cd frontend; npm install
```

Start up your frontend
```bash
npm run start
```

Now you can navigate to localhost:8080 to interact with the frontend!