import { newwave } from "../../declarations/newwave";

document.querySelector("form").addEventListener("submit", async (e) => {
  e.preventDefault();
  const button = e.target.querySelector("button");
  console.log('############# Starting Protocol simulation... #############');

  button.setAttribute("disabled", true);

  let entityToCreate = {
    //_internalId: ["_internalId"], // [] also means optional, i.e. Motoko: ? --> JS: []
    _internalId: [],
    _creator: [],
    _owner: [],
    _settings: [],
    _entityType: { Webasset: null },
    _name: ["_name"],
    _description: ["_description"],
    _keywords: [["_keywords"]],
    _externalId: ["_externalId"],
    _entitySpecificFields: [],
  };
  const entity = await newwave.create_entity(entityToCreate);
  console.log('entity');
  console.log(entity);
  const entityId = entity.internalId;
  console.log('entityId');
  console.log(entityId);
  const retrievedEntity = await newwave.get_entity(entityId);
  console.log('retrievedEntity');
  console.log(retrievedEntity);
  let entityToCreate2 = {
    //_internalId: ["_internalId2"], // [] also means optional, i.e. Motoko: ? --> JS: []
    _internalId: [],
    _creator: [],
    _owner: [],
    _settings: [],
    _entityType: { Webasset: null },
    _name: ["_name"],
    _description: ["_description"],
    _keywords: [["_keywords"]],
    _externalId: ["_externalId"],
    _entitySpecificFields: [],
  };
  const entity2 = await newwave.create_entity(entityToCreate2);
  console.log('entity2');
  console.log(entity2);
  const entityId2 = entity2.internalId;
  console.log('entityId2');
  console.log(entityId2);
  let bridgeToCreate = {
    //_internalId: ["_bridgeInternalId"],
    _internalId: [],
    _creator: [], // [] also means optional, i.e. Motoko: ? --> JS: []
    _owner: [],
    _settings: [],
    _entityType: { BridgeEntity: null },
    _name: ["_name"],
    _description: ["_description"],
    _keywords: [["_keywords"]],
    _externalId: ["_externalId"],
    _entitySpecificFields: [],
    _bridgeType: { OwnerCreated: null },
    _fromEntityId: entityId,
    _toEntityId: entityId2,
    _state: [],
  };
  const bridge = await newwave.create_bridge(bridgeToCreate);
  console.log('bridge');
  console.log(bridge);
  console.log('bridge internalId');
  console.log(bridge.internalId);
  const retrievedBridge = await newwave.get_bridge(bridge.internalId);
  console.log('retrievedBridge');
  console.log(retrievedBridge);
  let bridgeToCreatePending = {
    //_internalId: ["_pendingBridgeId"],
    _internalId: [],
    _creator: [], // [] also means optional, i.e. Motoko: ? --> JS: []
    _owner: [],
    _settings: [],
    _entityType: { BridgeEntity: null },
    _name: ["_name"],
    _description: ["_description"],
    _keywords: [["_keywords"]],
    _externalId: ["_externalId"],
    _entitySpecificFields: [],
    _bridgeType: { OwnerCreated: null },
    _fromEntityId: entityId2,
    _toEntityId: entityId,
    _state: [{ Pending: null }],
  };
  const bridgePending = await newwave.create_bridge(bridgeToCreatePending);
  console.log('bridgePending');
  console.log(bridgePending);
  const bridgeIdsForEntityNone = await newwave.get_bridge_ids_by_entity_id(entityId, false, false, false);
  console.log('bridgeIdsForEntityNone');
  console.log(bridgeIdsForEntityNone);
  const bridgeIdsForEntityFrom = await newwave.get_bridge_ids_by_entity_id(entityId, true, false, false);
  console.log('bridgeIdsForEntityFrom');
  console.log(bridgeIdsForEntityFrom);
  const bridgeIdsForEntityTo = await newwave.get_bridge_ids_by_entity_id(entityId, false, true, false);
  console.log('bridgeIdsForEntityTo');
  console.log(bridgeIdsForEntityTo);
  const bridgeIdsForEntityTo2 = await newwave.get_bridge_ids_by_entity_id(entityId2, false, true, false);
  console.log('bridgeIdsForEntityTo2');
  console.log(bridgeIdsForEntityTo2);
  const bridgeIdsForEntityPending = await newwave.get_bridge_ids_by_entity_id(entityId, false, false, true);
  console.log('bridgeIdsForEntityPending');
  console.log(bridgeIdsForEntityPending);
  const bridgeIdsForEntityNoPending = await newwave.get_bridge_ids_by_entity_id(entityId, true, true, false);
  console.log('bridgeIdsForEntityNoPending');
  console.log(bridgeIdsForEntityNoPending);
  const bridgeIdsForEntityAll = await newwave.get_bridge_ids_by_entity_id(entityId, true, true, true);
  console.log('bridgeIdsForEntityAll');
  console.log(bridgeIdsForEntityAll);
  const bridgesForEntityAll = await newwave.get_bridges_by_entity_id(entityId, true, true, true);
  console.log('bridgesForEntityAll');
  console.log(bridgesForEntityAll);
  let entityToCreate3 = {
    //_internalId: ["_internalId3"], // [] also means optional, i.e. Motoko: ? --> JS: []
    _internalId: [],
    _creator: [],
    _owner: [],
    _settings: [],
    _entityType: { Person: null },
    _name: ["_name"],
    _description: ["_description"],
    _keywords: [["_keywords"]],
    _externalId: ["_externalId"],
    _entitySpecificFields: [],
  };
  let bridgeToCreate3 = {
    //_internalId: ["_pendingBridgeId3"],
    _internalId: [],
    _creator: [], // [] also means optional, i.e. Motoko: ? --> JS: []
    _owner: [],
    _settings: [],
    _entityType: { BridgeEntity: null },
    _name: ["_name"],
    _description: ["_description"],
    _keywords: [["_keywords"]],
    _externalId: ["_externalId"],
    _entitySpecificFields: [],
    _bridgeType: { OwnerCreated: null },
    _fromEntityId: entityId,
    _toEntityId: "",
    _state: [{ Pending: null }],
  };
  const createEntityAndBridgeTo = await newwave.create_entity_and_bridge(entityToCreate3, bridgeToCreate3);
  console.log('createEntityAndBridgeTo');
  console.log(createEntityAndBridgeTo);
  let entityToCreate4 = {
    //_internalId: ["_internalId4"], // [] also means optional, i.e. Motoko: ? --> JS: []
    _internalId: [],
    _creator: [],
    _owner: [],
    _settings: [],
    _entityType: { Person: null },
    _name: ["_name"],
    _description: ["_description"],
    _keywords: [["_keywords"]],
    _externalId: ["_externalId"],
    _entitySpecificFields: [],
  };
  let bridgeToCreate4 = {
    //_internalId: ["_bridgeId4"],
    _internalId: [],
    _creator: [], // [] also means optional, i.e. Motoko: ? --> JS: []
    _owner: [],
    _settings: [],
    _entityType: { BridgeEntity: null },
    _name: ["_name"],
    _description: ["_description"],
    _keywords: [["_keywords"]],
    _externalId: ["_externalId"],
    _entitySpecificFields: [],
    _bridgeType: { OwnerCreated: null },
    _fromEntityId: "",
    _toEntityId: entityId2,
    _state: [{ Confirmed: null }],
  };
  const createEntityAndBridgeFrom = await newwave.create_entity_and_bridge(entityToCreate4, bridgeToCreate4);
  console.log('createEntityAndBridgeFrom');
  console.log(createEntityAndBridgeFrom);
  const getBridgedEntitiesByEntityId = await newwave.get_bridged_entities_by_entity_id(entityId, true, true, true);
  console.log('getBridgedEntitiesByEntityId');
  console.log(getBridgedEntitiesByEntityId);
  const getEntityAndBridgeIds = await newwave.get_entity_and_bridge_ids(entityId, true, true, true);
  console.log('getEntityAndBridgeIds');
  console.log(getEntityAndBridgeIds);

  button.removeAttribute("disabled");

  return false;
});
