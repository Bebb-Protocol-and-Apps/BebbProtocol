# Bebb Protocol
A decentralized protocol to store and manage a form of hyperlinks between all different kinds of nodes.

This protocol, which enables everyone to create and retrieve connections, build applications on top of it and together establish a wide-spanning network of connections between different kinds of nodes, will serve as a fundamental building block of proof-of-concept applications building on top (e.g. Personal NFT Gallery).

The protocol's functionality includes creating and retrieving an Entity (node), creating and retrieving a Bridge (connection) and retrieving Bridges attached to an Entity. The file main.mo defines these respective functions along others and serves as the central entry point to the protocol. 

The goal of these implementation efforts and different versions is to achieve a production-scale protocol version which may be used by different applications building on top and support their respective use cases reliably.

## Running the project locally

If you want to test your project locally, you can use the following commands:
Note: Local development currently won't work due to functionality that only works on the mainnet

```bash
# Starts the replica, running in the background
dfx start --background

# Deploys your canisters to the replica and generates your candid interface
dfx deploy index
dfx deploy frontend
```

During development, whenever the code for Index or Service canisters change, we need to run a fresh replica (and also regenerate the candid files):
```bash
dfx stop
dfx start --background --clean
dfx generate
dfx deploy index
dfx deploy frontend
npm run start
```

## Deploy Bebb to the mainnet

Development: 
```bash 
dfx deploy index --network development
cd frontend  
dfx deploy frontend --network development
dfx deploy --network development
```

Alex Staging
```bash
dfx deploy index --network alexStaging
cd frontend
dfx deploy frontend --network alexStaging
dfx deploy --network alexStaging
```

## Testing Backend Changes
The majority of the changes are tested via the frontend canister that is deployed with the backend canister above

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

# Upgrading the backend canisters
First upgrade the backend canister
```bash
dfx deploy index --network <network>
```
Then build the service canister you want to upgrade
```bash
dfx build bebbentityservice --network <network>
dfx build bebbbridgeservice --network <network>
```
Go to the management scripts
```bash
cd management_scripts
npm install
npm run upgrade
```
