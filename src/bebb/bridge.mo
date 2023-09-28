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
import Types "Types";
import BaseEntity "base_entity";

import CanDbEntity "mo:candb/Entity";
import CandyTypes "mo:candy/types";

module {

  public type CanDbAttributes = [(CanDbEntity.AttributeKey, CanDbEntity.AttributeValue)];

  /**
   * Defines the errors for the public API when trying to retrieve a Bridge ID
  */
  public type BridgeIdErrors = {
    #Unauthorized;
    #BridgeNotFound;
    #Error;
  };

  /**
   * Defines the result type for trying to retieve the ID of a bridge from
   * the public API
  */
  public type BridgeIdResult = Types.Result<Text, BridgeIdErrors>;

  /**
   * Defines the bridge errors that can occur when trying to retrieve a bridge
  */
  public type BridgeErrors = {
    #Unauthorized : Text;
    #BridgeNotFound;
    #Error;
  };

  /**
   * Defines the result type for trying to retrieve an Entity from
   * the public API
  */
  public type BridgeResult = Types.Result<Bridge, BridgeErrors>;

  /**
   * Stores bridge specific settings
  */
  public class BridgeSettings() {
    var mainSetting : Text = "default";
  };

  /**
   * The available bridge types that can be used to describe a bridge
   * This defines the Bridges relationship to the Entity as defined by the Bridge owner
  */
  public type BridgeType = {
    #IsPartOf;
    #IsRelatedto;
    #IsAttachedto;
  };

  /**
   * The type that defines the attributes for a Bridge
  */
  public type Bridge = BaseEntity.BaseEntity and {
    /**
     * Settings for the bridge
    */
    // settings : BridgeSettings;
    /**
     * The type of the bridge
    */
    // bridgeType : BridgeType;
    /**
     * The entity ID that specifies the starting entity for the bridge
    */
    fromEntityId : Text;
    /**
     * The entity ID that specifies the ending entity for the bridge
    */
    toEntityId : Text;
  };

  /**
   * The initialization object is the fields provided by a user
   * in order to create a bridge. The rest of the fields are automatically
   * created by Bebb
  */
  public type BridgeInitiationObject = {
    // settings : ?BridgeSettings;
    name : ?Text;
    description : ?Text;
    keywords : ?[Text];
    // bridgeType : BridgeType;
    fromEntityId : Text;
    toEntityId : Text;
    entitySpecificFields : ?Text;
  };

  /**
   * This function is used to convert a user provided initialization object
   * and converts it into a Bridge. This bridge contains a null id and is not
   * saved in the database yet
   *
   * @return The newly created bridge with a empty id
  */
  public func generateBridgeFromInitializationObject(
    initiationObject : BridgeInitiationObject,
    id : Text,
    caller : Principal,
  ) : Bridge {
    return {
      id : Text = id;
      // creationTimestamp : Nat64 = Nat64.fromNat(Int.abs(Time.now()));
      creator : Principal = caller;
      owner : Principal = caller;
      // settings : BridgeSettings = switch (initiationObject.settings) {
      //   case null { BridgeSettings() };
      //   case (?customSettings) { customSettings };
      // };
      name : Text = Option.get<Text>(initiationObject.name, "");
      description : Text = Option.get<Text>(initiationObject.description, "");
      keywords : [Text] = Option.get<[Text]>(initiationObject.keywords, []);
      entitySpecificFields : Text = Option.get<Text>(initiationObject.entitySpecificFields, "");
      listOfEntitySpecificFieldKeys : [Text] = ["bridgeType", "fromEntityId", "toEntityId"];
      // bridgeType : BridgeType = initiationObject.bridgeType;
      fromEntityId : Text = initiationObject.fromEntityId;
      toEntityId : Text = initiationObject.toEntityId;
    };
  };

  /**
   * This function is used to convert a Bridge object 
   * into an array with the Bridge's attributes.
   * This array is used to store the Bridge in CanDB
   *
   * @return The array with the Bridge's attributes
  */
  public func getBridgeAttributesFromBridgeObject( bridge : Bridge ) : CanDbAttributes {
    // https://mops.one/candy/docs/properties
    // https://mops.one/candy/docs/conversion
      // see e.g. propertySharedToText
    let prop: [CandyTypes.PropertyShared] = [{
      name = "name";
      value = #Principal(Principal.fromText("abc"));
      immutable = true;
    }];
    return [
      ("id", #text(bridge.id)),
      // ("creationTimestamp", #int(Nat64.toNat(bridge.creationTimestamp))),
      ("creator", #text(Principal.toText(bridge.creator))),
      ("owner", #text(Principal.toText(bridge.owner))),
      ("name", #text(bridge.name)),
      ("description", #text(bridge.description)),
      ("keywords", #arrayText(bridge.keywords)),
      ("entitySpecificFields", #text(bridge.entitySpecificFields)),
      ("listOfEntitySpecificFieldKeys", #arrayText(bridge.listOfEntitySpecificFieldKeys)),
      // ("settings", #candy(bridge.settings)), // TODO: to verify
      // ("bridgeType", #candy(bridge.bridgeType)), // TODO: to verify
      ("fromEntityId", #text(bridge.fromEntityId)),
      ("toEntityId", #text(bridge.toEntityId)),
      // ("test", #candy(#Class(prop))), //This does not show a type error (TODO: remove)
    ];
  };

  /**
   * Function takes a bridge update object and an already created bridge and updates the bridge with the new values
   * provided by the bridge update object
   *
   * @return The new bridge with the values updated with the bridge update values
  */
  public func updateBridgeFromUpdateObject(bridgeUpdateObject : BridgeUpdateObject, originalBridge : Bridge) : Bridge {
    return {
      id : Text = originalBridge.id;
      // creationTimestamp : Nat64 = originalBridge.creationTimestamp;
      creator : Principal = originalBridge.creator;
      owner : Principal = originalBridge.owner;
      // settings : BridgeSettings = Option.get<BridgeSettings>(bridgeUpdateObject.settings, originalBridge.settings);
      name = Option.get<Text>(bridgeUpdateObject.name, originalBridge.name);
      description : Text = Option.get<Text>(bridgeUpdateObject.description, originalBridge.description);
      keywords = Option.get<[Text]>(bridgeUpdateObject.keywords, originalBridge.keywords);
      // bridgeType : BridgeType = originalBridge.bridgeType;
      fromEntityId : Text = originalBridge.fromEntityId;
      toEntityId : Text = originalBridge.toEntityId;
      entitySpecificFields = originalBridge.entitySpecificFields;
      listOfEntitySpecificFieldKeys = originalBridge.listOfEntitySpecificFieldKeys;
    };
  };

  /**
   This type defines the fields that the current owner is allowed
   to modify and use to update the bridge
  */
  public type BridgeUpdateObject = {
    /**
     * The id of the bridge to update
     * Note: This value cannot be updated and only used to identify the Bridge to update
    */
    id : Text;
    /**
      * The new settings to add to the bridge
    */
    settings : ?BridgeSettings;
    /**
     * The updated name for the bridge
    */
    name : ?Text;
    /**
     * The updated descrition for the bridge
    */
    description : ?Text;
    /**
     * The Updated keywords for the bridge
    */
    keywords : ?[Text];
  };
};
