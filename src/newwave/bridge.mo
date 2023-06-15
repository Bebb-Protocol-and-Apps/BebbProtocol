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
import NewWaveError "errors";

module  {

  public type BridgeResult = Types.Result<?Bridge, NewWaveError.NewWaveError>;


  public class BridgeSettings() {
    var mainSetting : Text = "default";
  };

  public type BridgeType = {
      #OwnerCreated;
  };

  public type BridgeState = {
    #Pending;
    #Rejected;
    #Confirmed;
  };

  public type Bridge = {
    id: Text;
    creationTimestamp : Nat64;
    creator : Principal;
    owner : Principal;
    settings : BridgeSettings;
    name : ?Text;
    description : ?Text;
    keywords : ?[Text];
    listOfBridgeSpecificFieldKeys : [Text];
    bridgeType : BridgeType;
    fromEntityId : Text;
    toEntityId : Text;
    state : BridgeState;
  };
  public let BridgeKeys : [Text] = ["bridgeType"];

  public type BridgeInitiationObject = {
    _settings : ?BridgeSettings;
    _name : ?Text;
    _description : ?Text;
    _keywords : ?[Text];
    _bridgeType : BridgeType;
    _fromEntityId : Text;
    _toEntityId : Text;
    _state : ?BridgeState;
  };

  public let BridgeInitiationObjectKeys : [Text] = ["_bridgeType", "_fromEntityId", "_toEntityId", "_state"];

  public func generateBridgeFromInitializationObject(
    initiationObject : BridgeInitiationObject,
    caller : Principal,
  ) : async Bridge { // or Entity.Entity
    return {
      id : Text = await Utils.newRandomUniqueId();
      creationTimestamp : Nat64 = Nat64.fromNat(Int.abs(Time.now()));
      creator : Principal = caller;
      owner : Principal = caller;
      settings : BridgeSettings = switch(initiationObject._settings) {
        case null { BridgeSettings() };
        case (?customSettings) { customSettings };
      };
      name : ?Text = initiationObject._name;
      description : ?Text = initiationObject._description;
      keywords : ?[Text] = initiationObject._keywords;
      listOfBridgeSpecificFieldKeys : [Text] = ["bridgeType", "fromEntityId", "toEntityId", "state"];
      bridgeType : BridgeType = initiationObject._bridgeType;
      fromEntityId : Text = initiationObject._fromEntityId;
      toEntityId : Text = initiationObject._toEntityId;
      state : BridgeState = #Confirmed;
    }
  };

  public type BridgeUpdateObject = {
    settings : ?BridgeSettings;
    name : ?Text;
    description : ?Text;
    keywords : ?[Text];
    state : ?BridgeState;
    bridgeType : ?BridgeType;
  };
};
