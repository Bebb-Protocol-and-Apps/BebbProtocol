import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';

export type AutoScalingCanisterSharedFunctionHook = ActorMethod<
  [string],
  string
>;
export interface BebbBridgeService {
  'create_bridge' : ActorMethod<
    [BridgeInitiationObject, BridgeEntityCanisterHints],
    BridgeIdResult
  >,
  'delete_bridge' : ActorMethod<
    [string, BridgeEntityCanisterHints],
    BridgeIdResult
  >,
  'getPK' : ActorMethod<[], string>,
  'get_bridge' : ActorMethod<[string], BridgeResult>,
  'skExists' : ActorMethod<[string], boolean>,
  'transferCycles' : ActorMethod<[], undefined>,
  'update_bridge' : ActorMethod<[BridgeUpdateObject], BridgeIdResult>,
}
export interface Bridge {
  'id' : string,
  'toEntityId' : string,
  'creator' : Principal,
  'fromEntityId' : string,
  'owner' : Principal,
  'creationTimestamp' : bigint,
  'name' : string,
  'description' : string,
  'keywords' : Array<string>,
  'settings' : BridgeSettings,
  'listOfEntitySpecificFieldKeys' : Array<string>,
  'bridgeType' : BridgeType,
  'entitySpecificFields' : string,
}
export interface BridgeEntityCanisterHints {
  'toEntityCanisterId' : string,
  'fromEntityCanisterId' : string,
}
export type BridgeErrors = { 'Error' : null } |
  { 'Unauthorized' : string } |
  { 'BridgeNotFound' : null };
export type BridgeIdErrors = { 'Error' : null } |
  { 'Unauthorized' : string } |
  { 'BridgeNotFound' : null };
export type BridgeIdResult = { 'Ok' : string } |
  { 'Err' : BridgeIdErrors };
export interface BridgeInitiationObject {
  'toEntityId' : string,
  'fromEntityId' : string,
  'name' : [] | [string],
  'description' : [] | [string],
  'keywords' : [] | [Array<string>],
  'settings' : [] | [BridgeSettings],
  'bridgeType' : BridgeType,
  'entitySpecificFields' : [] | [string],
}
export type BridgeResult = { 'Ok' : Bridge } |
  { 'Err' : BridgeErrors };
export type BridgeSettings = {};
export type BridgeType = { 'IsPartOf' : null } |
  { 'IsAttachedto' : null } |
  { 'IsRelatedto' : null };
export interface BridgeUpdateObject {
  'id' : string,
  'name' : [] | [string],
  'description' : [] | [string],
  'keywords' : [] | [Array<string>],
  'settings' : [] | [BridgeSettings],
}
export type ScalingLimitType = { 'heapSize' : bigint } |
  { 'count' : bigint };
export interface ScalingOptions {
  'autoScalingHook' : AutoScalingCanisterSharedFunctionHook,
  'sizeLimit' : ScalingLimitType,
}
export interface _SERVICE extends BebbBridgeService {}
