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
  'get_bridge' : (arg_0: string) => Promise<[] | [BridgeEntity]>,
  'get_bridge_ids_by_entity_id' : (
      arg_0: string,
      arg_1: boolean,
      arg_2: boolean,
      arg_3: boolean,
    ) => Promise<Array<string>>,
  'get_bridges_by_entity_id' : (
      arg_0: string,
      arg_1: boolean,
      arg_2: boolean,
      arg_3: boolean,
    ) => Promise<Array<BridgeEntity>>,
}
