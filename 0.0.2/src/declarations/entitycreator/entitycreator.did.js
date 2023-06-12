export const idlFactory = ({ IDL }) => {
  const EntityType = IDL.Variant({
    'Webasset' : IDL.Null,
    'BridgeEntity' : IDL.Null,
    'Person' : IDL.Null,
    'Location' : IDL.Null,
  });
  const EntitySettings = IDL.Record({});
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
    'create_entity' : IDL.Func([EntityInitiationObject], [Entity], []),
  });
};
export const init = ({ IDL }) => { return []; };
