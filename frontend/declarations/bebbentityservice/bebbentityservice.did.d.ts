import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';

export type AutoScalingCanisterSharedFunctionHook = ActorMethod<
  [string],
  string
>;
export interface BebbEntityService {
  'create_entity' : ActorMethod<[EntityInitiationObject], EntityIdResult>,
  'getPK' : ActorMethod<[], string>,
  'get_entity' : ActorMethod<[string], EntityResult>,
  'skExists' : ActorMethod<[string], boolean>,
  'transferCycles' : ActorMethod<[], undefined>,
}
export type BridgeLinkStatus = { 'CreatedOther' : null } |
  { 'CreatedOwner' : null };
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
export type ScalingLimitType = { 'heapSize' : bigint } |
  { 'count' : bigint };
export interface ScalingOptions {
  'autoScalingHook' : AutoScalingCanisterSharedFunctionHook,
  'sizeLimit' : ScalingLimitType,
}
export type Time = bigint;
export interface _SERVICE extends BebbEntityService {}
