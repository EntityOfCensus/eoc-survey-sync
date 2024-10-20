--[[
    Imports -- Required Libraries
]] --

local json = require("json")
local ao = require("ao")
local sqlite3 = require("lsqlite3")

-- Open the database
local db = db or sqlite3.open_memory()

-- Nodes Table Definition
NODES = [[
  CREATE TABLE IF NOT EXISTS Nodes (
    node_id TEXT PRIMARY KEY,    -- String ID
    node_type TEXT NOT NULL,     -- Type of node (main, client, respondent)
    node_status TEXT NOT NULL,   -- Status of the node (e.g., active, inactive)
    node_version TEXT NOT NULL,  -- Version of the node's schema
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );
]]

-- Clients Table Definition
CLIENTS = [[
  CREATE TABLE IF NOT EXISTS Clients (
    client_id TEXT PRIMARY KEY,    -- String ID
    node_id TEXT NOT NULL,         -- Associated node ID (not enforced with a foreign key in distributed setup)
    client_name TEXT NOT NULL,
    schema_version TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );
]]

-- Tools Table Definition
TOOLS = [[
  CREATE TABLE IF NOT EXISTS Tools (
    tool_id TEXT PRIMARY KEY,      -- String ID
    client_id TEXT NOT NULL,       -- Link to Clients (client_id), managed by the app
    tool_type TEXT NOT NULL,       -- Tool type (e.g., "survey", "poll", etc.)
    tool_name TEXT NOT NULL,
    description TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );
]]

-- StandardCategories Table Definition
STANDARD_CATEGORIES = [[
  CREATE TABLE IF NOT EXISTS StandardCategories (
    category_id TEXT PRIMARY KEY,  -- String ID
    category_name TEXT NOT NULL,   -- Name of the category
    tool_type TEXT NOT NULL,       -- Specifies which tool type (e.g., survey, form, poll) this category applies to
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );
]]

-- StandardQuestions Table Definition
STANDARD_QUESTIONS = [[
  CREATE TABLE IF NOT EXISTS StandardQuestions (
    question_id TEXT PRIMARY KEY,  -- String ID
    category_id TEXT NOT NULL,     -- Link to StandardCategories (managed by app logic)
    question_text TEXT NOT NULL,   -- The text of the standard question
    question_type TEXT NOT NULL,   -- e.g., "multiple-choice", "single-choice", etc.
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );
]]

-- StandardAnswerOptions Table Definition
STANDARD_ANSWER_OPTIONS = [[
  CREATE TABLE IF NOT EXISTS StandardAnswerOptions (
    option_id TEXT PRIMARY KEY,    -- String ID
    question_id TEXT NOT NULL,     -- Link to StandardQuestions (managed by app logic)
    answer_text TEXT NOT NULL,     -- The text of the answer option
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );
]]

-- AdvancedTargetGroupCriteria Table Definition
ADVANCED_TARGET_GROUP_CRITERIA = [[
  CREATE TABLE IF NOT EXISTS AdvancedTargetGroupCriteria (
    criteria_id TEXT PRIMARY KEY,   -- String ID
    tool_id TEXT NOT NULL,          -- Link to Tools (tool_id), managed by app logic
    target_criteria TEXT NOT NULL,  -- Criteria for targeting (e.g., "age:18-25")
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );
]]

-- Respondents Table Definition
RESPONDENTS = [[
  CREATE TABLE IF NOT EXISTS Respondents (
    respondent_id TEXT PRIMARY KEY,   -- String ID
    node_id TEXT NOT NULL,            -- Associated node ID (managed by app logic)
    respondent_name TEXT NOT NULL,
    age INTEGER,
    sex TEXT,
    geolocation TEXT,
    email TEXT,
    schema_version TEXT NOT NULL,     -- Track schema version for respondent
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );
]]

