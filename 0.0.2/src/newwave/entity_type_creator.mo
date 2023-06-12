import Debug "mo:base/Debug";
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
import Bool "mo:base/Bool";

import Random "mo:base/Random";
import Blob "mo:base/Blob";

import EntityType "entity_type";
import EntitySettings "entity_settings";
import Entity "entity";

//import EntityStorage "entity_storage";

import EntityTypeStorage "entity_type_storage";

// example from: https://github.com/dfinity/examples/blob/master/motoko/classes/src/map/Buckets.mo
actor class EntityTypeCreator(entityType : EntityType.EntityType) {

  type Key = Text;
  type Value = Entity.Entity; // potentially needs to be flexible based on entityType (creates entities of that type)
  var initialized = false;
  // initialize empty HashMap of size 1 and fill in init()
  stable var stableEntityStorage : [(Nat, EntityTypeStorage.EntityTypeStorage)] = [];
  var entityStorage = HashMap.HashMap<Nat, EntityTypeStorage.EntityTypeStorage>(1, Nat.equal, Hash.hash);

 // must be called while being setting up and before create_entity
  public shared ({ caller }) func init() : async (Bool) {
    assert(Bool.equal(initialized, false)); // can only be initialized once
    entityStorage.put(0, await EntityTypeStorage.EntityTypeStorage(entityType)); // initialize entity_type_storage with entityType
    initialized := true;
    return initialized;
  };

  public shared ({ caller }) func create_entity(entityToCreate : Entity.EntityInitiationObject) : async (Entity.Entity) {
    // TODO: potentially update entityToCreate fields (might vary depending on EntityType)
    // TODO: potentially assign final internal_id to Entity (might vary depending on EntityType)
    let entity : Entity.Entity = Entity.Entity(entityToCreate, caller);
    // stores via entity_type_storage (abstraction over multiple entity_storage_units)
    let result = await Option.unwrap(entityStorage.get(0)).putEntity(entity.internalId, entity);
    assert(Text.equal(result, entity.internalId));
    return entity;
  };

  // #region Upgrade Hooks
  system func preupgrade() {
    stableEntityStorage := Iter.toArray(entityStorage.entries());
  };

  system func postupgrade() {
    entityStorage := HashMap.fromIter(Iter.fromArray(stableEntityStorage), stableEntityStorage.size(), Nat.equal, Hash.hash);
    stableEntityStorage := [];
  };
  // #endregion
};
