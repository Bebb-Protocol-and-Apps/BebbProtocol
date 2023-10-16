import { IndexClient } from "./candb-client/IndexClient";
import { ActorClient } from "./candb-client/ActorClient";

import type { Identity } from "@dfinity/agent";

import { idlFactory as IndexCanisterIDL } from "../../declarations/index/index";
import { IndexCanister } from "../../declarations/index/index.did";
import { BebbEntityService } from "../../declarations/bebbentityservice/bebbentityservice.did";
import { idlFactory as BebbEntityServiceCanisterIDL } from "../../declarations/bebbentityservice/index";
import { BebbBridgeService } from "../../declarations/bebbbridgeservice/bebbbridgeservice.did";
import { idlFactory as BebbBridgeServiceCanisterIDL } from "../../declarations/bebbbridgeservice/index";

console.log("Debug client process.env.NODE_ENV ", process.env.NODE_ENV);
console.log("Debug client process.env.DFX_NETWORK ", process.env.DFX_NETWORK);

let HOST =
  process.env.NODE_ENV !== "development"
    ? "https://ic0.app"
    : "http://localhost:4943";

let appDomain = ".icp0.io";

if (process.env.DFX_NETWORK === "ic") {
  // production
  HOST = "https://icp0.io";
  appDomain = ".icp0.io";
} else if (process.env.DFX_NETWORK === "local") {
  // on localhost
  HOST = "http://localhost:4943";
} else if (process.env.DFX_NETWORK === "development") {
  // development canisters on mainnet (for network development)
  HOST = "https://icp0.io";
  appDomain = ".icp0.io";
} else if (process.env.DFX_NETWORK === "testing") {
  // testing canisters on mainnet (for network testing)
  HOST = "https://icp0.io";
  appDomain = ".icp0.io";
} else if (process.env.DFX_NETWORK === "alexStaging") {
  // testing canisters on mainnet (for network testing for Alex)
  HOST = "https://icp0.io";
  appDomain = ".icp0.io";
} else {
  HOST = "https://icp0.io";
};

export function intializeIndexClient(isLocal: boolean, identity: Identity = null): IndexClient<IndexCanister> {
  console.log("Debug intializeIndexClient isLocal ", isLocal);
  console.log("Debug intializeIndexClient identity ", identity);
  console.log("Debug intializeIndexClient process.env.INDEX_CANISTER_ID ", process.env.INDEX_CANISTER_ID);
  // canisterId of your index canister
  const canisterId = isLocal ? process.env.INDEX_CANISTER_ID : "c2yuv-naaaa-aaaam-abumq-cai";
  console.log("Debug intializeIndexClient canisterId ", canisterId);
  if (identity) {
    return new IndexClient<IndexCanister>({
      IDL: IndexCanisterIDL,
      canisterId, 
      agentOptions: {
        identity,
        host: HOST,
      },
    })
  };
  return new IndexClient<IndexCanister>({
    IDL: IndexCanisterIDL,
    canisterId, 
    agentOptions: {
      host: HOST,
    },
  })
};

export function initializeBebbEntityServiceClient(isLocal: boolean, indexClient: IndexClient<IndexCanister>, identity: Identity = null): ActorClient<IndexCanister, BebbEntityService> {
  if (identity) {
    return new ActorClient<IndexCanister, BebbEntityService>({
      actorOptions: {
        IDL: BebbEntityServiceCanisterIDL,
        agentOptions: {
          identity,
          host: HOST,
        }
      },
      indexClient, 
    })
  };
  return new ActorClient<IndexCanister, BebbEntityService>({
    actorOptions: {
      IDL: BebbEntityServiceCanisterIDL,
      agentOptions: {
        host: HOST,
      }
    },
    indexClient, 
  })
};

export function initializeBebbBridgeServiceClient(isLocal: boolean, indexClient: IndexClient<IndexCanister>, identity: Identity = null): ActorClient<IndexCanister, BebbBridgeService> {
  if (identity) {
    return new ActorClient<IndexCanister, BebbBridgeService>({
      actorOptions: {
        IDL: BebbBridgeServiceCanisterIDL,
        agentOptions: {
          identity,
          host: HOST,
        }
      },
      indexClient, 
    })
  };
  return new ActorClient<IndexCanister, BebbBridgeService>({
    actorOptions: {
      IDL: BebbBridgeServiceCanisterIDL,
      agentOptions: {
        host: HOST,
      }
    },
    indexClient, 
  })
};