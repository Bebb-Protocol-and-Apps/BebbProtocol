import Debug "mo:base/Debug";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import HashMap "mo:base/HashMap";
import Bool "mo:base/Bool";

import EntityType "entity_type";
import EntitySettings "entity_settings";
import Entity "entity";
import BridgeEntity "bridge_entity";
import EntityStorageUnit "entity_storage_unit";

import BridgeRegistry "canister:bridgeregistry";
import BridgesDirectory "canister:bridgesdirectory";

actor BridgeRetriever {
  public shared ({ caller }) func get_bridge(entityId : Text) : async ?BridgeEntity.BridgeEntity {
    let bridgeToReturn : ?BridgeEntity.BridgeEntity = await BridgeRegistry.getEntity(entityId);
    return bridgeToReturn;
  };

  public shared ({ caller }) func get_bridge_ids_by_entity_id(entityId : Text, includeBridgesFromEntity : Bool, includeBridgesToEntity : Bool, includeBridgesPendingForEntity : Bool) : async [Text] {
    let bridgeIdsToReturn = await BridgesDirectory.getEntityEntries(entityId, includeBridgesFromEntity, includeBridgesToEntity, includeBridgesPendingForEntity);
    return bridgeIdsToReturn;
  };

  public shared ({ caller }) func get_bridges_by_entity_id(entityId : Text, includeBridgesFromEntity : Bool, includeBridgesToEntity : Bool, includeBridgesPendingForEntity : Bool) : async [BridgeEntity.BridgeEntity] {
    let bridgeIdsToRetrieve = await get_bridge_ids_by_entity_id(entityId, includeBridgesFromEntity, includeBridgesToEntity, includeBridgesPendingForEntity);
    let bridgesToReturn = await BridgeRegistry.getEntities(bridgeIdsToRetrieve);
    return bridgesToReturn;
  };
};
