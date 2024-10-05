import {
    dryrun,
    createDataItemSigner,
    message,
    connect,
  } from '@permaweb/aoconnect';
import dotenv from 'dotenv';

dotenv.config();

const wallet = JSON.parse(process.env.JWK);
const ao_process_id = process.env.FHE_PROCESS_ID
const ao_process_id2 = process.env.FHE_PROCESS_ID2


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


async function encryptIntegerValue(value) {
  try {
    console.log('encrypt value', value);
    const txIn = await dryrun({
      process: ao_process_id,
      tags: [
        { name: 'Action', value: 'EncryptIntegerValue' },
        { name: 'Val', value: value + '' },
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

await encryptIntegerValue(10);