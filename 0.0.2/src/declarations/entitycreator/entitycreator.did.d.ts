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
export interface EntityInitiationObject {
  '_externalId' : [] | [string],
  '_owner' : [] | [Principal],
  '_creator' : [] | [Principal],
  '_entitySpecificFields' : [] | [string],
  '_entityType' : EntityType,
  '_description' : [] | [string],
  '_keywords' : [] | [Array<string>],
  '_settings' : [] | [EntitySettings],
  '_internalId' : [] | [string],
  '_name' : [] | [string],
}
export type EntitySettings = {};
export type EntityType = { 'Webasset' : null } |
  { 'BridgeEntity' : null } |
  { 'Person' : null } |
  { 'Location' : null };
export interface _SERVICE {
  'create_entity' : (arg_0: EntityInitiationObject) => Promise<Entity>,
}
