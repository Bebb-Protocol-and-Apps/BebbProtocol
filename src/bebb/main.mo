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
import Time "mo:base/Time";

actor {
  /*************************************************
              Canister Public Interface
  *************************************************/

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
   * Public interface for deleting an entity. Currently only an owner can delete an entity. This will also delete all the bridges
   * either pointing to or from this Entity
   *
   * @return The entity id if the entity is successfully deleted, otherwise an error
  */
  public shared ({ caller }) func delete_entity(entityId : Text) : async Entity.EntityIdResult {
    let result = await deleteEntity(caller, entityId);
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
  public shared query ({ caller }) func get_to_bridge_ids_by_entity_id(entityId : Text) : async Entity.EntityAttachedBridgesResult {
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
  public shared query ({ caller }) func get_from_bridge_ids_by_entity_id(entityId : Text) : async Entity.EntityAttachedBridgesResult {
    let result = getEntity(entityId);
    switch (result) {
      case (null) { return #Err(#EntityNotFound) };
      case (?entity) { return #Ok(entity.fromIds) };
    };
  };

  /*************************************************
          Helper Functions related to entities
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
  let oneMB : Nat = 1048576; // 1 MB
  private let maxPreviewBlobSize : Nat = 2 * oneMB; 
  private let maxNumPreviews = 5;
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
            // Ensure that the preivews are not too large and that there aren't too many previews
            // If any of the previews are too large then return an error with
            // the preview index that caused the error of being too large
            var counter = 0;
            switch(entityUpdateObject.previews)
            {
              case(null) {};
              case(?new_previews)
              {
                // Check to ensure there aren't too many previews
                if (new_previews.size() > maxNumPreviews)
                {
                    return #Err(#TooManyPreviews);
                };

                // Check all the previews and make sure they aren't too big
                for (preview in new_previews.vals()) {
                    let fileSize = preview.previewData.size();
                    if (fileSize > maxPreviewBlobSize)
                    {
                      return #Err(#PreviewTooLarge(counter));
                    };
                    counter := counter + 1;
                };
              };
            };
            let updatedEntity : Entity.Entity = Entity.updateEntityFromUpdateObject(entityUpdateObject, entityToUpdate);
            let result = putEntity(updatedEntity);
            return #Ok(updatedEntity.id);
          };
        };
      };
    };
  };

  /**
   * Function takes in a caller and the entity id and attempts to delete the entity. If the caller is the entity owner,
   * the entity will as well as all the linking bridges to and from this Entity
   *
   * @return The Entity id of the deleted entity or an error
  */
  func deleteEntity(caller : Principal, entityId : Text) : async Entity.EntityIdResult {
    switch (getEntity(entityId)) {
      case null { return #Err(#EntityNotFound) };
      case (?entityToDelete) {
        switch (Principal.equal(entityToDelete.owner, caller)) {
          case false {
            return #Err(#Unauthorized);
          }; // Only owner may delete the Entity
          case true {
            // First delete all the bridges pointing to this Entity
            for (toBridge in entityToDelete.toIds.vals()) {
              let bridge = getBridge(toBridge.id);
              switch (bridge) {
                case (null) {};
                case (?bridgeToDelete) {
                  // Since this bridge points to the current Entity being deleted, we need to
                  // delete the reference to where the bridge was pointing from and delete the reference to
                  // this bridge in the Entity it was pointing from before deleting the bridge
                  let deleteReferenceResult = deleteBridgeFromEntityFromIds(bridgeToDelete.fromEntityId, bridgeToDelete.id);
                  let deleteBridge = deleteBridgeFromStorage(bridgeToDelete.id);
                };
              };
            };

            // Second delete all the bridges pointing from this Entity
            for (fromBridge in entityToDelete.fromIds.vals()) {
              let bridge = getBridge(fromBridge.id);
              switch (bridge) {
                case (null) {};
                case (?bridgeToDelete) {
                  // Since this bridge points from the current Entity being deleted, we need to
                  // delete the reference to where the bridge was pointing to and delete the reference to
                  // this bridge in the Entity it was pointing to before deleting the bridge
                  let deleteReferenceResult = deleteBridgeFromEntityToIds(bridgeToDelete.toEntityId, bridgeToDelete.id);
                  let deleteBridge = deleteBridgeFromStorage(bridgeToDelete.id);
                };
              };
            };

            // Finally delete the entity itself
            let result = deleteEntityFromStorage(entityToDelete.id);
            return #Ok(entityToDelete.id);
          };
        };
      };
    };
  };

  /**
   * Function deletes an entity from storage. Ensure to delete the connections from the Bridges
   * before removing the entity
   *
   * @ return True if the entity was successfully deleted, false otherwise
  */
  func deleteEntityFromStorage(entityId : Text) : Bool {
    entitiesStorage.delete(entityId);
    return true;
  };

  /*************************************************
          Helper Functions related to bridges
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

    // If the from id result fails, then just delete the bridge but no connections were added
    let fromIdResult = addBridgeToEntityFromIds(bridge.fromEntityId, bridge);
    if (fromIdResult == false) {
      bridgesStorage.delete(bridge.id);
      return null;
    };

    // If the to id result fails, then the from id was added, so make sure to delete the from id on the Entity as well
    // as the bridge itself
    let toIdResult = addBridgeToEntityToIds(bridge.toEntityId, bridge);
    if (toIdResult == false) {
      let bridgeDeleteFromEntityFromIdsResult = deleteBridgeFromEntityFromIds(bridge.fromEntityId, bridge.id);
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
   * of the entity it is linked from
   *
   * @return True if the bridge ID was added to the from ID list, otherwise
   * false is returned if it couldn't
  */
  private func addBridgeToEntityFromIds(entityId : Text, bridge : Bridge.Bridge) : Bool {
    let entity = getEntity(entityId);
    switch (entity) {
      case (null) {
        return false;
      };
      case (?retrievedEntity) {
        let newEntityAttachedBridge = {
          linkStatus=Entity.determineBridgeLinkStatus(retrievedEntity, bridge);
          id=bridge.id;
          creationTime = Time.now();
          bridgeType = bridge.bridgeType;
        };
        let newEntity = Entity.updateEntityFromIds(retrievedEntity, Array.append<Entity.EntityAttachedBridge>(retrievedEntity.fromIds, [newEntityAttachedBridge]));
        let result = putEntity(newEntity);
        return true;
      };
    };
  };

  /**
   * This function takes a bridge and adds the bridge ID to the toIds field
   * of the entity it is linked to
   *
   * @return True if the bridge ID was added to the to ID list, otherwise
   * false is returned if it couldn't
  */
  private func addBridgeToEntityToIds(entityId : Text, bridge : Bridge.Bridge) : Bool {
    var entity = getEntity(entityId);
    switch (entity) {
      case (null) {
        return false;
      };
      case (?retrievedEntity) {
         let newEntityAttachedBridge = {
          linkStatus=Entity.determineBridgeLinkStatus(retrievedEntity, bridge);
          id=bridge.id;
          creationTime = Time.now();
          bridgeType = bridge.bridgeType;
        };
        let newEntity = Entity.updateEntityToIds(retrievedEntity, Array.append<Entity.EntityAttachedBridge>(retrievedEntity.toIds, [newEntityAttachedBridge]));
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
        let newEntity = Entity.updateEntityFromIds(retrievedEntity, Array.filter<Entity.EntityAttachedBridge>(retrievedEntity.fromIds, func x = x.id != bridgeId));
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
        let newEntity = Entity.updateEntityToIds(retrievedEntity, Array.filter<Entity.EntityAttachedBridge>(retrievedEntity.toIds, func x = x.id != bridgeId));
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

// Migration
// Force canister update (deletes all data): dfx canister install --mode=reinstall bebb --network ic 
// Commands to check:
  // Entities
  // should not exist before migration but after (incl. attached Bridges): dfx canister --network ic call bebb get_entity '("83D99219-8B46-4624-BC1D-D821671E4CEC")'
  // should not exist before migration but after (incl. attached Bridges): dfx canister --network ic call bebb get_entity '("2BD20745-5BE3-4BF9-9CCE-D97BB88FC071")'
  // Bridges
  // should not exist before migration but after: dfx canister --network ic call bebb get_bridge '("7A44FFFE-E64A-4DC2-89C2-1A84999BEA0D")'
  // should not exist before migration but after: dfx canister --network ic call bebb get_bridge '("5035EFBF-E66F-1718-A31E-000000000000")'
// Commands to run:
  // Entities: dfx canister call bebb uploadEntities '[replace with (vec{...})]'
  // Bridges: dfx canister call bebb uploadBridges '[replace with (vec{...})]'

// For prod: add the network flag (--network ic)

  public type OldEntityType = {
      #BridgeEntity;
      #Webasset;
      #Person;
      #Location;
  };
  public type OldEntity = {
    internalId : Text;
    creationTimestamp : Nat64;
    creator : Principal;
    owner : Principal;
    settings : Entity.EntitySettings;
    entityType : OldEntityType;
    name : ?Text;
    description : ?Text;
    keywords : ?[Text];
    externalId : ?Text;
    entitySpecificFields : ?Text;
    listOfEntitySpecificFieldKeys : [Text];
    // resolveRepresentedEntity : () -> T; // if possible, generic return value, otherwise probably Text
  };
  type BridgeCategories = { // TODO: define bridge categories, probably import from a dedicated file (BridgeType)
    ownerCreatedBridges : List.List<Text>;
    otherBridges : List.List<Text>;
  };

  public shared ({ caller }) func uploadEntities(migratedEntities : [(Text, OldEntity)]) : async Bool {
    if (not Principal.equal(Principal.fromText("cda4n-7jjpo-s4eus-yjvy7-o6qjc-vrueo-xd2hh-lh5v2-k7fpf-hwu5o-yqe"), caller)) {
      return false;
    };
    for ((id, oldEntity) in migratedEntities.vals()) {
      let newEntity = {
        id = oldEntity.internalId;
        creationTimestamp = oldEntity.creationTimestamp;
        creator = oldEntity.creator;
        owner = oldEntity.owner;
        settings = Entity.EntitySettings();
        entityType = #Resource(#Web);
        name : Text = Option.get<Text>(oldEntity.name, "");
        description : Text = Option.get<Text>(oldEntity.description, "");
        keywords : [Text] = Option.get<[Text]>(oldEntity.keywords, []);
        entitySpecificFields : Text = Option.get<Text>(oldEntity.entitySpecificFields, "");
        listOfEntitySpecificFieldKeys : [Text] = oldEntity.listOfEntitySpecificFieldKeys;
        toIds = [];
        fromIds = [];
        previews = [];
      };

      //entitiesStorage.put(oldEntity.internalId, newEntity);
      let result = putEntity(newEntity);
      assert(result == newEntity.id);
    };

    return true;
  };

  public type OldBridgeType = {
        #OwnerCreated;
  };
  public type OldBridgeState = {
        #Pending;
        #Rejected;
        #Confirmed;
    };
  public type OldBridgeEntity = OldEntity and {
    bridgeType : OldBridgeType;
    fromEntityId : Text;
    toEntityId : Text;
    state : OldBridgeState;
  };

  public shared ({ caller }) func uploadBridges(migratedBridges : [(Text, OldBridgeEntity)]) : async Bool {
    if (not Principal.equal(Principal.fromText("cda4n-7jjpo-s4eus-yjvy7-o6qjc-vrueo-xd2hh-lh5v2-k7fpf-hwu5o-yqe"), caller)) {
      return false;
    };
    for ((id, oldBridge) in migratedBridges.vals()) {
      let newBridge = {
        id = oldBridge.internalId;
        creationTimestamp = oldBridge.creationTimestamp;
        creator = oldBridge.creator;
        owner = oldBridge.owner;
        settings = Bridge.BridgeSettings();
        name : Text = Option.get<Text>(oldBridge.name, "");
        description : Text = Option.get<Text>(oldBridge.description, "");
        keywords : [Text] = Option.get<[Text]>(oldBridge.keywords, []);
        entitySpecificFields : Text = Option.get<Text>(oldBridge.entitySpecificFields, "");
        listOfEntitySpecificFieldKeys : [Text] = ["bridgeType", "fromEntityId", "toEntityId"];
        bridgeType = #IsRelatedto;
        fromEntityId = oldBridge.fromEntityId;
        toEntityId = oldBridge.toEntityId;
      };

      //bridgesStorage.put(oldBridge.internalId, newBridge);
      let result = addNewBridge(newBridge);
      //assert(result != null);
    };

    return true;
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
