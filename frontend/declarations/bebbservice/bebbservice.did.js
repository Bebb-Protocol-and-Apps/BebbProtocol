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
  const BridgeInitiationObject = IDL.Record({
    'toEntityId' : IDL.Text,
    'fromEntityId' : IDL.Text,
    'name' : IDL.Opt(IDL.Text),
    'description' : IDL.Opt(IDL.Text),
    'keywords' : IDL.Opt(IDL.Vec(IDL.Text)),
    'settings' : IDL.Opt(BridgeSettings),
    'bridgeType' : BridgeType,
    'entitySpecificFields' : IDL.Opt(IDL.Text),
  });
  const BridgeIdErrors = IDL.Variant({
    'Error' : IDL.Null,
    'Unauthorized' : IDL.Null,
    'BridgeNotFound' : IDL.Null,
  });
  const BridgeIdResult = IDL.Variant({
    'Ok' : IDL.Text,
    'Err' : BridgeIdErrors,
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
  const EntityIdErrors = IDL.Variant({
    'Error' : IDL.Null,
    'PreviewTooLarge' : IDL.Int,
    'EntityNotFound' : IDL.Null,
    'TooManyPreviews' : IDL.Null,
    'Unauthorized' : IDL.Null,
  });
  const EntityIdResult = IDL.Variant({
    'Ok' : IDL.Text,
    'Err' : EntityIdErrors,
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
  const BridgeErrors = IDL.Variant({
    'Error' : IDL.Null,
    'Unauthorized' : IDL.Text,
    'BridgeNotFound' : IDL.Null,
  });
  const BridgeResult = IDL.Variant({ 'Ok' : Bridge, 'Err' : BridgeErrors });
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
  const BebbService = IDL.Service({
    'create_bridge' : IDL.Func([BridgeInitiationObject], [BridgeIdResult], []),
    'create_entity' : IDL.Func([EntityInitiationObject], [EntityIdResult], []),
    'getPK' : IDL.Func([], [IDL.Text], ['query']),
    'get_bridge' : IDL.Func([IDL.Text], [BridgeResult], ['query']),
    'get_entity' : IDL.Func([IDL.Text], [EntityResult], ['query']),
    'skExists' : IDL.Func([IDL.Text], [IDL.Bool], ['query']),
    'transferCycles' : IDL.Func([], [], []),
  });
  return BebbService;
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