-- RespondentTools Table Definition
RESPONDENT_TOOLS = [[
  CREATE TABLE IF NOT EXISTS RespondentTools (
    respondent_tool_id TEXT PRIMARY KEY,   -- String ID
    respondent_id TEXT NOT NULL,           -- Link to Respondents (managed by app logic)
    tool_id TEXT NOT NULL,                 -- Link to Tools (managed by app logic)
    last_participation_date DATETIME,
    participation_count INTEGER DEFAULT 0, -- Tracks how many times the respondent has participated
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );
]]

-- SchemaManagement Table Definition
SCHEMA_MANAGEMENT = [[
  CREATE TABLE IF NOT EXISTS SchemaManagement (
    schema_id TEXT PRIMARY KEY,     -- String ID
    schema_version TEXT NOT NULL,   -- Version of the schema
    node_type TEXT NOT NULL,        -- Type of node (e.g., "client", "respondent")
    schema_sql TEXT NOT NULL,       -- SQL that defines the schema
    description TEXT,               -- Description of the schema update
    applied_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );
]]

-- NodeScripts Table Definition
NODE_SCRIPTS = [[
  CREATE TABLE IF NOT EXISTS NodeScripts (
    script_id TEXT PRIMARY KEY,    -- String ID
    node_type TEXT NOT NULL,       -- Node type (client/respondent)
    script_name TEXT NOT NULL,     -- Name of the script
    script_version TEXT NOT NULL,  -- Version of the script
    script_content TEXT NOT NULL,  -- The Lua script content
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );
]]

-- ClientToolInstances Table Definition (No cross-node foreign key)
CLIENT_TOOL_INSTANCES = [[
  CREATE TABLE IF NOT EXISTS ClientToolInstances (
    instance_id TEXT PRIMARY KEY,    -- String ID
    client_tool_id TEXT NOT NULL,    -- Link to Tools (in Main Node) managed via app logic
    instance_name TEXT NOT NULL,
    target_age_range TEXT,
    target_sex TEXT,
    target_geolocation TEXT,
    deployment_date DATETIME,
    expiration_date DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );
]]

-- ClientCategories Table Definition (No cross-node foreign key)
CLIENT_CATEGORIES = [[
  CREATE TABLE IF NOT EXISTS ClientCategories (
    client_category_id TEXT PRIMARY KEY,   -- String ID
    instance_id TEXT NOT NULL,             -- Link to ClientToolInstances
    category_id TEXT NOT NULL,             -- Link to StandardCategories (in Main Node) managed via app logic
    FOREIGN KEY (instance_id) REFERENCES ClientToolInstances(instance_id)
  );
]]

-- ClientQuestions Table Definition
CLIENT_QUESTIONS = [[
  CREATE TABLE IF NOT EXISTS ClientQuestions (
    client_question_id TEXT PRIMARY KEY,   -- String ID
    instance_id TEXT NOT NULL,             -- Link to ClientToolInstances
    client_category_id TEXT,               -- Optional Link to ClientCategories (nullable)
    question_text TEXT NOT NULL,
    question_type TEXT NOT NULL,           -- e.g., "multiple-choice", "single-choice", etc.
    order_number INTEGER,
    additional_context TEXT,
    FOREIGN KEY (instance_id) REFERENCES ClientToolInstances(instance_id)
  );
]]

-- ClientAnswerOptions Table Definition
CLIENT_ANSWER_OPTIONS = [[
  CREATE TABLE IF NOT EXISTS ClientAnswerOptions (
    answer_option_id TEXT PRIMARY KEY,    -- String ID
    client_question_id TEXT NOT NULL,     -- Link to ClientQuestions
    answer_text TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (client_question_id) REFERENCES ClientQuestions(client_question_id)
  );
]]

-- ClientResponses Table Definition
CLIENT_RESPONSES = [[
  CREATE TABLE IF NOT EXISTS ClientResponses (
    response_id TEXT PRIMARY KEY,     -- String ID
    instance_id TEXT NOT NULL,        -- Link to ClientToolInstances
    respondent_id TEXT NOT NULL,      -- Link to Respondents (managed by app logic, in Main Node)
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (instance_id) REFERENCES ClientToolInstances(instance_id)
  );
]]

