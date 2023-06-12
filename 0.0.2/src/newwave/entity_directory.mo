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

//import EntityType "entity_type";
import EntitySettings "entity_settings";
import Entity "entity";

import EntityDirectoryStorageUnit "entity_directory_storage_unit";

// example from: https://github.com/dfinity/examples/blob/master/motoko/classes/src/map/Buckets.mo
actor EntityDirectory {
  stable var stableEntityDirectoryStorageUnits : [(Text, EntityDirectoryStorageUnit.EntityDirectoryStorageUnit)] = [];
  var entityDirectoryStorageUnits = HashMap.HashMap<Text, EntityDirectoryStorageUnit.EntityDirectoryStorageUnit>(0, Text.equal, Text.hash);
  let entityIdSubstringForStorageUnitIndexStart = 0;
  let entityIdSubstringForStorageUnitIndexEnd = 2;

  public shared ({ caller }) func putEntityEntry(entityId : Text, entityStorageUnitAddress : Principal) : async Text {
    // get correct storageUnitIndex as initial characters from entityId
    let storageUnitIndex : Text = extract(entityId, entityIdSubstringForStorageUnitIndexStart, entityIdSubstringForStorageUnitIndexEnd);
    // stores in correct entity_directory_storage_unit (according to id)
    let entityDirectoryStorageUnit : EntityDirectoryStorageUnit.EntityDirectoryStorageUnit = switch(entityDirectoryStorageUnits.get(storageUnitIndex)) {
      case null {
        let newEntityDirectoryStorageUnit : EntityDirectoryStorageUnit.EntityDirectoryStorageUnit = await EntityDirectoryStorageUnit.EntityDirectoryStorageUnit(storageUnitIndex);
        entityDirectoryStorageUnits.put(storageUnitIndex, newEntityDirectoryStorageUnit);
        newEntityDirectoryStorageUnit          
      };
      case (?entityDirectoryStorageUnits) { entityDirectoryStorageUnits };
    };
    let result = await entityDirectoryStorageUnit.putEntityEntry(entityId, entityStorageUnitAddress);
    return result;
  };

  public func getEntityEntry(entityId : Text) : async ?Principal {
    let storageUnitIndex : Text = extract(entityId, entityIdSubstringForStorageUnitIndexStart, entityIdSubstringForStorageUnitIndexEnd);
    switch(entityDirectoryStorageUnits.get(storageUnitIndex)) {
      case null { null };
      case (?entityDirectoryStorageUnits) {        
        let result = await entityDirectoryStorageUnits.getEntityEntry(entityId);
        return result;
      };
    };
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
    stableEntityDirectoryStorageUnits := Iter.toArray(entityDirectoryStorageUnits.entries());
  };

  system func postupgrade() {
    entityDirectoryStorageUnits := HashMap.fromIter(Iter.fromArray(stableEntityDirectoryStorageUnits), stableEntityDirectoryStorageUnits.size(), Text.equal, Text.hash);
    stableEntityDirectoryStorageUnits := [];
  };
  // #endregion
};
