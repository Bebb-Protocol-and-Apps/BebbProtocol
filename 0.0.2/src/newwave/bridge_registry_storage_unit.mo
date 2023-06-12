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
import BridgeEntity "bridge_entity";

import BridgesDirectory "canister:bridgesdirectory";

// example from: https://github.com/dfinity/examples/blob/master/motoko/classes/src/map/Buckets.mo
actor class BridgeRegistryStorageUnit(index : Text) {

  type Key = Text;
  type Value = BridgeEntity.BridgeEntity;

  stable var mapStable : [(Key, Value)] = [];
  var map : HashMap.HashMap<Key, Value> = HashMap.HashMap(0, Text.equal, Text.hash);

  func get(k : Key) : ?Value {
    assert(Text.startsWith(k, #text index));
    map.get(k);
  };

  public func put(k : Key, v : Value) : async Key {
    assert(Text.startsWith(k, #text index));
    map.put(k, v);
    return k;
  };

  public func getEntity(entityId : Text) : async ?BridgeEntity.BridgeEntity {
    let result = get(entityId);
    return result;
  };

  public func putEntity(entity : BridgeEntity.BridgeEntity) : async BridgeEntity.BridgeEntity {
    let result = await put(entity.internalId, entity);
    // add bridge to Bridges Directories
    let bridgeAddedToDirectory = await BridgesDirectory.putEntityEntry(entity);
    assert(Text.equal(entity.internalId, bridgeAddedToDirectory));
    return entity;
  };

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