-- RespondentAnswers Table Definition
RESPONDENT_ANSWERS = [[
  CREATE TABLE IF NOT EXISTS RespondentAnswers (
    answer_id TEXT PRIMARY KEY,    -- String ID
    response_id TEXT NOT NULL,     -- Link to ClientResponses (in Client Node)
    client_question_id TEXT NOT NULL, -- Link to ClientQuestions (in Client Node)
    selected_option_id TEXT,       -- Link to ClientAnswerOptions (in Client Node)
    answer_text TEXT,              -- For open-ended questions
    answered_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (response_id) REFERENCES ClientResponses(response_id),
    FOREIGN KEY (client_question_id) REFERENCES ClientQuestions(client_question_id),
    FOREIGN KEY (selected_option_id) REFERENCES ClientAnswerOptions(answer_option_id)
  );
]]

-- VotingRecords Table Definition
VOTING_RECORDS = [[
  CREATE TABLE IF NOT EXISTS VotingRecords (
    vote_id TEXT PRIMARY KEY,        -- String ID
    respondent_id TEXT NOT NULL,     -- Link to Respondents (in Main Node, managed via app logic)
    tool_id TEXT NOT NULL,           -- Link to Tools (in Main Node, managed via app logic)
    selected_option_id TEXT,         -- Link to ClientAnswerOptions (in Client Node)
    voted_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );
]]

-- FormSubmissions Table Definition
FORM_SUBMISSIONS = [[
  CREATE TABLE IF NOT EXISTS FormSubmissions (
    submission_id TEXT PRIMARY KEY,    -- String ID
    respondent_id TEXT NOT NULL,       -- Link to Respondents (managed by app logic, in Main Node)
    instance_id TEXT NOT NULL,         -- Link to ClientToolInstances (in Client Node)
    client_category_id TEXT,           -- Link to ClientCategories (nullable)
    submission_data TEXT NOT NULL,     -- JSON or other format
    submitted_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (instance_id) REFERENCES ClientToolInstances(instance_id)
  );
]]

-- Function to Initialize the Database
function InitDb()
  local initial_main_schema_sql = NODES .. CLIENTS .. TOOLS .. STANDARD_CATEGORIES .. STANDARD_QUESTIONS .. STANDARD_ANSWER_OPTIONS .. ADVANCED_TARGET_GROUP_CRITERIA .. RESPONDENTS .. RESPONDENT_TOOLS .. SCHEMA_MANAGEMENT .. NODE_SCRIPTS
  db:exec(initial_main_schema_sql)
  InsertSchemaManagement("init_main_node", "v1.0", "main", initial_main_schema_sql, "Initial schema for main AO process")

  local initial_client_schema_sql = CLIENT_TOOL_INSTANCES .. CLIENT_CATEGORIES .. CLIENT_QUESTIONS .. CLIENT_ANSWER_OPTIONS .. CLIENT_RESPONSES
  InsertSchemaManagement("init_client_node", "v1.0", "client", initial_client_schema_sql, "Initial schema for client AO process")

  local initial_respondent_schema_sql = RESPONDENT_ANSWERS .. VOTING_RECORDS .. FORM_SUBMISSIONS
  InsertSchemaManagement("init_respondent_node", "v1.0", "respondent", initial_respondent_schema_sql, "Initial schema for respondent AO process")
   
end

-- Utility Functions

function InsertNode(node_id, node_type, node_status, node_version)
  -- Insert the node information into the Nodes table
  local stmt = db:prepare([[
      INSERT INTO Nodes (node_id, node_type, node_status, node_version) 
      VALUES (?, ?, ?, ?)
  ]])
  stmt:bind_values(node_id, node_type, node_status, node_version)
  stmt:step()
  stmt:finalize()

  return "Node inserted"
