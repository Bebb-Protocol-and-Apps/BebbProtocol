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

module {

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
  */
  public type BridgeType = {
    #OwnerCreated;
  };

  /**
    * The bridge states that describe the current status of a bridge
  */
  public type BridgeState = {
    #Pending;
    #Rejected;
    #Confirmed;
  };

  /**
    * The type that defines the attributes for a Bridge
  */
  public type Bridge = {
    /**
     * The ID of the Bridge that is used to store it in
     * in the bridge database
    */
    id : Text;
    /**
     * The timestamp in UTC (maybe) that the bridge was created
    */
    creationTimestamp : Nat64;
    /**
     * The original creator of the bridge.
    */
    creator : Principal;
    /**
     * The current owner of the bridge
    */
    owner : Principal;
    /**
     * Settings for the bridge
    */
    settings : BridgeSettings;
    /**
     * A human readable name? for the bridge
    */
    name : ?Text;
    /**
     * An owner defined description for what the bridge is
    */
    description : ?Text;
    /**
     * Keywords that are used to descripe the bridge to
     * enable more efficient lookup of the bridge?
    */
    keywords : ?[Text];
    /**
     * Unknown
    */
    listOfBridgeSpecificFieldKeys : [Text];
    /**
     * The type of the bridge
    */
    bridgeType : BridgeType;
    /**
     * The entity ID that specifies the starting entity for the bridge
    */
    fromEntityId : Text;
    /**
     * The entity ID that specifies the ending entity for the bridge
    */
    toEntityId : Text;
    /**
     * The current bridge stated (TO BE DEPRECATED)
    */
    state : BridgeState;
  };

  /**
   * The initialization object is the fields provided by a user
   * in order to create a bridge. The rest of the fields are automatically
   * created by Bebb
  */
  public type BridgeInitiationObject = {
    settings : ?BridgeSettings;
    name : ?Text;
    description : ?Text;
    keywords : ?[Text];
    bridgeType : BridgeType;
    fromEntityId : Text;
    toEntityId : Text;
    state : ?BridgeState;
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
      creationTimestamp : Nat64 = Nat64.fromNat(Int.abs(Time.now()));
      creator : Principal = caller;
      owner : Principal = caller;
      settings : BridgeSettings = switch (initiationObject.settings) {
        case null { BridgeSettings() };
        case (?customSettings) { customSettings };
      };
      name : ?Text = initiationObject.name;
      description : ?Text = initiationObject.description;
      keywords : ?[Text] = initiationObject.keywords;
      listOfBridgeSpecificFieldKeys : [Text] = ["bridgeType", "fromEntityId", "toEntityId", "state"];
      bridgeType : BridgeType = initiationObject.bridgeType;
      fromEntityId : Text = initiationObject.fromEntityId;
      toEntityId : Text = initiationObject.toEntityId;
      state : BridgeState = #Confirmed;
    };
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
      creationTimestamp : Nat64 = originalBridge.creationTimestamp;
      creator : Principal = originalBridge.creator;
      owner : Principal = originalBridge.owner;
      settings : BridgeSettings = Option.get<BridgeSettings>(bridgeUpdateObject.settings, originalBridge.settings);
      name : ?Text = Option.get<?Text>(?bridgeUpdateObject.name, originalBridge.name);
      description : ?Text = Option.get<?Text>(?bridgeUpdateObject.description, originalBridge.description);
      keywords : ?[Text] = Option.get<?[Text]>(?bridgeUpdateObject.keywords, originalBridge.keywords);
      bridgeType : BridgeType = originalBridge.bridgeType;
      fromEntityId : Text = originalBridge.fromEntityId;
      toEntityId : Text = originalBridge.toEntityId;
      state : BridgeState = originalBridge.state;
      listOfBridgeSpecificFieldKeys = originalBridge.listOfBridgeSpecificFieldKeys;
    };
  };

  /**
   This type defines the fields that the current owner is allowed
   to modify and use to update the bridge
  */
  public type BridgeUpdateObject = {
    /**
     * The id of the bridge to update
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
