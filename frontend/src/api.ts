import { ActorClient } from "candb-client-typescript/dist/ActorClient";
import { BebbService } from "../declarations/bebbservice/bebbservice.did";
import { IndexCanister } from "../declarations/index/index.did";
import { EntityInitiationObject } from "../declarations/bebbservice/bebbservice.did";
import { EntityType } from "../declarations/bebbservice/bebbservice.did";
import { EntityTypeResourceTypes } from "../declarations/bebbservice/bebbservice.did";

export async function greetUser(helloServiceClient: ActorClient<IndexCanister, BebbService>, group: string, name: string) {
  let pk = `group#${group}`;
  let userGreetingQueryResults = await helloServiceClient.query<BebbService["get_entity"]>(
    pk,
    (actor) => actor.get_entity(name)
  );

  for (let settledResult of userGreetingQueryResults) {
    // handle settled result if fulfilled
    if (settledResult.status === "fulfilled") {
      // handle candid returned optional type (string[] or string)
      return Array.isArray(settledResult.value) ? settledResult.value[0] : settledResult.value
    } 
  }
  
  return "User does not exist";
};

export async function putUser(helloServiceClient: ActorClient<IndexCanister, BebbService>, group: string, name: string, nickname: string) {
  let pk = `group#${group}`;
  let sk = name;
  let entity_initialization_object: EntityInitiationObject = {
    settings: [],
    entityType: { "Resource": { "Web" : null } },
    name: ["EntityName"], // Replace with the desired name or set it to null or undefined
    description: ["EntityDescription"], // Replace with the desired description or set it to null or undefined
    keywords: [["Keyword1", "Keyword2"]], // Replace with an array of keywords or set it to null or undefined
    entitySpecificFields:[ "SpecificFieldsValue"], // Replace with the desired entity specific fields or set it to null or undefined
  };
  await helloServiceClient.update<BebbService["create_entity"]>(
    pk,
    sk,
    (actor) => actor.create_entity(entity_initialization_object)
  );
}