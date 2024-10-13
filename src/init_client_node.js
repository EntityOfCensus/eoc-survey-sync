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

// await register2();
// const processId = await spawnClientNode();
// console.log('processId', processId);      

await InitClientApi();
// await getNodeScripts();

// await testLoadClientSurveyById("lgpdiT8p6qBYje9M02fyMfCZttRVoMDJsaxFCF4d1kA", "1")

async function InitClientApi() {
  const processId = await spawnClientNode();
  const txMainNodeReady = await canRegister();
  if(txMainNodeReady.Messages.length == 0) {
    await loadClientApi(processId);          
  } else if (txMainNodeReady.Messages[0].Data == "Ok") {
    await evalClientApi(processId);
  }
}

async function RegisterClientApi(processId) {
  await getNodeScripts();

  console.log('processId', processId);      
  const messageId =  await register(processId, "test_" + processId);

  const txIn = await dryrun({
    process: processId,
    tags: [
      { name: 'Action', value: 'GetSurveyDetails' },
      { name: 'survey_id', value: "1" },
    ],
  });


      console.log('txIn', txIn);
      const survey_id = await testLoadClientSurvey(processId);
      await testLoadClientSurveyById(processId, "1");
    //   await getNodeScripts();
}


async function testLoadClientSurvey(processId) {
  const survey_test = fs.readFileSync('./src/example/survey.test.json', 'utf-8');
  console.log(survey_test);
  const messageId = await message({
      process: processId,
      signer: createDataItemSigner(wallet),
      // the survey as stringified JSON
      data: survey_test,
      tags: [{ name: 'Action', value: 'CreateSurvey' }],
  });

  console.log(messageId);
  
}

async function testLoadClientSurveyById(processId, survey_id) {
  const txSurveyData =  await dryrun({
    process: processId,
    tags: [
        { name: 'Action', value: 'GetSurveyDetails' },
        { name: 'survey_id', value: survey_id },
    ],
  });
  if(txSurveyData.Messages.length > 0) {
    console.log(txSurveyData.Messages[0].Data);
  }
}


async function spawnClientNode() {
  return await spawn({
    // The Arweave TXID of the ao Module
    module: "GYrbbe0VbHim_7Hi6zrOpHQXrSQz07XNtwCnfbFo2I0",
    // The Arweave wallet address of a Scheduler Unit
    scheduler: "TZ7o7SIZ06ZEJ14lXwVtng1EtSx60QkPy-kh-kdAXog",
    // A signer function containing your wallet
    signer: createDataItemSigner(wallet),
    /*
      Refer to a Processes' source code or documentation
      for tags that may effect its computation.
    */
    tags: [
      { name: "Authority", value: "fcoN_xJeisVsPXA-trzVAuIiqO3ydLQxM-L4XbrQKzY" },
      { name: "Name", value: "survey-sync" },
      { name: "aos-Version", value: "2.0.0"},
      { name: "App-Name", value: "aos"}
    ],
  });
}

async function loadClientApi(processId) {
    const clientApi = {
        node_type: "client",
        script_name: "client_node_api.lua",
        script_version: "v1.0",
        script_content: await evalClientApi(processId)
    };
    const data = JSON.stringify(clientApi);
    const loadApiMessageId = await message({
        process: MAIN_NODE_ID,
        signer: createDataItemSigner(wallet),
        // the survey as stringified JSON
        data: data,
        tags: [{ name: 'Action', value: 'LoadApi' }],
    });

    console.log(loadApiMessageId);
}

async function evalClientApi(processId) {
  const code = fs.readFileSync('./process/client_node_api.lua', 'utf-8');
  console.log(code);
  setTimeout(async function (){
    await message({
      process: processId,
      signer: createDataItemSigner(wallet),
      // the survey as stringified JSON
      data: code,
      tags: [{ name: 'Action', value: 'Eval' }],
    });  
    await RegisterClientApi(processId);
  } , 2000);
  return code;
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
  const message_Id = await message({
    process: MAIN_NODE_ID,
    signer: createDataItemSigner(wallet),
    data: JSON.stringify({process_id: processId, name: name}),
    tags: [
        { name: 'Action', value: 'RegisterClient' },
    ],
  });
  const schemaSql=  await getSchemaManagement();
  if(schemaSql) {
    const updateSchemaMessageId = await message({
      process: processId,
      signer: createDataItemSigner(wallet),
      data: schemaSql,
      tags: [
          { name: 'Action', value: 'UpdateSchema' },
      ],
    });
    console.log('updateSchemaMessageId', updateSchemaMessageId);
  }
return message_Id;
}

async function register2() {
const tx=  await dryrun({
    process: MAIN_NODE_ID,
    // signer: createDataItemSigner(wallet),
    // // the survey as stringified JSON
    // data: JSON.stringify({process_id: processId}),
    tags: [
        { name: 'Action', value: 'RegisterClient' },
    ],
});
  return tx;
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
          { name: 'node_type', value: "client" },
        ],
      });
      const data = txIn.Messages[0].Data + '';
      console.log(data);
      return data;
    } catch (error) {
      console.log(error);
      return null;
    }
}
