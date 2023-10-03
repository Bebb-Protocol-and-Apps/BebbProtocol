import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';

export interface IndexCanister {
  'autoScaleHelloServiceCanister' : ActorMethod<[string], string>,
  'createHelloServiceCanisterByGroup' : ActorMethod<[string], [] | [string]>,
  'getCanistersByPK' : ActorMethod<[string], Array<string>>,
}
export interface _SERVICE extends IndexCanister {}
