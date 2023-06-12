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
import Map "mo:base/RBTree";
import Text "mo:base/Text";

import Random "mo:base/Random";
import Blob "mo:base/Blob";

import EntityType "entity_type";
import EntitySettings "entity_settings";
import Entity "entity";

import EntityDirectory "canister:entitydirectory";

//import EntityStorage "entity_storage";

// example from: https://github.com/dfinity/examples/blob/master/motoko/classes/src/map/Buckets.mo
//actor class EntityStorageUnit(index : Text) EntityStorage.EntityStorage and { //subtyping for actor classes does not seem possible currently
actor class EntityStorageUnit(index : Text) = Self {

  type Key = Text;
  type Value = Entity.Entity; // potentially needs to be flexible based on storedEntityType (store entities of that type)

  stable var mapStable : [(Key, Value)] = [];
  //var map = Map.RBTree<Key, Value>(Text.compare);
  var map : HashMap.HashMap<Key, Value> = HashMap.HashMap(0, Text.equal, Text.hash);

  func get(k : Key) : ?Value {
    assert(Text.startsWith(k, #text index));
    map.get(k);
  };

  public func put(k : Key, v : Value) : async Key {
    assert(Text.startsWith(k, #text index));
    map.put(k,v);
    return k;
  };

  public func getEntity(entityId : Text) : async ?Entity.Entity {
    let result = get(entityId);
    return result;
  };

  public func putEntity(entityId : Text, entity : Entity.Entity) : async Text {
    // if Value is changed to Entities of storedEntityType, this function needs to transform Entity to Entity type before put
    let result = await put(entityId, entity);
    // add to EntityDirectory
    let entityAddedToDirectory = await EntityDirectory.putEntityEntry(entityId, Principal.fromActor(Self)); // pass own Principal as address
    assert(Text.equal(entityId, entityAddedToDirectory));
    return result;
  };

  /* potentially add storedEntityType specific functions (if used accordingly)
  public func getEntityOfStoredType(k : Key) : async ?Value {
    return get(k);
  };

  public func putEntityOfStoredType(k : Key, v : Value) : async Key {
    // if Value is changed to Entities of storedEntityType, this function should just be able to use put
    return put(k, v);
  }; */

  // #region Upgrade Hooks
  system func preupgrade() {
    mapStable := Iter.toArray(map.entries());
  };

  system func postupgrade() {
    map := HashMap.fromIter(Iter.fromArray(mapStable), mapStable.size(), Text.equal, Text.hash);
    mapStable := [];
  };
  // #endregion
};
