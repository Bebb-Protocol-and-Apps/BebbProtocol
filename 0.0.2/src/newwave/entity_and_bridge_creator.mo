import Debug "mo:base/Debug";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import HashMap "mo:base/HashMap";

import EntityType "entity_type";
import EntitySettings "entity_settings";
import Entity "entity";
import BridgeEntity "bridge_entity";

import EntityCreator "canister:entitycreator";
import BridgeCreator "canister:bridgecreator";

actor EntityAndBridgeCreator {
  public shared ({ caller }) func create_entity_and_bridge(entityToCreate : Entity.EntityInitiationObject, bridgeToCreate : BridgeEntity.BridgeEntityInitiationObject) : async (Entity.Entity, BridgeEntity.BridgeEntity) {  
    let createdEntity : Entity.Entity = await EntityCreator.create_entity(entityToCreate);
    var updatedBridgeToCreate = bridgeToCreate;
    switch(bridgeToCreate._fromEntityId) {
      case ("") {
        updatedBridgeToCreate := {
          _internalId = bridgeToCreate._internalId;
          _creator = bridgeToCreate._creator;
          _owner = bridgeToCreate._owner;
          _settings = bridgeToCreate._settings;
          _entityType = bridgeToCreate._entityType;
          _name = bridgeToCreate._name;
          _description = bridgeToCreate._description;
          _keywords = bridgeToCreate._keywords;
          _externalId = bridgeToCreate._externalId;
          _entitySpecificFields = bridgeToCreate._entitySpecificFields;
          _bridgeType = bridgeToCreate._bridgeType;
          _fromEntityId = createdEntity.internalId; // only field that needs update, rest is peasantry
          _toEntityId = bridgeToCreate._toEntityId;
          _state = bridgeToCreate._state;
        }; 
      };
      case (_) {
        updatedBridgeToCreate := {
          _internalId = bridgeToCreate._internalId;
          _creator = bridgeToCreate._creator;
          _owner = bridgeToCreate._owner;
          _settings = bridgeToCreate._settings;
          _entityType = bridgeToCreate._entityType;
          _name = bridgeToCreate._name;
          _description = bridgeToCreate._description;
          _keywords = bridgeToCreate._keywords;
          _externalId = bridgeToCreate._externalId;
          _entitySpecificFields = bridgeToCreate._entitySpecificFields;
          _bridgeType = bridgeToCreate._bridgeType;
          _fromEntityId = bridgeToCreate._fromEntityId;
          _toEntityId = createdEntity.internalId; // only field that needs update, rest is peasantry
          _state = bridgeToCreate._state;
        };
      };
    };
    let bridgeEntity : BridgeEntity.BridgeEntity = await BridgeCreator.create_bridge(updatedBridgeToCreate);
    return (createdEntity, bridgeEntity);
  };
};
