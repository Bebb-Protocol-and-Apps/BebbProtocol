import type { Principal } from '@dfinity/principal';
export type List = [] | [[string, List]];
export interface _SERVICE {
  'getEntityEntries' : (arg_0: string) => Promise<List>,
  'putEntityEntry' : (arg_0: string, arg_1: string, arg_2: string) => Promise<
      string
    >,
}
