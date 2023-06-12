export const idlFactory = ({ IDL }) => {
  return IDL.Service({
    'getEntityEntry' : IDL.Func([IDL.Text], [IDL.Opt(IDL.Principal)], []),
    'putEntityEntry' : IDL.Func([IDL.Text, IDL.Principal], [IDL.Text], []),
  });
};
export const init = ({ IDL }) => { return []; };
