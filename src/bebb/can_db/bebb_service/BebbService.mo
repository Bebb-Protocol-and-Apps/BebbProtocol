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

shared ({ caller = owner }) actor class BebbService({
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
    if (partitionKey != "entities") {
      return #Err(#Unauthorized);
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
    if (partitionKey != "entities") {
      return #Err(#Unauthorized("Wrong Partition"));
    };
    let result = getEntity(entityId);
    switch (result) {
      case (null) { return #Err(#EntityNotFound) };
      case (?entity) { return #Ok(entity) };
    };
  };

  // TODO: update_entity

  // TODO: delete_entity

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

  /*************************************************
          Public Interface for Bridges
  *************************************************/
  /**
   * Public interface for creating a new bridge. When a bridge is created, it will add the bridge to the database and also
   * add the bridge id to the attached entities for reference
   *
   * @return The bridge id if the bridge was successfully created, otherwise an error
  */
  public shared ({ caller }) func create_bridge(bridgeToCreate : Bridge.BridgeInitiationObject) : async Bridge.BridgeIdResult {
    if (partitionKey != "bridges") {
      return #Err(#Unauthorized);
    };
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
    if (partitionKey != "bridges") {
      return #Err(#Unauthorized("Wrong Partition"));
    };
    let result = getBridge(bridgeId);
    switch (result) {
      case (null) { return #Err(#Error) };
      case (?bridge) { return #Ok(bridge) };
    };
  };


  // TODO: update_bridge

  // TODO: delete_bridge

  // TODO: get_to_bridge_ids_by_entity_id

  // TODO: get_from_bridge_ids_by_entity_id

  /*************************************************
          Helper Functions related to Bridges
  *************************************************/
  /**
   * Function creates a new bridge based on the input initialization object. If it is able
   * to make the object, it stores it and return the id, otherwise it will not
   * store an object and return an empty string
   *
   * @return The id of the new entity if the entity creation was successful, otherwise an empty string
  */
  private func createBridge(caller : Principal, bridgeToCreate : Bridge.BridgeInitiationObject) : async ?Text {
    // Check if both the to and from entities exist for the bridge
    // TODO: needs to be changed
    // let toEntityExists = checkIfEntityExists(bridgeToCreate.toEntityId);
    // let fromEntityExists = checkIfEntityExists(bridgeToCreate.fromEntityId);

    // if (toEntityExists == false or fromEntityExists == false) {
    //   return null;
    // };

    // Find a unique id for the new bridge that will not
    // conflict with any current items
    var newBridgeId : Text = await Utils.newRandomUlid();
    let bridge : Bridge.Bridge = Bridge.generateBridgeFromInitializationObject(bridgeToCreate, newBridgeId, caller);
    return await addNewBridge(bridge);
  };

  /**
   * Function adds a new bridge and attempts to add the bridge to the entities
   * bridge lookup tables. If adding the bridge to the entities fails, then the bridge
   * is not created and is instead deleted
   *
   * @return Returns null if the entitiy failed to get created, otherwise it returns
   * the bridge id of the newly created bridge
  */
  private func addNewBridge(bridge : Bridge.Bridge) : async ?Text {
    // Don't allow creating the bridge if the bridge already exists
      // TODO: needs to be changed
    if (checkIfBridgeExists(bridge.id) == true) {
      return null;
    };

    // Add the bridge of the bridge database and add the bridge id to the related entities
    let result = await putBridge(bridge);

    // If the from id result fails, then just delete the bridge but no connections were added
      // TODO: needs to be changed
    // let fromIdResult = addBridgeToEntityFromIds(bridge.fromEntityId, bridge);
    // if (fromIdResult == false) {
    //   bridgesStorage.delete(bridge.id);
    //   return null;
    // };

    // // If the to id result fails, then the from id was added, so make sure to delete the from id on the Entity as well
    // // as the bridge itself
    //   // TODO: needs to be changed
    // let toIdResult = addBridgeToEntityToIds(bridge.toEntityId, bridge);
    // if (toIdResult == false) {
    //   // TODO: needs to be changed
    //   let bridgeDeleteFromEntityFromIdsResult = deleteBridgeFromEntityFromIds(bridge.fromEntityId, bridge.id);
    //   bridgesStorage.delete(bridge.id);
    //   return null;
    // };

    return ?bridge.id;
  };

  /**
   * Function is a simple way to add a Bridge to storage without any checks and
   * adding the bridge to the appropriate entity. This is useful for updating
   * an already created bridge
   *
   * @return The newly created bridge
  */
  private func putBridge(bridge : Bridge.Bridge): async Bridge.Bridge {
    let bridgeAttributes = Bridge.getBridgeAttributesFromBridgeObject(bridge);
    await* CanDB.put(db, {
      sk = bridge.id;
      attributes = bridgeAttributes;
    });
    return bridge;
  };

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

  /**
   * Function retrieves a bridge based on the input ID
   *
   * @return The bridge if it is found or null if not found
  */
  private func getBridge(bridgeId : Text) : ?Bridge.Bridge {
    let bridgeData = switch(CanDB.get(db, { sk = bridgeId }))  { // TODO: double-check pk and sk
      case null { null };
      case (?canDbEntity) { unwrapBridge(canDbEntity)};
    };

    switch(bridgeData) {
      case(?b)  { ?b };
      case null { null };
    };
  };

  func unwrapBridge(canDbEntity: CanDbEntity.Entity): ?Bridge.Bridge {
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
    let bridgeTypeValue = CanDbEntity.getAttributeMapValueForKey(attributes, "bridgeType");
    let fromEntityIdValue = CanDbEntity.getAttributeMapValueForKey(attributes, "fromEntityId");
    let toEntityIdValue = CanDbEntity.getAttributeMapValueForKey(attributes, "toEntityId");

    switch(idValue, creationTimestampValue, creatorValue, ownerValue, nameValue, descriptionValue, keywordsValue, entitySpecificFieldsValue, listOfEntitySpecificFieldKeysValue, settingsValue, bridgeTypeValue, fromEntityIdValue, toEntityIdValue) {
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
          ?(#blob(bridgeType)),
          ?(#text(fromEntityId)),
          ?(#text(toEntityId)),
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
          settings = Option.get<Bridge.BridgeSettings>(from_candid(settings), Bridge.BridgeSettings()); // TODO: while the null case shouldn't happen, this is also a bad way of handling it
          bridgeType = Option.get<Bridge.BridgeType>(from_candid(bridgeType), #IsRelatedto); // TODO: while the null case shouldn't happen, this is also a bad way of handling it
          fromEntityId;
          toEntityId;
        }
      };
      case _ { null };
    };
  };
  
  // TODO: needs to change as Bridges are distributed across multiple canisters
    // Does not work properly currently
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