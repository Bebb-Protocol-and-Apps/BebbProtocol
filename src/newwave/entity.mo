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

import Utils "Utils";
import Text "mo:base/Text";
import Types "Types";

module {
  public type EntityIdErrors = {
    #Unauthorized : Text;
    #Error;
  };

  public type EntityIdResult = Types.Result<?Text, EntityIdErrors>;

  public type EntityErrors = {
    #Unauthorized : Text;
    #EntityNotFound;
    #Error;
  };

  public type EntityResult = Types.Result<?Entity, EntityErrors>;

  public class EntitySettings() {
    var mainSetting : Text = "default";
  };

  public type EntityType = {
    #BridgeEntity;
    #Webasset;
    #Person;
    #Location;
  };

  public type Entity = {
    id: Text;
    creationTimestamp : Nat64;
    creator : Principal;
    owner : Principal;
    settings : EntitySettings;
    entityType : EntityType;
    name : ?Text;
    description : ?Text;
    keywords : ?[Text];
    entitySpecificFields : ?Text;
    listOfEntitySpecificFieldKeys : [Text];
  };


  public type EntityInitiationObject = {
    settings : ?EntitySettings;
    entityType : EntityType;
    name : ?Text;
    description : ?Text;
    keywords : ?[Text];
    entitySpecificFields : ?Text;
  };

  public func generateEntityFromInitializationObject(
    initiationObject : EntityInitiationObject,
    caller : Principal,
  ) : async Entity {
    return {
      id : Text = "";
      creationTimestamp : Nat64 = Nat64.fromNat(Int.abs(Time.now()));
      creator : Principal = caller;
      owner : Principal = caller;
      settings : EntitySettings = switch(initiationObject.settings) {
        case null { EntitySettings() };
        case (?customSettings) { customSettings };
      };
      entityType : EntityType = initiationObject.entityType;
      name : ?Text = initiationObject.name;
      description : ?Text = initiationObject.description;
      keywords : ?[Text] = initiationObject.keywords;
      entitySpecificFields : ?Text = initiationObject.entitySpecificFields;
      listOfEntitySpecificFieldKeys : [Text] = [];
    }
  };

  public type EntityUpdateObject = {
    id : Text;
    settings : ?EntitySettings;
    name : ?Text;
    description : ?Text;
    keywords : ?[Text];
  };
};
