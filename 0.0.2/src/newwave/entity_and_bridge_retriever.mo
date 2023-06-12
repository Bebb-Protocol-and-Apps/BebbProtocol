import Debug "mo:base/Debug";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import HashMap "mo:base/HashMap";
import Array "mo:base/Array";

import EntityType "entity_type";
import EntitySettings "entity_settings";
import Entity "entity";
import BridgeEntity "bridge_entity";

import EntityRetriever "canister:entityretriever";
import BridgeRetriever "canister:bridgeretriever";

actor EntityAndBridgeRetriever {
  public shared ({ caller }) func get_bridged_entities_by_entity_id(entityId : Text, includeBridgesFromEntity : Bool, includeBridgesToEntity : Bool, includeBridgesPendingForEntity : Bool) : async [Entity.Entity] {
    let entityBridges : [BridgeEntity.BridgeEntity] = await BridgeRetriever.get_bridges_by_entity_id(entityId, includeBridgesFromEntity, includeBridgesToEntity, includeBridgesPendingForEntity);
    let bridgedEntityIds : [var Text] = Array.init<Text>(entityBridges.size(), "");
    var i = 0;
    for (entityBridge in entityBridges.vals()) {
      if (entityBridge.fromEntityId == entityId) {
        bridgedEntityIds[i] := entityBridge.toEntityId;
      } else {
        bridgedEntityIds[i] := entityBridge.fromEntityId;
      };
      i += 1;
    };
    let bridgedEntities : [Entity.Entity] = await EntityRetriever.get_entities(Array.freeze<Text>(bridgedEntityIds));
    return bridgedEntities;
  };

  public shared ({ caller }) func get_entity_and_bridge_ids(entityId : Text, includeBridgesFromEntity : Bool, includeBridgesToEntity : Bool, includeBridgesPendingForEntity : Bool) : async (?Entity.Entity, [Text]) {
    switch(await EntityRetriever.get_entity(entityId)) {
      case null {
        return (null, []);
      };
      case (?entity) { 
        let bridgeIds : [Text] = await BridgeRetriever.get_bridge_ids_by_entity_id(entityId, includeBridgesFromEntity, includeBridgesToEntity, includeBridgesPendingForEntity);
        return (?entity, bridgeIds);
      };
    };
  };
};
