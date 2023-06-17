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

module {
  /**
   * Defines the errors for the public API when trying to retrieve an Entity ID
  */
  public type EntityIdErrors = {
    #Unauthorized : Text;
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
   * THe available entity types that can be used to describe an entity
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
  public type Entity = {
    /**
     * The ID of the Entity that is used to store it in 
     * in the entity database
    */
    id: Text;
    /**
     * The timestamp in UTC (maybe) that the entity was created
    */
    creationTimestamp : Nat64;
    /**
     * The original creator of the entity. 
    */
    creator : Principal;
    /**
     * The current owner of the entity
    */
    owner : Principal;
    /**
     * Settings for the entity
    */
    settings : EntitySettings;
    /**
     * The type that defines the entity
    */
    entityType : EntityType;
    /**
     * A human readable name? for the entity
    */
    name : ?Text;
    /**
     * An owner defined description for what the entity is
    */
    description : ?Text;
    /**
     * Keywords that are used to descripe the entity to 
     * enable more efficient lookup of the entity?
    */
    keywords : ?[Text];
    /**
     * Unknown
    */
    entitySpecificFields : ?Text;
    /**
     * Unknown
    */
    listOfEntitySpecificFieldKeys : [Text];
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
  */
  public func generateEntityFromInitializationObject(
    initiationObject : EntityInitiationObject,
    caller : Principal,
  ) : async Entity {
    return {
      id : Text = "";
      creationTimestamp : Nat64 = Nat64.fromNat(Int.abs(Time.now()));
      creator : Principal = caller;
      owner : Principal = caller;
      settings : EntitySettings = switch(initiationObject.settings) {
        case null { EntitySettings() };
        case (?customSettings) { customSettings };
      };
      entityType : EntityType = initiationObject.entityType;
      name : ?Text = initiationObject.name;
      description : ?Text = initiationObject.description;
      keywords : ?[Text] = initiationObject.keywords;
      entitySpecificFields : ?Text = initiationObject.entitySpecificFields;
      listOfEntitySpecificFieldKeys : [Text] = [];
    }
  };

  /**
   This type defines the fields that the current owner is allowed
   to modify and use to update the entity
  */  
  public type EntityUpdateObject = {
    id : Text;
    settings : ?EntitySettings;
    name : ?Text;
    description : ?Text;
    keywords : ?[Text];
  };
};
