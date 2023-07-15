import Time "mo:base/Time";
import Int "mo:base/Int";
import Nat64 "mo:base/Nat64";

import Error "mo:base/Error";
import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import P "mo:base/Prelude";
import Nat32 "mo:base/Nat32";
import Result "mo:base/Result";

import Random "mo:base/Random";
import Blob "mo:base/Blob";

import Utils "Utils";
import Text "mo:base/Text";
import Types "Types";
import BaseEntity "base_entity";
import Bridge "bridge";

module {

  /**
   * Types of errors for finding the attached bridges
  */
  public type EntityAttachedBridgesErrors = {
    #EntityNotFound;
    #Error;
  };

  /**
   * Stores the possible link status which describe how the Entity is linked to the Bridge
   * This status is owned by the Entity to allow the Entity control over how it views the Bridge and
   * provide info to others looking at the connection
  */
  public type BridgeLinkStatus = {
    #CreatedOwner;
    #CreatedOther;
  };

  /**
   * Defines the specific data to cache from a specific bridge connection. Provides Entity controlled data to describe
   * the connection to the Bridge
  */
  public type EntityAttachedBridge = {
    /**
     * Stores the link status defining the relationship of the bridge as defined by 
     * the Entity. I.e Did the Entity Owner created the bridge, did the Entity endorse the link etc
    */
    linkStatus: BridgeLinkStatus;
    /**
     * The id of the bridge that is associated with this link
    */
    id: Text;
    /**
     * The time that the bridge was added to the Entity
    */
    creationTime: Time.Time;
    /**
     * Stores the type of the bridge and how the bridge is related to the entity
    */
    bridgeType : Bridge.BridgeType;
  };

  /**
   * Defines the bridge attachment types that Entities store when caching references to the Bridges either linked
   * to them or from them.
  */
  public type EntityAttachedBridges = [EntityAttachedBridge];

  /**
   * Return type for when finding the ids of attached bridges
  */
  public type EntityAttachedBridgesResult = Types.Result<EntityAttachedBridges, EntityAttachedBridgesErrors>;

  /**
   * Defines the errors for the public API when trying to retrieve an Entity ID
  */
  public type EntityIdErrors = {
    #Unauthorized;
    #EntityNotFound;
    #Error;
  };

  /**
   * Defines the result type for trying to retieve the ID of an entity from
   * the public API
  */
  public type EntityIdResult = Types.Result<Text, EntityIdErrors>;

  /**
   * Defines the entity errors that can occur when trying to retrieve an entity
  */
  public type EntityErrors = {
    #Unauthorized : Text;
    #EntityNotFound;
    #Error;
  };

  /**
   * Defines the result type for trying to retrieve an Entity from
   * the public API
  */
  public type EntityResult = Types.Result<Entity, EntityErrors>;

  /**
   * Stores entity specific settings
  */
  public class EntitySettings() {
    var mainSetting : Text = "default";
  };

  /**
   * The available entity types that can be used to describe an entity
  */
  public type EntityType = {
    #BridgeEntity;
    #Webasset;
    #Person;
    #Location;
  };

  /**
   * Type that defines the attributes for an Entity
  */
  public type Entity = BaseEntity.BaseEntity and {
    /**
     * Settings for the entity
    */
    settings : EntitySettings;
    /**
     * The type that defines the entity
    */
    entityType : EntityType;
    /**
     * Contains all the bridge ids that originate from this
     * Entity
    */
    fromIds : EntityAttachedBridges;

    /**
     * Contains all the bridge ids that point to this entity
    */
    toIds : EntityAttachedBridges;
  };

  /**
   * The initialization object is the fields provided by a user
   * in order to create an entity. The rest of the fields are automatically
   * created by Bebb
  */
  public type EntityInitiationObject = {
    settings : ?EntitySettings;
    entityType : EntityType;
    name : ?Text;
    description : ?Text;
    keywords : ?[Text];
    entitySpecificFields : ?Text;
  };

  /**
   * This function is used to convert a user provided initialization object
   * and converts it into an Entity. This entity contains a null id and is not
   * saved in the database yet
   *
   * @return The newly created entity with a empty id
  */
  public func generateEntityFromInitializationObject(
    initiationObject : EntityInitiationObject,
    entityId : Text,
    caller : Principal,
  ) : Entity {
    return {
      id : Text = entityId;
      creationTimestamp : Nat64 = Nat64.fromNat(Int.abs(Time.now()));
      creator : Principal = caller;
      owner : Principal = caller;
      settings : EntitySettings = switch (initiationObject.settings) {
        case null { EntitySettings() };
        case (?customSettings) { customSettings };
      };
      entityType : EntityType = initiationObject.entityType;
      name : ?Text = initiationObject.name;
      description : ?Text = initiationObject.description;
      keywords : ?[Text] = initiationObject.keywords;
      entitySpecificFields : ?Text = initiationObject.entitySpecificFields;
      listOfEntitySpecificFieldKeys : [Text] = ["entityType", "fromIds", "toIds"];
      toIds : EntityAttachedBridges = [];
      fromIds : EntityAttachedBridges = [];
    };
  };

  /**
   * Function updates an entity and returns a new entity with the fromIds updated to the new value
   *
   * @return A new entity with the new fromIds field
  */
  public func updateEntityFromIds(entity : Entity, fromIds : EntityAttachedBridges) : Entity {
    return {
      id = entity.id;
      creationTimestamp = entity.creationTimestamp;
      creator = entity.creator;
      owner = entity.owner;
      settings = entity.settings;
      entityType = entity.entityType;
      name = entity.name;
      description = entity.description;
      keywords = entity.keywords;
      entitySpecificFields = entity.entitySpecificFields;
      listOfEntitySpecificFieldKeys = entity.listOfEntitySpecificFieldKeys;
      fromIds = fromIds;
      toIds = entity.toIds;
    };
  };

  /**
   * Function updates an entity and returns a new entity with the toIds updated to the new value
   *
   * @return A new entity with the new toIds field
  */
  public func updateEntityToIds(entity : Entity, toIds : EntityAttachedBridges) : Entity {
    return {
      id = entity.id;
      creationTimestamp = entity.creationTimestamp;
      creator = entity.creator;
      owner = entity.owner;
      settings = entity.settings;
      entityType = entity.entityType;
      name = entity.name;
      description = entity.description;
      keywords = entity.keywords;
      entitySpecificFields = entity.entitySpecificFields;
      listOfEntitySpecificFieldKeys = entity.listOfEntitySpecificFieldKeys;
      fromIds = entity.fromIds;
      toIds = toIds;
    };
  };

  /**
   * Function takes a entity update object and an already created entity and updates the entity with the new values
   * provided by the entity update object
   *
   * @return The new entity with the values updated with the entity update values
  */
  public func updateEntityFromUpdateObject(entityUpdateObject : EntityUpdateObject, originalEntity : Entity) : Entity {
    return {
      id = originalEntity.id;
      creationTimestamp = originalEntity.creationTimestamp;
      creator = originalEntity.creator;
      owner = originalEntity.owner;
      settings = Option.get<EntitySettings>(entityUpdateObject.settings, originalEntity.settings);
      entityType = originalEntity.entityType;
      name = Option.get<?Text>(?entityUpdateObject.name, originalEntity.name);
      description : ?Text = Option.get<?Text>(?entityUpdateObject.description, originalEntity.description);
      keywords : ?[Text] = Option.get<?[Text]>(?entityUpdateObject.keywords, originalEntity.keywords);
      entitySpecificFields = originalEntity.entitySpecificFields;
      listOfEntitySpecificFieldKeys = originalEntity.listOfEntitySpecificFieldKeys;
      fromIds = originalEntity.fromIds;
      toIds = originalEntity.toIds;
    };
  };

  /**
   This type defines the fields that the current owner is allowed
   to modify and use to update the entity
  */
  public type EntityUpdateObject = {
    /**
     * The ID of the entity to update
     * Note: This value cannot be updated and only used to identify the Entity to update
    */
    id : Text;
    /**
      * The new settings to add to the entity
    */
    settings : ?EntitySettings;
    /**
     * The updated name for the entity
    */
    name : ?Text;
    /**
     * The updated descrition for the entity
    */
    description : ?Text;
    /**
     * The Updated keywords for the entity
    */
    keywords : ?[Text];
  };

  /**
   * Determines the initial link bridge state to apply to the bridge attachment based on the ownership of the bridge
   * and the Entity
  */
  public func determineBridgeLinkStatus(entity: Entity, bridge: Bridge.Bridge) : BridgeLinkStatus
  {
      if (entity.owner == bridge.owner)
      {
        return #CreatedOwner;
      };

      return #CreatedOther;
  }
};
