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
      case ("") { return #Err(#Error)};
      case (id) { return #Ok(id)};
    }
  };

  public shared query ({ caller }) func get_entity(entityId : Text) : async Entity.EntityResult {
    let result = getEntity(entityId);
    switch(result)
    {
      case (null) { return #Err(#EntityNotFound)};
      case (entity) { return #Ok(entity)};
    }
  };

  public shared ({ caller }) func create_bridge(bridgeToCreate : Bridge.BridgeInitiationObject) : async ?Bridge.BridgeIdErrors {
    let result = await createBridge(caller, bridgeToCreate);
    switch(result)
    {
      case (null) { return #Err(#Error)};
      case (id) { return #Ok(id)};
    } };

  public shared query ({ caller }) func get_bridge(entityId : Text) : async ?Bridge.Bridge {
    let result = getBridge(entityId);
    return result;
  };

  // public shared query ({ caller }) func get_bridge_ids_by_entity_id(entityId : Text, includeBridgesFromEntity : Bool, includeBridgesToEntity : Bool, includeBridgesPendingForEntity : Bool) : async [Text] {
  //   let result = getBridgeIdsByEntityId(entityId, includeBridgesFromEntity, includeBridgesToEntity, includeBridgesPendingForEntity);
  //   return result;
  // };

  // public shared query ({ caller }) func get_bridges_by_entity_id(entityId : Text, includeBridgesFromEntity : Bool, includeBridgesToEntity : Bool, includeBridgesPendingForEntity : Bool) : async [Bridge.Bridge] {
  //   let result = getBridgesByEntityId(entityId, includeBridgesFromEntity, includeBridgesToEntity, includeBridgesPendingForEntity);
  //   return result;
  // };

  // public shared ({ caller }) func create_entity_and_bridge(entityToCreate : Entity.EntityInitiationObject, bridgeToCreate : Bridge.BridgeInitiationObject) : async (Entity.Entity, ?Bridge.Bridge) {
  //   let result = await createEntityAndBridge(caller, entityToCreate, bridgeToCreate);
  //   return result;
  // };

  // public shared query ({ caller }) func get_bridged_entities_by_entity_id(entityId : Text, includeBridgesFromEntity : Bool, includeBridgesToEntity : Bool, includeBridgesPendingForEntity : Bool) : async [Entity.Entity] {
  //   let result = getBridgedEntitiesByEntityId(entityId, includeBridgesFromEntity, includeBridgesToEntity, includeBridgesPendingForEntity);
  //   return result;
  // };

  // public shared query ({ caller }) func get_entity_and_bridge_ids(entityId : Text, includeBridgesFromEntity : Bool, includeBridgesToEntity : Bool, includeBridgesPendingForEntity : Bool) : async (?Entity.Entity, [Text]) {
  //   let result = getEntityAndBridgeIds(entityId, includeBridgesFromEntity, includeBridgesToEntity, includeBridgesPendingForEntity);
  //   return result;
  // };

  public shared ({ caller }) func delete_bridge(bridgeId : Text) : async Bridge.BridgeIdResult {
    let result = await deleteBridge(caller, bridgeId);
    return result;
  };

  public shared ({ caller }) func update_bridge(bridgeUpdateObject : Bridge.BridgeUpdateObject) : async Bridge.BridgeIdResult {
    let result = await updateBridge(caller, bridgeUpdateObject);
    return result;
  };

  public shared ({ caller }) func update_entity(entityUpdateObject : Entity.EntityUpdateObject) : async Entity.EntityIdResult {
    let result = await updateEntity(caller, entityUpdateObject);
    return result;
  };

// HELPER FUNCTIONS
  /**
   * Function creates a new entity based on the input initialization object. If it is able
   * to make the object, it stores it and return the id, otherwise it will not
   * store an object and return an empty string
   *
   * @return The id of the new entity if the entity creation was successful, otherwise an empty string
  */
  private func createEntity(caller : Principal, entityToCreate : Entity.EntityInitiationObject) : async Text {

    // Find a unique id for the new entity that will not
    // conflict with any current items
    var newEntityId : Text = "";
    var counter : Nat = 0;
    var found_unique_id : Bool = false;
    while(not found_unique_id)
    {
      // 10 is chosen arbitarily to ensure that in case of something weird happening
      //  there is a timeout and it errors rather then looking forever
      if (counter > 10)
      {
        return "";
      };

      newEntityId := await Utils.newRandomUniqueId();
      switch (entitiesStorage.get(newEntityId))
      {
        case (null) {
          // Create the entity 
          let entity = Entity.generateEntityFromInitializationObject(entityToCreate, newEntityId, caller);
          return putEntity(entity);
        };
        case (_)
        {
          counter := counter + 1;
        };
      };


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

  /**
  * Function checks that the given entity id provided exists within the database
  *
  * @return True if the entity exists, false otherwise
  */
  private func checkIfEntityExists(entityId : Text) : Bool {
    let result = getEntity(entityId);
    switch(result)
    {
      case(null) { return  false;};
      case(entity) { return true;};
    };
  };


  // func checkIfEntityWithAttributeExists(attribute : Text, attributeValue : Text) : Bool {
  //   switch(attribute) {
  //     case "internalId" {
  //       switch(getEntity(attributeValue)) {
  //         case null { return false; };
  //         case _ { return true; };
  //       };
  //     };
  //     case "externalId" {
  //       for ((k, entity) in entitiesStorage.entries()) {
  //         if (entity.externalId == ?attributeValue) {
  //           return true;
  //         };          
  //       };
  //       return false;
  //     };
  //     case _ { return false; }
  //   };
  // };

  // func getEntityByAttribute(attribute : Text, attributeValue : Text) : ?Entity.Entity {
  //   switch(attribute) {
  //     case "internalId" {
  //       return getEntity(attributeValue);
  //     };
  //     case "externalId" {
  //       for ((k, entity) in entitiesStorage.entries()) {
  //         if (entity.externalId == ?attributeValue) {
  //           return ?entity;
  //         };          
  //       };
  //       return null;
  //     };
  //     case _ { return null; }
  //   };
  // };

  // func getEntitiesByAttribute(attribute : Text, attributeValue : Text) : [Entity.Entity] {
  //   switch(attribute) {
  //     case "externalId" {
  //       var entitiesToReturn = List.nil<Entity.Entity>();
  //       for ((k, entity) in entitiesStorage.entries()) {
  //         if (entity.externalId == ?attributeValue) {
  //           entitiesToReturn := List.push<Entity.Entity>(entity, entitiesToReturn);
  //         };          
  //       };
  //       return List.toArray<Entity.Entity>(entitiesToReturn);
  //     };
  //     case _ { return []; }
  //   };
  // };

  /**
   * Function creates a new bridge based on the input initialization object. If it is able
   * to make the object, it stores it and return the id, otherwise it will not
   * store an object and return an empty string
   *
   * @return The id of the new entity if the entity creation was successful, otherwise an empty string
  */
  private func createBridge(caller : Principal, bridgeToCreate : Bridge.BridgeInitiationObject) : async ?Text{
    // Check if both the to and from entities exist for the bridge
    let toEntityExists = checkIfEntityExists(bridgeToCreate.toEntityId);
    let fromEntityExists = checkIfEntityExists(bridgeToCreate.fromEntityId);
    
    if (toEntityExists == false or fromEntityExists == false)
    {
      return null;
    };


    // Find a unique id for the new bridge that will not
    // conflict with any current items
    var newBridgeId : Text = "";
    var counter : Nat = 0;
    var found_unique_id : Bool = false;
    while(not found_unique_id)
    {
      // 10 is chosen arbitarily to ensure that in case of something weird happening
      //  there is a timeout and it errors rather then looking forever
      if (counter > 10)
      {
        return null;
      };

      newBridgeId := await Utils.newRandomUniqueId();
      if (bridgesStorage.get(newBridgeId) == null)
      {
        let bridge : Bridge.Bridge = Bridge.generateBridgeFromInitializationObject(bridgeToCreate, newBridgeId, caller);
        return addNewBridge(bridge)
      };

      counter := counter + 1;
    };
    return null;
  };

  stable var bridgesStorageStable : [(Text, Bridge.Bridge)] = [];
  var bridgesStorage : HashMap.HashMap<Text, Bridge.Bridge> = HashMap.HashMap(0, Text.equal, Text.hash);

  /**
   * Function adds a new bridge and attempts to add the bridge to the entities
   * bridge lookup tables. If adding the bridge to the entities fails, then the bridge
   * is not created and is instead deleted
   *
   * @return Returns null if the entitiy failed to get created, otherwise it returns
   * the bridge id of the newly created bridge
  */
  private func addNewBridge(bridge : Bridge.Bridge) : ?Text {
    // Don't allow creating the bridge if the bridge already exists 
    if (checkIfBridgeExists(bridge.id) == true)
    {
      return null;
    };

    let result = putBridge(bridge);
    let fromIdResult = addBridgeToEntityFromIds(bridge.fromEntityId, bridge.id);
    let toIdResult = addBridgeToEntityToIds(bridge.toEntityId, bridge.id);
    
    // Ensure the bridge could be added to both entities bridge lookup tables
    if (fromIdResult == false or toIdResult == false)
    {
      // Delete the bridge since it failed to get created
      bridgesStorage.delete(bridge.id);
      return null;
    };

    return ?bridge.id;
  };

  /**
   * Function is a simple way to add a Bridge to storage without any checks and 
   * adding the bridge to the appropriate entity. This is useful for updating
   * an already created bridge
   *
   * @return The newly created bridge
  */
  func putBridge(bridge : Bridge.Bridge) : Bridge.Bridge {
    let result = bridgesStorage.put(bridge.id, bridge);
    return bridge;
  };


  /**
   * This function takes a bridge and adds the bridge ID to the fromIds field
   * to the entity that this Bridge Links from
   *
   * @return True if the bridge ID was added to the from ID list, otherwise
   * false is returned if it couldn't
  */
  private func addBridgeToEntityFromIds(entityId: Text, bridgeId : Text) : Bool {
    let entity = getEntity(entityId);
    switch (entity) {
      case (null) {
        return false;
      };
      case (?retrievedEntity) {
        retrievedEntity.fromIds := Array.append<Text>(retrievedEntity.fromIds, [bridgeId]);
        return true;
      }
    }
  };

  /**
   * This function takes a bridge and adds the bridge ID to the toIds field
   * to the entity that this Bridge Links to
   *
   * @return True if the bridge ID was added to the to ID list, otherwise
   * false is returned if it couldn't
  */
  private func addBridgeToEntityToIds(entityId: Text, bridgeId : Text) : Bool {
    var entity = getEntity(entityId);
    switch (entity) {
      case (null) {
        return false;
      };
      case (?retrievedEntity) {
        retrievedEntity.toIds := Array.append<Text>(retrievedEntity.toIds, [bridgeId]);
        return true;
      }
    }
  };

  /**
   * Function retrieves a bridge based on the input ID 
   * 
   * @return The bridge if it is found or null if not found
  */
  private func getBridge(bridgeId : Text) : ?Bridge.Bridge {
    let result = bridgesStorage.get(bridgeId);
    return result;
  };

  /**
  * Function checks that the given bridge id provided exists within the database
  *
  * @return True if the entity exists, false otherwise
  */
  private func checkIfBridgeExists(bridgeId : Text) : Bool {
    let result = getBridge(bridgeId);
    switch(result)
    {
      case(null) { return  false;};
      case(bridge) { return true;};
    };
  };

  // type BridgeCategories = { // TODO: define bridge categories, probably import from a dedicated file (BridgeType)
  //   ownerCreatedBridges : List.List<Text>;
  //   otherBridges : List.List<Text>;
  // };

  // stable var pendingFromBridgesStorageStable : [(Text, BridgeCategories)] = [];
  // var pecndingFromBridgesStorage : HashMap.HashMap<Text, BridgeCategories> = HashMap.HashMap(0, Text.equal, Text.hash);
  // stable var pendingToBridgesStorageStable : [(Text, BridgeCategories)] = [];
  // var pendingToBridgesStorage : HashMap.HashMap<Text, BridgeCategories> = HashMap.HashMap(0, Text.equal, Text.hash);
  // stable var fromBridgesStorageStable : [(Text, BridgeCategories)] = [];
  // var fromBridgesStorage : HashMap.HashMap<Text, BridgeCategories> = HashMap.HashMap(0, Text.equal, Text.hash);
  // stable var toBridgesStorageStable : [(Text, BridgeCategories)] = [];
  // var toBridgesStorage : HashMap.HashMap<Text, BridgeCategories> = HashMap.HashMap(0, Text.equal, Text.hash);

  // func putEntityEntry(bridge : Bridge.Bridge) : Text {
  //   if (bridge.state == #Pending) { // if bridge state is Pending, store accordingly
  //   // store in pending from storage
  //     switch(pendingFromBridgesStorage.get(bridge.fromEntityId)) {
  //       case null {
  //         // first entry for entityId
  //         var otherBridgesList = List.nil<Text>();
  //         otherBridgesList := List.push<Text>(bridge.internalId, otherBridgesList);
  //         let newEntityEntry : BridgeCategories = {
  //           ownerCreatedBridges = List.nil<Text>();
  //           otherBridges = otherBridgesList;
  //         };
  //         pendingFromBridgesStorage.put(bridge.fromEntityId, newEntityEntry);     
  //       };
  //       case (?entityEntry) {
  //         // add to existing entry for entityId
  //         let updatedEntityEntry : BridgeCategories = {
  //           ownerCreatedBridges = entityEntry.ownerCreatedBridges;
  //           otherBridges = List.push<Text>(bridge.internalId, entityEntry.otherBridges);
  //         };
  //         pendingFromBridgesStorage.put(bridge.fromEntityId, updatedEntityEntry);    
  //       };
  //     };
  //   // store in pending to storage
  //     switch(pendingToBridgesStorage.get(bridge.toEntityId)) {
  //       case null {
  //         // first entry for entityId
  //         var otherBridgesList = List.nil<Text>();
  //         otherBridgesList := List.push<Text>(bridge.internalId, otherBridgesList);
  //         let newEntityEntry : BridgeCategories = {
  //           ownerCreatedBridges = List.nil<Text>();
  //           otherBridges = otherBridgesList;
  //         };
  //         pendingToBridgesStorage.put(bridge.toEntityId, newEntityEntry);     
  //       };
  //       case (?entityEntry) {
  //         // add to existing entry for entityId
  //         let updatedEntityEntry : BridgeCategories = {
  //           ownerCreatedBridges = entityEntry.ownerCreatedBridges;
  //           otherBridges = List.push<Text>(bridge.internalId, entityEntry.otherBridges);
  //         };
  //         pendingToBridgesStorage.put(bridge.toEntityId, updatedEntityEntry);    
  //       };
  //     };
  //   } else {
  //     // store bridge for entities bridged to and from
  //     // store in from storage
  //     switch(fromBridgesStorage.get(bridge.fromEntityId)) {
  //       case null {
  //         // first entry for entityId
  //         var otherBridgesList = List.nil<Text>();
  //         otherBridgesList := List.push<Text>(bridge.internalId, otherBridgesList);
  //         let newEntityEntry : BridgeCategories = {
  //           ownerCreatedBridges = List.nil<Text>();
  //           otherBridges = otherBridgesList;
  //         };
  //         fromBridgesStorage.put(bridge.fromEntityId, newEntityEntry);     
  //       };
  //       case (?entityEntry) {
  //         // add to existing entry for entityId
  //         let updatedEntityEntry : BridgeCategories = {
  //           ownerCreatedBridges = entityEntry.ownerCreatedBridges;
  //           otherBridges = List.push<Text>(bridge.internalId, entityEntry.otherBridges);
  //         };
  //         fromBridgesStorage.put(bridge.fromEntityId, updatedEntityEntry);    
  //       };
  //     };
  //   // store in to storage
  //     switch(toBridgesStorage.get(bridge.toEntityId)) {
  //       case null {
  //         // first entry for entityId
  //         var otherBridgesList = List.nil<Text>();
  //         otherBridgesList := List.push<Text>(bridge.internalId, otherBridgesList);
  //         let newEntityEntry : BridgeCategories = {
  //           ownerCreatedBridges = List.nil<Text>();
  //           otherBridges = otherBridgesList;
  //         };
  //         toBridgesStorage.put(bridge.toEntityId, newEntityEntry);     
  //       };
  //       case (?entityEntry) {
  //         // add to existing entry for entityId
  //         let updatedEntityEntry : BridgeCategories = {
  //           ownerCreatedBridges = entityEntry.ownerCreatedBridges;
  //           otherBridges = List.push<Text>(bridge.internalId, entityEntry.otherBridges);
  //         };
  //         toBridgesStorage.put(bridge.toEntityId, updatedEntityEntry);    
  //       };
  //     };
  //   };
  //   return bridge.internalId;
  // };

  // func getBridgeIdsByEntityId(entityId : Text, includeBridgesFromEntity : Bool, includeBridgesToEntity : Bool, includeBridgesPendingForEntity : Bool) : [Text] {
  //   var bridgeIdsToReturn = List.nil<Text>();
  //   if (includeBridgesFromEntity) {
  //     switch(fromBridgesStorage.get(entityId)) {
  //       case null {};
  //       case (?entityEntry) {
  //         bridgeIdsToReturn := List.append<Text>(bridgeIdsToReturn, entityEntry.otherBridges); // TODO: determine which category's list/categories' lists in entry to return
  //       };
  //     };
  //   };
  //   if (includeBridgesToEntity) {
  //     switch(toBridgesStorage.get(entityId)) {
  //       case null {};
  //       case (?entityEntry) {
  //         bridgeIdsToReturn := List.append<Text>(bridgeIdsToReturn, entityEntry.otherBridges); // TODO: determine which category's list/categories' lists in entry to return
  //       };
  //     };
  //   };
  //   if (includeBridgesPendingForEntity) {
  //     switch(pendingFromBridgesStorage.get(entityId)) {
  //       case null {};
  //       case (?entityEntry) {
  //         bridgeIdsToReturn := List.append<Text>(bridgeIdsToReturn, entityEntry.otherBridges); // TODO: determine which category's list/categories' lists in entry to return
  //       };
  //     };
  //     switch(pendingToBridgesStorage.get(entityId)) {
  //       case null {};
  //       case (?entityEntry) {
  //         bridgeIdsToReturn := List.append<Text>(bridgeIdsToReturn, entityEntry.otherBridges); // TODO: determine which category's list/categories' lists in entry to return
  //       };
  //     };
  //   };
  //   return List.toArray<Text>(bridgeIdsToReturn);
  // };

  // func getBridgesByEntityId(entityId : Text, includeBridgesFromEntity : Bool, includeBridgesToEntity : Bool, includeBridgesPendingForEntity : Bool) : [Bridge.Bridge] {
  //   let bridgeIdsToRetrieve = getBridgeIdsByEntityId(entityId, includeBridgesFromEntity, includeBridgesToEntity, includeBridgesPendingForEntity);
  //   // adapted from https://forum.dfinity.org/t/motoko-sharable-generics/9021/3
  //   let executingFunctionsBuffer = Buffer.Buffer<?Bridge.Bridge>(bridgeIdsToRetrieve.size());
  //   for (bridgeId in bridgeIdsToRetrieve.vals()) { 
  //     executingFunctionsBuffer.add(getBridge(bridgeId)); 
  //   };
  //   let collectingResultsBuffer = Buffer.Buffer<Bridge.Bridge>(bridgeIdsToRetrieve.size());
  //   var i = 0;
  //   for (bridgeId in bridgeIdsToRetrieve.vals()) {
  //     switch(executingFunctionsBuffer.get(i)) {
  //       case null {};
  //       case (?bridge) { collectingResultsBuffer.add(bridge); };
  //     };      
  //     i += 1;
  //   };
  //   return collectingResultsBuffer.toArray();
  // };

  // func createEntityAndBridge(caller : Principal, entityToCreate : Entity.EntityInitiationObject, bridgeToCreate : Bridge.BridgeInitiationObject) : async (Entity.Entity, ?Bridge.Bridge) {  
  //   let createdEntity : Entity.Entity = await createEntity(caller, entityToCreate);
  //   var updatedBridgeToCreate = bridgeToCreate;
  //   switch(bridgeToCreate._fromEntityId) {
  //     case ("") {
  //       updatedBridgeToCreate := {
  //         _internalId = bridgeToCreate._internalId;
  //         _creator = bridgeToCreate._creator;
  //         _owner = bridgeToCreate._owner;
  //         _settings = bridgeToCreate._settings;
  //         _entityType = bridgeToCreate._entityType;
  //         _name = bridgeToCreate._name;
  //         _description = bridgeToCreate._description;
  //         _keywords = bridgeToCreate._keywords;
  //         _externalId = bridgeToCreate._externalId;
  //         _entitySpecificFields = bridgeToCreate._entitySpecificFields;
  //         _bridgeType = bridgeToCreate._bridgeType;
  //         _fromEntityId = createdEntity.internalId; // only field that needs update, rest is peasantry
  //         _toEntityId = bridgeToCreate._toEntityId;
  //         _state = bridgeToCreate._state;
  //       }; 
  //     };
  //     case (_) {
  //       updatedBridgeToCreate := {
  //         _internalId = bridgeToCreate._internalId;
  //         _creator = bridgeToCreate._creator;
  //         _owner = bridgeToCreate._owner;
  //         _settings = bridgeToCreate._settings;
  //         _entityType = bridgeToCreate._entityType;
  //         _name = bridgeToCreate._name;
  //         _description = bridgeToCreate._description;
  //         _keywords = bridgeToCreate._keywords;
  //         _externalId = bridgeToCreate._externalId;
  //         _entitySpecificFields = bridgeToCreate._entitySpecificFields;
  //         _bridgeType = bridgeToCreate._bridgeType;
  //         _fromEntityId = bridgeToCreate._fromEntityId;
  //         _toEntityId = createdEntity.internalId; // only field that needs update, rest is peasantry
  //         _state = bridgeToCreate._state;
  //       };
  //     };
  //   };
  //   let bridge : ?Bridge.Bridge = await createBridge(caller, updatedBridgeToCreate);
  //   return (createdEntity, bridge);
  // };

  // func getBridgedEntitiesByEntityId(entityId : Text, includeBridgesFromEntity : Bool, includeBridgesToEntity : Bool, includeBridgesPendingForEntity : Bool) : [Entity.Entity] {
  //   let entityBridges : [Bridge.Bridge] = getBridgesByEntityId(entityId, includeBridgesFromEntity, includeBridgesToEntity, includeBridgesPendingForEntity);
  //   if (entityBridges.size() == 0) {
  //     return [];
  //   };
  //   let bridgedEntityIds : [var Text] = Array.init<Text>(entityBridges.size(), "");
  //   var i = 0;
  //   for (entityBridge in entityBridges.vals()) {
  //     if (entityBridge.fromEntityId == entityId) {
  //       bridgedEntityIds[i] := entityBridge.toEntityId;
  //     } else {
  //       bridgedEntityIds[i] := entityBridge.fromEntityId;
  //     };
  //     i += 1;
  //   };
  //   let executingFunctionsBuffer = Buffer.Buffer<?Entity.Entity>(bridgedEntityIds.size());
  //   for (entityId in bridgedEntityIds.vals()) { 
  //     executingFunctionsBuffer.add(getEntity(entityId)); 
  //   };
  //   let collectingResultsBuffer = Buffer.Buffer<Entity.Entity>(bridgedEntityIds.size());
  //   i := 0;
  //   for (entityId in bridgedEntityIds.vals()) {
  //     switch(executingFunctionsBuffer.get(i)) {
  //       case null {};
  //       case (?entity) { collectingResultsBuffer.add(entity); };
  //     };      
  //     i += 1;
  //   };
  //   let bridgedEntities : [Entity.Entity] = collectingResultsBuffer.toArray();
  //   return bridgedEntities;
  // };

  // func getEntityAndBridgeIds(entityId : Text, includeBridgesFromEntity : Bool, includeBridgesToEntity : Bool, includeBridgesPendingForEntity : Bool) : (?Entity.Entity, [Text]) {
  //   switch(getEntity(entityId)) {
  //     case null {
  //       return (null, []);
  //     };
  //     case (?entity) { 
  //       let bridgeIds : [Text] = getBridgeIdsByEntityId(entityId, includeBridgesFromEntity, includeBridgesToEntity, includeBridgesPendingForEntity);
  //       return (?entity, bridgeIds);
  //     };
  //   };
  // };

  // func deleteBridgeFromStorage(bridgeId : Text) : Bool {
  //   bridgesStorage.delete(bridgeId);
  //   return true;
  // };

  // func detachBridgeFromEntities(bridge : Bridge.Bridge) : Bool {
  //   // Delete Bridge's references from Entities' entries
  //   if (bridge.state == #Pending) {
  //   // delete from pending from storage
  //     switch(pendingFromBridgesStorage.get(bridge.fromEntityId)) {
  //       case null {
  //         return false;    
  //       };
  //       case (?entityEntry) {
  //         // delete from entry for entityId by filtering out the bridge's id
  //         let updatedEntityEntry : BridgeCategories = {
  //           ownerCreatedBridges = List.filter<Text>(entityEntry.ownerCreatedBridges, func id { id !=  bridge.internalId });
  //           otherBridges = List.filter<Text>(entityEntry.otherBridges, func id { id !=  bridge.internalId });
  //         };
  //         pendingFromBridgesStorage.put(bridge.fromEntityId, updatedEntityEntry);    
  //       };
  //     };
  //   // delete from pending to storage
  //     switch(pendingToBridgesStorage.get(bridge.toEntityId)) {
  //       case null {
  //         return false;    
  //       };
  //       case (?entityEntry) {
  //         // delete from entry for entityId by filtering out the bridge's id
  //         let updatedEntityEntry : BridgeCategories = {
  //           ownerCreatedBridges = List.filter<Text>(entityEntry.ownerCreatedBridges, func id { id !=  bridge.internalId });
  //           otherBridges = List.filter<Text>(entityEntry.otherBridges, func id { id !=  bridge.internalId });
  //         };
  //         pendingToBridgesStorage.put(bridge.toEntityId, updatedEntityEntry);    
  //       };
  //     };
  //   } else {
  //     // delete Bridge from Entities bridged to and from
  //     // delete from storage for Bridges from Entity
  //     switch(fromBridgesStorage.get(bridge.fromEntityId)) {
  //       case null {
  //         return false;   
  //       };
  //       case (?entityEntry) {
  //         // delete from entry for entityId
  //         let updatedEntityEntry : BridgeCategories = {
  //           ownerCreatedBridges = List.filter<Text>(entityEntry.ownerCreatedBridges, func id { id !=  bridge.internalId });
  //           otherBridges = List.filter<Text>(entityEntry.otherBridges, func id { id !=  bridge.internalId });
  //         };
  //         fromBridgesStorage.put(bridge.fromEntityId, updatedEntityEntry);    
  //       };
  //     };
  //   // delete from storage for Bridges to Entity
  //     switch(toBridgesStorage.get(bridge.toEntityId)) {
  //       case null {
  //         return false;   
  //       };
  //       case (?entityEntry) {
  //         // delete from entry for entityId
  //         let updatedEntityEntry : BridgeCategories = {
  //           ownerCreatedBridges = List.filter<Text>(entityEntry.ownerCreatedBridges, func id { id !=  bridge.internalId });
  //           otherBridges = List.filter<Text>(entityEntry.otherBridges, func id { id !=  bridge.internalId });
  //         };
  //         toBridgesStorage.put(bridge.toEntityId, updatedEntityEntry);    
  //       };
  //     };
  //   };
    
  //   return true;
  // };

  func deleteBridge(caller : Principal, bridgeId : Text) : async Bridge.BridgeIdResult {
    switch(getBridge(bridgeId)) {
      case null { return #Err(#BridgeNotFound); };
      case (?bridgeToDelete) {
        switch(Principal.equal(bridgeToDelete.owner, caller)) {
          case false {
            return #Err(#Unauthorized);
          }; // Only owner may delete the Bridge
          case true {
            // TBD: other deletion constraints
            // switch(detachBridgeFromEntities(bridgeToDelete)) {
            //   case false { 
            //     assert(false); // Should roll back all changes (Something like this would be better: trap("Was Not Able to Delete the Bridge");)
            //     return #Err(#Other "Unable to Delete the Bridge");
            //   };
            //   case true {         
            //     switch(deleteBridgeFromStorage(bridgeId)) {
            //       case true {
            //         return #Ok(?bridgeToDelete);
            //       };
            //       case _ { 
            //         assert(false); // Should roll back all changes (Something like this would be better: trap("Was Not Able to Delete the Bridge");)
            //         return #Err(#Other "Unable to Delete the Bridge");
            //       };
            //     };                          
            //   };
            // };   
            // FIx deleting bridges
            return #Err(#BridgeNotFound)      
          };
        };
      };
    };
  };

  func updateBridge(caller : Principal, bridgeUpdateObject : Bridge.BridgeUpdateObject) : async Bridge.BridgeIdResult {
    switch(getBridge(bridgeUpdateObject.id)) {
      case null { return #Err(#BridgeNotFound); };
      case (?bridgeToUpdate) {
        switch(Principal.equal(bridgeToUpdate.owner, caller)) {
          case false {
            return #Err(#Unauthorized);
          }; // Only owner may update the Bridge
          case true {
            // TBD: other update constraints
            let updatedBridge : Bridge.Bridge = {
              id : Text = bridgeToUpdate.id;
              creationTimestamp : Nat64 = bridgeToUpdate.creationTimestamp;
              creator : Principal = bridgeToUpdate.creator;
              owner : Principal = bridgeToUpdate.owner;
              settings : Bridge.BridgeSettings = Option.get<Bridge.BridgeSettings>(bridgeUpdateObject.settings, bridgeToUpdate.settings);
              name : ?Text = Option.get<?Text>(?bridgeUpdateObject.name, bridgeToUpdate.name);
              description : ?Text = Option.get<?Text>(?bridgeUpdateObject.description, bridgeToUpdate.description);
              keywords : ?[Text] = Option.get<?[Text]>(?bridgeUpdateObject.keywords, bridgeToUpdate.keywords);
              bridgeType : Bridge.BridgeType = bridgeToUpdate.bridgeType;
              fromEntityId : Text = bridgeToUpdate.fromEntityId;
              toEntityId : Text = bridgeToUpdate.toEntityId;
              state : Bridge.BridgeState = bridgeToUpdate.state;
              listOfBridgeSpecificFieldKeys = bridgeToUpdate.listOfBridgeSpecificFieldKeys;
            };
            let result = bridgesStorage.put(updatedBridge.id, updatedBridge);
            return #Ok(updatedBridge.id);        
          };
        };
      };
    };
  };

  /**
  * Function takes in an entity update object and updates the entity that corresponds with the update
  * if it exists and the caller has permissions. Otherwise an error is returned
  * 
  * @return Either the Entity ID if the call was successful or an error if not
  */
  private func updateEntity(caller : Principal, entityUpdateObject : Entity.EntityUpdateObject) : async Entity.EntityIdResult {
    var entity = getEntity(entityUpdateObject.id);
    switch(entity) {
      case null { return #Err(#EntityNotFound); };
      case (?entityToUpdate) {
        switch(Principal.equal(entityToUpdate.owner, caller)) {
          case false {
            return #Err(#Unauthorized);
          }; 
          // Only owner may update the Entity
          case true {
            // entityToUpdate.settings := Option.get<Entity.EntitySettings>(entityUpdateObject.settings, entityToUpdate.settings);
            // entityToUpdate.entityType := entityToUpdate.entityType;
            // entityToUpdate.name := Option.get<?Text>(?entityUpdateObject.name, entityToUpdate.name);
            // entityToUpdate.description := Option.get<?Text>(?entityUpdateObject.description, entityToUpdate.description);
            // entityToUpdate.keywords := Option.get<?[Text]>(?entityUpdateObject.keywords, entityToUpdate.keywords);

            // let result = putEntity(entityToUpdate);
            // Fix the updating when mototko stops being dumb
            return #Err(#Error);      
          };
        };
      };
    };
  };

// Upgrade Hooks
  system func preupgrade() {
    entitiesStorageStable := Iter.toArray(entitiesStorage.entries());
    bridgesStorageStable := Iter.toArray(bridgesStorage.entries());
    // pendingFromBridgesStorageStable := Iter.toArray(pendingFromBridgesStorage.entries());
    // pendingToBridgesStorageStable := Iter.toArray(pendingToBridgesStorage.entries());
    // fromBridgesStorageStable := Iter.toArray(fromBridgesStorage.entries());
    // toBridgesStorageStable := Iter.toArray(toBridgesStorage.entries());
  };

  system func postupgrade() {
    entitiesStorage := HashMap.fromIter(Iter.fromArray(entitiesStorageStable), entitiesStorageStable.size(), Text.equal, Text.hash);
    entitiesStorageStable := [];
    bridgesStorage := HashMap.fromIter(Iter.fromArray(bridgesStorageStable), bridgesStorageStable.size(), Text.equal, Text.hash);
    bridgesStorageStable := [];
    // pendingFromBridgesStorage := HashMap.fromIter(Iter.fromArray(pendingFromBridgesStorageStable), pendingFromBridgesStorageStable.size(), Text.equal, Text.hash);
    // pendingFromBridgesStorageStable := [];
    // pendingToBridgesStorage := HashMap.fromIter(Iter.fromArray(pendingToBridgesStorageStable), pendingToBridgesStorageStable.size(), Text.equal, Text.hash);
    // pendingToBridgesStorageStable := [];
    // fromBridgesStorage := HashMap.fromIter(Iter.fromArray(fromBridgesStorageStable), fromBridgesStorageStable.size(), Text.equal, Text.hash);
    // fromBridgesStorageStable := [];
    // toBridgesStorage := HashMap.fromIter(Iter.fromArray(toBridgesStorageStable), toBridgesStorageStable.size(), Text.equal, Text.hash);
    // toBridgesStorageStable := [];
  };
};
