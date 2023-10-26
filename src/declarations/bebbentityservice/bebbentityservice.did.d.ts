import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';

export type AutoScalingCanisterSharedFunctionHook = ActorMethod<
  [string],
  string
>;
export interface BebbEntityService {
  'add_bridge_attachment' : ActorMethod<
    [string, Bridge, boolean],
    EntityIdResult
  >,
  'create_entity' : ActorMethod<[EntityInitiationObject], EntityIdResult>,
  'delete_bridge_attachment' : ActorMethod<[Bridge, boolean], EntityIdResult>,
  'delete_entity' : ActorMethod<[string], EntityIdResult>,
  'getPK' : ActorMethod<[], string>,
  'get_entity' : ActorMethod<[string], EntityResult>,
  'get_from_bridge_ids_by_entity_id' : ActorMethod<
    [string],
    EntityAttachedBridgesResult
  >,
  'get_to_bridge_ids_by_entity_id' : ActorMethod<
    [string],
    EntityAttachedBridgesResult
  >,
  'skExists' : ActorMethod<[string], boolean>,
  'transferCycles' : ActorMethod<[], undefined>,
  'update_entity' : ActorMethod<[EntityUpdateObject], EntityIdResult>,
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
export type BridgeLinkStatus = { 'CreatedOther' : null } |
  { 'CreatedOwner' : null };
export type BridgeSettings = {};
export type BridgeType = { 'IsPartOf' : null } |
  { 'IsAttachedto' : null } |
  { 'IsRelatedto' : null };
export interface Entity {
  'id' : string,
  'creator' : Principal,
  'toIds' : EntityAttachedBridges,
  'previews' : Array<EntityPreview>,
  'owner' : Principal,
  'creationTimestamp' : bigint,
  'name' : string,
  'fromIds' : EntityAttachedBridges,
  'description' : string,
  'keywords' : Array<string>,
  'settings' : EntitySettings,
  'listOfEntitySpecificFieldKeys' : Array<string>,
  'entityType' : EntityType,
  'entitySpecificFields' : string,
}
export interface EntityAttachedBridge {
  'id' : string,
  'creationTime' : Time,
  'bridgeType' : BridgeType,
  'linkStatus' : BridgeLinkStatus,
}
export type EntityAttachedBridges = Array<EntityAttachedBridge>;
export type EntityAttachedBridgesErrors = { 'Error' : null } |
  { 'EntityNotFound' : null };
export type EntityAttachedBridgesResult = { 'Ok' : EntityAttachedBridges } |
  { 'Err' : EntityAttachedBridgesErrors };
export type EntityErrors = { 'Error' : null } |
  { 'EntityNotFound' : null } |
  { 'Unauthorized' : string };
export type EntityIdErrors = { 'Error' : null } |
  { 'PreviewTooLarge' : bigint } |
  { 'EntityNotFound' : null } |
  { 'TooManyPreviews' : null } |
  { 'Unauthorized' : string };
export type EntityIdResult = { 'Ok' : string } |
  { 'Err' : EntityIdErrors };
export interface EntityInitiationObject {
  'name' : [] | [string],
  'description' : [] | [string],
  'keywords' : [] | [Array<string>],
  'settings' : [] | [EntitySettings],
  'entityType' : EntityType,
  'entitySpecificFields' : [] | [string],
}
export interface EntityPreview {
  'previewData' : Uint8Array | number[],
  'previewType' : EntityPreviewSupportedTypes,
}
export type EntityPreviewSupportedTypes = { 'Glb' : null } |
  { 'Jpg' : null } |
  { 'Png' : null } |
  { 'Gltf' : null } |
  { 'Other' : string };
export type EntityResult = { 'Ok' : Entity } |
  { 'Err' : EntityErrors };
export type EntitySettings = {};
export type EntityType = { 'Other' : string } |
  { 'Resource' : EntityTypeResourceTypes };
export type EntityTypeResourceTypes = { 'Web' : null } |
  { 'DigitalAsset' : null } |
  { 'Content' : null };
export interface EntityUpdateObject {
  'id' : string,
  'previews' : [] | [Array<EntityPreview>],
  'name' : [] | [string],
  'description' : [] | [string],
  'keywords' : [] | [Array<string>],
  'settings' : [] | [EntitySettings],
}
export type ScalingLimitType = { 'heapSize' : bigint } |
  { 'count' : bigint };
export interface ScalingOptions {
  'autoScalingHook' : AutoScalingCanisterSharedFunctionHook,
  'sizeLimit' : ScalingLimitType,
}
export type Time = bigint;
export interface _SERVICE extends BebbEntityService {}
