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

await InitRespondentApi("octavianstirbei@gmail.com", "Octavian Stirbei", "41", "M", "RO - Buc", "octavianstirbei@gmail.com", onRespondentNodeReady);

async function InitRespondentApi(respondent_id, respondent_name, age, sex, geolocation, email, callback) {
  var isReady = false;
  const txData = await dryrun({
    process: MAIN_NODE_ID,
    data: JSON.stringify({respondent_id: respondent_id}),
    tags: [{ name: 'Action', value: 'GetRespondentById' }],
  });
  if(txData.Messages.length > 0) {
    try {
      const respondent = JSON.parse(txData.Messages[0].Data);
      console.log(respondent);
      isReady = true;
      callback(respondent.node_id);  
    }catch(error) {

    } 
  } 
  
  if(!isReady){
    const processId = await spawnRespondentNode();
    console.log('spawnRespondentNode', processId);
    await InitRespondentNodeApi(processId, respondent_id, respondent_name, age, sex, geolocation, email, callback);  
  }
}

async function onRespondentNodeReady(processId) {
  console.log('respondentReady', processId);
}

async function InitRespondentNodeApi(processId, respondent_id, respondent_name, age, sex, geolocation, email, callback) {
  const latestApi = await getLatestApi("respondent");
  if(latestApi && latestApi.script_content) {
    setTimeout(async function (){
      await message({
        process: processId,
        signer: createDataItemSigner(wallet),
        // the survey as stringified JSON
        data: latestApi.script_content,
        tags: [{ name: 'Action', value: 'Eval' }],
      });  
      await RegisterRespondentApi(processId, respondent_id, respondent_name, age, sex, geolocation, email, callback);
    } , 2000);
  
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

async function RegisterRespondentApi(processId, respondent_id, respondent_name, age, sex, geolocation, email, callback) {
  console.log('RegisterRespondentApi', processId)
  const schemaSql = await getLatestSchemaManagement("respondent");
  if(schemaSql && schemaSql.schema_sql)
  await initSchemaSql(processId, schemaSql.schema_sql);
  await register(processId, schemaSql.schema_version, respondent_id, respondent_name, age, sex, geolocation, email);
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

async function spawnRespondentNode() {
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

async function register(node_id, schema_version, respondent_id, respondent_name, age, sex, geolocation, email) {
  const message_Id = await message({
    process: MAIN_NODE_ID,
    signer: createDataItemSigner(wallet),
    data: JSON.stringify({node_id: node_id, respondent_id: respondent_id, respondent_name: respondent_name, age: age, sex: sex, geolocation: geolocation, email: email, schema_version: schema_version}),
    tags: [
        { name: 'Action', value: 'CreateRespondent' },
    ],
  });
  return message_Id;
}