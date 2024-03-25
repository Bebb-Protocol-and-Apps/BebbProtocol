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
import Buffer "mo:base/Buffer";

import CanDbEntity "mo:candb/Entity";
import BebbEntityService "BebbEntityService";

shared ({ caller = owner }) actor class BebbBridgeService({
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
          Public Interface for Bridges
  *************************************************/
  /**
   * Public interface for creating a new bridge. When a bridge is created, it will add the bridge to the database and also
   * add the bridge id to the attached entities for reference
   *
   * @return The bridge id if the bridge was successfully created, otherwise an error
  */
  public shared ({ caller }) func create_bridge(bridgeToCreate : Bridge.BridgeInitiationObject, canisterIds: Bridge.BridgeEntityCanisterHints) : async Bridge.BridgeIdResult {
    if (partitionKey != db.pk) {
      return #Err(#Unauthorized("Wrong Partition"));
    };
    let result = await createBridge(caller, bridgeToCreate, canisterIds);
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
    if (partitionKey != db.pk) {
      return #Err(#Unauthorized("Wrong Partition"));
    };
    let result = getBridge(bridgeId);
    switch (result) {
      case (null) { return #Err(#Error) };
      case (?bridge) { return #Ok(bridge) };
    };
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
   * Public interface for deleting a Bridge. Only the owner is allowed to delete the Brige.
   * Also deletes the Bridge attachment on the connected Entities
   *
   * @return The bridge id if the deletion was successful, otherwise an error
  */
  public shared ({ caller }) func delete_bridge(bridgeId : Text, canisterIds: Bridge.BridgeEntityCanisterHints) : async Bridge.BridgeIdResult {
    let result = await deleteBridge(caller, bridgeId, canisterIds);
    return result;
  };

  /*************************************************
          Helper Functions related to Bridges
  *************************************************/
  /**
   * Function deletes the Bridge if it exists. If it is able
   * to, it returns the id
   *
   * @return The id of the Bridge if the deletion was successful, otherwise null
  */
  private func deleteBridge(caller : Principal, bridgeId : Text, canisterIds: Bridge.BridgeEntityCanisterHints) : async Bridge.BridgeIdResult {
    switch (getBridge(bridgeId)) {
      case null { return #Err(#BridgeNotFound) };
      case (?bridgeToDelete) {
        switch (Principal.equal(bridgeToDelete.owner, caller)) {
          case false {
            return #Err(#Unauthorized("Not the owner"));
          }; // Only owner may delete the Bridge
          case true {
            // Parallelized retrievals of the connected Entities for additional processing 
              // first, to check that the two Entities actually exist in the canisters provided
            let executingFunctionsBuffer = Buffer.Buffer<async Bool>(2);
            executingFunctionsBuffer.add(checkIfEntityExists(bridgeToDelete.toEntityId, canisterIds.toEntityCanisterId)); 
            executingFunctionsBuffer.add(checkIfEntityExists(bridgeToDelete.fromEntityId, canisterIds.fromEntityCanisterId));
            switch(await executingFunctionsBuffer.get(0)) { // toEntityResponse
              case false { return #Err(#Unauthorized("Not the correct canister for toEntity")); }; // to Entity doesn't exist
              case true {
                switch(await executingFunctionsBuffer.get(1)) { // fromEntityResponse
                  case false { return #Err(#Unauthorized("Not the correct canister for fromEntity")); }; // from Entity doesn't exist
                  case true {
                    let attachmentDeletionResult = await deleteBridgeAttachmentsFromEntities(bridgeToDelete, canisterIds);
                    let result = deleteBridgeFromStorage(bridgeId);
                    return #Ok(bridgeId);
                  };
                };
              };
            };
          };
        };
      };
    };
  };

  /**
   * Function deletes a Bridge from storage. Ensure to delete the connections from the connected Entities
   * before removing the Bridge
   *
   * @return True if the Bridge was successfully deleted, false otherwise
  */
  func deleteBridgeFromStorage(bridgeId : Text) : Bool {
    CanDB.delete(db, {
      sk = bridgeId;
    });
    return true;
  };

  private func deleteBridgeAttachmentsFromEntities(bridge : Bridge.Bridge, canisterIds: Bridge.BridgeEntityCanisterHints) : async ?Text {
    // Parallelized calls to the canisters storing the connected Entities to delete the Bridge attachment 
    let executingFunctionsBuffer = Buffer.Buffer<async Bool>(2);
    executingFunctionsBuffer.add(deleteBridgeAttachmentOnEntity(bridge, true, canisterIds.toEntityCanisterId)); 
    executingFunctionsBuffer.add(deleteBridgeAttachmentOnEntity(bridge, false, canisterIds.fromEntityCanisterId));
    switch(await executingFunctionsBuffer.get(0)) { // toEntityResponse
      case false { return null; }; // Error in deleting attachment on to Entity, TODO: better handling (e.g. retry, add to error list, notify)
      case(true) {
        switch(await executingFunctionsBuffer.get(1)) { // fromEntityResponse
          case false { return null; }; // Error in deleting attachment on from Entity, TODO: better handling (e.g. retry, add to error list, notify)
          case(true) {
            // both attachments were deleted
            return ?bridge.id;
          };
        };
      };
    };
  };

  private func deleteBridgeAttachmentOnEntity(bridge : Bridge.Bridge, bridgingTo : Bool, canisterId: Text) : async Bool {
    let entityCanister = actor(canisterId): actor { delete_bridge_attachment: (Bridge.Bridge, Bool) -> async Entity.EntityIdResult };
    // Call function on Entity canister to delete Bridge attachment
    let entityIdResult = await entityCanister.delete_bridge_attachment(bridge, bridgingTo);
    switch (entityIdResult)
    {
      case(#Ok(entityId)) {
        return true;
      };
      case _ {
        return false;
      }
    };
  };

  /**
   * Function creates a new bridge based on the input initialization object. If it is able
   * to make the object, it stores it and return the id, otherwise it will not
   * store an object and return an empty string
   *
   * @return The id of the new entity if the entity creation was successful, otherwise an empty string
  */
  private func createBridge(caller : Principal, bridgeToCreate : Bridge.BridgeInitiationObject, canisterIds: Bridge.BridgeEntityCanisterHints) : async ?Text {
    // Parallelized retrievals of the to be connected Entities for additional processing 
      // first, to check that the two Entities actually exist 
    let executingFunctionsBuffer = Buffer.Buffer<async ?Entity.Entity>(2);
    executingFunctionsBuffer.add(getEntity(bridgeToCreate.toEntityId, canisterIds.toEntityCanisterId)); 
    executingFunctionsBuffer.add(getEntity(bridgeToCreate.fromEntityId, canisterIds.fromEntityCanisterId));
    switch(await executingFunctionsBuffer.get(0)) { // toEntityResponse
      case null { return null; }; // to Entity doesn't exist
      case(?toEntityRetrieved) {
        switch(await executingFunctionsBuffer.get(1)) { // fromEntityResponse
          case null { return null; }; // from Entity doesn't exist
          case(?fromEntityRetrieved) {
            var toEntity : Entity.Entity = toEntityRetrieved;
            var fromEntity : Entity.Entity = fromEntityRetrieved;
            // Find a unique id for the new Bridge 
            var newBridgeId : Text = await Utils.newRandomUlid();
            let bridge : Bridge.Bridge = Bridge.generateBridgeFromInitializationObject(bridgeToCreate, newBridgeId, caller);
            return await addNewBridge(bridge, fromEntity, toEntity, canisterIds);
          };
        };
      };
    };
  };

  /**
   * Function adds a new bridge and attempts to add the bridge to the entities
   * bridge lookup tables. If adding the bridge to the entities fails, then the bridge
   * is not created and is instead deleted
   *
   * @return Returns null if the entitiy failed to get created, otherwise it returns
   * the bridge id of the newly created bridge
  */
  private func addNewBridge(bridge : Bridge.Bridge, fromEntity : Entity.Entity, toEntity : Entity.Entity, canisterIds: Bridge.BridgeEntityCanisterHints) : async ?Text {
    // Add the Bridge to the Bridge database and add the Bridge id to the connected Entities
    let result = await putBridge(bridge);
    // Parallelized calls to the canisters storing the connected Entities to add the Bridge attachment 
    let executingFunctionsBuffer = Buffer.Buffer<async Bool>(2);
    executingFunctionsBuffer.add(addBridgeAttachmentOnEntity(toEntity, bridge, true, canisterIds.toEntityCanisterId)); 
    executingFunctionsBuffer.add(addBridgeAttachmentOnEntity(fromEntity, bridge, false, canisterIds.fromEntityCanisterId));
    switch(await executingFunctionsBuffer.get(0)) { // toEntityResponse
      case false { return null; }; // Error in adding attachment on to Entity, TODO: better handling (e.g. retry, add to error list, notify)
      case(true) {
        switch(await executingFunctionsBuffer.get(1)) { // fromEntityResponse
          case false { return null; }; // Error in adding attachment on from Entity, TODO: better handling (e.g. retry, add to error list, notify)
          case(true) {
            // both attachments were added
            return ?bridge.id;
          };
        };
      };
    };
  };

  /**
  * Function checks that the given entity id provided exists within the database
  *
  * @return True if the entity exists, false otherwise
  */
  private func checkIfEntityExists(entityId : Text, canisterId: Text) : async Bool {
    let entityCanister = actor(canisterId): actor { skExists: (Text) -> async Bool };
    return await entityCanister.skExists(entityId);
  };

  /**
   * Function checks that the given bridge id provided exists within the database
   *
   * @return True if the entity exists, false otherwise
  */
  private func checkIfBridgeExists(bridgeId : Text, canister_id: Text) : Bool {
    let result = getBridge(bridgeId);
    switch (result) {
      case (null) { return false };
      case (bridge) { return true };
    };
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

  /**
   * Function retrieves a bridge based on the input ID
   *
   * @return The bridge if it is found or null if not found
  */
  private func getBridge(bridgeId : Text) : ?Bridge.Bridge {
    let bridgeData = switch(CanDB.get(db, { sk = bridgeId }))  {
      case null { null };
      case (?canDbEntity) { unwrapBridge(canDbEntity)};
    };

    switch(bridgeData) {
      case(?b)  { ?b };
      case null { null };
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
            return #Err(#Unauthorized("Not the owner"));
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

  /**
   * This function takes a bridge and adds the bridge ID to the fromIds field
   * of the entity it is linked from
   * bridgingTo: if Entity is Entity to bridge to then true, if bridging from the Entity then false
   * @return True if the bridge ID was added to the from ID list, otherwise
   * false is returned if it couldn't
  */
  private func addBridgeAttachmentOnEntity(entity : Entity.Entity, bridge : Bridge.Bridge, bridgingTo : Bool, canisterId: Text) : async Bool {
    let entityCanister = actor(canisterId): actor { add_bridge_attachment: (Text, Bridge.Bridge, Bool) -> async Entity.EntityIdResult };
    // Call function on Entity canister to add Bridge attachment
    let entityIdResult = await entityCanister.add_bridge_attachment(entity.id, bridge, bridgingTo);
    switch (entityIdResult)
    {
      case(#Ok(entityId)) {
        return true;
      };
      case _ {
        return false;
      }
    };
  };

  /**
   * Given a canister id hint, this will look at that canister to try to retrieve the corresponding Entity
   *
   * @return The entity if it exists, otherwise null
  */
  private func getEntity(entityId : Text, canister_id: Text) : async ?Entity.Entity {
    let entityCanister = actor(canister_id): actor { get_entity: (Text) -> async Entity.EntityResult };
    let entityResult = await entityCanister.get_entity(entityId);
    switch (entityResult)
    {
      case(#Ok(entity)) {
        return ?entity;
      };
      case _ {
        return null;
      }
    }
  };

}