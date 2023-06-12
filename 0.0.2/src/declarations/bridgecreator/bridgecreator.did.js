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
  return IDL.Service({
    'create_bridge' : IDL.Func(
        [BridgeEntityInitiationObject],
        [BridgeEntity],
        [],
      ),
  });
};
export const init = ({ IDL }) => { return []; };
