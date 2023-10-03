export const idlFactory = ({ IDL }) => {
  const IndexCanister = IDL.Service({
    'autoScaleHelloServiceCanister' : IDL.Func([IDL.Text], [IDL.Text], []),
    'createHelloServiceCanisterByGroup' : IDL.Func(
        [IDL.Text],
        [IDL.Opt(IDL.Text)],
        [],
      ),
    'getCanistersByPK' : IDL.Func([IDL.Text], [IDL.Vec(IDL.Text)], ['query']),
  });
  return IndexCanister;
};
export const init = ({ IDL }) => { return []; };
