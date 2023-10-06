import { IndexClient } from "candb-client-typescript/dist/IndexClient";
import { ActorClient } from "candb-client-typescript/dist/ActorClient";

import { idlFactory as IndexCanisterIDL } from "../declarations/index/index";
import { IndexCanister } from "../declarations/index/index.did";
import { BebbEntityService } from "../declarations/bebbentityservice/bebbentityservice.did";
import { idlFactory as BebbEntityServiceCanisterIDL } from "../declarations/bebbentityservice/index";
import { BebbBridgeService } from "../declarations/bebbbridgeservice/bebbbridgeservice.did";
import { idlFactory as BebbBridgeServiceCanisterIDL } from "../declarations/bebbbridgeservice/index";

export function intializeIndexClient(isLocal: boolean): IndexClient<IndexCanister> {
  const host = isLocal ? "http://127.0.0.1:4943" : "https://ic0.app";
  // canisterId of your index canister
  const canisterId = isLocal ? process.env.INDEX_CANISTER_ID : "<prod_canister_id>";
  return new IndexClient<IndexCanister>({
    IDL: IndexCanisterIDL,
    canisterId, 
    agentOptions: {
      host,
    },
  })
};

export function initializeBebbEntityServiceClient(isLocal: boolean, indexClient: IndexClient<IndexCanister>): ActorClient<IndexCanister, BebbEntityService> {
  const host = isLocal ? "http://127.0.0.1:8000" : "https://ic0.app";
  return new ActorClient<IndexCanister, BebbEntityService>({
    actorOptions: {
      IDL: BebbEntityServiceCanisterIDL,
      agentOptions: {
        host,
      }
    },
    indexClient, 
  })
};

export function initializeBebbBridgeServiceClient(isLocal: boolean, indexClient: IndexClient<IndexCanister>): ActorClient<IndexCanister, BebbBridgeService> {
  const host = isLocal ? "http://127.0.0.1:8000" : "https://ic0.app";
  return new ActorClient<IndexCanister, BebbBridgeService>({
    actorOptions: {
      IDL: BebbBridgeServiceCanisterIDL,
      agentOptions: {
        host,
      }
    },
    indexClient, 
  })
};