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

  /**
   * Public interface for creating an entity. This will attempt to create the entity and return the id if it does so
   * successfully
   *
   * @return Returns the entity id if it was successfully created, otherwise it returns an error
  */
  public shared ({ caller }) func create_entity(entityToCreate : Entity.EntityInitiationObject) : async Entity.EntityIdResult {
    let result = await createEntity(caller, entityToCreate);
    switch (result) {
      case ("") { return #Err(#Error) };
      case (id) { return #Ok(id) };
    };
  };

  /**
   * Public interface for retreiving an entity. Retrieving an entity is subject to any permission and rules defined by the entity.
   * If the entity is found, the entity is returned, otherwise an error is returned.
   *
   * @note Currently there are no permissions and anyone that knows the entity Id can retrieve it
   * @return The entity if the id matches an entity, otherwise an error
  */
  public shared query ({ caller }) func get_entity(entityId : Text) : async Entity.EntityResult {
    let result = getEntity(entityId);
    switch (result) {
      case (null) { return #Err(#EntityNotFound) };
      case (?entity) { return #Ok(entity) };
    };
  };

  /**
   * Public interface for updating an entity. Only the owner of the entity is allowed to update the values specified in the
   * entity update object
   *
   * @return The entity id if the update was sucessful, otherwise an error
  */
  public shared ({ caller }) func update_entity(entityUpdateObject : Entity.EntityUpdateObject) : async Entity.EntityIdResult {
    let result = await updateEntity(caller, entityUpdateObject);
    return result;
  };

  /**
   * Public interface for creating a new bridge. When a bridge is created, it will add the bridge to the database and also
   * add the bridge id to the attached entities for reference
   *
   * @return The bridge id if the bridge was successfully created, otherwise an error
  */
  public shared ({ caller }) func create_bridge(bridgeToCreate : Bridge.BridgeInitiationObject) : async Bridge.BridgeIdResult {
    let result = await createBridge(caller, bridgeToCreate);
    switch (result) {
      case (null) { return #Err(#Error) };
      case (?id) { return #Ok(id) };
    };
  };

  /**
   * Public interface for retrieving a bridge.
   *
   * @return Returns the bridge if the id matches a stored bridge, otherwise an error
  */
  public shared query ({ caller }) func get_bridge(bridgeId : Text) : async Bridge.BridgeResult {
    let result = getBridge(bridgeId);
    switch (result) {
      case (null) { return #Err(#Error) };
      case (?bridge) { return #Ok(bridge) };
    };
  };

  /**
   * Public interface for deleting a bridge. Currently only an owner can delete a bridge. This will also delete the reference
   * of the bridge in the attached entities
   *
   * @return The bridge id if the bridge is successfully deleted, otherwise an error
  */
  public shared ({ caller }) func delete_bridge(bridgeId : Text) : async Bridge.BridgeIdResult {
    let result = await deleteBridge(caller, bridgeId);
    return result;
  };

  /**
   * Public interface for updating a bridge. Only the owner is allowed to update a brige. Updates the bridge with the info
   * contained within the bridge update object
   *
   * @return The bridge id if the update was successful, otherwise an error
  */
  public shared ({ caller }) func update_bridge(bridgeUpdateObject : Bridge.BridgeUpdateObject) : async Bridge.BridgeIdResult {
    let result = await updateBridge(caller, bridgeUpdateObject);
    return result;
  };

  /**
   * Public interface for retrieving all the to bridge ids attached to an entity
   *
   * @return A list of bridge ids of bridges pointed to a specied entity if the eneityId matches a valid entity, otherwise an error
  */
  public shared ({ caller }) func get_to_bridge_ids_by_entity_id(entityId : Text) : async Entity.EntityAttachedBridges {
    let result = getEntity(entityId);
    switch (result) {
      case (null) { return #Err(#EntityNotFound) };
      case (?entity) { return #Ok(entity.toIds) };
    };
  };

  /**
   * Public interface for retrieving all the from bridge ids attached to an entity
   *
   * @return A list of bridge ids of bridges pointed from a specied entity if the eneityId matches a valid entity, otherwise an error
  */
  public shared ({ caller }) func get_from_bridge_ids_by_entity_id(entityId : Text) : async Entity.EntityAttachedBridges {
    let result = getEntity(entityId);
    switch (result) {
      case (null) { return #Err(#EntityNotFound) };
      case (?entity) { return #Ok(entity.fromIds) };
    };
  };

  // HELPER FUNCTIONS

  /*************************************************
              Code related to entities
  *************************************************/

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
    while (not found_unique_id) {
      // 10 is chosen arbitarily to ensure that in case of something weird happening
      //  there is a timeout and it errors rather then looking forever
      if (counter > 10) {
        return "";
      };

      newEntityId := await Utils.newRandomUniqueId();
      switch (entitiesStorage.get(newEntityId)) {
        case (null) {
          // Create the entity
          let entity = Entity.generateEntityFromInitializationObject(entityToCreate, newEntityId, caller);
          return putEntity(entity);
        };
        case (_) {
          counter := counter + 1;
        };
      };

    };
    return "";
  };

  /**
   * The format to store entities in the canister
  */
  stable var entitiesStorageStable : [(Text, Entity.Entity)] = [];
  var entitiesStorage : HashMap.HashMap<Text, Entity.Entity> = HashMap.HashMap(0, Text.equal, Text.hash);

  /**
   * Simple function to store an entity in the database. There are no protections so this function should only
   * be called if the caller has permissions to store the entity to the database
   *
   * @return The entity id of the stored entity
  */
  private func putEntity(entity : Entity.Entity) : Text {
    entitiesStorage.put(entity.id, entity);
    return entity.id;
  };

  /**
   * A simple function to retrieve an entity by the entity id, this provides no protection so should only be called if
   * the caller has permissions to read the entity data
   *
   * @return The entity if it exists, otherwise null
  */
  private func getEntity(entityId : Text) : ?Entity.Entity {
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
    switch (result) {
      case (null) { return false };
      case (entity) { return true };
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
    switch (entity) {
      case null { return #Err(#EntityNotFound) };
      case (?entityToUpdate) {
        switch (Principal.equal(entityToUpdate.owner, caller)) {
          case false {
            return #Err(#Unauthorized);
          };
          // Only owner may update the Entity
          case true {
            let updatedEntity : Entity.Entity = Entity.updateEntityFromUpdateObject(entityUpdateObject, entityToUpdate);
            let result = putEntity(updatedEntity);
            return #Ok(updatedEntity.id);
          };
        };
      };
    };
  };

  /*************************************************
              Code related to bridges
  *************************************************/

  /**
   * The format to store bridges in the canister
  */
  stable var bridgesStorageStable : [(Text, Bridge.Bridge)] = [];
  var bridgesStorage : HashMap.HashMap<Text, Bridge.Bridge> = HashMap.HashMap(0, Text.equal, Text.hash);

  /**
   * Function creates a new bridge based on the input initialization object. If it is able
   * to make the object, it stores it and return the id, otherwise it will not
   * store an object and return an empty string
   *
   * @return The id of the new entity if the entity creation was successful, otherwise an empty string
  */
  private func createBridge(caller : Principal, bridgeToCreate : Bridge.BridgeInitiationObject) : async ?Text {
    // Check if both the to and from entities exist for the bridge
    let toEntityExists = checkIfEntityExists(bridgeToCreate.toEntityId);
    let fromEntityExists = checkIfEntityExists(bridgeToCreate.fromEntityId);

    if (toEntityExists == false or fromEntityExists == false) {
      return null;
    };

    // Find a unique id for the new bridge that will not
    // conflict with any current items
    var newBridgeId : Text = "";
    var counter : Nat = 0;
    var found_unique_id : Bool = false;
    while (not found_unique_id) {
      // 10 is chosen arbitarily to ensure that in case of something weird happening
      //  there is a timeout and it errors rather then looking forever
      if (counter > 10) {
        return null;
      };

      newBridgeId := await Utils.newRandomUniqueId();
      if (bridgesStorage.get(newBridgeId) == null) {
        let bridge : Bridge.Bridge = Bridge.generateBridgeFromInitializationObject(bridgeToCreate, newBridgeId, caller);
        return addNewBridge(bridge);
      };

      counter := counter + 1;
    };
    return null;
  };

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
    if (checkIfBridgeExists(bridge.id) == true) {
      return null;
    };

    // Add the bridge of the bridge database and add the bridge id to the related entities
    let result = putBridge(bridge);
    let fromIdResult = addBridgeToEntityFromIds(bridge.fromEntityId, bridge.id);
    let toIdResult = addBridgeToEntityToIds(bridge.toEntityId, bridge.id);

    // Ensure the bridge could be added to both entities bridge lookup tables
    if (fromIdResult == false or toIdResult == false) {
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
  private func putBridge(bridge : Bridge.Bridge) : Bridge.Bridge {
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
  private func addBridgeToEntityFromIds(entityId : Text, bridgeId : Text) : Bool {
    let entity = getEntity(entityId);
    switch (entity) {
      case (null) {
        return false;
      };
      case (?retrievedEntity) {
        let newEntity = Entity.updateEntityFromIds(retrievedEntity, Array.append<Text>(retrievedEntity.fromIds, [bridgeId]));
        let result = putEntity(newEntity);
        return true;
      };
    };
  };

  /**
   * This function takes a bridge and adds the bridge ID to the toIds field
   * to the entity that this Bridge Links to
   *
   * @return True if the bridge ID was added to the to ID list, otherwise
   * false is returned if it couldn't
  */
  private func addBridgeToEntityToIds(entityId : Text, bridgeId : Text) : Bool {
    var entity = getEntity(entityId);
    switch (entity) {
      case (null) {
        return false;
      };
      case (?retrievedEntity) {
        let newEntity = Entity.updateEntityToIds(retrievedEntity, Array.append<Text>(retrievedEntity.toIds, [bridgeId]));
        let result = putEntity(newEntity);
        return true;
      };
    };
  };

  /**
   * This function takes an entity and the bridge associated to it, and deletes the bridge
   * id from the fromIds list in the Entity
   *
   * @return True if the bridge id was successfully removed from the fromIds list, false
   * if either it didn't exist or something went wrong
  */
  private func deleteBridgeFromEntityFromIds(entityId : Text, bridgeId : Text) : Bool {
    let entity = getEntity(entityId);
    switch (entity) {
      case (null) {
        return false;
      };
      case (?retrievedEntity) {
        let newEntity = Entity.updateEntityFromIds(retrievedEntity, Array.filter<Text>(retrievedEntity.fromIds, func x = x != bridgeId));
        let result = putEntity(newEntity);
        return true;
      };
    };
  };

  /**
   * This function takes an entity and the bridge associated to it, and deletes the bridge
   * id from the toIds list in the Entity
   *
   * @return True if the bridge id was successfully removed from the toIds list, false
   * if either it didn't exist or something went wrong
  */
  private func deleteBridgeFromEntityToIds(entityId : Text, bridgeId : Text) : Bool {
    let entity = getEntity(entityId);
    switch (entity) {
      case (null) {
        return false;
      };
      case (?retrievedEntity) {
        let newEntity = Entity.updateEntityToIds(retrievedEntity, Array.filter<Text>(retrievedEntity.toIds, func x = x != bridgeId));
        let result = putEntity(newEntity);
        return true;
      };
    };
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
   * Function deletes a bridge from storage. Ensure to delete the connections to the Entities
   * before removing the bridge
   *
   * @ return True if the bridge was successfully deleted, false otherwise
  */
  func deleteBridgeFromStorage(bridgeId : Text) : Bool {
    bridgesStorage.delete(bridgeId);
    return true;
  };

  /**
  * Function checks that the given bridge id provided exists within the database
  *
  * @return True if the entity exists, false otherwise
  */
  private func checkIfBridgeExists(bridgeId : Text) : Bool {
    let result = getBridge(bridgeId);
    switch (result) {
      case (null) { return false };
      case (bridge) { return true };
    };
  };

  /**
   * Function takes in a caller and the bridge id and attempts to delete the bridge. If the caller is the bridge owner,
   * the bridge will be deleted as long as the reference within the entity will be deleted
   *
   * @return The Bridge id of the deleted bridge or an error
  */
  func deleteBridge(caller : Principal, bridgeId : Text) : async Bridge.BridgeIdResult {
    switch (getBridge(bridgeId)) {
      case null { return #Err(#BridgeNotFound) };
      case (?bridgeToDelete) {
        switch (Principal.equal(bridgeToDelete.owner, caller)) {
          case false {
            return #Err(#Unauthorized);
          }; // Only owner may delete the Bridge
          case true {
            // First delete the references to the bridge in the entities
            // Then delete the bridge itself
            let bridgeDeleteFromEntityFromIdsResult = deleteBridgeFromEntityFromIds(bridgeToDelete.fromEntityId, bridgeId);
            let bridgeDeleteFromEntityToIdResult = deleteBridgeFromEntityToIds(bridgeToDelete.toEntityId, bridgeId);
            if (bridgeDeleteFromEntityFromIdsResult == false or bridgeDeleteFromEntityToIdResult == false) {
              return #Err(#Error);
            };
            let bridgeDeleteResult = deleteBridgeFromStorage(bridgeId);
            return #Ok(bridgeId);
          };
        };
      };
    };
  };

  /**
   * Function takes in a caller and a bridge update object. If the caller is the bridge owner,
   * the bridge will be updated with the data within the bridge update object
   *
   * @return The Bridge id of the updated bridge or an error
  */
  func updateBridge(caller : Principal, bridgeUpdateObject : Bridge.BridgeUpdateObject) : async Bridge.BridgeIdResult {
    switch (getBridge(bridgeUpdateObject.id)) {
      case null { return #Err(#BridgeNotFound) };
      case (?bridgeToUpdate) {
        switch (Principal.equal(bridgeToUpdate.owner, caller)) {
          case false {
            return #Err(#Unauthorized);
          }; // Only owner may update the Bridge
          case true {
            let updatedBridge : Bridge.Bridge = Bridge.updateBridgeFromUpdateObject(bridgeUpdateObject, bridgeToUpdate);
            let result = putBridge(updatedBridge);
            return #Ok(updatedBridge.id);
          };
        };
      };
    };
  };

  /*************************************************
              Code related to system upgrades
  *************************************************/

  system func preupgrade() {
    entitiesStorageStable := Iter.toArray(entitiesStorage.entries());
    bridgesStorageStable := Iter.toArray(bridgesStorage.entries());
  };

  system func postupgrade() {
    entitiesStorage := HashMap.fromIter(Iter.fromArray(entitiesStorageStable), entitiesStorageStable.size(), Text.equal, Text.hash);
    entitiesStorageStable := [];
    bridgesStorage := HashMap.fromIter(Iter.fromArray(bridgesStorageStable), bridgesStorageStable.size(), Text.equal, Text.hash);
    bridgesStorageStable := [];
  };
};
