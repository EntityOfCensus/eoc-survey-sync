import {
    dryrun,
    createDataItemSigner,
    message,
    spawn
  } from '@permaweb/aoconnect';
import dotenv from 'dotenv';

dotenv.config();


const wallet = JSON.parse(process.env.JWK);
const MAIN_NODE_ID = process.env.MAIN_NODE_ID

await InitClientApi("octavianstirbei@gmail.com", "Octavian Stirbei", onClientNodeReady);

async function InitClientApi(client_id, client_name, callback) {
  var isReady = false;
  const txData = await dryrun({
    process: MAIN_NODE_ID,
    data: JSON.stringify({client_id: client_id}),
    tags: [{ name: 'Action', value: 'GetClientById' }],
  });
  if(txData.Messages.length > 0) {
    try {
      const client = JSON.parse(txData.Messages[0].Data);
      console.log(client);
      isReady = true;
      callback(client.node_id);  
    }catch(error) {

    } 
  } 
  
  if(!isReady){
    const processId = await spawnClientNode();
    console.log('spawnClientNode', processId);
    await InitClientNodeApi(processId, client_id, client_name, callback);  
  }
}

async function onClientNodeReady(processId) {
  console.log('clientReady', processId);
}

async function InitClientNodeApi(processId, client_id, client_name, callback) {
  const latestApi = await getLatestApi("client");
  if(latestApi && latestApi.script_content) {
    setTimeout(async function (){
      await message({
        process: processId,
        signer: createDataItemSigner(wallet),
        // the survey as stringified JSON
        data: latestApi.script_content,
        tags: [{ name: 'Action', value: 'Eval' }],
      });  
      await RegisterClientApi(processId, client_id, client_name, callback);
    } , 5000);
  
  }
}

async function getLatestApi(node_type) {
  const data = {node_type: node_type};
  const txData =  await dryrun({
      process: MAIN_NODE_ID,
      data: JSON.stringify(data),
      tags: [{ name: 'Action', value: 'GetLatestNodeScript' }],
  });
  if(txData.Messages.length > 0) {
    const scriptJson = JSON.parse(txData.Messages[0].Data);
    return scriptJson;
  }
  return null;
}

async function getLatestSchemaManagement(node_type) {
  const data = {node_type: node_type};
  const txData =   await dryrun({
      process: MAIN_NODE_ID,
      data: JSON.stringify(data),
      tags: [{ name: 'Action', value: 'GetLatestSchemaManagement' }],
  });
  if(txData.Messages.length > 0) {
    const sqlJson = JSON.parse(txData.Messages[0].Data);
    return sqlJson;
  }
  return null;
}

async function RegisterClientApi(processId, client_id, client_name, callback) {
  console.log('RegisterClientApi', processId)
  const schemaSql = await getLatestSchemaManagement("client");
  if(schemaSql && schemaSql.schema_sql)
  await initSchemaSql(processId, schemaSql.schema_sql);
  await register(processId, schemaSql.schema_version, client_id, client_name);
  callback(processId);
}

async function initSchemaSql(processId, schemaSql) {
  await message({
    process: processId,
    signer: createDataItemSigner(wallet),
    // the survey as stringified JSON
    data: schemaSql,
    tags: [{ name: 'Action', value: 'InitDb' }],
  });  
}

async function spawnClientNode() {
  return await spawn({
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
      { name: "Name", value: "survey-sync-abc-test" },
    ],
  });
}

async function register(node_id, schema_version, client_id, client_name) {
  const message_Id = await message({
    process: MAIN_NODE_ID,
    signer: createDataItemSigner(wallet),
    data: JSON.stringify({node_id: node_id, client_id: client_id, client_name: client_name, schema_version: schema_version}),
    tags: [
        { name: 'Action', value: 'CreateClient' },
    ],
  });
  return message_Id;
}