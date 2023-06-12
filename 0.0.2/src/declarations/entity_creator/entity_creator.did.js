export const idlFactory = ({ IDL }) => {
  const EntitySettings = IDL.Record({});
  const EntityType = IDL.Variant({
    'Webasset' : IDL.Null,
    'BridgeEntity' : IDL.Null,
    'Person' : IDL.Null,
    'Location' : IDL.Null,
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
  return IDL.Service({ 'create_entity' : IDL.Func([], [Entity], []) });
};
export const init = ({ IDL }) => { return []; };