end

-- Function to insert a new client
function InsertClient(client_id, node_id, client_name, schema_version)
  local stmt = db:prepare([[
      INSERT INTO Clients (client_id, node_id, client_name, schema_version)
      VALUES (?, ?, ?, ?)
  ]])
  stmt:bind_values(client_id, node_id, client_name, schema_version)
  stmt:step()
  stmt:finalize()
end

-- Function to update a client's information
function UpdateClient(client_id, client_name, schema_version)
  local stmt = db:prepare([[
      UPDATE Clients
      SET client_name = ?, schema_version = ?
      WHERE client_id = ?
  ]])
  stmt:bind_values(client_name, schema_version, client_id)
  stmt:step()
  stmt:finalize()
end

-- Function to delete a client
function DeleteClient(client_id)
  local stmt = db:prepare([[ DELETE FROM Clients WHERE client_id = ? ]])
  stmt:bind_values(client_id)
  stmt:step()
  stmt:finalize()
end

-- Function to get a client by client_id
function GetClientById(client_id)
  local stmt = db:prepare([[
      SELECT client_id, node_id, client_name, schema_version, created_at 
      FROM Clients 
      WHERE client_id = ?
  ]])
  stmt:bind_values(client_id)
  local result = stmt:step()

  -- Initialize client data structure
  local client_data = {}

  -- If a result is found, populate the client_data table
  if result == sqlite3.ROW then
      client_data = {
          client_id = stmt:get_value(0),
          node_id = stmt:get_value(1),
          client_name = stmt:get_value(2),
          schema_version = stmt:get_value(3),
          created_at = stmt:get_value(4)
      }
  end

  stmt:finalize()

  -- Return the client data if found, otherwise return nil
  return client_data
end

-- Function to insert a new respondent
function InsertRespondent(respondent_id, node_id, respondent_name, age, sex, geolocation, email, schema_version)
  local stmt = db:prepare([[
      INSERT INTO Respondents (respondent_id, node_id, respondent_name, age, sex, geolocation, email, schema_version)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
  ]])
  stmt:bind_values(respondent_id, node_id, respondent_name, age, sex, geolocation, email, schema_version)
  stmt:step()
  stmt:finalize()
  return "Respondent inserted"
end

-- Function to update an existing respondent
function UpdateRespondent(respondent_id, respondent_name, age, sex, geolocation, email, schema_version)
  local stmt = db:prepare([[
      UPDATE Respondents
      SET respondent_name = ?, age = ?, sex = ?, geolocation = ?, email = ?, schema_version = ?
      WHERE respondent_id = ?
  ]])
  stmt:bind_values(respondent_name, age, sex, geolocation, email, schema_version, respondent_id)
  stmt:step()
  stmt:finalize()
  return "Respondent updated"
end

-- Function to delete a respondent
function DeleteRespondent(respondent_id)
  local stmt = db:prepare([[ DELETE FROM Respondents WHERE respondent_id = ? ]])
  stmt:bind_values(respondent_id)
  stmt:step()
  stmt:finalize()
  return "Respondent deleted"
end

-- Function to get a respondent by respondent_id
function GetRespondentById(respondent_id)
  local stmt = db:prepare([[
      SELECT respondent_id, node_id, respondent_name, age, sex, geolocation, email, schema_version, created_at
      FROM Respondents
      WHERE respondent_id = ?
  ]])
  stmt:bind_values(respondent_id)
  local result = stmt:step()

  local respondent_data = {}
  if result == sqlite3.ROW then
      respondent_data = {
          respondent_id = stmt:get_value(0),
          node_id = stmt:get_value(1),
          respondent_name = stmt:get_value(2),
          age = stmt:get_value(3),
          sex = stmt:get_value(4),
          geolocation = stmt:get_value(5),
          email = stmt:get_value(6),
          schema_version = stmt:get_value(7),
          created_at = stmt:get_value(8)
      }
  end

  stmt:finalize()
  return respondent_data
