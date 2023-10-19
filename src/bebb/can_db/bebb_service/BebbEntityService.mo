import CA "mo:candb/CanisterActions";
import CanDB "mo:candb/CanDB";

import Entity "../../entity";
import Bridge "../../bridge";
import Types "../../Types";
import Utils "../../Utils";
import Time "mo:base/Time";
import Principal "mo:base/Principal";
import Nat64 "mo:base/Nat64";
import Option "mo:base/Option";

import CanDbEntity "mo:candb/Entity";

shared ({ caller = owner }) actor class BebbEntityService({
  // the partition key of this canister
  partitionKey: Text;
  // the scaling options that determine when to auto-scale out this canister storage partition
  scalingOptions: CanDB.ScalingOptions;
  // (optional) allows the developer to specify owners in addition to this canister's controllers (i.e. for allowing admin or dev team access to specific API endpoints)
  owners: ?[Principal];
}) {
  /// @required (may wrap, but must be present in some form in the canister)
  stable let db = CanDB.init({
    pk = partitionKey;
    scalingOptions = scalingOptions;
    btreeOrder = null;
  });

  /// @recommended (not required) public API
  public query func getPK(): async Text { db.pk };

  /// @required public API (Do not delete or change)
  public query func skExists(sk: Text): async Bool { 
    CanDB.skExists(db, sk);
  };

  /// @required public API (Do not delete or change)
  public shared({ caller = caller }) func transferCycles(): async () {
    if (caller == owner) {
      return await CA.transferCycles(caller);
    };
  };

  /*************************************************
          Public Interface for Entities
  *************************************************/
  /**
   * Public interface for creating an entity. This will attempt to create the entity and return the id if it does so
   * successfully
   *
   * @return Returns the entity id if it was successfully created, otherwise it returns an error
  */
  public shared ({ caller }) func create_entity(entityToCreate : Entity.EntityInitiationObject) : async Entity.EntityIdResult {
    if (partitionKey != "BebbEntity#") {
      return #Err(#Unauthorized("Wrong Partition"));
    };
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
    if (partitionKey != "BebbEntity#") {
      return #Err(#Unauthorized("Wrong Partition"));
    };
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

  public shared ({ caller }) func delete_entity(entityId : Text) : async Entity.EntityIdResult {
    let result = await deleteEntity(caller, entityId);
    return result;
  };

  // TODO: get_to_bridge_ids_by_entity_id (likely here)

  // TODO: get_from_bridge_ids_by_entity_id (likely here)

  /*************************************************
          Helper Functions related to Entities
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
    let newEntityId : Text = await Utils.newRandomUlid();
    let entity = Entity.generateEntityFromInitializationObject(entityToCreate, newEntityId, caller);
    return await putEntity(entity);
  };

  /**
   * Simple function to store an entity in the database. There are no protections so this function should only
   * be called if the caller has permissions to store the entity to the database
   *
   * @return The entity id of the stored entity
  */
  private func putEntity(entity : Entity.Entity) : async Text {
    let entityAttributes = Entity.getEntityAttributesFromEntityObject(entity);
    await* CanDB.put(db, {
      sk = entity.id;
      attributes = entityAttributes;
    });
    return entity.id;
  };

  /**
   * A simple function to retrieve an entity by the entity id, this provides no protection so should only be called if
   * the caller has permissions to read the entity data
   *
   * @return The entity if it exists, otherwise null
  */
  private func getEntity(entityId : Text) : ?Entity.Entity {
    let entityData = switch(CanDB.get(db, { pk= "entity"; sk = entityId }))  { // TODO: double-check pk and sk
      case null { null };
      case (?canDbEntity) { unwrapEntity(canDbEntity)};
    };

    switch(entityData) {
      case(?e) { ?e };
      case null { null };
    };
  };

  private func updateEntity(caller : Principal, entityUpdateObject : Entity.EntityUpdateObject) : async Entity.EntityIdResult {
    var entity = getEntity(entityUpdateObject.id);
    switch (entity) {
      case null { return #Err(#EntityNotFound) };
      case (?entityToUpdate) {
        switch (Principal.equal(entityToUpdate.owner, caller)) {
          case false {
            return #Err(#Unauthorized("Not the owner"));
          };
          // Only owner may update the Entity
          case true {
            // Ensure that the preivews are not too large and that there aren't too many previews
            // If any of the previews are too large then return an error with
            // the preview index that caused the error of being too large
            // var counter = 0;
            // switch(entityUpdateObject.previews)
            // {
            //   case(null) {};
            //   case(?new_previews)
            //   {
            //     // Check to ensure there aren't too many previews
            //     if (new_previews.size() > maxNumPreviews)
            //     {
            //         return #Err(#TooManyPreviews);
            //     };

            //     // Check all the previews and make sure they aren't too big
            //     for (preview in new_previews.vals()) {
            //         let fileSize = preview.previewData.size();
            //         if (fileSize > maxPreviewBlobSize)
            //         {
            //           return #Err(#PreviewTooLarge(counter));
            //         };
            //         counter := counter + 1;
            //     };
            //   };
            // };
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
   * the entity will delete itself but will leave the bridges dangling
   *
   * @return The Entity id of the deleted entity or an error
  */
  func deleteEntity(caller : Principal, entityId : Text) : async Entity.EntityIdResult {
    switch (getEntity(entityId)) {
      case null { return #Err(#EntityNotFound) };
      case (?entityToDelete) {
        switch (Principal.equal(entityToDelete.owner, caller)) {
          case false {
            return #Err(#Unauthorized("Not the Owner"));
          }; // Only owner may delete the Entity
          case true {
            // // First delete all the bridges pointing to this Entity
            // for (toBridge in entityToDelete.toIds.vals()) {
            //   let bridge = getBridge(toBridge.id);
            //   switch (bridge) {
            //     case (null) {};
            //     case (?bridgeToDelete) {
            //       // Since this bridge points to the current Entity being deleted, we need to
            //       // delete the reference to where the bridge was pointing from and delete the reference to
            //       // this bridge in the Entity it was pointing from before deleting the bridge
            //       let deleteReferenceResult = deleteBridgeFromEntityFromIds(bridgeToDelete.fromEntityId, bridgeToDelete.id);
            //       let deleteBridge = deleteBridgeFromStorage(bridgeToDelete.id);
            //     };
            //   };
            // };

            // Second delete all the bridges pointing from this Entity
            // for (fromBridge in entityToDelete.fromIds.vals()) {
            //   let bridge = getBridge(fromBridge.id);
            //   switch (bridge) {
            //     case (null) {};
            //     case (?bridgeToDelete) {
            //       // Since this bridge points from the current Entity being deleted, we need to
            //       // delete the reference to where the bridge was pointing to and delete the reference to
            //       // this bridge in the Entity it was pointing to before deleting the bridge
            //       let deleteReferenceResult = deleteBridgeFromEntityToIds(bridgeToDelete.toEntityId, bridgeToDelete.id);
            //       let deleteBridge = deleteBridgeFromStorage(bridgeToDelete.id);
            //     };
            //   };
            // };

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
   * @return True if the entity was successfully deleted, false otherwise
  */
  func deleteEntityFromStorage(entityId : Text) : Bool {
    CanDB.delete(db, {
      sk = entityId;
    });
    return true;
  };


  func unwrapEntity(canDbEntity: CanDbEntity.Entity): ?Entity.Entity {
    let { sk; pk; attributes } = canDbEntity;

    let idValue = CanDbEntity.getAttributeMapValueForKey(attributes, "id");
    let creationTimestampValue = CanDbEntity.getAttributeMapValueForKey(attributes, "creationTimestamp");
    let creatorValue = CanDbEntity.getAttributeMapValueForKey(attributes, "creator");
    let ownerValue = CanDbEntity.getAttributeMapValueForKey(attributes, "owner");
    let nameValue = CanDbEntity.getAttributeMapValueForKey(attributes, "name");
    let descriptionValue = CanDbEntity.getAttributeMapValueForKey(attributes, "description");
    let keywordsValue = CanDbEntity.getAttributeMapValueForKey(attributes, "keywords");
    let entitySpecificFieldsValue = CanDbEntity.getAttributeMapValueForKey(attributes, "entitySpecificFields");
    let listOfEntitySpecificFieldKeysValue = CanDbEntity.getAttributeMapValueForKey(attributes, "listOfEntitySpecificFieldKeys");
    let settingsValue = CanDbEntity.getAttributeMapValueForKey(attributes, "settings");
    let entityTypeValue = CanDbEntity.getAttributeMapValueForKey(attributes, "entityType");
    let toIdsValue = CanDbEntity.getAttributeMapValueForKey(attributes, "toIds");
    let fromIdsValue = CanDbEntity.getAttributeMapValueForKey(attributes, "fromIds");
    let previewsValue = CanDbEntity.getAttributeMapValueForKey(attributes, "previews");

    switch(idValue, creationTimestampValue, creatorValue, ownerValue, nameValue, descriptionValue, keywordsValue, entitySpecificFieldsValue, listOfEntitySpecificFieldKeysValue, settingsValue, entityTypeValue, toIdsValue, fromIdsValue, previewsValue) {
      case (
          ?(#text(id)),
          ?(#int(creationTimestamp)),
          ?(#text(creator)),
          ?(#text(owner)),
          ?(#text(name)),
          ?(#text(description)),
          ?(#arrayText(keywords)),
          ?(#text(entitySpecificFields)),
          ?(#arrayText(listOfEntitySpecificFieldKeys)),
          ?(#blob(settings)),
          ?(#blob(entityType)),
          ?(#blob(toIds)),
          ?(#blob(fromIds)),
          ?(#blob(previews)),
      ) { ? {
          id;
          creationTimestamp = Nat64.fromIntWrap(creationTimestamp);
          creator = Principal.fromText(creator);
          owner = Principal.fromText(owner);
          name;
          description;
          keywords;
          entitySpecificFields;
          listOfEntitySpecificFieldKeys;
          settings = Option.get<Entity.EntitySettings>(from_candid(settings), Entity.EntitySettings()); // TODO: while the null case shouldn't happen, this is also a bad way of handling it
          entityType = Option.get<Entity.EntityType>(from_candid(entityType), #Other("Autofilled in unwrapEntity")); // TODO: while the null case shouldn't happen, this is also a bad way of handling it
          toIds = Option.get<Entity.EntityAttachedBridges>(from_candid(toIds), []); // TODO: while the null case shouldn't happen, this is also a bad way of handling it
          fromIds = Option.get<Entity.EntityAttachedBridges>(from_candid(fromIds), []); // TODO: while the null case shouldn't happen, this is also a bad way of handling it
          previews = Option.get<[Entity.EntityPreview]>(from_candid(previews), []); // TODO: while the null case shouldn't happen, this is also a bad way of handling it
        }
      };
      case _ { null };
    };
  };

// TODO: the following functions might be helpful in an adapted form  

  // TODO: this needs to be changed as the Entities are now stored in different canisters
    // This will currently fail
  /**
   * This function takes a bridge and adds the bridge ID to the fromIds field
   * of the entity it is linked from
   *
   * @return True if the bridge ID was added to the from ID list, otherwise
   * false is returned if it couldn't
  */
  // private func addBridgeToEntityFromIds(entityId : Text, bridge : Bridge.Bridge) : Bool {
  //   let entity = getEntity(entityId);
  //   switch (entity) {
  //     case (null) {
  //       return false;
  //     };
  //     case (?retrievedEntity) {
  //       let newEntityAttachedBridge = {
  //         linkStatus = Entity.determineBridgeLinkStatus(retrievedEntity, bridge);
  //         id=bridge.id;
  //         creationTime = Time.now();
  //         bridgeType = bridge.bridgeType;
  //       };
  //       let newEntity = Entity.updateEntityFromIds(retrievedEntity, Array.append<Entity.EntityAttachedBridge>(retrievedEntity.fromIds, [newEntityAttachedBridge]));
  //       let result = putEntity(newEntity);
  //       return true;
  //     };
  //   };
  // };

  // TODO: this needs to be changed as the Entities are now stored in different canisters
    // This will currently fail
  /**
   * This function takes a bridge and adds the bridge ID to the toIds field
   * of the entity it is linked to
   *
   * @return True if the bridge ID was added to the to ID list, otherwise
   * false is returned if it couldn't
  */
  // private func addBridgeToEntityToIds(entityId : Text, bridge : Bridge.Bridge) : Bool {
  //   var entity = getEntity(entityId);
  //   switch (entity) {
  //     case (null) {
  //       return false;
  //     };
  //     case (?retrievedEntity) {
  //        let newEntityAttachedBridge = {
  //         linkStatus = Entity.determineBridgeLinkStatus(retrievedEntity, bridge);
  //         id=bridge.id;
  //         creationTime = Time.now();
  //         bridgeType = bridge.bridgeType;
  //       };
  //       let newEntity = Entity.updateEntityToIds(retrievedEntity, Array.append<Entity.EntityAttachedBridge>(retrievedEntity.toIds, [newEntityAttachedBridge]));
  //       let result = putEntity(newEntity);
  //       return true;
  //     };
  //   };
  // };

  // TODO: if we want to keep/need the functionality of checkIfEntityExists, we need to change it (as the Entities are now stored in different canisters)
    // This call will thus currently always fail
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

}