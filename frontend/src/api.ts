import { ActorClient } from "candb-client-typescript/dist/ActorClient";

import { IndexCanister } from "../declarations/index/index.did";

import {
  BebbEntityService,
  EntityInitiationObject,
} from "../declarations/bebbentityservice/bebbentityservice.did";
import {
  BebbBridgeService,
  BridgeInitiationObject
} from "../declarations/bebbbridgeservice/bebbbridgeservice.did";

export async function getBebbEntity(bebbServiceClient: ActorClient<IndexCanister, BebbEntityService>, partition: string, name: string) {
  let pk = `${partition}#`;
  let entityQueryResults = await bebbServiceClient.query<BebbEntityService["get_entity"]>(
    pk,
    (actor) => actor.get_entity(name)
  );

  for (let settledResult of entityQueryResults) {
    // handle settled result if fulfilled
    if (settledResult.status === "fulfilled") {
      // handle candid returned optional type (string[] or string)
      return Array.isArray(settledResult.value) ? settledResult.value[0] : settledResult.value
    } 
  }
  
  return "Entity does not exist";
};

export async function getBebbBridge(bebbServiceClient: ActorClient<IndexCanister, BebbBridgeService>, partition: string, name: string) {
  let pk = `${partition}#`;
  let bridgeQueryResults = await bebbServiceClient.query<BebbBridgeService["get_bridge"]>(
    pk,
    (actor) => actor.get_bridge(name)
  );

  for (let settledResult of bridgeQueryResults) {
    // handle settled result if fulfilled
    if (settledResult.status === "fulfilled") {
      // handle candid returned optional type (string[] or string)
      return Array.isArray(settledResult.value) ? settledResult.value[0] : settledResult.value
    } 
  }
  
  return "Bridge does not exist";
};

const getPkForPartition = (partition: string) => {
  if (partition === "Entity") {
    return "BebbEntity#";
  } else if (partition === "Bridge") {
    return "BebbBridge#";
  } else {
    throw "Unsupported partition";
  };
};

export async function putBebbEntity(bebbServiceClient: ActorClient<IndexCanister, BebbEntityService>, partition: string, entityObject: any) {
  console.log("Debug putBebbEntity partition ", partition);
  console.log("Debug putBebbEntity entityObject ", entityObject);
  if (partition === "Entity") {
    let pk = getPkForPartition(partition);
    console.log("Debug putBebbEntity pk ", pk);
    let sk = entityObject.id;
    if (!sk) {
      sk = "sk" + Math.floor(Math.random() * Date.now());
    };
    console.log("Debug putBebbEntity sk ", sk);
    let entity_initialization_object: EntityInitiationObject = {
      settings: [],
      entityType: { "Resource": { "Web" : null } },
      name: [entityObject.name], // Replace with the desired name or set it to null or undefined
      description: ["EntityDescription"], // Replace with the desired description or set it to null or undefined
      keywords: [["Bebb Protocol"]] as [Array<string>], // Replace with an array of keywords or set it to null or undefined
      entitySpecificFields: [ "SpecificFieldsValue"], // Replace with the desired entity specific fields or set it to null or undefined
    };
    await bebbServiceClient.update<BebbEntityService["create_entity"]>(
      pk,
      sk,
      (actor) => actor.create_entity(entity_initialization_object)
    );
  } else {
    throw new Error("Unsupported partition");
  };  
};

export async function putBebbBridge(bebbServiceClient: ActorClient<IndexCanister, BebbBridgeService>, partition: string, entityObject: any) {
  if (partition === "Bridge") {
    let pk = getPkForPartition(partition);
    let sk = entityObject.id;
    if (!sk) {
      sk = "sk" + Math.floor(Math.random() * Date.now());
    };
    let bridge_initialization_object: BridgeInitiationObject = {
      settings: [],
      name: [],
      description: [``] as [string],
      keywords: [["Bebb Protocol"]] as [Array<string>],
      entitySpecificFields: [],
      bridgeType: { 'IsRelatedto' : null },
      fromEntityId: entityObject.fromEntityId,
      toEntityId: entityObject.toEntityId,
    };
    await bebbServiceClient.update<BebbBridgeService["create_bridge"]>(
      pk,
      sk,
      (actor) => actor.create_bridge(bridge_initialization_object)
    );
  } else {
    throw new Error("Unsupported partition");
  };  
};