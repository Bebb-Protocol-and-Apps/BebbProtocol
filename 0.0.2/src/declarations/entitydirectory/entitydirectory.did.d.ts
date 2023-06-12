import type { Principal } from '@dfinity/principal';
export interface _SERVICE {
  'getEntityEntry' : (arg_0: string) => Promise<[] | [Principal]>,
  'putEntityEntry' : (arg_0: string, arg_1: Principal) => Promise<string>,
}
