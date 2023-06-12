export const idlFactory = ({ IDL }) => {
  const BridgeState = IDL.Variant({
    'Confirmed' : IDL.Null,
    'Rejected' : IDL.Null,
    'Pending' : IDL.Null,
  });
  const EntityType = IDL.Variant({
    'Webasset' : IDL.Null,
    'BridgeEntity' : IDL.Null,
    'Person' : IDL.Null,
    'Location' : IDL.Null,
  });
  const BridgeType = IDL.Variant({ 'OwnerCreated' : IDL.Null });
  const EntitySettings = IDL.Record({});
  const BridgeEntityInitiationObject = IDL.Record({
    '_externalId' : IDL.Opt(IDL.Text),
    '_fromEntityId' : IDL.Text,
    '_owner' : IDL.Opt(IDL.Principal),
    '_creator' : IDL.Opt(IDL.Principal),
    '_entitySpecificFields' : IDL.Opt(IDL.Text),
    '_state' : IDL.Opt(BridgeState),
    '_entityType' : EntityType,
    '_bridgeType' : BridgeType,
    '_description' : IDL.Opt(IDL.Text),
    '_keywords' : IDL.Opt(IDL.Vec(IDL.Text)),
    '_settings' : IDL.Opt(EntitySettings),
    '_internalId' : IDL.Opt(IDL.Text),
    '_toEntityId' : IDL.Text,
    '_name' : IDL.Opt(IDL.Text),
  });
  const BridgeEntity = IDL.Record({
    'internalId' : IDL.Text,
    'toEntityId' : IDL.Text,
    'creator' : IDL.Principal,
    'fromEntityId' : IDL.Text,
    'owner' : IDL.Principal,
    'externalId' : IDL.Opt(IDL.Text),
    'creationTimestamp' : IDL.Nat64,
    'name' : IDL.Opt(IDL.Text),
    'description' : IDL.Opt(IDL.Text),
    'keywords' : IDL.Opt(IDL.Vec(IDL.Text)),
    'state' : BridgeState,
    'settings' : EntitySettings,
    'listOfEntitySpecificFieldKeys' : IDL.Vec(IDL.Text),
    'entityType' : EntityType,
    'bridgeType' : BridgeType,
    'entitySpecificFields' : IDL.Opt(IDL.Text),
  });
  const EntityInitiationObject = IDL.Record({
    '_externalId' : IDL.Opt(IDL.Text),
    '_owner' : IDL.Opt(IDL.Principal),
    '_creator' : IDL.Opt(IDL.Principal),
    '_entitySpecificFields' : IDL.Opt(IDL.Text),
    '_entityType' : EntityType,
    '_description' : IDL.Opt(IDL.Text),
    '_keywords' : IDL.Opt(IDL.Vec(IDL.Text)),
    '_settings' : IDL.Opt(EntitySettings),
    '_internalId' : IDL.Opt(IDL.Text),
    '_name' : IDL.Opt(IDL.Text),
  });
  const Entity = IDL.Record({
    'internalId' : IDL.Text,
    'creator' : IDL.Principal,
    'owner' : IDL.Principal,
    'externalId' : IDL.Opt(IDL.Text),
    'creationTimestamp' : IDL.Nat64,
    'name' : IDL.Opt(IDL.Text),
    'description' : IDL.Opt(IDL.Text),
    'keywords' : IDL.Opt(IDL.Vec(IDL.Text)),
    'settings' : EntitySettings,
    'listOfEntitySpecificFieldKeys' : IDL.Vec(IDL.Text),
    'entityType' : EntityType,
    'entitySpecificFields' : IDL.Opt(IDL.Text),
  });
  return IDL.Service({
    'create_bridge' : IDL.Func(
        [BridgeEntityInitiationObject],
        [BridgeEntity],
        [],
      ),
    'create_entity' : IDL.Func([EntityInitiationObject], [Entity], []),
    'create_entity_and_bridge' : IDL.Func(
        [EntityInitiationObject, BridgeEntityInitiationObject],
        [Entity, BridgeEntity],
        [],
      ),
    'get_bridge' : IDL.Func([IDL.Text], [IDL.Opt(BridgeEntity)], []),
    'get_bridge_ids_by_entity_id' : IDL.Func(
        [IDL.Text, IDL.Bool, IDL.Bool, IDL.Bool],
        [IDL.Vec(IDL.Text)],
        [],
      ),
    'get_bridged_entities_by_entity_id' : IDL.Func(
        [IDL.Text, IDL.Bool, IDL.Bool, IDL.Bool],
        [IDL.Vec(Entity)],
        [],
      ),
    'get_bridges_by_entity_id' : IDL.Func(
        [IDL.Text, IDL.Bool, IDL.Bool, IDL.Bool],
        [IDL.Vec(BridgeEntity)],
        [],
      ),
    'get_entity' : IDL.Func([IDL.Text], [IDL.Opt(Entity)], []),
    'get_entity_and_bridge_ids' : IDL.Func(
        [IDL.Text, IDL.Bool, IDL.Bool, IDL.Bool],
        [IDL.Opt(Entity), IDL.Vec(IDL.Text)],
        [],
      ),
  });
};
export const init = ({ IDL }) => { return []; };
