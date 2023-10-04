import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';

export interface IndexCanister {
  'autoScaleBebbServiceCanister' : ActorMethod<[string], string>,
  'createBebbServiceCanisterByType' : ActorMethod<[string], [] | [string]>,
  'getCanistersByPK' : ActorMethod<[string], Array<string>>,
  'getPkOptions' : ActorMethod<[], Array<string>>,
}
export interface _SERVICE extends IndexCanister {}
