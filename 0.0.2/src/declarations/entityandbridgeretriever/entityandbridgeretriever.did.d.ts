import type { Principal } from '@dfinity/principal';
export interface Entity {
  'internalId' : string,
  'creator' : Principal,
  'owner' : Principal,
  'externalId' : [] | [string],
  'creationTimestamp' : bigint,
  'name' : [] | [string],
  'description' : [] | [string],
  'keywords' : [] | [Array<string>],
  'settings' : EntitySettings,
  'listOfEntitySpecificFieldKeys' : Array<string>,
  'entityType' : EntityType,
  'entitySpecificFields' : [] | [string],
}
export type EntitySettings = {};
export type EntityType = { 'Webasset' : null } |
  { 'BridgeEntity' : null } |
  { 'Person' : null } |
  { 'Location' : null };
export interface _SERVICE {
  'get_bridged_entities_by_entity_id' : (
      arg_0: string,
      arg_1: boolean,
      arg_2: boolean,
      arg_3: boolean,
    ) => Promise<Array<Entity>>,
  'get_entity_and_bridge_ids' : (
      arg_0: string,
      arg_1: boolean,
      arg_2: boolean,
      arg_3: boolean,
    ) => Promise<[[] | [Entity], Array<string>]>,
}
