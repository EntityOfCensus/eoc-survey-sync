import {
    dryrun,
    createDataItemSigner,
    message,
    connect,
  } from '@permaweb/aoconnect';
import dotenv from 'dotenv';

dotenv.config();

const wallet = JSON.parse(process.env.JWK);
const ao_process_id = process.env.MAIN_NODE_ID


async function getSchemaManagement() {
    try {
      const txIn = await dryrun({
        process: ao_process_id,
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

await getSchemaManagement();  