end

-- Function to insert a new tool
function InsertTool(tool_id, client_id, tool_type, tool_name, description)
  local stmt = db:prepare([[
      INSERT INTO Tools (tool_id, client_id, tool_type, tool_name, description)
      VALUES (?, ?, ?, ?, ?)
  ]])
  stmt:bind_values(tool_id, client_id, tool_type, tool_name, description)
  stmt:step()
  stmt:finalize()
end

-- Function to insert a standard category
function InsertStandardCategory(category_id, category_name, tool_type)
  local stmt = db:prepare([[
      INSERT INTO StandardCategories (category_id, category_name, tool_type)
      VALUES (?, ?, ?)
  ]])
  stmt:bind_values(category_id, category_name, tool_type)
  stmt:step()
  stmt:finalize()
end

-- Function to insert standard answer options for a category
function InsertStandardAnswerOption(option_id, category_id, answer_text)
  local stmt = db:prepare([[
      INSERT INTO StandardAnswerOptions (option_id, category_id, answer_text)
      VALUES (?, ?, ?)
  ]])
  stmt:bind_values(option_id, category_id, answer_text)
  stmt:step()
  stmt:finalize()
end

-- Function to get all tools for a client
function GetToolsForClient(client_id)
  local stmt = db:prepare([[
      SELECT * FROM Tools WHERE client_id = ?
  ]])
  stmt:bind_values(client_id)
  local result = stmt:step()
  local tools = {}

  while result == sqlite3.ROW do
      table.insert(tools, {
          tool_id = stmt:get_value(0),
          client_id = stmt:get_value(1),
          tool_type = stmt:get_value(2),
          tool_name = stmt:get_value(3),
          description = stmt:get_value(4)
      })
      result = stmt:step()
  end

  stmt:finalize()
  return tools
end

-- Function to get standard categories
function GetStandardCategories(tool_type)
  local stmt = db:prepare([[
      SELECT * FROM StandardCategories WHERE tool_type = ?
  ]])
  stmt:bind_values(tool_type)
  local result = stmt:step()
  local categories = {}

  while result == sqlite3.ROW do
      table.insert(categories, {
          category_id = stmt:get_value(0),
          category_name = stmt:get_value(1),
          tool_type = stmt:get_value(2)
      })
      result = stmt:step()
  end

  stmt:finalize()
  return categories
end

-- Function to update schema management table
function InsertSchemaManagement(schema_id, schema_version, node_type, schema_sql, description)
  local stmt = db:prepare([[
      INSERT INTO SchemaManagement (schema_id, schema_version, node_type, schema_sql, description)
      VALUES (?, ?, ?, ?, ?)
  ]])
  stmt:bind_values(schema_id, schema_version, node_type, schema_sql, description)
  stmt:step()
  stmt:finalize()
end

-- Function to get the latest schema management record for a node type
function GetLatestSchemaManagement(node_type)
  local stmt = db:prepare([[
      SELECT * FROM SchemaManagement
      WHERE node_type = ?
      ORDER BY schema_version DESC
      LIMIT 1
  ]])
  stmt:bind_values(node_type)
  local result = stmt:step()
  local schema = {}

  if result == sqlite3.ROW then
      schema = {
          schema_id = stmt:get_value(0),
          schema_version = stmt:get_value(1),
          node_type = stmt:get_value(2),
          schema_sql = stmt:get_value(3),
          description = stmt:get_value(4),
          applied_at = stmt:get_value(5)
      }
  end

  stmt:finalize()
  return schema
end

