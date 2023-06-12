import Debug "mo:base/Debug";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";

import EntityType "entity_type";
import EntitySettings "entity_settings";
import Entity "entity";
import BridgeEntity "bridge_entity";

import EntityTypeCreator "entity_type_creator";

actor EntityCreator {
  stable var stableEntityTypeCreators : [(Text, EntityTypeCreator.EntityTypeCreator)] = [];
  var entityTypeCreators = HashMap.HashMap<Text, EntityTypeCreator.EntityTypeCreator>(0, Text.equal, Text.hash);
  
  public shared ({ caller }) func create_entity(entityToCreate : Entity.EntityInitiationObject) : async (Entity.Entity) {
    let entityTypeCreator : EntityTypeCreator.EntityTypeCreator = switch(entityTypeCreators.get(debug_show(entityToCreate._entityType))) {
      case null {
        let newEntityTypeCreator : EntityTypeCreator.EntityTypeCreator = await EntityTypeCreator.EntityTypeCreator(entityToCreate._entityType);
        ignore await newEntityTypeCreator.init();
        entityTypeCreators.put(debug_show(entityToCreate._entityType), newEntityTypeCreator);
        newEntityTypeCreator          
      };
      case (?entityTypeCreator) { entityTypeCreator };
    };
    let result = await entityTypeCreator.create_entity(entityToCreate);
    return result;
  };

  // #region Upgrade Hooks
  system func preupgrade() {
    stableEntityTypeCreators := Iter.toArray(entityTypeCreators.entries());
  };

  system func postupgrade() {
    entityTypeCreators := HashMap.fromIter(Iter.fromArray(stableEntityTypeCreators), stableEntityTypeCreators.size(), Text.equal, Text.hash);
    stableEntityTypeCreators := [];
  };
  // #endregion
};
