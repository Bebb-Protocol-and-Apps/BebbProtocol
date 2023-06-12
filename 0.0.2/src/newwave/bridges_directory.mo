import Time "mo:base/Time";
import Int "mo:base/Int";
import Nat64 "mo:base/Nat64";
import Debug "mo:base/Debug";

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
import Text "mo:base/Text";
import Char "mo:base/Char";
import Random "mo:base/Random";
import Blob "mo:base/Blob";
import List "mo:base/List";

//import EntityType "entity_type";
import EntitySettings "entity_settings";
import Entity "entity";
import BridgeEntity "bridge_entity";

import BridgesFromEntityDirectory "canister:bridgesfromentitydirectory";
import BridgesToEntityDirectory "canister:bridgestoentitydirectory";
import BridgesPendingDirectory "canister:bridgespendingdirectory";

actor BridgesDirectory {
  public shared ({ caller }) func putEntityEntry(bridge : BridgeEntity.BridgeEntity) : async Text {
    if (bridge.state == #Pending) { // if bridge state is Pending, store accordingly
      let bridgePendingStored : Text = await BridgesPendingDirectory.putEntityEntry(bridge.internalId, bridge.fromEntityId, bridge.toEntityId);
    } else {
      // store bridge for entities bridged to and from
      let bridgedFromStored : Text = await BridgesFromEntityDirectory.putEntityEntry(bridge.fromEntityId, bridge.internalId);
      let bridgedToStored : Text = await BridgesToEntityDirectory.putEntityEntry(bridge.toEntityId, bridge.internalId);
    };
    return bridge.internalId;
  };

  public func getEntityEntries(entityId : Text, includeBridgesFromEntity : Bool, includeBridgesToEntity : Bool, includeBridgesPendingForEntity : Bool) : async [Text] {
    var bridgeIdsToReturn = List.nil<Text>();
    if (includeBridgesFromEntity) {
      bridgeIdsToReturn := List.append<Text>(bridgeIdsToReturn, await BridgesFromEntityDirectory.getEntityEntries(entityId));
    };
    if (includeBridgesToEntity) {
      bridgeIdsToReturn := List.append<Text>(bridgeIdsToReturn, await BridgesToEntityDirectory.getEntityEntries(entityId));
    };
    if (includeBridgesPendingForEntity) {
      bridgeIdsToReturn := List.append<Text>(bridgeIdsToReturn, await BridgesPendingDirectory.getEntityEntries(entityId));
    };
    return List.toArray<Text>(bridgeIdsToReturn);
  };
};
