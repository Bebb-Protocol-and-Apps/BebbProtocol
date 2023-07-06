# Bebb Protocol v0.0.4

## Overview
Bebb Protocol is a decentrally hosted open data network
Users contribute data to the network and stay in control over it (including ownership)
The contributed user data forms the network to which everyone has access in accordance with the settings the data owners have put in place
The contributed data are Entities and Bridges
Entities represent all kinds of physical and digital entities (e.g. Person, physical/virtual location, physical/digital object, data items, Websites) as a Web resource
Bridges represent the relationships between the Entities and are similar to hyperlinks
The Entities and the Bridges between them thus span a highly connected data network which can be used by users, applications and software agents for different purposes
As a wide range of entities and relationships can be represented with Bebb Protocol, it establishes a solution for the Internet-of-Everything (decentralized and user-controlled)

## General Notes on Version 0.0.4 
Implements a mono-canister architecture
Not meant to be used in production (pre-alpha)
Well commented code serving as documentation

## Entity
Similar to a node in a graph database
Entity type and related types defined in entity.mo
Entity Types: resource/web, resource/digitalasset and resource/content
Stores Bridge attachments
	Bridges attached to this Entity
	Bridges attached from this Entity
	Bridge attachment is object itself
		Of type EntityAttachedBridge 
		linkStatus to keep track how Entity owner regards this Bridge
			#CreatedOwner;
			#CreatedOther
		Allows for filtering attached Bridges based on its fields

## Bridge
Similar to an edge in a graph database
Bridge type and related types defined in bridge.mo
Bridge Types: partof, relatedto and attachedto

## Public Interface
### create_entity
Update request
Parameter:
	EntityInitiationObject (in entity.mo)
Returns EntityIdResult
	Id of created Entity or of existing Entity if a duplicate were created otherwise (of type Text)
	Or returns an error if the Entity couldn’t be created (EntityIdErrors)
The Entity is created in accordance with any relevant rules and settings 
The new Entity is persisted in the system

### get_entity
Query request
Parameters:
	Entity Id (of type Text)
Returns EntityResult
	The Entity (of type Entity, in entity.mo)
	Or returns an error if the Entity couldn’t be retrieved (EntityErrors)
The Entity is retrieved in accordance with any relevant rules and settings

### update_entity
Update request
Parameters:
	EntityUpdateObject (in entity.mo)
		Includes Entity id
Returns EntityIdResult
	Id of updated Entity (of type Text)
	Or returns an error if the Entity couldn’t be updated (EntityIdErrors)
The Entity is updated in accordance with any relevant rules and settings
Only the Entity’s owner may update the Entity
The updates to the Entity are persisted in the system

### delete_entity
Update request
Parameters:
	Entity Id (of type Text)
Returns EntityIdResult
	Id of deleted Entity (of type Text)
	Or returns an error if the Entity couldn’t be deleted (EntityIdErrors)
The Entity is deleted in accordance with any relevant rules and settings
Only the Entity’s owner may delete the Entity
The Entity is deleted from the system and the change is persisted
This operation can have effects on other Entities and Bridges

### create_bridge
Update request
Parameter:
	BridgeInitiationObject (in bridge.mo)
Returns BridgeIdResult (in bridge.mo)
	Id of created Bridge or of existing Bridge if a non-permitted duplicate were created otherwise (of type Text)
	Or returns an error if the Bridge couldn’t be created (BridgeIdErrors)
The Bridge is created in accordance with any relevant rules and settings 
Several Bridges between the same two Entities (“duplicates”) might not be allowed
The new Bridge is persisted in the system
The bridged Entities are now connected by the new Bridge

### get_bridge
Query request
Parameters:
	Bridge Id (of type Text)
Returns BridgeResult (in bridge.mo)
	Returns the Bridge (of type Bridge)
	Or returns an error if the Bridge couldn’t be retrieved (BridgeErrors)
The Bridge is retrieved in accordance with any relevant rules and settings

### update_bridge
Update request
Parameters:
	BridgeUpdateObject (in bridge.mo)
Includes Bridge Id
Returns BridgeIdResult (in bridge.mo)
	Id of updated Bridge (of type Text)
	Or returns an error if the Bridge couldn’t be updated (BridgeIdErrors)
The Bridge is updated in accordance with any relevant rules and settings
Only the Bridge’s owner may update the Bridge
Only certain fields may be updated while others (e.g. from and to Entities) cannot be updated
The updated Bridge is persisted in the system

### delete_bridge
Update request
Parameters:
	Bridge Id (of type Text)
Returns BridgeIdResult (in bridge.mo)
	The id of the deleted Bridge (of type Text)
	Or returns an error if the Bridge couldn’t be deleted (BridgeIdErrors)
The Bridge is deleted in accordance with any relevant rules and settings
Only the Bridge’s owner may delete the Bridge
The Bridge is deleted from the system and the change is persisted
The Entities are no longer connected by the Bridge 

### get_to_bridge_ids_by_entity_id
Query request
Parameters:
	Entity Id
Returns EntityAttachedBridgesResult (in entity.mo)
	The Ids of Bridges attached to the Entity (Bridges linking to this Entity from other Entities)
	The Bridge Ids are returned as an array ([Text]) which will be empty if there aren’t any Bridges attached to the Entity 
	Or returns an error if the Bridge Ids for the Entity couldn’t be retrieved (EntityAttachedBridgesErrors)
The Bridge Ids for the Entity are retrieved in accordance with any relevant rules and settings

### get_from_bridge_ids_by_entity_id
Query request
Parameters:
	Entity Id
Returns EntityAttachedBridgesResult (in entity.mo)
	The Ids of Bridges attached from the Entity (Bridges linking from this Entity to other Entities)
	The Bridge Ids are returned as an array ([Text]) which will be empty if there aren’t any Bridges attached from the Entity 
	Or returns an error if the Bridge Ids for the Entity couldn’t be retrieved (EntityAttachedBridgesErrors)
The Bridge Ids for the Entity are retrieved in accordance with any relevant rules and settings
