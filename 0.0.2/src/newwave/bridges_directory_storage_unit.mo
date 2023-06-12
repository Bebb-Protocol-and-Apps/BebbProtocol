import HashMap "mo:base/HashMap";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
//import Map "mo:base/RBTree";
import Text "mo:base/Text";
import List "mo:base/List";

import Entity "entity";
import BridgeEntity "bridge_entity";

// example from: https://github.com/dfinity/examples/blob/master/motoko/classes/src/map/Buckets.mo
actor class BridgesDirectoryStorageUnit(index : Text) {

  type Key = Text;
  type Value = { // TODO: define bridge categories, probably import from a dedicated file
    ownerCreatedBridges : List.List<Text>;
    otherBridges : List.List<Text>;
  };

  stable var mapStable : [(Key, Value)] = [];
  var map : HashMap.HashMap<Key, Value> = HashMap.HashMap(0, Text.equal, Text.hash);

  func get(k : Key) : ?Value {
    assert(Text.startsWith(k, #text index));
    map.get(k);
  };

  public func put(k : Key, bridgeId : Text) : async Key {
    assert(Text.startsWith(k, #text index));
    switch(get(k)) {
      case null {
        // first entry for entityId
        var otherBridgesList = List.nil<Text>();
        otherBridgesList := List.push<Text>(bridgeId, otherBridgesList);
        let newEntityEntry : Value = {
          ownerCreatedBridges = List.nil<Text>();
          otherBridges = otherBridgesList;
        };
        map.put(k, newEntityEntry);
        return bridgeId;        
      };
      case (?entityEntry) {
        // add to existing entry for entityId
        let updatedEntityEntry : Value = {
          ownerCreatedBridges = entityEntry.ownerCreatedBridges;
          otherBridges = List.push<Text>(bridgeId, entityEntry.otherBridges);
        };
        map.put(k, updatedEntityEntry);
        return bridgeId;         
      };
    }
  };

  public func getEntityEntry(entityId : Text) : async ?Value {
    let result = get(entityId);
    return result;
  };

  public func putEntityEntry(bridgedEntityId : Text, bridgeId : Text) : async Text {
    let result = await put(bridgedEntityId, bridgeId);
    return result;
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