-- Function to insert or update a node script in the NodeScripts table
function InsertNodeScript(script_id, node_type, script_name, script_version, script_content)
  -- First, check if a script with the same node_type and script_name already exists
  local stmt = db:prepare([[
      SELECT COUNT(*) FROM NodeScripts WHERE node_type = ? AND script_name = ?
  ]])
  stmt:bind_values(node_type, script_name)
  local result = stmt:step()
  local count = stmt:get_value(0)
  stmt:finalize()

  if count > 0 then
      -- If the script exists, update the existing record
      local update_stmt = db:prepare([[
          UPDATE NodeScripts 
          SET script_version = ?, script_content = ?, created_at = CURRENT_TIMESTAMP 
          WHERE node_type = ? AND script_name = ?
      ]])
      update_stmt:bind_values(script_version, script_content, node_type, script_name)
      update_stmt:step()
      update_stmt:finalize()
      return "Script updated"
  else
      -- If the script does not exist, insert a new record
      local insert_stmt = db:prepare([[
          INSERT INTO NodeScripts (script_id, node_type, script_name, script_version, script_content) 
          VALUES (?, ?, ?, ?, ?)
      ]])
      insert_stmt:bind_values(script_id, node_type, script_name, script_version, script_content)
      insert_stmt:step()
      insert_stmt:finalize()
      return "Script inserted"
  end
end

-- Function to get the latest node script by node_type
function GetLatestNodeScript(node_type)
  -- Query to get the latest script for the given node_type by the latest version
  local stmt = db:prepare([[
      SELECT script_id, script_name, script_version, script_content 
      FROM NodeScripts 
      WHERE node_type = ?
      ORDER BY script_version DESC
      LIMIT 1
  ]])
  stmt:bind_values(node_type)
  local result = stmt:step()

  -- Initialize the script data structure
  local script_data = {}

  -- If a result is found, populate the script_data table
  if result == sqlite3.ROW then
      script_data = {
          script_id = stmt:get_value(0),
          script_name = stmt:get_value(1),
          script_version = stmt:get_value(2),
          script_content = stmt:get_value(3)
      }
  end

  stmt:finalize()

  -- Return the script data if found, or return nil
  return script_data
end

InitDb()

-- Handler Definitions

-- Define the InsertNodeScript handler
Handlers.add(
    "InsertNodeScript",
    Handlers.utils.hasMatchingTag("Action", "InsertNodeScript"),
    function(msg)
        -- Decode the incoming JSON message
        local script_data = json.decode(msg.Data)

        -- Call the InsertNodeScript function to insert or update the script
        local result = InsertNodeScript(
            msg.id,
            script_data.node_type,
            script_data.script_name,
            script_data.script_version,
            script_data.script_content
        )

        -- Send a response back to the caller
        ao.send({
            Target = msg.From,
            Data = result
        })
    end
)

-- Define the GetLatestNodeScript handler
Handlers.add(
    "GetLatestNodeScript",
    Handlers.utils.hasMatchingTag("Action", "GetLatestNodeScript"),
    function(msg)
        -- Decode the incoming JSON message
        local script_request = json.decode(msg.Data)

        -- Call the GetLatestNodeScript function to fetch the latest script
        local script_data = GetLatestNodeScript(script_request.node_type)

        -- If a script is found, send it back; otherwise, send an error message
        if script_data and next(script_data) then
            ao.send({
                Target = msg.From,
                Data = json.encode(script_data)
            })
        else
            ao.send({
                Target = msg.From,
                Data = "No script found for node_type: " .. script_request.node_type
            })
        end
    end
)

-- Define the CreateClient action handler
Handlers.add(
    "CreateClient",
    Handlers.utils.hasMatchingTag("Action", "CreateClient"),
    function(msg)
        -- Decode the incoming JSON message
        local client_data = json.decode(msg.Data)

        -- Insert a new node record for the client
        local node_id = client_data.node_id
        local node_type = "client"
        local node_status = "active"
        local node_version = client_data.schema_version

        -- Insert the node into the Nodes table
        InsertNode(node_id, node_type, node_status, node_version)

        -- Insert the client into the Clients table
        InsertClient(
            client_data.client_id,
            node_id,
            client_data.client_name,
            client_data.schema_version
        )

        -- Send a response back to the caller
        ao.send({
            Target = msg.From,
            Data = "Client and Node inserted successfully"
        })
    end
)

