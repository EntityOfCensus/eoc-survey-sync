import {
    dryrun,
    createDataItemSigner,
    message,
    connect,
    spawn
  } from '@permaweb/aoconnect';
import dotenv from 'dotenv';
import fs from 'fs';

dotenv.config();

const wallet = JSON.parse(process.env.JWK);
const MAIN_NODE_ID = process.env.MAIN_NODE_ID

await InitClientApi();
await getNodeScripts();

async function InitClientApi() {
    const txMainNodeReady = await canRegister();
      if(txMainNodeReady.Messages.length == 0) {
        await loadClientApi();          
      } 

      const processId = await spawn({
        // The Arweave TXID of the ao Module
        module: "GYrbbe0VbHim_7Hi6zrOpHQXrSQz07XNtwCnfbFo2I0",
        // The Arweave wallet address of a Scheduler Unit
        scheduler: "_GQ33BkPtZrqxA84vM8Zk-N2aO0toNNu_C-l-rawrBA",
        // A signer function containing your wallet
        signer: createDataItemSigner(wallet),
        /*
          Refer to a Processes' source code or documentation
          for tags that may effect its computation.
        */
        tags: [
          { name: "Client_API", value: "v1.0" },
          { name: "Name", value: "survey-sync" },
        ],
      });
      console.log('processId', processId);      
      const messageId =  await register(processId, "test_"+processId);
      console.log('messageId', messageId);
    //   await getNodeScripts();
}

async function loadClientApi() {
    const code = fs.readFileSync('./process/client_node_api.lua', 'utf-8');
    console.log(code);
    const clientApi = {
        node_type: "client",
        script_name: "client_node_api.lua",
        script_version: "v1.0",
        script_content: code
    };
    const data = JSON.stringify(clientApi);
    const messageId = await message({
        process: MAIN_NODE_ID,
        signer: createDataItemSigner(wallet),
        // the survey as stringified JSON
        data: data,
        tags: [{ name: 'Action', value: 'LoadApi' }],
    });

    console.log(messageId);
}

async function canRegister() {
    return await dryrun({
        process: MAIN_NODE_ID,
        tags: [
            { name: 'Action', value: 'CanRegister' },
            { name: 'node_type', value: "client" },
        ],
    });
}

async function register(processId, name) {
    return await message({
        process: MAIN_NODE_ID,
        signer: createDataItemSigner(wallet),
        // the survey as stringified JSON
        data: JSON.stringify({process_id: processId, name: name}),
        tags: [
            { name: 'Action', value: 'RegisterClient' },
        ],
    });
}

async function getNodeScripts() {
    try {
      const txIn = await dryrun({
        process: MAIN_NODE_ID,
        tags: [
          { name: 'Action', value: 'GetNodeScripts' },
          { name: 'node_type', value: "client" },
        ],
      });
      const data = txIn.Messages[0].Data + '';
      console.log(data);
      return data;
    } catch (error) {
      console.log(error);
      return {};
    }
}

async function getSchemaManagement() {
    try {
      const txIn = await dryrun({
        process: MAIN_NODE_ID,
        tags: [
          { name: 'Action', value: 'GetSchemaManagement' },
        ],
      });
      const data = txIn.Messages[0].Data + '';
      console.log(data);
      return data;
    } catch (error) {
      console.log(error);
      return {};
    }
}
