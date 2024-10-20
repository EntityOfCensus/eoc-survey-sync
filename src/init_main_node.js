import {
    createDataItemSigner,
    dryrun,
    message,
  } from '@permaweb/aoconnect';
import dotenv from 'dotenv';
import fs from 'fs';

dotenv.config();


const wallet = JSON.parse(process.env.JWK);
const MAIN_NODE_ID = process.env.MAIN_NODE_ID

const dataValidClient = await getLatestSchemaManagement("client");
console.log(dataValidClient);
const dataValidRespondent = await getLatestSchemaManagement("respondent");
console.log(dataValidRespondent);

await loadNodeScripts();

async function loadNodeScripts() {
    await loadClientApi();
    await loadRespondentApi();
}

async function loadClientApi() {
    const client_node_api = fs.readFileSync('./process/client_node_api.lua', 'utf-8');
    const nodeApi = {
        node_type: "client",
        script_name: "client_node_api.lua",
        script_version: "v1.0",
        script_content: client_node_api
    };
    const data = JSON.stringify(nodeApi);
    const msgId = await loadApi(data);
    console.log(msgId);
    const dataValid = await getLatestApi("client");
    console.log(dataValid);
}

async function loadRespondentApi() {
    const respondent_node_api = fs.readFileSync('./process/respondent_node_api.lua', 'utf-8');
    const nodeApi = {
        node_type: "respondent",
        script_name: "respondent_node_api.lua",
        script_version: "v1.0",
        script_content: respondent_node_api
    };
    const data = JSON.stringify(nodeApi);
    const msgId = await loadApi(data);
    console.log(msgId);
    const dataValid = await getLatestApi("respondent");
    console.log(dataValid);
}

async function loadApi(data) {
    return await message({
        process: MAIN_NODE_ID,
        signer: createDataItemSigner(wallet),
        data: data,
        tags: [{ name: 'Action', value: 'InsertNodeScript' }],
    });

}

async function getLatestApi(node_type) {
    const data = {node_type: node_type};
    return await dryrun({
        process: MAIN_NODE_ID,
        data: JSON.stringify(data),
        tags: [{ name: 'Action', value: 'GetLatestNodeScript' }],
    });

}

async function getLatestSchemaManagement(node_type) {
    const data = {node_type: node_type};
    return await dryrun({
        process: MAIN_NODE_ID,
        data: JSON.stringify(data),
        tags: [{ name: 'Action', value: 'GetLatestSchemaManagement' }],
    });

}