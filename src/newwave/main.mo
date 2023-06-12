import Debug "mo:base/Debug";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import HashMap "mo:base/HashMap";
import List "mo:base/List";
import Bool "mo:base/Bool";
import Buffer "mo:base/Buffer";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Option "mo:base/Option";

import EntityType "entity_type";
import EntitySettings "entity_settings";
import Entity "entity";
import BridgeEntity "bridge_entity";
import BridgeType "bridge_type";
import BridgeState "bridge_state";

import HTTP "./Http";
import Types "./Types";

actor {
// INTERFACE
  public shared ({ caller }) func create_entity(entityToCreate : Entity.EntityInitiationObject) : async Entity.Entity {
    let result = await createEntity(caller, entityToCreate);
    return result;
    // return EntityCreator.create_entity(); throws error (doesn't match expected type) -> TODO: possible to return promise? Would this speed up this canister? e.g. try ... : async (async Entity.Entity)
  };

  public shared query ({ caller }) func get_entity(entityId : Text) : async ?Entity.Entity {
    let result = getEntity(entityId);
    return result;
  };

  public shared ({ caller }) func create_bridge(bridgeToCreate : BridgeEntity.BridgeEntityInitiationObject) : async ?BridgeEntity.BridgeEntity {
    let result = await createBridge(caller, bridgeToCreate);
    return result;
    // return BridgeCreator.create_bridge(bridgeToCreate); TODO: possible to return promise? Would this speed up this canister?
  };

  public shared query ({ caller }) func get_bridge(entityId : Text) : async ?BridgeEntity.BridgeEntity {
    let result = getBridge(entityId);
    return result;
  };

  public shared query ({ caller }) func get_bridge_ids_by_entity_id(entityId : Text, includeBridgesFromEntity : Bool, includeBridgesToEntity : Bool, includeBridgesPendingForEntity : Bool) : async [Text] {
    let result = getBridgeIdsByEntityId(entityId, includeBridgesFromEntity, includeBridgesToEntity, includeBridgesPendingForEntity);
    return result;
  };

  public shared query ({ caller }) func get_bridges_by_entity_id(entityId : Text, includeBridgesFromEntity : Bool, includeBridgesToEntity : Bool, includeBridgesPendingForEntity : Bool) : async [BridgeEntity.BridgeEntity] {
    let result = getBridgesByEntityId(entityId, includeBridgesFromEntity, includeBridgesToEntity, includeBridgesPendingForEntity);
    return result;
  };

  public shared ({ caller }) func create_entity_and_bridge(entityToCreate : Entity.EntityInitiationObject, bridgeToCreate : BridgeEntity.BridgeEntityInitiationObject) : async (Entity.Entity, ?BridgeEntity.BridgeEntity) {
    let result = await createEntityAndBridge(caller, entityToCreate, bridgeToCreate);
    return result;
  };

  public shared query ({ caller }) func get_bridged_entities_by_entity_id(entityId : Text, includeBridgesFromEntity : Bool, includeBridgesToEntity : Bool, includeBridgesPendingForEntity : Bool) : async [Entity.Entity] {
    let result = getBridgedEntitiesByEntityId(entityId, includeBridgesFromEntity, includeBridgesToEntity, includeBridgesPendingForEntity);
    return result;
  };

  public shared query ({ caller }) func get_entity_and_bridge_ids(entityId : Text, includeBridgesFromEntity : Bool, includeBridgesToEntity : Bool, includeBridgesPendingForEntity : Bool) : async (?Entity.Entity, [Text]) {
    let result = getEntityAndBridgeIds(entityId, includeBridgesFromEntity, includeBridgesToEntity, includeBridgesPendingForEntity);
    return result;
  };

  public shared ({ caller }) func delete_bridge(bridgeId : Text) : async Types.BridgeResult {
    let result = await deleteBridge(caller, bridgeId);
    return result;
  };

  public shared ({ caller }) func update_bridge(bridgeUpdateObject : BridgeEntity.BridgeEntityUpdateObject) : async Types.BridgeResult {
    let result = await updateBridge(caller, bridgeUpdateObject);
    return result;
  };

  public shared ({ caller }) func update_entity(entityUpdateObject : Entity.EntityUpdateObject) : async Types.EntityResult {
    let result = await updateEntity(caller, entityUpdateObject);
    return result;
  };

// HELPER FUNCTIONS
  func createEntity(caller : Principal, entityToCreate : Entity.EntityInitiationObject) : async (Entity.Entity) {
    // perform duplication checks (with externalId)
    let existingEntity : ?Entity.Entity = switch(entityToCreate._externalId) {
      case null { null };
      case (?"") { null };
      case (?entityToCreateExternalId) {
        switch(entityToCreate._entityType) {
          case (#Webasset) {
            switch(getEntityByAttribute("externalId", entityToCreateExternalId)) {
              case null { null };
              case (?entityFound) { ?entityFound };
            };
          };
          case _ { // TODO: add more Entity Types
            null
          };
        };
      };
    };
    switch(existingEntity) {
      case (?entityEntry) {
        // return existing Entity
        return entityEntry;
      };
      case null {
        // create Entity
        // TODO: potentially update entityToCreate fields (might vary depending on EntityType)
        // TODO: potentially assign final internal_id to Entity (might vary depending on EntityType)
        let entity : Entity.Entity = await Entity.Entity(entityToCreate, caller);
        // stores via entity_type_storage (abstraction over multiple entity_storage_units)
        let result = putEntity(entity.internalId, entity);
        assert(Text.equal(result, entity.internalId));
        return entity;  
      };
    };
  };

  stable var entitiesStorageStable : [(Text, Entity.Entity)] = [];
  var entitiesStorage : HashMap.HashMap<Text, Entity.Entity> = HashMap.HashMap(0, Text.equal, Text.hash);

  func putEntity(entityId : Text, entity : Entity.Entity) : Text {
    entitiesStorage.put(entityId, entity);
    return entityId;
  };

  func getEntity(entityId : Text) : ?Entity.Entity {
    let result = entitiesStorage.get(entityId);
    return result;
  };

  func checkIfEntityWithAttributeExists(attribute : Text, attributeValue : Text) : Bool {
    switch(attribute) {
      case "internalId" {
        switch(getEntity(attributeValue)) {
          case null { return false; };
          case _ { return true; };
        };
      };
      case "externalId" {
        for ((k, entity) in entitiesStorage.entries()) {
          if (entity.externalId == ?attributeValue) {
            return true;
          };          
        };
        return false;
      };
      case _ { return false; }
    };
  };

  func getEntityByAttribute(attribute : Text, attributeValue : Text) : ?Entity.Entity {
    switch(attribute) {
      case "internalId" {
        return getEntity(attributeValue);
      };
      case "externalId" {
        for ((k, entity) in entitiesStorage.entries()) {
          if (entity.externalId == ?attributeValue) {
            return ?entity;
          };          
        };
        return null;
      };
      case _ { return null; }
    };
  };

  func getEntitiesByAttribute(attribute : Text, attributeValue : Text) : [Entity.Entity] {
    switch(attribute) {
      case "externalId" {
        var entitiesToReturn = List.nil<Entity.Entity>();
        for ((k, entity) in entitiesStorage.entries()) {
          if (entity.externalId == ?attributeValue) {
            entitiesToReturn := List.push<Entity.Entity>(entity, entitiesToReturn);
          };          
        };
        return List.toArray<Entity.Entity>(entitiesToReturn);
      };
      case _ { return []; }
    };
  };

  func createBridge(caller : Principal, bridgeToCreate : BridgeEntity.BridgeEntityInitiationObject) : async ?BridgeEntity.BridgeEntity {
    // ensure that bridged Entities exist
    switch(checkIfEntityWithAttributeExists("internalId", bridgeToCreate._fromEntityId)) {
      case false { return null; }; // TODO: potentially return error message instead
      case true {
        if (checkIfEntityWithAttributeExists("internalId", bridgeToCreate._toEntityId) == false) {
          return null; // TODO: potentially return error message instead
        };
      };
    };
    let bridge : BridgeEntity.BridgeEntity = await BridgeEntity.BridgeEntity(bridgeToCreate, caller);
    let result = putBridge(bridge);
    return ?result;
  };

  stable var bridgesStorageStable : [(Text, BridgeEntity.BridgeEntity)] = [];
  var bridgesStorage : HashMap.HashMap<Text, BridgeEntity.BridgeEntity> = HashMap.HashMap(0, Text.equal, Text.hash);

  func putBridge(bridge : BridgeEntity.BridgeEntity) : BridgeEntity.BridgeEntity {
    let result = bridgesStorage.put(bridge.internalId, bridge);
    let bridgeAddedToDirectory = putEntityEntry(bridge);
    assert(Text.equal(bridge.internalId, bridgeAddedToDirectory));
    return bridge;
  };

  type BridgeCategories = { // TODO: define bridge categories, probably import from a dedicated file (BridgeType)
    ownerCreatedBridges : List.List<Text>;
    otherBridges : List.List<Text>;
  };

  stable var pendingFromBridgesStorageStable : [(Text, BridgeCategories)] = [];
  var pendingFromBridgesStorage : HashMap.HashMap<Text, BridgeCategories> = HashMap.HashMap(0, Text.equal, Text.hash);
  stable var pendingToBridgesStorageStable : [(Text, BridgeCategories)] = [];
  var pendingToBridgesStorage : HashMap.HashMap<Text, BridgeCategories> = HashMap.HashMap(0, Text.equal, Text.hash);
  stable var fromBridgesStorageStable : [(Text, BridgeCategories)] = [];
  var fromBridgesStorage : HashMap.HashMap<Text, BridgeCategories> = HashMap.HashMap(0, Text.equal, Text.hash);
  stable var toBridgesStorageStable : [(Text, BridgeCategories)] = [];
  var toBridgesStorage : HashMap.HashMap<Text, BridgeCategories> = HashMap.HashMap(0, Text.equal, Text.hash);

  func putEntityEntry(bridge : BridgeEntity.BridgeEntity) : Text {
    if (bridge.state == #Pending) { // if bridge state is Pending, store accordingly
    // store in pending from storage
      switch(pendingFromBridgesStorage.get(bridge.fromEntityId)) {
        case null {
          // first entry for entityId
          var otherBridgesList = List.nil<Text>();
          otherBridgesList := List.push<Text>(bridge.internalId, otherBridgesList);
          let newEntityEntry : BridgeCategories = {
            ownerCreatedBridges = List.nil<Text>();
            otherBridges = otherBridgesList;
          };
          pendingFromBridgesStorage.put(bridge.fromEntityId, newEntityEntry);     
        };
        case (?entityEntry) {
          // add to existing entry for entityId
          let updatedEntityEntry : BridgeCategories = {
            ownerCreatedBridges = entityEntry.ownerCreatedBridges;
            otherBridges = List.push<Text>(bridge.internalId, entityEntry.otherBridges);
          };
          pendingFromBridgesStorage.put(bridge.fromEntityId, updatedEntityEntry);    
        };
      };
    // store in pending to storage
      switch(pendingToBridgesStorage.get(bridge.toEntityId)) {
        case null {
          // first entry for entityId
          var otherBridgesList = List.nil<Text>();
          otherBridgesList := List.push<Text>(bridge.internalId, otherBridgesList);
          let newEntityEntry : BridgeCategories = {
            ownerCreatedBridges = List.nil<Text>();
            otherBridges = otherBridgesList;
          };
          pendingToBridgesStorage.put(bridge.toEntityId, newEntityEntry);     
        };
        case (?entityEntry) {
          // add to existing entry for entityId
          let updatedEntityEntry : BridgeCategories = {
            ownerCreatedBridges = entityEntry.ownerCreatedBridges;
            otherBridges = List.push<Text>(bridge.internalId, entityEntry.otherBridges);
          };
          pendingToBridgesStorage.put(bridge.toEntityId, updatedEntityEntry);    
        };
      };
    } else {
      // store bridge for entities bridged to and from
      // store in from storage
      switch(fromBridgesStorage.get(bridge.fromEntityId)) {
        case null {
          // first entry for entityId
          var otherBridgesList = List.nil<Text>();
          otherBridgesList := List.push<Text>(bridge.internalId, otherBridgesList);
          let newEntityEntry : BridgeCategories = {
            ownerCreatedBridges = List.nil<Text>();
            otherBridges = otherBridgesList;
          };
          fromBridgesStorage.put(bridge.fromEntityId, newEntityEntry);     
        };
        case (?entityEntry) {
          // add to existing entry for entityId
          let updatedEntityEntry : BridgeCategories = {
            ownerCreatedBridges = entityEntry.ownerCreatedBridges;
            otherBridges = List.push<Text>(bridge.internalId, entityEntry.otherBridges);
          };
          fromBridgesStorage.put(bridge.fromEntityId, updatedEntityEntry);    
        };
      };
    // store in to storage
      switch(toBridgesStorage.get(bridge.toEntityId)) {
        case null {
          // first entry for entityId
          var otherBridgesList = List.nil<Text>();
          otherBridgesList := List.push<Text>(bridge.internalId, otherBridgesList);
          let newEntityEntry : BridgeCategories = {
            ownerCreatedBridges = List.nil<Text>();
            otherBridges = otherBridgesList;
          };
          toBridgesStorage.put(bridge.toEntityId, newEntityEntry);     
        };
        case (?entityEntry) {
          // add to existing entry for entityId
          let updatedEntityEntry : BridgeCategories = {
            ownerCreatedBridges = entityEntry.ownerCreatedBridges;
            otherBridges = List.push<Text>(bridge.internalId, entityEntry.otherBridges);
          };
          toBridgesStorage.put(bridge.toEntityId, updatedEntityEntry);    
        };
      };
    };
    return bridge.internalId;
  };

  func getBridge(entityId : Text) : ?BridgeEntity.BridgeEntity {
    let bridgeToReturn : ?BridgeEntity.BridgeEntity = bridgesStorage.get(entityId);
    return bridgeToReturn;
  };

  func getBridgeIdsByEntityId(entityId : Text, includeBridgesFromEntity : Bool, includeBridgesToEntity : Bool, includeBridgesPendingForEntity : Bool) : [Text] {
    var bridgeIdsToReturn = List.nil<Text>();
    if (includeBridgesFromEntity) {
      switch(fromBridgesStorage.get(entityId)) {
        case null {};
        case (?entityEntry) {
          bridgeIdsToReturn := List.append<Text>(bridgeIdsToReturn, entityEntry.otherBridges); // TODO: determine which category's list/categories' lists in entry to return
        };
      };
    };
    if (includeBridgesToEntity) {
      switch(toBridgesStorage.get(entityId)) {
        case null {};
        case (?entityEntry) {
          bridgeIdsToReturn := List.append<Text>(bridgeIdsToReturn, entityEntry.otherBridges); // TODO: determine which category's list/categories' lists in entry to return
        };
      };
    };
    if (includeBridgesPendingForEntity) {
      switch(pendingFromBridgesStorage.get(entityId)) {
        case null {};
        case (?entityEntry) {
          bridgeIdsToReturn := List.append<Text>(bridgeIdsToReturn, entityEntry.otherBridges); // TODO: determine which category's list/categories' lists in entry to return
        };
      };
      switch(pendingToBridgesStorage.get(entityId)) {
        case null {};
        case (?entityEntry) {
          bridgeIdsToReturn := List.append<Text>(bridgeIdsToReturn, entityEntry.otherBridges); // TODO: determine which category's list/categories' lists in entry to return
        };
      };
    };
    return List.toArray<Text>(bridgeIdsToReturn);
  };

  func getBridgesByEntityId(entityId : Text, includeBridgesFromEntity : Bool, includeBridgesToEntity : Bool, includeBridgesPendingForEntity : Bool) : [BridgeEntity.BridgeEntity] {
    let bridgeIdsToRetrieve = getBridgeIdsByEntityId(entityId, includeBridgesFromEntity, includeBridgesToEntity, includeBridgesPendingForEntity);
    // adapted from https://forum.dfinity.org/t/motoko-sharable-generics/9021/3
    let executingFunctionsBuffer = Buffer.Buffer<?BridgeEntity.BridgeEntity>(bridgeIdsToRetrieve.size());
    for (bridgeId in bridgeIdsToRetrieve.vals()) { 
      executingFunctionsBuffer.add(getBridge(bridgeId)); 
    };
    let collectingResultsBuffer = Buffer.Buffer<BridgeEntity.BridgeEntity>(bridgeIdsToRetrieve.size());
    var i = 0;
    for (bridgeId in bridgeIdsToRetrieve.vals()) {
      switch(executingFunctionsBuffer.get(i)) {
        case null {};
        case (?bridge) { collectingResultsBuffer.add(bridge); };
      };      
      i += 1;
    };
    return collectingResultsBuffer.toArray();
  };

  func createEntityAndBridge(caller : Principal, entityToCreate : Entity.EntityInitiationObject, bridgeToCreate : BridgeEntity.BridgeEntityInitiationObject) : async (Entity.Entity, ?BridgeEntity.BridgeEntity) {  
    let createdEntity : Entity.Entity = await createEntity(caller, entityToCreate);
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
    let bridgeEntity : ?BridgeEntity.BridgeEntity = await createBridge(caller, updatedBridgeToCreate);
    return (createdEntity, bridgeEntity);
  };

  func getBridgedEntitiesByEntityId(entityId : Text, includeBridgesFromEntity : Bool, includeBridgesToEntity : Bool, includeBridgesPendingForEntity : Bool) : [Entity.Entity] {
    let entityBridges : [BridgeEntity.BridgeEntity] = getBridgesByEntityId(entityId, includeBridgesFromEntity, includeBridgesToEntity, includeBridgesPendingForEntity);
    if (entityBridges.size() == 0) {
      return [];
    };
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
    let executingFunctionsBuffer = Buffer.Buffer<?Entity.Entity>(bridgedEntityIds.size());
    for (entityId in bridgedEntityIds.vals()) { 
      executingFunctionsBuffer.add(getEntity(entityId)); 
    };
    let collectingResultsBuffer = Buffer.Buffer<Entity.Entity>(bridgedEntityIds.size());
    i := 0;
    for (entityId in bridgedEntityIds.vals()) {
      switch(executingFunctionsBuffer.get(i)) {
        case null {};
        case (?entity) { collectingResultsBuffer.add(entity); };
      };      
      i += 1;
    };
    let bridgedEntities : [Entity.Entity] = collectingResultsBuffer.toArray();
    return bridgedEntities;
  };

  func getEntityAndBridgeIds(entityId : Text, includeBridgesFromEntity : Bool, includeBridgesToEntity : Bool, includeBridgesPendingForEntity : Bool) : (?Entity.Entity, [Text]) {
    switch(getEntity(entityId)) {
      case null {
        return (null, []);
      };
      case (?entity) { 
        let bridgeIds : [Text] = getBridgeIdsByEntityId(entityId, includeBridgesFromEntity, includeBridgesToEntity, includeBridgesPendingForEntity);
        return (?entity, bridgeIds);
      };
    };
  };

  func deleteBridgeFromStorage(bridgeId : Text) : Bool {
    bridgesStorage.delete(bridgeId);
    return true;
  };

  func detachBridgeFromEntities(bridge : BridgeEntity.BridgeEntity) : Bool {
    // Delete Bridge's references from Entities' entries
    if (bridge.state == #Pending) {
    // delete from pending from storage
      switch(pendingFromBridgesStorage.get(bridge.fromEntityId)) {
        case null {
          return false;    
        };
        case (?entityEntry) {
          // delete from entry for entityId by filtering out the bridge's id
          let updatedEntityEntry : BridgeCategories = {
            ownerCreatedBridges = List.filter<Text>(entityEntry.ownerCreatedBridges, func id { id !=  bridge.internalId });
            otherBridges = List.filter<Text>(entityEntry.otherBridges, func id { id !=  bridge.internalId });
          };
          pendingFromBridgesStorage.put(bridge.fromEntityId, updatedEntityEntry);    
        };
      };
    // delete from pending to storage
      switch(pendingToBridgesStorage.get(bridge.toEntityId)) {
        case null {
          return false;    
        };
        case (?entityEntry) {
          // delete from entry for entityId by filtering out the bridge's id
          let updatedEntityEntry : BridgeCategories = {
            ownerCreatedBridges = List.filter<Text>(entityEntry.ownerCreatedBridges, func id { id !=  bridge.internalId });
            otherBridges = List.filter<Text>(entityEntry.otherBridges, func id { id !=  bridge.internalId });
          };
          pendingToBridgesStorage.put(bridge.toEntityId, updatedEntityEntry);    
        };
      };
    } else {
      // delete Bridge from Entities bridged to and from
      // delete from storage for Bridges from Entity
      switch(fromBridgesStorage.get(bridge.fromEntityId)) {
        case null {
          return false;   
        };
        case (?entityEntry) {
          // delete from entry for entityId
          let updatedEntityEntry : BridgeCategories = {
            ownerCreatedBridges = List.filter<Text>(entityEntry.ownerCreatedBridges, func id { id !=  bridge.internalId });
            otherBridges = List.filter<Text>(entityEntry.otherBridges, func id { id !=  bridge.internalId });
          };
          fromBridgesStorage.put(bridge.fromEntityId, updatedEntityEntry);    
        };
      };
    // delete from storage for Bridges to Entity
      switch(toBridgesStorage.get(bridge.toEntityId)) {
        case null {
          return false;   
        };
        case (?entityEntry) {
          // delete from entry for entityId
          let updatedEntityEntry : BridgeCategories = {
            ownerCreatedBridges = List.filter<Text>(entityEntry.ownerCreatedBridges, func id { id !=  bridge.internalId });
            otherBridges = List.filter<Text>(entityEntry.otherBridges, func id { id !=  bridge.internalId });
          };
          toBridgesStorage.put(bridge.toEntityId, updatedEntityEntry);    
        };
      };
    };
    
    return true;
  };

  func deleteBridge(caller : Principal, bridgeId : Text) : async Types.BridgeResult {
    switch(getBridge(bridgeId)) {
      case null { return #Err(#BridgeNotFound); };
      case (?bridgeToDelete) {
        switch(Principal.equal(bridgeToDelete.owner, caller)) {
          case false {
            let errorText : Text = Principal.toText(caller);
            return #Err(#Unauthorized errorText);
          }; // Only owner may delete the Bridge
          case true {
            // TBD: other deletion constraints
            switch(detachBridgeFromEntities(bridgeToDelete)) {
              case false { 
                assert(false); // Should roll back all changes (Something like this would be better: trap("Was Not Able to Delete the Bridge");)
                return #Err(#Other "Unable to Delete the Bridge");
              };
              case true {         
                switch(deleteBridgeFromStorage(bridgeId)) {
                  case true {
                    return #Ok(?bridgeToDelete);
                  };
                  case _ { 
                    assert(false); // Should roll back all changes (Something like this would be better: trap("Was Not Able to Delete the Bridge");)
                    return #Err(#Other "Unable to Delete the Bridge");
                  };
                };                          
              };
            };         
          };
        };
      };
    };
  };

  func updateBridge(caller : Principal, bridgeUpdateObject : BridgeEntity.BridgeEntityUpdateObject) : async Types.BridgeResult {
    switch(getBridge(bridgeUpdateObject.internalId)) {
      case null { return #Err(#BridgeNotFound); };
      case (?bridgeToUpdate) {
        switch(Principal.equal(bridgeToUpdate.owner, caller)) {
          case false {
            let errorText : Text = Principal.toText(caller);
            return #Err(#Unauthorized errorText);
          }; // Only owner may update the Bridge
          case true {
            // TBD: other update constraints
            let updatedBridge : BridgeEntity.BridgeEntity = {
              internalId : Text = bridgeToUpdate.internalId;
              creationTimestamp : Nat64 = bridgeToUpdate.creationTimestamp;
              creator : Principal = bridgeToUpdate.creator;
              owner : Principal = bridgeToUpdate.owner;
              settings : EntitySettings.EntitySettings = Option.get<EntitySettings.EntitySettings>(bridgeUpdateObject.settings, bridgeToUpdate.settings);
              entityType : EntityType.EntityType = bridgeToUpdate.entityType;
              name : ?Text = Option.get<?Text>(?bridgeUpdateObject.name, bridgeToUpdate.name);
              description : ?Text = Option.get<?Text>(?bridgeUpdateObject.description, bridgeToUpdate.description);
              keywords : ?[Text] = Option.get<?[Text]>(?bridgeUpdateObject.keywords, bridgeToUpdate.keywords);
              externalId : ?Text = bridgeToUpdate.externalId;
              entitySpecificFields : ?Text = bridgeToUpdate.entitySpecificFields;
              listOfEntitySpecificFieldKeys : [Text] = bridgeToUpdate.listOfEntitySpecificFieldKeys;
              bridgeType : BridgeType.BridgeType = Option.get<BridgeType.BridgeType>(bridgeUpdateObject.bridgeType, bridgeToUpdate.bridgeType);
              fromEntityId : Text = bridgeToUpdate.fromEntityId;
              toEntityId : Text = bridgeToUpdate.toEntityId;
              state : BridgeState.BridgeState = Option.get<BridgeState.BridgeState>(bridgeUpdateObject.state, bridgeToUpdate.state);
            };
            let result = bridgesStorage.put(updatedBridge.internalId, updatedBridge);
            return #Ok(?updatedBridge);        
          };
        };
      };
    };
  };

  func updateEntity(caller : Principal, entityUpdateObject : Entity.EntityUpdateObject) : async Types.EntityResult {
    switch(getEntity(entityUpdateObject.internalId)) {
      case null { return #Err(#EntityNotFound); };
      case (?entityToUpdate) {
        switch(Principal.equal(entityToUpdate.owner, caller)) {
          case false {
            let errorText : Text = Principal.toText(caller);
            return #Err(#Unauthorized errorText);
          }; // Only owner may update the Entity
          case true {
            // TBD: other update constraints
            let updatedEntity : Entity.Entity = {
              internalId : Text = entityToUpdate.internalId;
              creationTimestamp : Nat64 = entityToUpdate.creationTimestamp;
              creator : Principal = entityToUpdate.creator;
              owner : Principal = entityToUpdate.owner;
              settings : EntitySettings.EntitySettings = Option.get<EntitySettings.EntitySettings>(entityUpdateObject.settings, entityToUpdate.settings);
              entityType : EntityType.EntityType = entityToUpdate.entityType;
              name : ?Text = Option.get<?Text>(?entityUpdateObject.name, entityToUpdate.name);
              description : ?Text = Option.get<?Text>(?entityUpdateObject.description, entityToUpdate.description);
              keywords : ?[Text] = Option.get<?[Text]>(?entityUpdateObject.keywords, entityToUpdate.keywords);
              externalId : ?Text = entityToUpdate.externalId;
              entitySpecificFields : ?Text = entityToUpdate.entitySpecificFields;
              listOfEntitySpecificFieldKeys : [Text] = entityToUpdate.listOfEntitySpecificFieldKeys;
            };
            let result = entitiesStorage.put(updatedEntity.internalId, updatedEntity);
            return #Ok(?updatedEntity);      
          };
        };
      };
    };
  };

// HTTP interface
  public query func http_request(request : HTTP.Request) : async HTTP.Response {
  // TODO: probably format response bodies to JSON
    //Debug.print(debug_show("http_request test"));
    //Debug.print(debug_show(request));
    if (request.url == "/getEntity") {
      let entityIdInput : ?HTTP.HeaderField = Array.find<HTTP.HeaderField>(request.headers, func (header) {
        if (header.0 == "entityid") {
          return true;
        } else {
          return false;
        };
      });
      let entityId : Text = switch(entityIdInput) {
        case (?v) { v.1 };
        case null {
          let response = {
            body = Text.encodeUtf8("No EntityId header provided");
            headers = [];
            status_code = 400 : Nat16;
            streaming_strategy = null;
            upgrade = false;
          };
          return(response);
        };
      };
      switch (getEntity(entityId)) {
        case (null) {
          let response = {
            body = Text.encodeUtf8("Invalid EntityId");
            headers = [];
            status_code = 404 : Nat16;
            streaming_strategy = null;
            upgrade = false;
          };
          return(response);
        };
        case (?entity) {
          let body = Text.encodeUtf8(debug_show(entity));
          let response = {
            body = body;
            headers = [("Content-Type", "text/html; charset=UTF-8"), ("Content-Length", Nat.toText(body.size()))];
            status_code = 200 : Nat16;
            streaming_strategy = null;
            upgrade = false;
          };
          return(response);
        };
      };
    } else if (request.url == "/getBridge") {
      let bridgeIdInput : ?HTTP.HeaderField = Array.find<HTTP.HeaderField>(request.headers, func (header) {
        if (header.0 == "bridgeid") {
          return true;
        } else {
          return false;
        };
      });
      let bridgeId : Text = switch(bridgeIdInput) {
        case (?v) { v.1 };
        case null {
          let response = {
            body = Text.encodeUtf8("No BridgeId header provided");
            headers = [];
            status_code = 400 : Nat16;
            streaming_strategy = null;
            upgrade = false;
          };
          return(response);
        };
      };
      switch (getBridge(bridgeId)) {
        case (null) {
          let response = {
            body = Text.encodeUtf8("Invalid BridgeId");
            headers = [];
            status_code = 404 : Nat16;
            streaming_strategy = null;
            upgrade = false;
          };
          return(response);
        };
        case (?bridge) {
          let body = Text.encodeUtf8(debug_show(bridge));
          let response = {
            body = body;
            headers = [("Content-Type", "text/html; charset=UTF-8"), ("Content-Length", Nat.toText(body.size()))];
            status_code = 200 : Nat16;
            streaming_strategy = null;
            upgrade = false;
          };
          return(response);
        };
      };
    } else if (request.url == "/getBridgeIdsByEntityId") {
      let entityIdInput : ?HTTP.HeaderField = Array.find<HTTP.HeaderField>(request.headers, func (header) {
        if (header.0 == "entityid") {
          return true;
        } else {
          return false;
        };
      });
      let entityId : Text = switch(entityIdInput) {
        case (?v) { v.1 };
        case null {
          let response = {
            body = Text.encodeUtf8("No EntityId header provided");
            headers = [];
            status_code = 400 : Nat16;
            streaming_strategy = null;
            upgrade = false;
          };
          return(response);
        };
      };
      // fill variables from corresponding headers
      var includeBridgesFromEntity : Bool = false;
      var includeBridgesToEntity : Bool = false;
      var includeBridgesPendingForEntity : Bool = false;
      for (header in request.headers.vals()) {
        //Debug.print(debug_show("header"));
        //Debug.print(debug_show(header));
        if (header.0 == "includebridgesfromentity") {
          if (header.1 == "true") {
            includeBridgesFromEntity := true;
          }
        } else if (header.0 == "includebridgestoentity") {
          if (header.1 == "true") {
            includeBridgesToEntity := true;
          }
        } else if (header.0 == "includebridgespendingforentity") {
          if (header.1 == "true") {
            includeBridgesPendingForEntity := true;
          }
        }
      };
      let bridgeIds : [Text] = getBridgeIdsByEntityId(entityId, includeBridgesFromEntity, includeBridgesToEntity, includeBridgesPendingForEntity);
      let body = Text.encodeUtf8(debug_show(bridgeIds));
      let response = {
        body = body;
        headers = [("Content-Type", "text/html; charset=UTF-8"), ("Content-Length", Nat.toText(body.size()))];
        status_code = 200 : Nat16;
        streaming_strategy = null;
        upgrade = false;
      };
      return(response);
    } else if (request.url == "/getBridgesByEntityId") {
      let entityIdInput : ?HTTP.HeaderField = Array.find<HTTP.HeaderField>(request.headers, func (header) {
        if (header.0 == "entityid") {
          return true;
        } else {
          return false;
        };
      });
      let entityId : Text = switch(entityIdInput) {
        case (?v) { v.1 };
        case null {
          let response = {
            body = Text.encodeUtf8("No EntityId header provided");
            headers = [];
            status_code = 400 : Nat16;
            streaming_strategy = null;
            upgrade = false;
          };
          return(response);
        };
      };
      // fill variables from corresponding headers
      var includeBridgesFromEntity : Bool = false;
      var includeBridgesToEntity : Bool = false;
      var includeBridgesPendingForEntity : Bool = false;
      for (header in request.headers.vals()) {
        //Debug.print(debug_show("header"));
        //Debug.print(debug_show(header));
        if (header.0 == "includebridgesfromentity") {
          if (header.1 == "true") {
            includeBridgesFromEntity := true;
          }
        } else if (header.0 == "includebridgestoentity") {
          if (header.1 == "true") {
            includeBridgesToEntity := true;
          }
        } else if (header.0 == "includebridgespendingforentity") {
          if (header.1 == "true") {
            includeBridgesPendingForEntity := true;
          }
        }
      };
      let bridges : [BridgeEntity.BridgeEntity] = getBridgesByEntityId(entityId, includeBridgesFromEntity, includeBridgesToEntity, includeBridgesPendingForEntity);
      let body = Text.encodeUtf8(debug_show(bridges));
      let response = {
        body = body;
        headers = [("Content-Type", "text/html; charset=UTF-8"), ("Content-Length", Nat.toText(body.size()))];
        status_code = 200 : Nat16;
        streaming_strategy = null;
        upgrade = false;
      };
      return(response);
    } else if (request.url == "/getBridgedEntitiesByEntityId") {
      let entityIdInput : ?HTTP.HeaderField = Array.find<HTTP.HeaderField>(request.headers, func (header) {
        if (header.0 == "entityid") {
          return true;
        } else {
          return false;
        };
      });
      let entityId : Text = switch(entityIdInput) {
        case (?v) { v.1 };
        case null {
          let response = {
            body = Text.encodeUtf8("No EntityId header provided");
            headers = [];
            status_code = 400 : Nat16;
            streaming_strategy = null;
            upgrade = false;
          };
          return(response);
        };
      };
      // fill variables from corresponding headers
      var includeBridgesFromEntity : Bool = false;
      var includeBridgesToEntity : Bool = false;
      var includeBridgesPendingForEntity : Bool = false;
      for (header in request.headers.vals()) {
        //Debug.print(debug_show("header"));
        //Debug.print(debug_show(header));
        if (header.0 == "includebridgesfromentity") {
          if (header.1 == "true") {
            includeBridgesFromEntity := true;
          }
        } else if (header.0 == "includebridgestoentity") {
          if (header.1 == "true") {
            includeBridgesToEntity := true;
          }
        } else if (header.0 == "includebridgespendingforentity") {
          if (header.1 == "true") {
            includeBridgesPendingForEntity := true;
          }
        }
      };
      let bridgedEntities : [Entity.Entity] = getBridgedEntitiesByEntityId(entityId, includeBridgesFromEntity, includeBridgesToEntity, includeBridgesPendingForEntity);
      let body = Text.encodeUtf8(debug_show(bridgedEntities));
      let response = {
        body = body;
        headers = [("Content-Type", "text/html; charset=UTF-8"), ("Content-Length", Nat.toText(body.size()))];
        status_code = 200 : Nat16;
        streaming_strategy = null;
        upgrade = false;
      };
      return(response);
    } else if (request.url == "/getEntityAndBridgeIds") {
      let entityIdInput : ?HTTP.HeaderField = Array.find<HTTP.HeaderField>(request.headers, func (header) {
        if (header.0 == "entityid") {
          return true;
        } else {
          return false;
        };
      });
      let entityId : Text = switch(entityIdInput) {
        case (?v) { v.1 };
        case null {
          let response = {
            body = Text.encodeUtf8("No EntityId header provided");
            headers = [];
            status_code = 400 : Nat16;
            streaming_strategy = null;
            upgrade = false;
          };
          return(response);
        };
      };
      // fill variables from corresponding headers
      var includeBridgesFromEntity : Bool = false;
      var includeBridgesToEntity : Bool = false;
      var includeBridgesPendingForEntity : Bool = false;
      for (header in request.headers.vals()) {
        //Debug.print(debug_show("header"));
        //Debug.print(debug_show(header));
        if (header.0 == "includebridgesfromentity") {
          if (header.1 == "true") {
            includeBridgesFromEntity := true;
          }
        } else if (header.0 == "includebridgestoentity") {
          if (header.1 == "true") {
            includeBridgesToEntity := true;
          }
        } else if (header.0 == "includebridgespendingforentity") {
          if (header.1 == "true") {
            includeBridgesPendingForEntity := true;
          }
        }
      };
      let entityAndBridgeIds : (?Entity.Entity, [Text]) = getEntityAndBridgeIds(entityId, includeBridgesFromEntity, includeBridgesToEntity, includeBridgesPendingForEntity);
      let body = Text.encodeUtf8(debug_show(entityAndBridgeIds));
      let response = {
        body = body;
        headers = [("Content-Type", "text/html; charset=UTF-8"), ("Content-Length", Nat.toText(body.size()))];
        status_code = 200 : Nat16;
        streaming_strategy = null;
        upgrade = false;
      };
      return(response);
    } else {
      return {
        upgrade = true; // ← If this is set, the request will be sent to http_request_update()
        status_code = 200;
        headers = [ ("content-type", "text/plain") ];
        body = "It does not work";
        streaming_strategy = null;
      };
    }
  };

  public shared func http_request_update(request : HTTP.Request) : async HTTP.Response {
    Debug.print(debug_show("http_request_update"));
    Debug.print(debug_show(request));
    if (request.url == "/createEntity") {
      var inputCreator : ?Principal = null;
      var inputOwner : ?Principal = null;
      var inputEntityType : EntityType.EntityType = #Webasset; // must be updated
      var inputName : ?Text = null;
      var inputDescription : ?Text = null;
      var inputKeywords : ?[Text] = null;
      var inputExternalId : ?Text = null;

      let entityTypeInput : ?HTTP.HeaderField = Array.find<HTTP.HeaderField>(request.headers, func (header) {
        if (header.0 == "entitytype") {
          return true;
        } else {
          return false;
        };
      });
      let entityType : Text = switch(entityTypeInput) {
        case (?v) { v.1 };
        case null {
          let response = {
            body = Text.encodeUtf8("No EntityType header provided");
            headers = [];
            status_code = 400 : Nat16;
            streaming_strategy = null;
            upgrade = false;
          };
          return(response);
        };
      };
      // TODO: text input to EntityType enum must be done better and more scalable
      if (entityType == "webasset") {
        inputEntityType := #Webasset;
      } else if (entityType == "person") {
        inputEntityType := #Person;
      } else if (entityType == "location") {
        inputEntityType := #Location;
      } else {
        let response = {
            body = Text.encodeUtf8("EntityType not supported");
            headers = [];
            status_code = 400 : Nat16;
            streaming_strategy = null;
            upgrade = false;
          };
          return(response);
      };
      for (header in request.headers.vals()) {
        //Debug.print(debug_show("header"));
        //Debug.print(debug_show(header));
        if (header.0 == "creator") {
          inputCreator := ?Principal.fromText(header.1);
        } else if (header.0 == "owner") {
          inputOwner := ?Principal.fromText(header.1);
        } else if (header.0 == "name") {
          inputName := ?header.1;
        } else if (header.0 == "description") {
          inputDescription := ?header.1;
        } else if (header.0 == "keywords") {
          inputKeywords := ?[header.1]; // TODO: each keyword in input string should be one entry in array
        } else if (header.0 == "externalid") {
          inputExternalId := ?header.1;
        }
      };
      let entityInitiationObject : Entity.EntityInitiationObject = {
        _internalId = null; // random id will be assigned
        _creator = inputCreator;
        _owner = inputOwner;
        _settings = null; // TODO: allow specification
        _entityType = inputEntityType;
        _name = inputName;
        _description = inputDescription;
        _keywords = inputKeywords;
        _externalId = inputExternalId;
        _entitySpecificFields = null; // TODO: fill correctly
      };
      let entity : Entity.Entity = await create_entity(entityInitiationObject);
      let body = Text.encodeUtf8(debug_show(entity));
      let response = {
        body = body;
        headers = [("Content-Type", "text/html; charset=UTF-8"), ("Content-Length", Nat.toText(body.size()))];
        status_code = 200 : Nat16;
        streaming_strategy = null;
        upgrade = false;
      };
      return(response);
    } else if (request.url == "/createBridge") {
      var inputCreator : ?Principal = null;
      var inputOwner : ?Principal = null;
      var inputName : ?Text = null;
      var inputDescription : ?Text = null;
      var inputKeywords : ?[Text] = null;
      var inputExternalId : ?Text = null;
      var inputFromEntityId : Text = "";
      var inputToEntityId : Text = "";

      let fromEntityIdInput : ?HTTP.HeaderField = Array.find<HTTP.HeaderField>(request.headers, func (header) {
        if (header.0 == "fromentityid") {
          return true;
        } else {
          return false;
        };
      });
      inputFromEntityId := switch(fromEntityIdInput) {
        case (?v) {
          switch(getEntity(v.1)) {
            case null {
              let response = {
                body = Text.encodeUtf8("Invalid FromEntityId header provided");
                headers = [];
                status_code = 400 : Nat16;
                streaming_strategy = null;
                upgrade = false;
              };
              return(response);
            };
            case (?entity) { v.1 };
          };
        };
        case null {
          let response = {
            body = Text.encodeUtf8("No FromEntityId header provided");
            headers = [];
            status_code = 400 : Nat16;
            streaming_strategy = null;
            upgrade = false;
          };
          return(response);
        };
      };
      let toEntityIdInput : ?HTTP.HeaderField = Array.find<HTTP.HeaderField>(request.headers, func (header) {
        if (header.0 == "toentityid") {
          return true;
        } else {
          return false;
        };
      });
      inputToEntityId := switch(toEntityIdInput) {
        case (?v) {
          switch(getEntity(v.1)) {
            case null {
              let response = {
                body = Text.encodeUtf8("Invalid ToEntityId header provided");
                headers = [];
                status_code = 400 : Nat16;
                streaming_strategy = null;
                upgrade = false;
              };
              return(response);
            };
            case (?entity) { v.1 };
          };
        };
        case null {
          let response = {
            body = Text.encodeUtf8("No ToEntityId header provided");
            headers = [];
            status_code = 400 : Nat16;
            streaming_strategy = null;
            upgrade = false;
          };
          return(response);
        };
      };
      for (header in request.headers.vals()) {
        //Debug.print(debug_show("header"));
        //Debug.print(debug_show(header));
        if (header.0 == "creator") {
          inputCreator := ?Principal.fromText(header.1);
        } else if (header.0 == "owner") {
          inputOwner := ?Principal.fromText(header.1);
        } else if (header.0 == "name") {
          inputName := ?header.1;
        } else if (header.0 == "description") {
          inputDescription := ?header.1;
        } else if (header.0 == "keywords") {
          inputKeywords := ?[header.1]; // TODO: each keyword in input string should be one entry in array
        } else if (header.0 == "externalid") {
          inputExternalId := ?header.1;
        }
      };
      let entityInitiationObject : BridgeEntity.BridgeEntityInitiationObject = {
        _internalId = null; // random id will be assigned
        _creator = inputCreator;
        _owner = inputOwner;
        _settings = null; // TODO: allow specification
        _entityType = #BridgeEntity;
        _name = inputName;
        _description = inputDescription;
        _keywords = inputKeywords;
        _externalId = inputExternalId;
        _entitySpecificFields = null; // TODO: fill correctly
        _bridgeType = #OwnerCreated; // TODO: fill appropriately
        _fromEntityId = inputFromEntityId;
        _toEntityId = inputToEntityId;
        _state = ?#Pending; // TODO: fill appropriately
      };
      let entity : ?BridgeEntity.BridgeEntity = await create_bridge(entityInitiationObject);
      let body = Text.encodeUtf8(debug_show(entity));
      let response = {
        body = body;
        headers = [("Content-Type", "text/html; charset=UTF-8"), ("Content-Length", Nat.toText(body.size()))];
        status_code = 200 : Nat16;
        streaming_strategy = null;
        upgrade = false;
      };
      return(response);
    } else if (request.url == "/createEntityAndBridge") {
      var inputCreator : ?Principal = null;
      var inputOwner : ?Principal = null;
      var inputEntityType : EntityType.EntityType = #Webasset; // must be updated
      var inputName : ?Text = null;
      var inputDescription : ?Text = null;
      var inputKeywords : ?[Text] = null;
      var inputExternalId : ?Text = null;

      let entityTypeInput : ?HTTP.HeaderField = Array.find<HTTP.HeaderField>(request.headers, func (header) {
        if (header.0 == "entitytype") {
          return true;
        } else {
          return false;
        };
      });
      let entityType : Text = switch(entityTypeInput) {
        case (?v) { v.1 };
        case null {
          let response = {
            body = Text.encodeUtf8("No EntityType header provided");
            headers = [];
            status_code = 400 : Nat16;
            streaming_strategy = null;
            upgrade = false;
          };
          return(response);
        };
      };
      // TODO: text input to EntityType enum must be done better and more scalable
      if (entityType == "webasset") {
        inputEntityType := #Webasset;
      } else if (entityType == "person") {
        inputEntityType := #Person;
      } else if (entityType == "location") {
        inputEntityType := #Location;
      } else {
        let response = {
            body = Text.encodeUtf8("EntityType not supported");
            headers = [];
            status_code = 400 : Nat16;
            streaming_strategy = null;
            upgrade = false;
          };
          return(response);
      };
      for (header in request.headers.vals()) {
        //Debug.print(debug_show("header"));
        //Debug.print(debug_show(header));
        if (header.0 == "creator") {
          inputCreator := ?Principal.fromText(header.1);
        } else if (header.0 == "owner") {
          inputOwner := ?Principal.fromText(header.1);
        } else if (header.0 == "name") {
          inputName := ?header.1;
        } else if (header.0 == "description") {
          inputDescription := ?header.1;
        } else if (header.0 == "keywords") {
          inputKeywords := ?[header.1]; // TODO: each keyword in input string should be one entry in array
        } else if (header.0 == "externalid") {
          inputExternalId := ?header.1;
        }
      };
      let entityInitiationObject : Entity.EntityInitiationObject = {
        _internalId = null; // random id will be assigned
        _creator = inputCreator;
        _owner = inputOwner;
        _settings = null; // TODO: allow specification
        _entityType = inputEntityType;
        _name = inputName;
        _description = inputDescription;
        _keywords = inputKeywords;
        _externalId = inputExternalId;
        _entitySpecificFields = null; // TODO: fill correctly
      };

      // Bridge initiation object
      var inputBridgeName : ?Text = null;
      var inputBridgeDescription : ?Text = null;
      var inputBridgeKeywords : ?[Text] = null;
      var inputBridgeExternalId : ?Text = null;
      var inputFromEntityId : Text = "";
      var inputToEntityId : Text = "";

      let fromEntityIdInput : ?HTTP.HeaderField = Array.find<HTTP.HeaderField>(request.headers, func (header) {
        if (header.0 == "fromentityid") {
          return true;
        } else {
          return false;
        };
      });
      let toEntityIdInput : ?HTTP.HeaderField = Array.find<HTTP.HeaderField>(request.headers, func (header) {
        if (header.0 == "toentityid") {
          return true;
        } else {
          return false;
        };
      });
      inputFromEntityId := switch(fromEntityIdInput) {
        case (?v) {
          switch(getEntity(v.1)) {
            case null {
              let response = {
                body = Text.encodeUtf8("Invalid FromEntityId header provided");
                headers = [];
                status_code = 400 : Nat16;
                streaming_strategy = null;
                upgrade = false;
              };
              return(response);
            };
            case (?entity) { v.1 };
          };
        };
        case null {
          inputToEntityId := switch(toEntityIdInput) {
            case (?vTo) {
              switch(getEntity(vTo.1)) {
                case null {
                  let response = {
                    body = Text.encodeUtf8("Invalid ToEntityId header provided");
                    headers = [];
                    status_code = 400 : Nat16;
                    streaming_strategy = null;
                    upgrade = false;
                  };
                  return(response);
                };
                case (?entityTo) { vTo.1 };
              };
            };
            case null {
              let response = {
                body = Text.encodeUtf8("Neither FromEntityId nor ToEntityId header provided");
                headers = [];
                status_code = 400 : Nat16;
                streaming_strategy = null;
                upgrade = false;
              };
              return(response);
            };
          };
          "" // needed to be returned to inputFromEntityId (outer switch)
        };
      };

      for (header in request.headers.vals()) {
        //Debug.print(debug_show("header"));
        //Debug.print(debug_show(header));
        if (header.0 == "creator") {
          inputCreator := ?Principal.fromText(header.1);
        } else if (header.0 == "owner") {
          inputOwner := ?Principal.fromText(header.1);
        } else if (header.0 == "name") {
          inputName := ?header.1;
        } else if (header.0 == "description") {
          inputDescription := ?header.1;
        } else if (header.0 == "keywords") {
          inputKeywords := ?[header.1]; // TODO: each keyword in input string should be one entry in array
        } else if (header.0 == "externalid") {
          inputExternalId := ?header.1;
        }
      };
      let bridgeInitiationObject : BridgeEntity.BridgeEntityInitiationObject = {
        _internalId = null; // random id will be assigned
        _creator = inputCreator; // potentially allow for different, bridge-specific input
        _owner = inputOwner; // potentially allow for different, bridge-specific input
        _settings = null; // TODO: allow specification
        _entityType = #BridgeEntity;
        _name = inputBridgeName;
        _description = inputBridgeDescription;
        _keywords = inputBridgeKeywords;
        _externalId = inputBridgeExternalId;
        _entitySpecificFields = null; // TODO: fill correctly
        _bridgeType = #OwnerCreated; // TODO: fill appropriately
        _fromEntityId = inputFromEntityId;
        _toEntityId = inputToEntityId;
        _state = ?#Pending; // TODO: fill appropriately
      };

      let entityAndBridge : (Entity.Entity, ?BridgeEntity.BridgeEntity) = await create_entity_and_bridge(entityInitiationObject, bridgeInitiationObject);
      let body = Text.encodeUtf8(debug_show(entityAndBridge));
      let response = {
        body = body;
        headers = [("Content-Type", "text/html; charset=UTF-8"), ("Content-Length", Nat.toText(body.size()))];
        status_code = 200 : Nat16;
        streaming_strategy = null;
        upgrade = false;
      };
      return(response);      
    } else {
      let response = {
        body = Text.encodeUtf8("Not supported");
        headers = [];
        status_code = 404 : Nat16;
        streaming_strategy = null;
        upgrade = false;
      };
      return(response);
    }
  };

// Upgrade Hooks
  system func preupgrade() {
    entitiesStorageStable := Iter.toArray(entitiesStorage.entries());
    bridgesStorageStable := Iter.toArray(bridgesStorage.entries());
    pendingFromBridgesStorageStable := Iter.toArray(pendingFromBridgesStorage.entries());
    pendingToBridgesStorageStable := Iter.toArray(pendingToBridgesStorage.entries());
    fromBridgesStorageStable := Iter.toArray(fromBridgesStorage.entries());
    toBridgesStorageStable := Iter.toArray(toBridgesStorage.entries());
  };

  system func postupgrade() {
    entitiesStorage := HashMap.fromIter(Iter.fromArray(entitiesStorageStable), entitiesStorageStable.size(), Text.equal, Text.hash);
    entitiesStorageStable := [];
    bridgesStorage := HashMap.fromIter(Iter.fromArray(bridgesStorageStable), bridgesStorageStable.size(), Text.equal, Text.hash);
    bridgesStorageStable := [];
    pendingFromBridgesStorage := HashMap.fromIter(Iter.fromArray(pendingFromBridgesStorageStable), pendingFromBridgesStorageStable.size(), Text.equal, Text.hash);
    pendingFromBridgesStorageStable := [];
    pendingToBridgesStorage := HashMap.fromIter(Iter.fromArray(pendingToBridgesStorageStable), pendingToBridgesStorageStable.size(), Text.equal, Text.hash);
    pendingToBridgesStorageStable := [];
    fromBridgesStorage := HashMap.fromIter(Iter.fromArray(fromBridgesStorageStable), fromBridgesStorageStable.size(), Text.equal, Text.hash);
    fromBridgesStorageStable := [];
    toBridgesStorage := HashMap.fromIter(Iter.fromArray(toBridgesStorageStable), toBridgesStorageStable.size(), Text.equal, Text.hash);
    toBridgesStorageStable := [];
  };
};
