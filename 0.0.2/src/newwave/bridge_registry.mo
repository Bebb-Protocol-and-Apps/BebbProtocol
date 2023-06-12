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
import Buffer "mo:base/Buffer";

//import EntityType "entity_type";
import EntitySettings "entity_settings";
import Entity "entity";
import BridgeEntity "bridge_entity";

import BridgeRegistryStorageUnit "bridge_registry_storage_unit";

// example from: https://github.com/dfinity/examples/blob/master/motoko/classes/src/map/Buckets.mo
actor BridgeRegistry {
  stable var stableBridgeRegistryStorageUnits : [(Text, BridgeRegistryStorageUnit.BridgeRegistryStorageUnit)] = [];
  var bridgeRegistryStorageUnits = HashMap.HashMap<Text, BridgeRegistryStorageUnit.BridgeRegistryStorageUnit>(0, Text.equal, Text.hash);
  let entityIdSubstringForStorageUnitIndexStart = 0;
  let entityIdSubstringForStorageUnitIndexEnd = 2;

  public shared ({ caller }) func putEntity(bridge : BridgeEntity.BridgeEntity) : async BridgeEntity.BridgeEntity {
    // get correct storageUnitIndex as initial characters from entityId
    let storageUnitIndex : Text = extract(bridge.internalId, entityIdSubstringForStorageUnitIndexStart, entityIdSubstringForStorageUnitIndexEnd);
    // stores in correct bridge_registry_storage_unit (according to id)
    let bridgeRegistryStorageUnit : BridgeRegistryStorageUnit.BridgeRegistryStorageUnit = switch(bridgeRegistryStorageUnits.get(storageUnitIndex)) {
      case null {
        let newBridgeRegistryStorageUnit : BridgeRegistryStorageUnit.BridgeRegistryStorageUnit = await BridgeRegistryStorageUnit.BridgeRegistryStorageUnit(storageUnitIndex);
        bridgeRegistryStorageUnits.put(storageUnitIndex, newBridgeRegistryStorageUnit);
        newBridgeRegistryStorageUnit          
      };
      case (?bridgeRegistryStorageUnit) { bridgeRegistryStorageUnit };
    };
    let result = await bridgeRegistryStorageUnit.putEntity(bridge);
    return result;
  };

  public func getEntity(entityId : Text) : async ?BridgeEntity.BridgeEntity {
    let storageUnitIndex : Text = extract(entityId, entityIdSubstringForStorageUnitIndexStart, entityIdSubstringForStorageUnitIndexEnd);
    switch(bridgeRegistryStorageUnits.get(storageUnitIndex)) {
      case null { null };
      case (?bridgeRegistryStorageUnit) {        
        let result = await bridgeRegistryStorageUnit.getEntity(entityId);
        return result;
      };
    };
  };

  public func getEntities(entityIds : [Text]) : async [BridgeEntity.BridgeEntity] {
    // adapted from https://forum.dfinity.org/t/motoko-sharable-generics/9021/3
    let executingFunctionsBuffer = Buffer.Buffer<async ?BridgeEntity.BridgeEntity>(entityIds.size());
    for (entityId in entityIds.vals()) { 
      executingFunctionsBuffer.add(getEntity(entityId)); 
    };
    let collectingResultsBuffer = Buffer.Buffer<BridgeEntity.BridgeEntity>(entityIds.size());
    var i = 0;
    for (entityId in entityIds.vals()) {
      switch(await executingFunctionsBuffer.get(i)) {
        case null {};
        case (?entity) { collectingResultsBuffer.add(entity); };
      };      
      i += 1;
    };
    return collectingResultsBuffer.toArray();
  };

// helper function to extract Substring from String (copied from Text base library)
  private func extract(t : Text, i : Nat, j : Nat) : Text {
    let size = t.size();
    if (i == 0 and j == size) return t;
    assert (j <= size);
    let cs = t.chars();
    var r = "";
    var n = i;
    while (n > 0) {
      ignore cs.next();
      n -= 1;
    };
    n := j;
    while (n > 0) {
      switch (cs.next()) {
        case null { assert false };
        case (?c) { r #= Char.toText(c) }
      };
      n -= 1;
    };
    return r;
  };

  // #region Upgrade Hooks
  system func preupgrade() {
    stableBridgeRegistryStorageUnits := Iter.toArray(bridgeRegistryStorageUnits.entries());
  };

  system func postupgrade() {
    bridgeRegistryStorageUnits := HashMap.fromIter(Iter.fromArray(stableBridgeRegistryStorageUnits), stableBridgeRegistryStorageUnits.size(), Text.equal, Text.hash);
    stableBridgeRegistryStorageUnits := [];
  };
  // #endregion
};
