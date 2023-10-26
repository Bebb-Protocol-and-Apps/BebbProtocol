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
  const BridgeEntityCanisterHints = IDL.Record({
    'toEntityCanisterId' : IDL.Text,
    'fromEntityCanisterId' : IDL.Text,
  });
  const BridgeIdErrors = IDL.Variant({
    'Error' : IDL.Null,
    'Unauthorized' : IDL.Text,
    'BridgeNotFound' : IDL.Null,
  });
  const BridgeIdResult = IDL.Variant({
    'Ok' : IDL.Text,
    'Err' : BridgeIdErrors,
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
  const BridgeUpdateObject = IDL.Record({
    'id' : IDL.Text,
    'name' : IDL.Opt(IDL.Text),
    'description' : IDL.Opt(IDL.Text),
    'keywords' : IDL.Opt(IDL.Vec(IDL.Text)),
    'settings' : IDL.Opt(BridgeSettings),
  });
  const BebbBridgeService = IDL.Service({
    'create_bridge' : IDL.Func(
        [BridgeInitiationObject, BridgeEntityCanisterHints],
        [BridgeIdResult],
        [],
      ),
    'delete_bridge' : IDL.Func(
        [IDL.Text, BridgeEntityCanisterHints],
        [BridgeIdResult],
        [],
      ),
    'getPK' : IDL.Func([], [IDL.Text], ['query']),
    'get_bridge' : IDL.Func([IDL.Text], [BridgeResult], ['query']),
    'skExists' : IDL.Func([IDL.Text], [IDL.Bool], ['query']),
    'transferCycles' : IDL.Func([], [], []),
    'update_bridge' : IDL.Func([BridgeUpdateObject], [BridgeIdResult], []),
  });
  return BebbBridgeService;
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