-- UpdateClient Handler: Update client details
Handlers.add(
  "UpdateClient",
  Handlers.utils.hasMatchingTag("Action", "UpdateClient"),
  function(msg)
      local client_data = json.decode(msg.Data)
      UpdateClient(
          client_data.client_id,
          client_data.client_name,
          client_data.schema_version
      )
      ao.send({ Target = msg.From, Data = "Client updated" })
  end
)

-- DeleteClient Handler: Delete a client
Handlers.add(
  "DeleteClient",
  Handlers.utils.hasMatchingTag("Action", "DeleteClient"),
  function(msg)
      local client_id = msg.Data.client_id
      DeleteClient(client_id)
      ao.send({ Target = msg.From, Data = "Client deleted" })
  end
)

-- Define the GetClientById handler
Handlers.add(
    "GetClientById",
    Handlers.utils.hasMatchingTag("Action", "GetClientById"),
    function(msg)
        -- Decode the incoming JSON message
        local client_request = json.decode(msg.Data)

        -- Call the GetClientById function to retrieve the client data
        local client_data = GetClientById(client_request.client_id)

        -- If client data is found, send it back; otherwise, send an error message
        if client_data and next(client_data) then
            ao.send({
                Target = msg.From,
                Data = json.encode(client_data)
            })
        else
            ao.send({
                Target = msg.From,
                Data = "No client found for client_id: " .. client_request.client_id
            })
        end
    end
)

-- CreateRespondent Handler: Insert a new respondent and its associated node
Handlers.add(
    "CreateRespondent",
    Handlers.utils.hasMatchingTag("Action", "CreateRespondent"),
    function(msg)
        -- Decode the incoming JSON message
        local respondent_data = json.decode(msg.Data)

        -- Insert a new node for the respondent
        local node_id = respondent_data.node_id
        local node_type = "respondent"
        local node_status = "active"
        local node_version = respondent_data.schema_version

        -- Insert the respondent node
        InsertNode(node_id, node_type, node_status, node_version)

        -- Insert the respondent into the Respondents table
        InsertRespondent(
            respondent_data.respondent_id,
            node_id,
            respondent_data.respondent_name,
            respondent_data.age,
            respondent_data.sex,
            respondent_data.geolocation,
            respondent_data.email,
            respondent_data.schema_version
        )

        -- Send a response back to the caller
        ao.send({
            Target = msg.From,
            Data = "Respondent and Node inserted successfully"
        })
    end
)

-- UpdateRespondent Handler: Update respondent details
Handlers.add(
    "UpdateRespondent",
    Handlers.utils.hasMatchingTag("Action", "UpdateRespondent"),
    function(msg)
        -- Decode the incoming JSON message
        local respondent_data = json.decode(msg.Data)

        -- Update the respondent in the Respondents table
        local result = UpdateRespondent(
            respondent_data.respondent_id,
            respondent_data.respondent_name,
            respondent_data.age,
            respondent_data.sex,
            respondent_data.geolocation,
            respondent_data.email,
            respondent_data.schema_version
        )

        -- Send a response back to the caller
        ao.send({
            Target = msg.From,
            Data = result
        })
    end
)

-- DeleteRespondent Handler: Delete a respondent
Handlers.add(
    "DeleteRespondent",
    Handlers.utils.hasMatchingTag("Action", "DeleteRespondent"),
    function(msg)
        -- Decode the incoming JSON message
        local respondent_id = msg.Data.respondent_id

        -- Delete the respondent from the Respondents table
        local result = DeleteRespondent(respondent_id)

        -- Send a response back to the caller
        ao.send({
            Target = msg.From,
            Data = result
        })
    end
)

