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

import Entity "entity";
import Bridge "bridge";
import HTTP "./Http";
import Types "./Types";
import Utils "./Utils";

actor {
// INTERFACE
  public shared ({ caller }) func create_entity(entityToCreate : Entity.EntityInitiationObject) : async Entity.EntityIdResult {
    let result = await createEntity(caller, entityToCreate);
    switch(result)
    {
      case ("") { return #Error(#Error)};
      case (?id) { return #OK(id)};
    }
  };

  public shared query ({ caller }) func get_entity(entityId : Text) : async Entity.EntityResult {
    let result = getEntity(entityId);
    switch(result)
    {
      case (null) { return #Error(#EntityNotFound)};
      case (?entity) { return #OK(entity)};
    }
  };

  public shared ({ caller }) func create_bridge(bridgeToCreate : Bridge.BridgeInitiationObject) : async ?Bridge.Bridge {
    let result = await createBridge(caller, bridgeToCreate);
    return result;
    // return BridgeCreator.create_bridge(bridgeToCreate); TODO: possible to return promise? Would this speed up this canister?
  };

  public shared query ({ caller }) func get_bridge(entityId : Text) : async ?Bridge.Bridge {
    let result = getBridge(entityId);
    return result;
  };

  public shared query ({ caller }) func get_bridge_ids_by_entity_id(entityId : Text, includeBridgesFromEntity : Bool, includeBridgesToEntity : Bool, includeBridgesPendingForEntity : Bool) : async [Text] {
    let result = getBridgeIdsByEntityId(entityId, includeBridgesFromEntity, includeBridgesToEntity, includeBridgesPendingForEntity);
    return result;
  };

  public shared query ({ caller }) func get_bridges_by_entity_id(entityId : Text, includeBridgesFromEntity : Bool, includeBridgesToEntity : Bool, includeBridgesPendingForEntity : Bool) : async [Bridge.Bridge] {
    let result = getBridgesByEntityId(entityId, includeBridgesFromEntity, includeBridgesToEntity, includeBridgesPendingForEntity);
    return result;
  };

  public shared ({ caller }) func create_entity_and_bridge(entityToCreate : Entity.EntityInitiationObject, bridgeToCreate : Bridge.BridgeInitiationObject) : async (Entity.Entity, ?Bridge.Bridge) {
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

  public shared ({ caller }) func update_bridge(bridgeUpdateObject : Bridge.BridgeUpdateObject) : async Types.BridgeResult {
    let result = await updateBridge(caller, bridgeUpdateObject);
    return result;
  };

  public shared ({ caller }) func update_entity(entityUpdateObject : Entity.EntityUpdateObject) : async Entity.EntityIdResult {
    let result = await updateEntity(caller, entityUpdateObject);
    switch(result)
    {
      case ("") { return #Error(#Error)};
      case (?id) { return #OK(id)};
    }
  };

// HELPER FUNCTIONS
  func createEntity(caller : Principal, entityToCreate : Entity.EntityInitiationObject) : async Text {
    // Create the entity 
    var entity = await Entity.generateEntityFromInitializationObject(entityToCreate, caller);
    
    // Find a unique id for the new entity that will not
    // conflict with any current items
    var newEntityId : Text = "";
    var counter : Nat = 0;
    var found_unique_id : Bool = false;
    while(not found_unique_id)
    {
      // 100 is chosen arbitarily to ensure that in case of something weird happening
      //  there is a timeout and it errors rather then looking forever
      if (counter > 100)
      {
        return "";
      };

      newEntityId := await Utils.newRandomUniqueId();
      if (entitiesStorage.get(newId) == null)
      {
        entity.id := newEntityId;
        return putEntity(entity)
      };

      counter := counter + 1;
    };
    return "";
  };

  stable var entitiesStorageStable : [(Text, Entity.Entity)] = [];
  var entitiesStorage : HashMap.HashMap<Text, Entity.Entity> = HashMap.HashMap(0, Text.equal, Text.hash);

  func putEntity(entity : Entity.Entity) : Text {
    entitiesStorage.put(entity.id, entity);
    return entity.id;
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

  func createBridge(caller : Principal, bridgeToCreate : Bridge.BridgeInitiationObject) : async ?Bridge.Bridge {
    // ensure that bridged Entities exist
    switch(checkIfEntityWithAttributeExists("internalId", bridgeToCreate._fromEntityId)) {
      case false { return null; }; // TODO: potentially return error message instead
      case true {
        if (checkIfEntityWithAttributeExists("internalId", bridgeToCreate._toEntityId) == false) {
          return null; // TODO: potentially return error message instead
        };
      };
    };
    let bridge : Bridge.Bridge = await Bridge.Bridge(bridgeToCreate, caller);
    let result = putBridge(bridge);
    return ?result;
  };

  stable var bridgesStorageStable : [(Text, Bridge.Bridge)] = [];
  var bridgesStorage : HashMap.HashMap<Text, Bridge.Bridge> = HashMap.HashMap(0, Text.equal, Text.hash);

  func putBridge(bridge : Bridge.Bridge) : Bridge.Bridge {
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

  func putEntityEntry(bridge : Bridge.Bridge) : Text {
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

  func getBridge(entityId : Text) : ?Bridge.Bridge {
    let bridgeToReturn : ?Bridge.Bridge = bridgesStorage.get(entityId);
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

  func getBridgesByEntityId(entityId : Text, includeBridgesFromEntity : Bool, includeBridgesToEntity : Bool, includeBridgesPendingForEntity : Bool) : [Bridge.Bridge] {
    let bridgeIdsToRetrieve = getBridgeIdsByEntityId(entityId, includeBridgesFromEntity, includeBridgesToEntity, includeBridgesPendingForEntity);
    // adapted from https://forum.dfinity.org/t/motoko-sharable-generics/9021/3
    let executingFunctionsBuffer = Buffer.Buffer<?Bridge.Bridge>(bridgeIdsToRetrieve.size());
    for (bridgeId in bridgeIdsToRetrieve.vals()) { 
      executingFunctionsBuffer.add(getBridge(bridgeId)); 
    };
    let collectingResultsBuffer = Buffer.Buffer<Bridge.Bridge>(bridgeIdsToRetrieve.size());
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

  func createEntityAndBridge(caller : Principal, entityToCreate : Entity.EntityInitiationObject, bridgeToCreate : Bridge.BridgeInitiationObject) : async (Entity.Entity, ?Bridge.Bridge) {  
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
    let bridge : ?Bridge.Bridge = await createBridge(caller, updatedBridgeToCreate);
    return (createdEntity, bridge);
  };

  func getBridgedEntitiesByEntityId(entityId : Text, includeBridgesFromEntity : Bool, includeBridgesToEntity : Bool, includeBridgesPendingForEntity : Bool) : [Entity.Entity] {
    let entityBridges : [Bridge.Bridge] = getBridgesByEntityId(entityId, includeBridgesFromEntity, includeBridgesToEntity, includeBridgesPendingForEntity);
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

  func detachBridgeFromEntities(bridge : Bridge.Bridge) : Bool {
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

  func updateBridge(caller : Principal, bridgeUpdateObject : Bridge.BridgeUpdateObject) : async Types.BridgeResult {
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
            let updatedBridge : Bridge.Bridge = {
              internalId : Text = bridgeToUpdate.internalId;
              creationTimestamp : Nat64 = bridgeToUpdate.creationTimestamp;
              creator : Principal = bridgeToUpdate.creator;
              owner : Principal = bridgeToUpdate.owner;
              settings : Entity.EntitySettings = Option.get<Entity.EntitySettings>(bridgeUpdateObject.settings, bridgeToUpdate.settings);
              entityType : Entity.EntityType = bridgeToUpdate.entityType;
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

  func updateEntity(caller : Principal, entityUpdateObject : Entity.EntityUpdateObject) : async Entity.EntityResult {
    switch(getEntity(entityUpdateObject.id)) {
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
              id : Text = entityToUpdate.id;
              creationTimestamp : Nat64 = entityToUpdate.creationTimestamp;
              creator : Principal = entityToUpdate.creator;
              owner : Principal = entityToUpdate.owner;
              settings : Entity.EntitySettings = Option.get<Entity.EntitySettings>(entityUpdateObject.settings, entityToUpdate.settings);
              entityType : Entity.EntityType = entityToUpdate.entityType;
              name : ?Text = Option.get<?Text>(?entityUpdateObject.name, entityToUpdate.name);
              description : ?Text = Option.get<?Text>(?entityUpdateObject.description, entityToUpdate.description);
              keywords : ?[Text] = Option.get<?[Text]>(?entityUpdateObject.keywords, entityToUpdate.keywords);
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
