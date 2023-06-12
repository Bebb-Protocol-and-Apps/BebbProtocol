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

import EntityType "entity_type";
import EntitySettings "entity_settings";
import Entity "entity";
import BridgeType "bridge_type";
import BridgeState "bridge_state";

import Utils "Utils";

module  {
  public type BridgeEntity = Entity.Entity and {
    bridgeType : BridgeType.BridgeType;
    fromEntityId : Text;
    toEntityId : Text;
    state : BridgeState.BridgeState;
  };
  public let BridgeEntityKeys : [Text] = ["bridgeType"];

  public type BridgeEntityInitiationObject = Entity.EntityInitiationObject and {
    _bridgeType : BridgeType.BridgeType;
    _fromEntityId : Text;
    _toEntityId : Text;
    _state : ?BridgeState.BridgeState;
  };
  public let BridgeEntityInitiationObjectKeys : [Text] = ["_bridgeType", "_fromEntityId", "_toEntityId", "_state"];

  public func BridgeEntity(
    initiationObject : BridgeEntityInitiationObject,
    caller : Principal,
  ) : BridgeEntity { // or Entity.Entity
    return {
      internalId : Text = switch(initiationObject._internalId) { // TODO: should bridge id be assignable? probably: always assign random id
        case null { Utils.newUniqueId() };
        case (?customId) { customId };
      };
      creationTimestamp : Nat64 = Nat64.fromNat(Int.abs(Time.now()));
      creator : Principal = switch(initiationObject._creator) {
        case null { caller };
        case (?customCreator) { customCreator };
      };
      owner : Principal = switch(initiationObject._owner) {
        case null { caller };
        case (?customOwner) { customOwner };
      };
      settings : EntitySettings.EntitySettings = switch(initiationObject._settings) {
        case null { EntitySettings.EntitySettings() };
        case (?customSettings) { customSettings };
      };
      entityType : EntityType.EntityType = #BridgeEntity;
      name : ?Text = initiationObject._name;
      description : ?Text = initiationObject._description;
      keywords : ?[Text] = initiationObject._keywords;
      externalId : ?Text = initiationObject._externalId;
      entitySpecificFields : ?Text = initiationObject._entitySpecificFields; // TODO: fill as stringified object with fields as listed in listOfEntitySpecificFieldKeys
      listOfEntitySpecificFieldKeys : [Text] = ["bridgeType", "fromEntityId", "toEntityId", "state"];
      bridgeType : BridgeType.BridgeType = initiationObject._bridgeType;
      fromEntityId : Text = initiationObject._fromEntityId;
      toEntityId : Text = initiationObject._toEntityId;
      state : BridgeState.BridgeState = switch(initiationObject._state) {
        case null { #Confirmed };
        case (?customState) { customState }; // TODO: state has to be correctly assigned (e.g. Confirmed if created by Entity owner)
      };
    }
  };
};
