export const idlFactory = ({ IDL }) => {
  const List = IDL.Rec();
  List.fill(IDL.Opt(IDL.Tuple(IDL.Text, List)));
  return IDL.Service({
    'getEntityEntries' : IDL.Func([IDL.Text], [List], []),
    'putEntityEntry' : IDL.Func([IDL.Text, IDL.Text, IDL.Text], [IDL.Text], []),
  });
};
export const init = ({ IDL }) => { return []; };
