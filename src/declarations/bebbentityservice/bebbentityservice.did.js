export const idlFactory = ({ IDL }) => {
  const AutoScalingCanisterSharedFunctionHook = IDL.Func(
      [IDL.Text],
      [IDL.Text],
      [],
    );
  const ScalingLimitType = IDL.Variant({
    'heapSize' : IDL.Nat,
    'count' : IDL.Nat,
  });
  const ScalingOptions = IDL.Record({
    'autoScalingHook' : AutoScalingCanisterSharedFunctionHook,
    'sizeLimit' : ScalingLimitType,
  });
  const BridgeSettings = IDL.Record({});
  const BridgeType = IDL.Variant({
    'IsPartOf' : IDL.Null,
    'IsAttachedto' : IDL.Null,
    'IsRelatedto' : IDL.Null,
  });
  const Bridge = IDL.Record({
    'id' : IDL.Text,
    'toEntityId' : IDL.Text,
    'creator' : IDL.Principal,
    'fromEntityId' : IDL.Text,
    'owner' : IDL.Principal,
    'creationTimestamp' : IDL.Nat64,
    'name' : IDL.Text,
    'description' : IDL.Text,
    'keywords' : IDL.Vec(IDL.Text),
    'settings' : BridgeSettings,
    'listOfEntitySpecificFieldKeys' : IDL.Vec(IDL.Text),
    'bridgeType' : BridgeType,
    'entitySpecificFields' : IDL.Text,
  });
  const EntityIdErrors = IDL.Variant({
    'Error' : IDL.Null,
    'PreviewTooLarge' : IDL.Int,
    'EntityNotFound' : IDL.Null,
    'TooManyPreviews' : IDL.Null,
    'Unauthorized' : IDL.Text,
  });
  const EntityIdResult = IDL.Variant({
    'Ok' : IDL.Text,
    'Err' : EntityIdErrors,
  });
  const EntitySettings = IDL.Record({});
  const EntityTypeResourceTypes = IDL.Variant({
    'Web' : IDL.Null,
    'DigitalAsset' : IDL.Null,
    'Content' : IDL.Null,
  });
  const EntityType = IDL.Variant({
    'Other' : IDL.Text,
    'Resource' : EntityTypeResourceTypes,
  });
  const EntityInitiationObject = IDL.Record({
    'name' : IDL.Opt(IDL.Text),
    'description' : IDL.Opt(IDL.Text),
    'keywords' : IDL.Opt(IDL.Vec(IDL.Text)),
    'settings' : IDL.Opt(EntitySettings),
    'entityType' : EntityType,
    'entitySpecificFields' : IDL.Opt(IDL.Text),
  });
  const Time = IDL.Int;
  const BridgeLinkStatus = IDL.Variant({
    'CreatedOther' : IDL.Null,
    'CreatedOwner' : IDL.Null,
  });
  const EntityAttachedBridge = IDL.Record({
    'id' : IDL.Text,
    'creationTime' : Time,
    'bridgeType' : BridgeType,
    'linkStatus' : BridgeLinkStatus,
  });
  const EntityAttachedBridges = IDL.Vec(EntityAttachedBridge);
  const EntityPreviewSupportedTypes = IDL.Variant({
    'Glb' : IDL.Null,
    'Jpg' : IDL.Null,
    'Png' : IDL.Null,
    'Gltf' : IDL.Null,
    'Other' : IDL.Text,
  });
  const EntityPreview = IDL.Record({
    'previewData' : IDL.Vec(IDL.Nat8),
    'previewType' : EntityPreviewSupportedTypes,
  });
  const Entity = IDL.Record({
    'id' : IDL.Text,
    'creator' : IDL.Principal,
    'toIds' : EntityAttachedBridges,
    'previews' : IDL.Vec(EntityPreview),
    'owner' : IDL.Principal,
    'creationTimestamp' : IDL.Nat64,
    'name' : IDL.Text,
    'fromIds' : EntityAttachedBridges,
    'description' : IDL.Text,
    'keywords' : IDL.Vec(IDL.Text),
    'settings' : EntitySettings,
    'listOfEntitySpecificFieldKeys' : IDL.Vec(IDL.Text),
    'entityType' : EntityType,
    'entitySpecificFields' : IDL.Text,
  });
  const EntityErrors = IDL.Variant({
    'Error' : IDL.Null,
    'EntityNotFound' : IDL.Null,
    'Unauthorized' : IDL.Text,
  });
  const EntityResult = IDL.Variant({ 'Ok' : Entity, 'Err' : EntityErrors });
  const EntityAttachedBridgesErrors = IDL.Variant({
    'Error' : IDL.Null,
    'EntityNotFound' : IDL.Null,
  });
  const EntityAttachedBridgesResult = IDL.Variant({
    'Ok' : EntityAttachedBridges,
    'Err' : EntityAttachedBridgesErrors,
  });
  const EntityUpdateObject = IDL.Record({
    'id' : IDL.Text,
    'previews' : IDL.Opt(IDL.Vec(EntityPreview)),
    'name' : IDL.Opt(IDL.Text),
    'description' : IDL.Opt(IDL.Text),
    'keywords' : IDL.Opt(IDL.Vec(IDL.Text)),
    'settings' : IDL.Opt(EntitySettings),
  });
  const BebbEntityService = IDL.Service({
    'add_bridge_attachment' : IDL.Func(
        [IDL.Text, Bridge, IDL.Bool],
        [EntityIdResult],
        [],
      ),
    'create_entity' : IDL.Func([EntityInitiationObject], [EntityIdResult], []),
    'delete_bridge_attachment' : IDL.Func(
        [Bridge, IDL.Bool],
        [EntityIdResult],
        [],
      ),
    'delete_entity' : IDL.Func([IDL.Text], [EntityIdResult], []),
    'getPK' : IDL.Func([], [IDL.Text], ['query']),
    'get_entity' : IDL.Func([IDL.Text], [EntityResult], ['query']),
    'get_from_bridge_ids_by_entity_id' : IDL.Func(
        [IDL.Text],
        [EntityAttachedBridgesResult],
        ['query'],
      ),
    'get_to_bridge_ids_by_entity_id' : IDL.Func(
        [IDL.Text],
        [EntityAttachedBridgesResult],
        ['query'],
      ),
    'skExists' : IDL.Func([IDL.Text], [IDL.Bool], ['query']),
    'transferCycles' : IDL.Func([], [], []),
    'update_entity' : IDL.Func([EntityUpdateObject], [EntityIdResult], []),
  });
  return BebbEntityService;
};
export const init = ({ IDL }) => {
  const AutoScalingCanisterSharedFunctionHook = IDL.Func(
      [IDL.Text],
      [IDL.Text],
      [],
    );
  const ScalingLimitType = IDL.Variant({
    'heapSize' : IDL.Nat,
    'count' : IDL.Nat,
  });
  const ScalingOptions = IDL.Record({
    'autoScalingHook' : AutoScalingCanisterSharedFunctionHook,
    'sizeLimit' : ScalingLimitType,
  });
  return [
    IDL.Record({
      'owners' : IDL.Opt(IDL.Vec(IDL.Principal)),
      'partitionKey' : IDL.Text,
      'scalingOptions' : ScalingOptions,
    }),
  ];
};
