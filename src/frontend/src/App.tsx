import * as React from "react";
import type { Identity } from "@dfinity/agent";
import { AuthClient } from "@dfinity/auth-client";

import { getBebbBridge, getBebbEntity, putBebbBridge, putBebbEntity } from "./api";
import {
  intializeIndexClient,
  initializeBebbEntityServiceClient,
  initializeBebbBridgeServiceClient
} from "./client";

const isLocal = process.env.NODE_ENV !== "production";
let indexClient = intializeIndexClient(isLocal);
let entityServiceClient = initializeBebbEntityServiceClient(isLocal, indexClient);
let bridgeServiceClient = initializeBebbBridgeServiceClient(isLocal, indexClient);

let authClient : AuthClient;
const APPLICATION_NAME = "Bebb UI";
const APPLICATION_LOGO_URL = "https://vdfyi-uaaaa-aaaai-acptq-cai.ic0.app/faviconFutureWebInitiative.ico";
//"https%3A%2F%2Fx6occ%2Dbiaaa%2Daaaai%2Dacqzq%2Dcai.icp0.io%2Ffavicon.ico"
//"https%3A%2F%2Fx6occ-biaaa-aaaai-acqzq-cai.icp0.io%2FFutureWebInitiative%5Fimg.png";
const AUTH_PATH = "/authenticate/?applicationName="+APPLICATION_NAME+"&applicationLogo="+APPLICATION_LOGO_URL+"#authorize";

const days = BigInt(30);
const hours = BigInt(24);
const nanosecondsPerHour = BigInt(3600000000000);
let loggedInIdentity;

const nfidConnect = async () => {
  authClient = await AuthClient.create();
  await authClient.login({
    onSuccess: async () => {
      loggedInIdentity = await authClient.getIdentity();
      initNfid(loggedInIdentity);
    },
    identityProvider: "https://nfid.one" + AUTH_PATH,
      /* process.env.DFX_NETWORK === "ic"
        ? "https://nfid.one" + AUTH_PATH
        : process.env.LOCAL_NFID_CANISTER + AUTH_PATH, */
    // Maximum authorization expiration is 30 days
    maxTimeToLive: days * hours * nanosecondsPerHour,
    windowOpenerFeatures: 
      `left=${window.screen.width / 2 - 525 / 2}, `+
      `top=${window.screen.height / 2 - 705 / 2},` +
      `toolbar=0,location=0,menubar=0,width=525,height=705`,
    // See https://docs.nfid.one/multiple-domains
    // for instructions on how to use derivationOrigin
    // derivationOrigin: "https://<canister_id>.ic0.app"
  });
};

const initNfid = async (identity: Identity) => {
  indexClient = intializeIndexClient(isLocal, identity);
  entityServiceClient = initializeBebbEntityServiceClient(isLocal, indexClient, identity);
  bridgeServiceClient = initializeBebbBridgeServiceClient(isLocal, indexClient, identity);
};

const partitionOptions = {
  Entity: { value: "Entity", label: "Bebb Entity" },
  Bridge: { value: "Bridge", label: "Bridge" }
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
      let responseToSet = {};
      if (partition.value === "Bridge") {
        bebbEntity = await getBebbBridge(bridgeServiceClient, partition.value, entityId);
        if (bebbEntity.id) {
          responseToSet = {
            id: bebbEntity.id,
            //creationTimestamp: bebbEntity.creationTimestamp,
            name: bebbEntity.name,
            description: bebbEntity.description,
            bridgeType: bebbEntity.bridgeType,
          };
        } else {
          responseToSet = bebbEntity;
        };
      } else {
        bebbEntity = await getBebbEntity(entityServiceClient, partition.value, entityId);
        if (bebbEntity.id) {
          responseToSet = {
            id: bebbEntity.id,
            //creationTimestamp: bebbEntity.creationTimestamp,
            name: bebbEntity.name,
            description: bebbEntity.description,
            entityType: bebbEntity.entityType,
          };
        } else {
          responseToSet = bebbEntity;
        };
      };
      console.log("getEntity bebbEntity", bebbEntity);
      console.log("getEntity response", responseToSet);
      setBebbEntityResponse(JSON.stringify(responseToSet));
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
        const result = await putBebbBridge(bridgeServiceClient, partition.value, bebbBridgeObject);
        // @ts-ignore
        if (result.Ok) {
          // @ts-ignore
          setSuccessText(`${name} successfully inserted with id: ${result.Ok}`);
        } else {
          // @ts-ignore
          result.Err ? setCreateErrorText(result.Err) : setCreateErrorText("Something went wrong, please try once more.");
        };
      } else {
        let errorText = "must enter a toEntityId and a fromEntityId to create a Bridge";
        console.error(errorText);
        setCreateErrorText(errorText);
      };
    } else {
      setCreateErrorText("");
      console.log("createEntity partition.value ", partition.value);
      // create the canister for the partition key if not sure that it exists
      await indexClient.indexCanisterActor.createBebbServiceCanisterByType(partition.value);
      // create the new Bebb Entity
      const bebbEntityObject = { name };
      const result = await putBebbEntity(entityServiceClient, partition.value, bebbEntityObject);
      // @ts-ignore
      if (result.Ok) {
        // @ts-ignore
        setSuccessText(`${name} successfully inserted with id: ${result.Ok}`);
      } else {
        // @ts-ignore
        result.Err ? setCreateErrorText(result.Err) : setCreateErrorText("Something went wrong, please try once more.");
      };
    };
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

        <button className="left-margin" type="button" onClick={nfidConnect}>Login</button>

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
          <div className="prompt-text">Retrieval response:</div>
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
