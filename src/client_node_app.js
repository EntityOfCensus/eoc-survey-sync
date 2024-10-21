import {
    dryrun,
    createDataItemSigner,
    message,
    spawn
} from '@permaweb/aoconnect';
import dotenv from 'dotenv';

dotenv.config();

const wallet = JSON.parse(process.env.JWK);
const MAIN_NODE_ID = process.env.MAIN_NODE_ID;
const CLIENT_NODE_ID = (await getClientById("octavianstirbei@gmail.com")).node_id;

// Function to get the client by client_id
async function getClientById(client_id) {
    const txData = await dryrun({
        process: MAIN_NODE_ID,
        data: JSON.stringify({ client_id: client_id }),
        tags: [{ name: 'Action', value: 'GetClientById' }],
    });
    if (txData.Messages.length > 0) {
        try {
            const client = JSON.parse(txData.Messages[0].Data);
            console.log('Client', client);
            return client;
        } catch (error) {
            console.error('Error parsing client data:', error);
        }
    }
    return null;
}

// Function to create a tool instance
async function createToolInstance(node_id, clientToolId, instanceName, targetAgeRange, targetSex, targetGeolocation, deploymentDate, expirationDate) {
    const instance_data = {
        client_tool_id: clientToolId,
        instance_name: instanceName,
        target_age_range: targetAgeRange,
        target_sex: targetSex,
        target_geolocation: targetGeolocation,
        deployment_date: deploymentDate,
        expiration_date: expirationDate
    };
    try {
        const message_Id = await message({
            process: node_id,
            signer: createDataItemSigner(wallet),
            data: JSON.stringify(instance_data),
            tags: [
                { name: 'Action', value: 'CreateToolInstance' },
            ],
        });
        console.log('Tool instance created:', message_Id);
        return message_Id;
    } catch (error) {
        console.error('Error creating tool instance:', error);
    }
    return null;
}

// Function to update a tool instance
async function updateToolInstance(node_id, instanceId, instanceName, targetAgeRange, targetSex, targetGeolocation, deploymentDate, expirationDate) {
    const instance_data = {
        instance_id: instanceId,
        instance_name: instanceName,
        target_age_range: targetAgeRange,
        target_sex: targetSex,
        target_geolocation: targetGeolocation,
        deployment_date: deploymentDate,
        expiration_date: expirationDate
    };
    try {
        const message_Id = await message({
            process: node_id,
            signer: createDataItemSigner(wallet),
            data: JSON.stringify(instance_data),
            tags: [
                { name: 'Action', value: 'UpdateToolInstance' },
            ],
        });
        console.log('Tool instance updated:', message_Id);
    } catch (error) {
        console.error('Error updating tool instance:', error);
    }
}

// Function to delete a tool instance
async function deleteToolInstance(node_id, instanceId) {
    const instance_data = { instance_id: instanceId };
    try {
        const message_Id = await message({
            process: node_id,
            signer: createDataItemSigner(wallet),
            data: JSON.stringify(instance_data),
            tags: [
                { name: 'Action', value: 'DeleteToolInstance' },
            ],
        });
        console.log('Tool instance deleted:', message_Id);
    } catch (error) {
        console.error('Error deleting tool instance:', error);
    }
}

// Function to create a question
async function createQuestion(node_id, instanceId, clientCategoryId, questionText, questionType, orderNumber, additionalContext) {
    const question_data = {
        instance_id: instanceId,
        client_category_id: clientCategoryId,
        question_text: questionText,
        question_type: questionType,
        order_number: orderNumber,
        additional_context: additionalContext
    };
    try {
        const message_Id = await message({
            process: node_id,
            signer: createDataItemSigner(wallet),
            data: JSON.stringify(question_data),
            tags: [
                { name: 'Action', value: 'CreateQuestion' },
            ],
        });
        console.log('Question created:', message_Id);
    } catch (error) {
        console.error('Error creating question:', error);
    }
}

