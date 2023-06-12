import type { Principal } from '@dfinity/principal';
export interface BridgeEntity {
  'internalId' : string,
  'toEntityId' : string,
  'creator' : Principal,
  'fromEntityId' : string,
  'owner' : Principal,
  'externalId' : [] | [string],
  'creationTimestamp' : bigint,
  'name' : [] | [string],
  'description' : [] | [string],
  'keywords' : [] | [Array<string>],
  'state' : BridgeState,
  'settings' : EntitySettings,
  'listOfEntitySpecificFieldKeys' : Array<string>,
  'entityType' : EntityType,
  'bridgeType' : BridgeType,
  'entitySpecificFields' : [] | [string],
}
export type BridgeState = { 'Confirmed' : null } |
  { 'Rejected' : null } |
  { 'Pending' : null };
export type BridgeType = { 'OwnerCreated' : null };
export type EntitySettings = {};
export type EntityType = { 'Webasset' : null } |
  { 'BridgeEntity' : null } |
  { 'Person' : null } |
  { 'Location' : null };
export interface _SERVICE {
  'getEntities' : (arg_0: Array<string>) => Promise<Array<BridgeEntity>>,
  'getEntity' : (arg_0: string) => Promise<[] | [BridgeEntity]>,
  'putEntity' : (arg_0: BridgeEntity) => Promise<BridgeEntity>,
}
