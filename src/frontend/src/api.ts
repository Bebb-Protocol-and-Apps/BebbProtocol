import { ActorClient } from "./candb-client/ActorClient";

import { IndexCanister } from "../../declarations/index/index.did";

import {
  BebbEntityService,
  EntityInitiationObject,
} from "../../declarations/bebbentityservice/bebbentityservice.did";
import {
  BebbBridgeService,
  BridgeInitiationObject
} from "../../declarations/bebbbridgeservice/bebbbridgeservice.did";

export async function getBebbEntity(bebbServiceClient: ActorClient<IndexCanister, BebbEntityService>, partition: string, name: string) {
  if (partition === "Entity") {
    let pk = getPkForPartition(partition);
    let entityQueryResults = await bebbServiceClient.query<BebbEntityService["get_entity"]>(
      pk,
      (actor) => actor.get_entity(name)
    );
    console.log("Debug getBebbEntity entityQueryResults ", entityQueryResults);

    for (let settledResult of entityQueryResults) {
      console.log("Debug getBebbEntity settledResult ", settledResult);
      // handle settled result if fulfilled
      if (settledResult.status === "fulfilled") {
        // @ts-ignore
        if (settledResult.value.Ok) {
          // @ts-ignore
          const entity = settledResult.value.Ok;
          // handle candid returned optional type (string[] or string)
          return Array.isArray(entity) ? entity[0] : entity;
        };
      };
    };
    
    return "Entity does not exist";
  } else {
    throw new Error("Unsupported partition");
  };
};

export async function getBebbBridge(bebbServiceClient: ActorClient<IndexCanister, BebbBridgeService>, partition: string, name: string) {
  if (partition === "Bridge") {
    let pk = getPkForPartition(partition);
    let bridgeQueryResults = await bebbServiceClient.query<BebbBridgeService["get_bridge"]>(
      pk,
      (actor) => actor.get_bridge(name)
    );

    for (let settledResult of bridgeQueryResults) {
      // handle settled result if fulfilled
      if (settledResult.status === "fulfilled") {
        // @ts-ignore
        if (settledResult.value.Ok) {
          // @ts-ignore
          const bridge = settledResult.value.Ok;
          // handle candid returned optional type (string[] or string)
          return Array.isArray(bridge) ? bridge : bridge;
        };
      };
    };
    
    return "Bridge does not exist";
  } else {
    throw new Error("Unsupported partition");
  };
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
    const result = await bebbServiceClient.update<BebbEntityService["create_entity"]>(
      pk,
      sk,
      (actor) => actor.create_entity(entity_initialization_object)
    );
    console.log("Return value:" + result);
    console.log(result);
    return result;
  } else {
    throw new Error("Unsupported partition");
  };  
};

export async function putBebbBridge(bebbServiceClient: ActorClient<IndexCanister, BebbBridgeService>, partition: string, entityObject: any) {
  console.log("Debug putBebbBridge partition ", partition);
  console.log("Debug putBebbBridge entityObject ", entityObject);
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
    console.log("Debug putBebbBridge bridge_initialization_object ", bridge_initialization_object);
    const result = await bebbServiceClient.update<BebbBridgeService["create_bridge"]>(
      pk,
      sk,
      (actor) => actor.create_bridge(bridge_initialization_object)
    );
    console.log("Debug putBebbBridge result ", result);
    return result;
  } else {
    throw new Error("Unsupported partition");
  };  
};