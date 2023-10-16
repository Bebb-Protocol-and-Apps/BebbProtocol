import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';

export interface IndexCanister {
  'autoScaleBebbServiceCanister' : ActorMethod<[string], string>,
  'createBebbServiceCanisterByType' : ActorMethod<[string], [] | [string]>,
  'getCanistersByPK' : ActorMethod<[string], Array<string>>,
  'getPkOptions' : ActorMethod<[], Array<string>>,
  'upgradeGroupCanistersInPKRange' : ActorMethod<
    [string, string, Uint8Array | number[]],
    UpgradePKRangeResult
  >,
}
export type InterCanisterActionResult = { 'ok' : null } |
  { 'err' : string };
export interface UpgradePKRangeResult {
  'nextKey' : [] | [string],
  'upgradeCanisterResults' : Array<[string, InterCanisterActionResult]>,
}
export interface _SERVICE extends IndexCanister {}
