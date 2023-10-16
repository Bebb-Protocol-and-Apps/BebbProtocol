export const idlFactory = ({ IDL }) => {
  const InterCanisterActionResult = IDL.Variant({
    'ok' : IDL.Null,
    'err' : IDL.Text,
  });
  const UpgradePKRangeResult = IDL.Record({
    'nextKey' : IDL.Opt(IDL.Text),
    'upgradeCanisterResults' : IDL.Vec(
      IDL.Tuple(IDL.Text, InterCanisterActionResult)
    ),
  });
  const IndexCanister = IDL.Service({
    'autoScaleBebbServiceCanister' : IDL.Func([IDL.Text], [IDL.Text], []),
    'createBebbServiceCanisterByType' : IDL.Func(
        [IDL.Text],
        [IDL.Opt(IDL.Text)],
        [],
      ),
    'getCanistersByPK' : IDL.Func([IDL.Text], [IDL.Vec(IDL.Text)], ['query']),
    'getPkOptions' : IDL.Func([], [IDL.Vec(IDL.Text)], ['query']),
    'upgradeGroupCanistersInPKRange' : IDL.Func(
        [IDL.Text, IDL.Text, IDL.Vec(IDL.Nat8)],
        [UpgradePKRangeResult],
        [],
      ),
  });
  return IndexCanister;
};
export const init = ({ IDL }) => { return []; };
