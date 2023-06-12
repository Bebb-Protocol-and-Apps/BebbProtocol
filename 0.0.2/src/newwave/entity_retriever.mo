import Debug "mo:base/Debug";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import HashMap "mo:base/HashMap";
import Buffer "mo:base/Buffer";

import EntityType "entity_type";
import EntitySettings "entity_settings";
import Entity "entity";
import BridgeEntity "bridge_entity";
import EntityStorageUnit "entity_storage_unit";

import EntityDirectory "canister:entitydirectory";

//import EntityTypeRetriever "entity_type_retriever"; //potentially implement if type-specific retrieval becomes necessary

actor EntityRetriever {
  public shared ({ caller }) func get_entity(entityId : Text) : async ?Entity.Entity {
    let entityStorageUnitAddress : ?Principal = await EntityDirectory.getEntityEntry(entityId);
    switch(entityStorageUnitAddress) {
      case null { return null; };
      case (?storageAddress) { 
        let entityStorageUnit : EntityStorageUnit.EntityStorageUnit = actor(Principal.toText(storageAddress));
        let entityToReturn : ?Entity.Entity = await entityStorageUnit.getEntity(entityId);
        return entityToReturn;
      };
    };
  };

  public shared ({ caller }) func get_entities(entityIds : [Text]) : async [Entity.Entity] {
    if (entityIds.size() == 0) {
      return [];
    };
    let executingFunctionsBuffer = Buffer.Buffer<async ?Entity.Entity>(entityIds.size());
    for (entityId in entityIds.vals()) { 
      executingFunctionsBuffer.add(get_entity(entityId)); 
    };
    let collectingResultsBuffer = Buffer.Buffer<Entity.Entity>(entityIds.size());
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


  //let entityTypeRetrievers = HashMap.HashMap<Text, EntityTypeRetriever.EntityTypeRetriever>(0, Text.equal, Text.hash); //potentially implement if type-specific retrieval becomes necessary
  /* public ({ caller }) func get_entity_with_type(entityId : Text, entityType : EntityType.EntityType) : async (Entity.Entity) {
    Debug.print("hello EntityRetriever get_entity_with_type");
    //Debug.print(entityId);
    let entityTypeRetriever : EntityTypeRetriever.EntityTypeRetriever = switch(entityTypeRetrievers.get(debug_show(entityType))) {
      case null {
        let newEntityTypeRetriever : EntityTypeRetriever.EntityTypeRetriever = await EntityTypeRetriever.EntityTypeRetriever(entityType);
        ignore await newEntityTypeRetriever.init();
        entityTypeRetrievers.put(debug_show(entityType), newEntityTypeRetriever);
        newEntityTypeRetriever          
      };
      case (?entityTypeRetriever) { entityTypeRetriever };
    };
    Debug.print("EntityRetriever after entityTypeRetriever");
    let result = await entityTypeRetriever.get_entity(entityId);
    Debug.print("EntityRetriever after result");
    return result;
  }; */ //potentially implement if type-specific retrieval becomes necessary
};
