import * as React from "react";
import { getBebbBridge, getBebbEntity, putBebbBridge, putBebbEntity } from "./api";
import {
  intializeIndexClient,
  initializeBebbEntityServiceClient,
  initializeBebbBridgeServiceClient
} from "./client";

const isLocal = true;
const indexClient = intializeIndexClient(isLocal);
const entityServiceClient = initializeBebbEntityServiceClient(isLocal, indexClient);
const bridgeServiceClient = initializeBebbBridgeServiceClient(isLocal, indexClient);
const partitionOptions = {
  Bridge: { value: "Bridge", label: "Bridge" },
  Entity: { value: "Entity", label: "Bebb Entity" }
};
type GroupType = 'Bridge' | 'Entity';

export default function App() {
  let [entityId, setEntityId] = React.useState("");
  let [bebbEntityResponse, setBebbEntityResponse] = React.useState("");
  let [retrievalErrorText, setRetrievalErrorText] = React.useState("");
  let [createErrorText, setCreateErrorText] = React.useState("");
  let [partition, setPartition] = React.useState(partitionOptions.Entity);
  let [successText, setSuccessText] = React.useState("");

  let [name, setName] = React.useState("");
  let [toEntityId, setToEntityId] = React.useState("");
  let [fromEntityId, setFromEntityId] = React.useState("");

  async function getEntity() {
    if (entityId === "") {
      let errorText = "must enter an id to retrieve";
      console.error(errorText);
      setRetrievalErrorText(errorText)
    } else {
      setRetrievalErrorText("");
      let bebbEntity;
      if (partition.value === "Bridge") {
        bebbEntity = await getBebbBridge(bridgeServiceClient, partition.value, entityId);
      } else {
        bebbEntity = await getBebbEntity(entityServiceClient, partition.value, entityId);
      };
      console.log("response", bebbEntity)
      setBebbEntityResponse(bebbEntity);
    }
  };

  async function createEntity() {
    if (partition.value === "Bridge") {
      if (toEntityId && fromEntityId) {
        setCreateErrorText("");
        console.log("createEntity partition.value ", partition.value);
        // create the canister for the partition key if not sure that it exists
        await indexClient.indexCanisterActor.createBebbServiceCanisterByType(partition.value);
        // create the new Bridge
        const bebbBridgeObject = {
          toEntityId,
          fromEntityId, 
          name,
        };
        await putBebbBridge(bridgeServiceClient, partition.value, bebbBridgeObject);
        setSuccessText(`${name} successfully inserted`);
      } else {
        let errorText = "must enter a toEntityId and a fromEntityId to create a Bridge";
        console.error(errorText);
        setCreateErrorText(errorText)
      };
    } else {
      setCreateErrorText("");
      console.log("createEntity partition.value ", partition.value);
      // create the canister for the partition key if not sure that it exists
      await indexClient.indexCanisterActor.createBebbServiceCanisterByType(partition.value);
      // create the new Bebb Entity
      const bebbEntityObject = { name };
      await putBebbEntity(entityServiceClient, partition.value, bebbEntityObject);
      setSuccessText(`${name} successfully inserted`);
    }
  };

  return (
    <div className="flex-center">
      
      <div className="section-wrapper">
        <h1>Hello to Bebb!</h1>
        <p>Below is a testing frontend to communicate with Bebb. 
          <br/><br/>
          To accomplish this, a unique <b>partition key</b> (PK) is used in order to <span className="partition-highlight">partition</span>, or separate the data associated with each unique "group" name. 
          <br/><br/>
          Creating a user inserts it into the currently selected group <span className="partition-highlight">partition</span>, and getting a user fetches it from the currently selected group partition.
        </p>
        <hr/>

        <div className="flex-wrapper">
          <div>Selected (<span className="partition-highlight">Partition</span>):</div> 
          <select className="left-margin" onChange={(e) => setPartition(partitionOptions[e.target.value as GroupType])}>
            {Object.values(partitionOptions).map(createOption)}
          </select>
        </div>
      </div>

      <div className="section-wrapper">
        <h2>Get an Entity from the {partition.label} partition</h2>
        <div className="flex-wrapper">
          <div className="prompt-text">Set id to retrieve:</div>
          <input
            className="margin-left"
            value={entityId}
            onChange={ev => setEntityId(ev.target.value)}
          />
          <button className="left-margin" type="button" onClick={getEntity}>Get Entity</button>
        </div>
        <div className="flex-wrapper">
          <div className="prompt-text">Greeting response:</div>
          <div>{bebbEntityResponse}</div>
          <div>{retrievalErrorText}</div>
        </div>
      </div>

      <div className="section-wrapper">
        <h2>Create an Entity in {partition.label} partition</h2>
        {
          partition.value === "Bridge" &&
            <div>
              <div className="flex-wrapper">
                <div className="prompt-text">Set Entity Id to bridge from:</div>
                <input
                  value={fromEntityId}
                  onChange={ev => setFromEntityId(ev.target.value)}
                />
              </div>
              <div className="flex-wrapper">
                <div className="prompt-text">Set Entity Id to bridge to:</div>
                <input
                  value={toEntityId}
                  onChange={ev => setToEntityId(ev.target.value)}
                />
              </div>
            </div>
        }
        <div className="flex-wrapper">
          <div className="prompt-text">Set name (optional):</div>
          <input
            value={name}
            onChange={ev => setName(ev.target.value)}
          />
        </div>

        <div className="flex-wrapper">
          <button type="button" onClick={createEntity}>Create Entity</button>
          <div className="left-margin">{successText}</div>
          <div>{createErrorText}</div>
        </div>
      </div>

    </div>
  );
};

type OptionType = {
  value: string;
  label: string;
};

function createOption(option: OptionType) {
  return <option key={option.value} value={option.value}>{option.label}</option>
};