// Function to update a question
async function updateQuestion(node_id, clientQuestionId, clientCategoryId, questionText, questionType, orderNumber, additionalContext) {
    const question_data = {
        client_question_id: clientQuestionId,
        client_category_id: clientCategoryId,
        question_text: questionText,
        question_type: questionType,
        order_number: orderNumber,
        additional_context: additionalContext
    };
    try {
        const message_Id = await message({
            process: node_id,
            signer: createDataItemSigner(wallet),
            data: JSON.stringify(question_data),
            tags: [
                { name: 'Action', value: 'UpdateQuestion' },
            ],
        });
        console.log('Question updated:', message_Id);
    } catch (error) {
        console.error('Error updating question:', error);
    }
}

// Function to delete a question
async function deleteQuestion(node_id, clientQuestionId) {
    const question_data = { client_question_id: clientQuestionId };
    try {
        const message_Id = await message({
            process: node_id,
            signer: createDataItemSigner(wallet),
            data: JSON.stringify(question_data),
            tags: [
                { name: 'Action', value: 'DeleteQuestion' },
            ],
        });
        console.log('Question deleted:', message_Id);
    } catch (error) {
        console.error('Error deleting question:', error);
    }
}

// Function to deploy a tool instance to respondent nodes
async function deployToolInstance(node_id, instanceId, targetNodes) {
    const deploy_data = {
        instance_id: instanceId,
        target_nodes: targetNodes
    };
    try {
        const message_Id = await message({
            process: node_id,
            signer: createDataItemSigner(wallet),
            data: JSON.stringify(deploy_data),
            tags: [
                { name: 'Action', value: 'DeployToolInstance' },
            ],
        });
        console.log('Tool instance deployed:', message_Id);
    } catch (error) {
        console.error('Error deploying tool instance:', error);
    }
}

// Function to paginate tool instances
async function getClientToolInstances(node_id, page, size) {
    const txData = await dryrun({
        process: node_id,
        data: JSON.stringify({ page: page, size: size }),
        tags: [{ name: 'Action', value: 'PaginateToolInstances' }],
    });
    if (txData.Messages.length > 0) {
        try {
            const clientToolInstancesPageData = JSON.parse(txData.Messages[0].Data);
            return clientToolInstancesPageData;
        } catch (error) {
            console.error('Error parsing tool instances:', error);
        }
    }
    return [];
}

// Function to paginate tool instances
async function getClientToolInstanceDetail(node_id, instance_id) {
    const txData = await dryrun({
        process: node_id,
        data: JSON.stringify({ instance_id: instance_id }),
        tags: [{ name: 'Action', value: 'GetToolInstanceDetails' }],
    });
    if (txData.Messages.length > 0) {
        try {
            const clientToolInstanceData = JSON.parse(txData.Messages[0].Data);
            return clientToolInstanceData;
        } catch (error) {
            console.error('Error parsing tool instances:', error);
        }
    }
    return [];
}

// Example usage
(async () => {
    // Example: Creating a new tool instance
    const instance_id  = await createToolInstance(CLIENT_NODE_ID, 'tool_001', 'Survey 2024', '18-45', 'All', 'USA', '2024-01-01', '2024-12-31');
    
    // // Example: Creating a question
    // await createQuestion(CLIENT_NODE_ID, 'instance_001', 'category_001', 'What is your age?', 'multiple-choice', 1, null);
    
    // // Example: Updating a question
    // await updateQuestion(CLIENT_NODE_ID, 'question_001', 'category_001', 'What is your favorite color?', 'multiple-choice', 2, null);

    // // Example: Deleting a question
    // await deleteQuestion(CLIENT_NODE_ID, 'question_001');

    // // Example: Deploying a tool instance
    // await deployToolInstance(CLIENT_NODE_ID, 'instance_001', ['node_a', 'node_b']);

    // Get paginated tool instances
    const clientToolInstances = await getClientToolInstances(CLIENT_NODE_ID, 1, 10);
    console.log('Tool Instances', clientToolInstances);
    const clientToolInstance = await getClientToolInstanceDetail(CLIENT_NODE_ID, instance_id);
    console.log('Tool Instance', clientToolInstance);

})();
