import * as React from "react";
import { greetUser, putUser } from "./api";
import { initializeHelloServiceClient, intializeIndexClient } from "./client";

const isLocal = true;
const indexClient = intializeIndexClient(isLocal);
const helloServiceClient = initializeHelloServiceClient(isLocal, indexClient);
const groupOptions = {
  bridge: { value: "bridges", label: "Bridge" },
  entity: { value: "entities", label: "Bebb Entity" }
}
type GroupType = 'bridge' | 'entity' 
export default function App() {
  let [greetName, setGreetName] = React.useState("");
  let [name, setName] = React.useState("");
  let [displayName, setDisplayName] = React.useState("");
  let [greetingResponse, setGreetingResponse] = React.useState("");
  let [greetErrorText, setGreetErrorText] = React.useState("");
  let [createErrorText, setCreateErrorText] = React.useState("");
  let [group, setGroup] = React.useState(groupOptions.entity);
  let [successText, setSuccessText] = React.useState("");

  async function getUserGreeting() {
    if (greetName === "") {
      let errorText = "must enter a name to try to greet";
      console.error(errorText);
      setGreetErrorText(errorText)
    } else {
      setGreetErrorText("");
      let greeting = await greetUser(helloServiceClient, group.value, greetName)
      console.log("response", greeting)
      setGreetingResponse(greeting);
    }
  }

  async function createUser() {
    if (name === "" || displayName == "") {
      let errorText = "must enter a name and a displayName for user";
      console.error(errorText);
      setCreateErrorText(errorText)
    } else {
      setCreateErrorText("");
      // create the canister for the partition key if not sure that it exists
      await indexClient.indexCanisterActor.createBebbServiceCanisterByType(group.value);
      // create the new user
      await putUser(helloServiceClient, group.value, name, displayName);
      setSuccessText(`${name} successfully inserted`)
    }
  }

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
          <div>Selected Group (<span className="partition-highlight">Partition</span>):</div> 
          <select className="left-margin" onChange={(e) => setGroup(groupOptions[e.target.value as GroupType])}>
            {Object.values(groupOptions).map(createOption)}
          </select>
        </div>
      </div>

      <div className="section-wrapper">
        <h2>Get an Entity from the {group.label} group</h2>
        <div className="flex-wrapper">
          <div className="prompt-text">Set username to greet:</div>
          <input
            className="margin-left"
            value={greetName}
            onChange={ev => setGreetName(ev.target.value)}
          />
          <button className="left-margin" type="button" onClick={getUserGreeting}>Get user greeting</button>
        </div>
        <div className="flex-wrapper">
          <div className="prompt-text">Greeting response:</div>
          <div>{greetingResponse}</div>
          <div>{greetErrorText}</div>
        </div>
      </div>

      <div className="section-wrapper">
        <h2>Create an Entity in {group.label} group</h2>
        <div className="flex-wrapper">
          <div className="prompt-text">Set username to create:</div>
          <input
            value={name}
            onChange={ev => setName(ev.target.value)}
          />
        </div>
        <div className="flex-wrapper">
          <div className="prompt-text">Set displayName:</div>
          <input
            value={displayName}
            onChange={ev => setDisplayName(ev.target.value)}
          />
        </div>
        <div className="flex-wrapper">
          <button type="button" onClick={createUser}>Create entity</button>
          <div className="left-margin">{successText}</div>
          <div>{createErrorText}</div>
        </div>
      </div>

    </div>
  )
}

type OptionType = {
  value: string;
  label: string;
}

function createOption(option: OptionType) {
  return <option key={option.value} value={option.value}>{option.label}</option>
}