-- GetRespondentById Handler: Retrieve respondent details by respondent_id
Handlers.add(
    "GetRespondentById",
    Handlers.utils.hasMatchingTag("Action", "GetRespondentById"),
    function(msg)
        -- Decode the incoming JSON message
        local respondent_id = json.decode(msg.Data).respondent_id

        -- Retrieve the respondent data
        local respondent_data = GetRespondentById(respondent_id)

        -- If client data is found, send it back; otherwise, send an error message
        if respondent_data and next(respondent_data) then
          ao.send({
              Target = msg.From,
              Data = json.encode(respondent_data)
          })
        else
            ao.send({
                Target = msg.From,
                Data = "No respondent found for respondent_id: " .. respondent_id
            })
        end
    end
)

-- CreateTool Handler: Insert a new tool for a client
Handlers.add(
  "CreateTool",
  Handlers.utils.hasMatchingTag("Action", "CreateTool"),
  function(msg)
      local tool_data = json.decode(msg.Data)
      InsertTool(
          tool_data.tool_id,
          tool_data.client_id,
          tool_data.tool_type,
          tool_data.tool_name,
          tool_data.description
      )
      ao.send({ Target = msg.From, Data = "Tool created" })
  end
)

-- CreateStandardCategory Handler: Insert a new standard category
Handlers.add(
  "CreateStandardCategory",
  Handlers.utils.hasMatchingTag("Action", "CreateStandardCategory"),
  function(msg)
      local category_data = json.decode(msg.Data)
      InsertStandardCategory(
          category_data.category_id,
          category_data.category_name,
          category_data.tool_type
      )
      ao.send({ Target = msg.From, Data = "Category created" })
  end
)

-- CreateStandardAnswerOption Handler: Insert a standard answer option for a category
Handlers.add(
  "CreateStandardAnswerOption",
  Handlers.utils.hasMatchingTag("Action", "CreateStandardAnswerOption"),
  function(msg)
      local answer_data = json.decode(msg.Data)
      InsertStandardAnswerOption(
          answer_data.option_id,
          answer_data.category_id,
          answer_data.answer_text
      )
      ao.send({ Target = msg.From, Data = "Answer option created" })
  end
)

-- GetToolsForClient Handler: Get all tools for a client
Handlers.add(
  "GetToolsForClient",
  Handlers.utils.hasMatchingTag("Action", "GetToolsForClient"),
  function(msg)
      local client_id = msg.Data.client_id
      local tools = GetToolsForClient(client_id)
      ao.send({ Target = msg.From, Data = json.encode(tools) })
  end
)

-- GetStandardCategories Handler: Get all standard categories for a tool type
Handlers.add(
  "GetStandardCategories",
  Handlers.utils.hasMatchingTag("Action", "GetStandardCategories"),
  function(msg)
      local tool_type = msg.Data.tool_type
      local categories = GetStandardCategories(tool_type)
      ao.send({ Target = msg.From, Data = json.encode(categories) })
  end
)

-- InsertSchemaManagement Handler: Insert a schema management record
Handlers.add(
  "InsertSchemaManagement",
  Handlers.utils.hasMatchingTag("Action", "InsertSchemaManagement"),
  function(msg)
      local schema_data = json.decode(msg.Data)
      InsertSchemaManagement(
          schema_data.schema_id,
          schema_data.schema_version,
          schema_data.node_type,
          schema_data.schema_sql,
          schema_data.description
      )
      ao.send({ Target = msg.From, Data = "Schema management record inserted" })
  end
)

-- GetLatestSchemaManagement Handler: Get the latest schema for a node type
Handlers.add(
  "GetLatestSchemaManagement",
  Handlers.utils.hasMatchingTag("Action", "GetLatestSchemaManagement"),
  function(msg)
      local node_type = json.decode(msg.Data).node_type
      local schema = GetLatestSchemaManagement(node_type)
      ao.send({ Target = msg.From, Data = json.encode(schema) })
  end
)