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

import EntityType "entity_type";
import EntitySettings "entity_settings";
import Entity "entity";
//import EntityStorage "entity_storage";
import EntityStorageUnit "entity_storage_unit";

// example from: https://github.com/dfinity/examples/blob/master/motoko/classes/src/map/Buckets.mo
//actor class EntityTypeStorage(entityType : EntityType.EntityType) = EntityStorage and { //subtyping for actor classes does not seem possible currently
actor class EntityTypeStorage(entityType : EntityType.EntityType) {

  type Key = Text;
  type Value = Entity.Entity; // potentially needs to be flexible based on entityType (creates entities of that type)

  stable var stableEntityStorageUnits : [(Text, EntityStorageUnit.EntityStorageUnit)] = [];
  var entityStorageUnits = HashMap.HashMap<Text, EntityStorageUnit.EntityStorageUnit>(0, Text.equal, Text.hash);

  public shared ({ caller }) func putEntity(k : Key, v : Entity.Entity) : async Text {
    // get correct storageUnitIndex as initial characters from entityId
    let storageUnitIndex : Text = extract(k, 0, 2);
    // stores in correct entity_storage_unit (according to id)
    let entityStorageUnit : EntityStorageUnit.EntityStorageUnit = switch(entityStorageUnits.get(storageUnitIndex)) {
      case null {
        let newEntityStorageUnit : EntityStorageUnit.EntityStorageUnit = await EntityStorageUnit.EntityStorageUnit(storageUnitIndex);
        entityStorageUnits.put(storageUnitIndex, newEntityStorageUnit);
        newEntityStorageUnit          
      };
      case (?entityStorageUnit) { entityStorageUnit };
    };
    let result = await entityStorageUnit.putEntity(k, v);
    return result;
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
    stableEntityStorageUnits := Iter.toArray(entityStorageUnits.entries());
  };

  system func postupgrade() {
    entityStorageUnits := HashMap.fromIter(Iter.fromArray(stableEntityStorageUnits), stableEntityStorageUnits.size(), Text.equal, Text.hash);
    stableEntityStorageUnits := [];
  };
  // #endregion
};
