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

module {
  public type EntityStorage = {
    creationTimestamp : Nat64;
    creator : Principal;
    owner : Principal;
    storedEntityType : EntityType.EntityType;
    description : ?Text;
    keywords : ?[Text];
    // potentially: settings : EntitySettings.EntitySettings; externalId : ?Text;
    getAddress : () -> Principal; // returns own (Canister) address
    getEntity : (entityId : Text) -> ?Entity.Entity; // retrieves the requested Entity (if present)
    putEntity : (entity : Entity.Entity) -> Text; // creates new Entity and returns its id
    // potentially: getMultiple, putMultiple
    // potentially: getEntityOfStoredType, putEntityOfStoredType
  };
};
