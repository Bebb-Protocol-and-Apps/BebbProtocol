//TODO: make flexible and extendable
//TODO: refactor to use multiple canisters
//TODO: make updatable

use ic_cdk::export::{candid::{CandidType, Deserialize}};
use ic_cdk::storage;
use ic_cdk_macros::*;
use std::collections::BTreeMap;
use sha2::{Sha256, Digest};

//TODO: consider different data storage options, especially graph database
type EntityIdDirectory = BTreeMap<String, String>;
type Entities = BTreeMap<String, Entity>;
type Bridges = BTreeMap<String, Bridge>;
//type Connections = Vec<(String, String)>;
static mut bridgeIdCounter: i32 = 0;

//TODO: consider GraphQL
#[derive(Clone, Debug, Default, CandidType, Deserialize)]
pub struct Entity {
    pub internalId: String,
    pub externalId: String,
    pub entityType: String,
    pub name: String,
    pub description: String,
    pub keywords: Vec<String>,
    pub attachedBridgeIds: Vec<String>,
}

#[derive(Clone, Debug, Default, CandidType, Deserialize)]
pub struct Bridge {
    pub internalId: String,
    pub fromEntityId: String,
    pub toEntityId: String,
}

#[update(name = "createEntity")]
fn create_entity(mut entity: Entity) -> String {
    //TODO: check creation rules, permissions and settings
    //TODO: invoke creation market protocol
    let entity_id_directory = storage::get_mut::<EntityIdDirectory>();
    assert_eq!(entity_id_directory.contains_key(&entity.externalId), false);
    // use externalId's hash as internalId
    let mut hasher = Sha256::new();
    hasher.update(entity.externalId.clone());
    entity.internalId = format!("{:X}", hasher.finalize());
    let payload = entity.internalId.clone();
    entity_id_directory.insert(entity.externalId.clone(), entity.internalId.clone());
    let entities = storage::get_mut::<Entities>();
    entities.insert(entity.internalId.clone(), entity);
    return payload;
}

#[update(name = "createEntityAndBridge")]
fn create_entity_and_bridge(existing_entity_id: String, mut new_entity: Entity) -> String {
    let new_entity_id = create_entity(new_entity);
    let bridge = Bridge {
        internalId: "".to_string(),
        fromEntityId: new_entity_id,
        toEntityId: existing_entity_id,        
    };
    return create_bridge(bridge);
}

#[update(name = "createBridge")]
fn create_bridge(mut bridge: Bridge) -> String {
    //TODO: check creation rules, permissions and settings
    //TODO: invoke creation market protocol
    // create bridge
    let mut hasher = Sha256::new();
    unsafe {
        hasher.update(bridgeIdCounter.to_string());
        bridgeIdCounter = bridgeIdCounter + 1;
    }
    bridge.internalId = format!("{:X}", hasher.finalize());
    let payload = bridge.internalId.clone();
    let bridges = storage::get_mut::<Bridges>();
    // connect entities
    let mut entities = storage::get_mut::<Entities>();
    let mut from_entity = entities
        .get(&bridge.fromEntityId)
        .cloned()
        .unwrap_or_else(|| Entity::default());
    let mut to_entity = entities
        .get(&bridge.toEntityId)
        .cloned()
        .unwrap_or_else(|| Entity::default());
    from_entity.attachedBridgeIds.push(bridge.internalId.clone());
    to_entity.attachedBridgeIds.push(bridge.internalId.clone());
    entities.insert(from_entity.internalId.clone(), from_entity);
    entities.insert(to_entity.internalId.clone(), to_entity);
    // return bridge id
    bridges.insert(bridge.internalId.clone(), bridge);
    return payload;
}

#[query(name = "getEntityById")]
fn get_entity_by_id(entity_id: String) -> Entity {
    //TODO: check retrieval rules, permissions and settings
    //TODO: invoke retrieval market protocol
    let entities = storage::get::<Entities>();

    entities
        .get(&entity_id)
        .cloned()
        .unwrap_or_else(|| Entity::default())
}

#[query(name = "getBridgeById")]
fn get_bridge_by_id(bridge_id: String) -> Bridge {
    //TODO: check retrieval rules, permissions and settings
    //TODO: invoke retrieval market protocol
    let bridges = storage::get::<Bridges>();

    bridges
        .get(&bridge_id)
        .cloned()
        .unwrap_or_else(|| Bridge::default())
}

#[query(name = "getEntityByExternalId")]
fn get_entity_by_external_id(external_id: String) -> Entity {
    //TODO: check retrieval rules, permissions and settings
    //TODO: invoke retrieval market protocol
    let entity_id_directory = storage::get::<EntityIdDirectory>();
    let entities = storage::get::<Entities>();

    entity_id_directory
        .get(&external_id)
        .and_then(|id| entities.get(id).cloned())
        .unwrap_or_else(|| Entity::default())
}

#[query(name = "getBridgedEntitiesForEntityId")]
fn get_bridged_entities_for_entity_id(entity_id: String) -> Vec<Entity> {
    //TODO: check retrieval rules, permissions and settings
    //TODO: invoke retrieval market protocol
    let entities = storage::get::<Entities>();
    let bridges = storage::get::<Bridges>();

    let entity = entities
        .get(&entity_id)
        .cloned()
        .unwrap_or_else(|| Entity::default());

    let mut bridged_entities = Vec::new();
    //TODO: order entities
    for attached_bridge_id in &entity.attachedBridgeIds {
        let attached_bridge = bridges
            .get(attached_bridge_id)
            .cloned()
            .unwrap_or_else(|| Bridge::default());
        if entity_id == attached_bridge.toEntityId {
            bridged_entities.push(
                entities
                    .get(&attached_bridge.fromEntityId)
                    .cloned()
                    .unwrap_or_else(|| Entity::default())
            );
        } else {
            bridged_entities.push(
                entities
                    .get(&attached_bridge.toEntityId)
                    .cloned()
                    .unwrap_or_else(|| Entity::default())
            );
        }
    }
    return bridged_entities;
}

#[query(name = "searchEntity")]
fn search_entity(text: String) -> Option<&'static Entity> {
    let text = text.to_lowercase();
    let entities = storage::get::<Entities>();

    for (_, entity) in entities.iter() {
        if entity.name.to_lowercase().contains(&text) || entity.description.to_lowercase().contains(&text) {
            return Some(entity);
        }

        for x in entity.keywords.iter() {
            if x.to_lowercase().contains(&text) {
                return Some(entity);
            }
        }
    }

    None
}