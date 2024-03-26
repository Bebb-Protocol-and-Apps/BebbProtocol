import { ActorClient } from "./candb-client/ActorClient";

import { IndexCanister } from "../../declarations/index/index.did";

import {
  BebbEntityService,
  EntityInitiationObject,
  EntityUpdateObject,
} from "../../declarations/bebbentityservice/bebbentityservice.did";
import {
  BebbBridgeService,
  BridgeInitiationObject,
  BridgeEntityCanisterHints,
  BridgeUpdateObject,
} from "../../declarations/bebbbridgeservice/bebbbridgeservice.did";

export async function getBebbEntity(bebbServiceClient: ActorClient<IndexCanister, BebbEntityService>, partition: string, entityId: string) {
  if (partition === "Entity") {
    let pk = getPkForPartition(partition);
    let entityQueryResults = await bebbServiceClient.query<BebbEntityService["get_entity"]>(
      pk,
      (actor) => actor.get_entity(entityId)
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

export async function getBebbEntityStorageLocation(bebbServiceClient: ActorClient<IndexCanister, BebbEntityService>, partition: string, entityId: string) {
  if (partition === "Entity") {
    let pk = getPkForPartition(partition);
    let entityQueryResults = await bebbServiceClient.queryWithCanisterIdMapping<BebbEntityService["get_entity"]>(
      pk,
      (actor) => actor.get_entity(entityId)
    );
    console.log("Debug getBebbEntityStorageLocation entityQueryResults ", entityQueryResults);

    for (let settledResult of entityQueryResults) {
      console.log("Debug getBebbEntityStorageLocation settledResult ", settledResult);
      // handle settled result if fulfilled
      if (settledResult.status === "fulfilled") {
        // @ts-ignore
        if (settledResult.value) {
          const keys = Object.keys(settledResult.value);
          console.log("Debug getBebbEntityStorageLocation keys ", keys);
          const entityCanisterId = keys[0];
          console.log("Debug getBebbEntityStorageLocation entityCanisterId ", entityCanisterId);
          // handle candid returned optional type (string[] or string)
          return Array.isArray(entityCanisterId) ? entityCanisterId[0] : entityCanisterId;
        };
      };
    };
    
    return "Entity does not exist";
  } else {
    throw new Error("Unsupported partition");
  };
};

export async function getBebbBridge(bebbServiceClient: ActorClient<IndexCanister, BebbBridgeService>, partition: string, bridgeId: string) {
  if (partition === "Bridge") {
    let pk = getPkForPartition(partition);
    let bridgeQueryResults = await bebbServiceClient.query<BebbBridgeService["get_bridge"]>(
      pk,
      (actor) => actor.get_bridge(bridgeId)
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
      // Create new Entity
      sk = "sk" + Math.floor(Math.random() * Date.now());
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
      // Update existing Entity
      let entity_update_object: EntityUpdateObject = {
        id: entityObject.id,
        previews: [],
        settings: [],
        name: [entityObject.name], // Replace with the desired name or set it to null or undefined
        description: ["EntityDescription"], // Replace with the desired description or set it to null or undefined
        keywords: [["Bebb Protocol"]] as [Array<string>], // Replace with an array of keywords or set it to null or undefined
      };
      const result = await bebbServiceClient.update<BebbEntityService["update_entity"]>(
        pk,
        sk,
        (actor) => actor.update_entity(entity_update_object)
      );
      console.log("Return value:" + result);
      console.log(result);
      return result;
    };
  } else {
    throw new Error("Unsupported partition");
  };  
};

export async function putBebbBridge(bebbServiceClient: ActorClient<IndexCanister, BebbBridgeService>, partition: string, entityObject: any, entityServiceClient: ActorClient<IndexCanister, BebbEntityService>) {
  console.log("Debug putBebbBridge partition ", partition);
  console.log("Debug putBebbBridge entityObject ", entityObject);
  if (partition === "Bridge") {
    let pk = getPkForPartition(partition);
    let sk = entityObject.id;
    if (!sk) {
      // Create new Bridge
      sk = "sk" + Math.floor(Math.random() * Date.now());
      const canisterIdEntityTo = await getBebbEntityStorageLocation(entityServiceClient, "Entity", entityObject.toEntityId);
      console.log("Debug putBebbBridge canisterIdEntityTo ", canisterIdEntityTo);
      const canisterIdEntityFrom = await getBebbEntityStorageLocation(entityServiceClient, "Entity", entityObject.fromEntityId);
      console.log("Debug putBebbBridge canisterIdEntityFrom ", canisterIdEntityFrom);
      const canisterIds: BridgeEntityCanisterHints = {
        fromEntityCanisterId: canisterIdEntityFrom,
        toEntityCanisterId: canisterIdEntityTo,
      };
      let bridge_initialization_object: BridgeInitiationObject = {
        settings: [],
        name: [entityObject.name],
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
        (actor) => actor.create_bridge(bridge_initialization_object, canisterIds)
      );
      console.log("Debug putBebbBridge result ", result);
      return result;
    } else {
      // Update existing Bridge
      let bridge_update_object: BridgeUpdateObject = {
        id: entityObject.id,
        settings: [],
        name: [entityObject.name],
        description: [``] as [string],
        keywords: [["Bebb Protocol"]] as [Array<string>],
      };
      console.log("Debug putBebbBridge bridge_update_object ", bridge_update_object);
      const result = await bebbServiceClient.update<BebbBridgeService["update_bridge"]>(
        pk,
        sk,
        (actor) => actor.update_bridge(bridge_update_object)
      );
      console.log("Debug putBebbBridge result ", result);
      return result;
    };
  } else {
    throw new Error("Unsupported partition");
  };  
};

export async function removeBebbEntity(bebbServiceClient: ActorClient<IndexCanister, BebbEntityService>, partition: string, entityId: string) {
  console.log("Debug removeBebbEntity partition ", partition);
  console.log("Debug removeBebbEntity entityId ", entityId);
  if (partition === "Entity") {
    let pk = getPkForPartition(partition);
    console.log("Debug removeBebbEntity pk ", pk);
    let sk = entityId;
    if (!sk) {
      throw new Error("No entityId provided");
    };
    console.log("Debug removeBebbEntity sk ", sk);
    const result = await bebbServiceClient.update<BebbEntityService["delete_entity"]>(
      pk,
      sk,
      (actor) => actor.delete_entity(sk)
    );
    console.log("Return value:" + result);
    console.log(result);
    return result;
  } else {
    throw new Error("Unsupported partition");
  };  
};

export async function removeBebbBridge(bebbServiceClient: ActorClient<IndexCanister, BebbBridgeService>, partition: string, bridgeId: string, entityServiceClient: ActorClient<IndexCanister, BebbEntityService>) {
  console.log("Debug removeBebbBridge partition ", partition);
  console.log("Debug removeBebbBridge bridgeId ", bridgeId);
  if (partition === "Bridge") {
    let pk = getPkForPartition(partition);
    let sk = bridgeId;
    if (!sk) {
      throw new Error("No bridgeId provided");
    };
    const bridge = await getBebbBridge(bebbServiceClient, partition, bridgeId);
    console.log("Debug removeBebbBridge bridge ", bridge);
    const canisterIdEntityTo = await getBebbEntityStorageLocation(entityServiceClient, "Entity", bridge.toEntityId);
    console.log("Debug removeBebbBridge canisterIdEntityTo ", canisterIdEntityTo);
    const canisterIdEntityFrom = await getBebbEntityStorageLocation(entityServiceClient, "Entity", bridge.fromEntityId);
    console.log("Debug removeBebbBridge canisterIdEntityFrom ", canisterIdEntityFrom);
    const canisterIds: BridgeEntityCanisterHints = {
      fromEntityCanisterId: canisterIdEntityFrom,
      toEntityCanisterId: canisterIdEntityTo,
    };
    const result = await bebbServiceClient.update<BebbBridgeService["delete_bridge"]>(
      pk,
      sk,
      (actor) => actor.delete_bridge(bridgeId, canisterIds)
    );
    console.log("Debug putBebbBridge result ", result);
    return result;
  } else {
    throw new Error("Unsupported partition");
  };  
};