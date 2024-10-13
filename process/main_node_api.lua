--[[
    Imports -- Required Libraries
]] --

local json = require("json")
local ao = require("ao")
local sqlite3 = require("lsqlite3")

-- Open the database
local db = db or sqlite3.open_memory()

-- NodeScripts Table Definition with Versioning
NODE_SCRIPTS = [[
  CREATE TABLE IF NOT EXISTS NodeScripts (
    script_id INTEGER PRIMARY KEY AUTOINCREMENT,
    node_type TEXT NOT NULL,          -- Specifies the node type: "client", "respondent"
    script_name TEXT NOT NULL,        -- The name of the script file (e.g., "client_node.lua")
    script_version TEXT NOT NULL,     -- Version identifier for the script (e.g., "v1.0")
    script_content TEXT NOT NULL,     -- Stores the Lua code as a string
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );
]]

-- Schema Definitions
CLIENTS = [[
  CREATE TABLE IF NOT EXISTS Clients (
    client_id INTEGER PRIMARY KEY AUTOINCREMENT,
    client_name TEXT NOT NULL,
    assigned_node_id TEXT NOT NULL,
    schema_version TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    status TEXT DEFAULT 'active'
  );
]]

RESPONDENTS = [[
  CREATE TABLE IF NOT EXISTS Respondents (
    respondent_id INTEGER PRIMARY KEY AUTOINCREMENT,
    respondent_name TEXT NOT NULL,
    age INTEGER,
    sex TEXT,
    geolocation TEXT,
    assigned_node_id INTEGER,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );
]]

SURVEY_METADATA = [[
  CREATE TABLE IF NOT EXISTS SurveyMetadata (
    survey_id INTEGER PRIMARY KEY AUTOINCREMENT,
    client_id INTEGER,
    title TEXT,
    target_geolocation TEXT,
    target_age_range TEXT,
    target_sex TEXT,
    advanced_target_criteria TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    status TEXT DEFAULT 'draft'
  );
]]

-- Schema Management Table Definition
SCHEMA_MANAGEMENT = [[
  CREATE TABLE IF NOT EXISTS SchemaManagement (
    schema_id INTEGER PRIMARY KEY AUTOINCREMENT,
    schema_version TEXT NOT NULL,
    node_type TEXT NOT NULL,  -- Specifies the node type: "main", "client", "respondent"
    schema_sql TEXT NOT NULL,
    description TEXT,
    applied_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );
]]

STANDARD_CATEGORIES = [[
  CREATE TABLE IF NOT EXISTS StandardCategories (
    category_id INTEGER PRIMARY KEY AUTOINCREMENT,
    category_name TEXT NOT NULL UNIQUE,
    description TEXT
  );
]]

STANDARD_QUESTIONS = [[
  CREATE TABLE IF NOT EXISTS StandardQuestions (
    question_id INTEGER PRIMARY KEY AUTOINCREMENT,
    category_id INTEGER,
    question_text TEXT NOT NULL,
    question_type TEXT NOT NULL,
    FOREIGN KEY (category_id) REFERENCES StandardCategories(category_id)
  );
]]

STANDARD_ANSWER_OPTIONS = [[
  CREATE TABLE IF NOT EXISTS StandardAnswerOptions (
    option_id INTEGER PRIMARY KEY AUTOINCREMENT,
    question_id INTEGER,
    answer_text TEXT NOT NULL,
    FOREIGN KEY (question_id) REFERENCES StandardQuestions(question_id)
  );
]]

AUDIT_LOG = [[
  CREATE TABLE IF NOT EXISTS AuditLog (
    log_id INTEGER PRIMARY KEY AUTOINCREMENT,
    action_type TEXT NOT NULL,
    client_id INTEGER,
    node_id INTEGER,
    description TEXT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (client_id) REFERENCES Clients(client_id)
  );
]]

-- Schema Definitions for Client Node
CLIENT_CATEGORIES = [[
  CREATE TABLE IF NOT EXISTS ClientCategories (
    client_category_id INTEGER PRIMARY KEY AUTOINCREMENT,
    survey_id INTEGER,
    standard_category_id INTEGER,
    FOREIGN KEY (survey_id) REFERENCES SurveyMetadata(survey_id),
    FOREIGN KEY (standard_category_id) REFERENCES StandardCategories(category_id)
  );
]]

CLIENT_QUESTIONS = [[
  CREATE TABLE IF NOT EXISTS ClientQuestions (
    client_question_id INTEGER PRIMARY KEY AUTOINCREMENT,
    survey_id INTEGER,
    standard_question_id INTEGER,
    FOREIGN KEY (survey_id) REFERENCES SurveyMetadata(survey_id),
    FOREIGN KEY (standard_question_id) REFERENCES StandardQuestions(question_id)
  );
]]

CLIENT_ANSWER_OPTIONS = [[
  CREATE TABLE IF NOT EXISTS ClientAnswerOptions (
    client_option_id INTEGER PRIMARY KEY AUTOINCREMENT,
    client_question_id INTEGER,
    standard_option_id INTEGER,
    FOREIGN KEY (client_question_id) REFERENCES ClientQuestions(client_question_id),
    FOREIGN KEY (standard_option_id) REFERENCES StandardAnswerOptions(option_id)
  );
]]

-- Schema Definitions for Respondent Node
RESPONDENT_QUESTIONNAIRE_ANSWERS = [[
  CREATE TABLE IF NOT EXISTS RespondentQuestionnaireAnswers (
    answer_id INTEGER PRIMARY KEY AUTOINCREMENT,
    respondent_id INTEGER,
    question_id INTEGER,
    selected_option_id INTEGER,
    answer_timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (respondent_id) REFERENCES Respondents(respondent_id),
    FOREIGN KEY (question_id) REFERENCES StandardQuestions(question_id),
    FOREIGN KEY (selected_option_id) REFERENCES StandardAnswerOptions(option_id)
  );
]]

SURVEY_RESPONSES = [[
  CREATE TABLE IF NOT EXISTS SurveyResponses (
    response_id INTEGER PRIMARY KEY AUTOINCREMENT,
    respondent_id INTEGER,
    survey_id INTEGER,
    question_id INTEGER,
    selected_option_id INTEGER,
    response_timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    completion_time DATETIME,
    FOREIGN KEY (respondent_id) REFERENCES Respondents(respondent_id),
    FOREIGN KEY (survey_id) REFERENCES SurveyMetadata(survey_id),
    FOREIGN KEY (question_id) REFERENCES ClientQuestions(client_question_id),
    FOREIGN KEY (selected_option_id) REFERENCES ClientAnswerOptions(client_option_id)
  );
]]

-- Function to Initialize the Database
function InitDb()
  db:exec(NODE_SCRIPTS)
  db:exec(CLIENTS)
  db:exec(RESPONDENTS)
  db:exec(SURVEY_METADATA)
  db:exec(SCHEMA_MANAGEMENT)
  db:exec(STANDARD_CATEGORIES)
  db:exec(STANDARD_QUESTIONS)
  db:exec(STANDARD_ANSWER_OPTIONS)
  db:exec(AUDIT_LOG)

  local initial_main_schema_sql = NODE_SCRIPTS .. CLIENTS .. RESPONDENTS .. STANDARD_CATEGORIES .. STANDARD_QUESTIONS .. STANDARD_ANSWER_OPTIONS .. AUDIT_LOG
  InsertSchemaVersion("v1.0", "main", initial_main_schema_sql, "Initial schema for main AO process")

  local initial_client_schema_sql = SURVEY_METADATA .. CLIENT_CATEGORIES .. CLIENT_QUESTIONS .. CLIENT_ANSWER_OPTIONS
  InsertSchemaVersion("v1.0", "client", initial_client_schema_sql, "Initial schema for client AO process")

  local initial_respondent_schema_sql = RESPONDENT_QUESTIONNAIRE_ANSWERS .. SURVEY_RESPONSES
  InsertSchemaVersion("v1.0", "respondent", initial_respondent_schema_sql, "Initial schema for respondent AO process")
   
end

-- Function to Insert a Lua Script into the NodeScripts Table
function InsertNodeScript(node_type, script_name, script_version, script_content)
  local insert_query = [[
    INSERT INTO NodeScripts (node_type, script_name, script_version, script_content, created_at)
    VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP);
  ]]
  local stmt = db:prepare(insert_query)
  stmt:bind_values(node_type, script_name, script_version, script_content)
  stmt:step()
  stmt:finalize()
end

-- Function to Retrieve All Lua Scripts by Node Type
function GetAllNodeScriptsByType(node_type)
  local query = [[
    SELECT script_id, script_name, script_version, script_content FROM NodeScripts
    WHERE node_type = ?;
  ]]
  local stmt = db:prepare(query)
  stmt:bind_values(node_type)

  local scripts = {}
  for row in stmt:nrows() do
    table.insert(scripts, {
      script_id = row.script_id,
      script_name = row.script_name,
      script_version = row.script_version,
      script_content = row.script_content
    })
  end
  stmt:finalize()
  
  return scripts
end

-- Function to Retrieve Lua Script by Type and Version
function GetNodeScriptByVersion(node_type, script_version)
  local query = [[
    SELECT script_content FROM NodeScripts
    WHERE node_type = ? AND script_version = ?
    ORDER BY created_at DESC LIMIT 1;
  ]]
  local stmt = db:prepare(query)
  stmt:bind_values(node_type, script_name, script_version)

  local script_content = nil
  if stmt:step() == sqlite3.ROW then
    script_content = stmt:get_value(0)
  end
  stmt:finalize()
  
  return script_content
end

-- Function to Retrieve the Latest Lua Script by Node Type
function GetLatestNodeScript(node_type)
  local query = [[
    SELECT script_content FROM NodeScripts
    WHERE node_type = ?
    ORDER BY script_version DESC, created_at DESC LIMIT 1;
  ]]
  local stmt = db:prepare(query)
  stmt:bind_values(node_type)

  local script_content = nil
  if stmt:step() == sqlite3.ROW then
    script_content = stmt:get_value(0)
  end
  stmt:finalize()
  
  return script_content
end

-- Function to Register a New Client
function AddClient(client_name, assigned_node_id, schema_version)
  -- Insert a new client into the Clients table
  local insert_client = [[
    INSERT INTO Clients (client_name, assigned_node_id, schema_version, created_at, status)
    VALUES (?, ?, ?, CURRENT_TIMESTAMP, 'active');
  ]]
  local stmt = db:prepare(insert_client)
  stmt:bind_values(client_name, assigned_node_id, schema_version)
  stmt:step()
  stmt:finalize()

  -- Log the registration in the AuditLog
  local audit_log = [[
    INSERT INTO AuditLog (action_type, client_id, description, timestamp)
    VALUES ('client_registration', last_insert_rowid(), ?, CURRENT_TIMESTAMP);
  ]]
  local audit_stmt = db:prepare(audit_log)
  audit_stmt:bind_values("New client registered: " .. client_name)
  audit_stmt:step()
  audit_stmt:finalize()
end

-- Function to Register a New Respondent
function RegisterRespondent(respondent_name, age, sex, geolocation)
  -- Insert a new respondent into the Respondents table
  local insert_respondent = [[
    INSERT INTO Respondents (respondent_name, age, sex, geolocation, created_at)
    VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP);
  ]]
  local stmt = db:prepare(insert_respondent)
  stmt:bind_values(respondent_name, age, sex, geolocation)
  stmt:step()
  stmt:finalize()

  -- Log the registration in the AuditLog
  local audit_log = [[
    INSERT INTO AuditLog (action_type, respondent_id, description, timestamp)
    VALUES ('respondent_registration', last_insert_rowid(), ?, CURRENT_TIMESTAMP);
  ]]
  local audit_stmt = db:prepare(audit_log)
  audit_stmt:bind_values("New respondent registered: " .. respondent_name)
  audit_stmt:step()
  audit_stmt:finalize()
end

-- Function to Update the Schema Version
function UpdateSchemaVersion(schema_sql, description)
  -- Generate a new schema version
  local new_schema_version = os.date("v1.%Y%m%d%H%M%S")

  -- Insert new schema version details into SchemaManagement
  local update_query = [[
    INSERT INTO SchemaManagement (schema_version, schema_sql, description, applied_at)
    VALUES (?, ?, ?, CURRENT_TIMESTAMP);
  ]]
  local stmt = db:prepare(update_query)
  stmt:bind_values(new_schema_version, schema_sql, description)
  stmt:step()
  stmt:finalize()

  -- Propagate schema changes to all active nodes
  PropagateSchemaToNodes(schema_sql, new_schema_version)
end

-- Function to Propagate Schema Updates to All Nodes
function PropagateSchemaToNodes(schema_sql, schema_version)
  local node_query = "SELECT node_id FROM Clients WHERE status = 'active'"
  for row in db:nrows(node_query) do
    local node_id = row.node_id
    local client_node = GetClientNodeInstance(node_id)  -- Hypothetical function to get node reference

    -- Apply the schema update to the client node
    local success, err = pcall(function()
      client_node:InitDb(schema_sql)
    end)

    -- Log the result in AuditLog
    local audit_query = [[
      INSERT INTO AuditLog (action_type, node_id, description, timestamp)
      VALUES (?, ?, ?, CURRENT_TIMESTAMP);
    ]]
    local action = success and "schema_update_success" or "schema_update_failure"
    local description = success and ("Schema updated to version " .. schema_version) or ("Failed to update schema: " .. err)

    local audit_stmt = db:prepare(audit_query)
    audit_stmt:bind_values(action, node_id, description)
    audit_stmt:step()
    audit_stmt:finalize()
  end
end

-- Function to Insert a Schema Version into the SchemaManagement Table
function InsertSchemaVersion(schema_version, node_type, schema_sql, description)
  local insert_query = [[
    INSERT INTO SchemaManagement (schema_version, node_type, schema_sql, description, applied_at)
    VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP);
  ]]
  local stmt = db:prepare(insert_query)
  stmt:bind_values(schema_version, node_type, schema_sql, description)
  stmt:step()
  stmt:finalize()
end

-- Function to Retrieve the Latest SchemaManagement by Node Type
function GetLatestSchemaManagement(node_type)
  local query = [[
    SELECT schema_sql FROM SchemaManagement
    WHERE node_type = ?
    ORDER BY schema_version DESC, applied_at DESC LIMIT 1;
  ]]
  local stmt = db:prepare(query)
  stmt:bind_values(node_type)

  local schema_sql = nil
  if stmt:step() == sqlite3.ROW then
    schema_sql = stmt:get_value(0)
  end
  stmt:finalize()  
  return schema_sql;
end


-- Function to Retrieve All Records from SchemaManagement Table as JSON
function RetrieveAllSchemaManagementAsJson()
    -- SQL query to select all records from SchemaManagement
    local query = [[
        SELECT schema_id, schema_version, node_type, schema_sql, description, applied_at FROM SchemaManagement;
    ]]

    -- Prepare a table to hold the results
    local schema_management_records = {}

    -- Prepare and execute the query
    for row in db:nrows(query) do
        -- Create a table for each record
        local record = {
            schema_id = row.schema_id,
            schema_version = row.schema_version,
            node_type = row.node_type,
            schema_sql = row.schema_sql,
            description = row.description,
            applied_at = row.applied_at
        }
        -- Insert each record into the result table
        table.insert(schema_management_records, record)
    end

    -- Convert the result table to a JSON string
    local json_result = json.encode(schema_management_records, { indent = true })

    -- Print the JSON result
    print(json_result)

    -- Return the JSON string
    return json_result
end

-- Close the database connection when done
function CloseDb()
  db:close()
end

-- Example Initialization
InitDb()

--[[
     CanSpawnClient
   ]]
--
Handlers.add(
    "CanRegister",
    Handlers.utils.hasMatchingTag("Action", "CanRegister"),
    function(msg)
      local script_content =  GetLatestNodeScript(msg.Tags.node_type);
      if script_content then
          ao.send(
              {
                  Target = msg.From,
                  Data = "Ok"
              }
          )
      end
    end
)

--[[
     LoadApi
   ]]
--
Handlers.add(
    "LoadApi",
    Handlers.utils.hasMatchingTag("Action", "LoadApi"),
    function(msg)
      local local_s = json.decode(msg.Data)
      InsertNodeScript(local_s.node_type, local_s.script_name, local_s.script_version, local_s.script_content)    
  end
)

--[[
     GetSchemaManagement
   ]]
--
Handlers.add(
    "GetSchemaManagement",
    Handlers.utils.hasMatchingTag("Action", "GetSchemaManagement"),
    function(msg)
        local schema_management_sql =  GetLatestSchemaManagement(msg.Tags.node_type);
        if schema_management_sql then
            ao.send(
                {
                    Target = msg.From,
                    Data = schema_management_sql
                }
            )
        end
    end
)

--[[
     GetNodeScripts
   ]]
--
Handlers.add(
    "GetNodeScripts",
    Handlers.utils.hasMatchingTag("Action", "GetNodeScripts"),
    function(msg)
      local node_script_records =  GetAllNodeScriptsByType(msg.Tags.node_type);
        if node_script_records then
            ao.send(
                {
                    Target = msg.From,
                    Data = json.encode(node_script_records)
                }
            )
        end
    end
)

--[[
     RegisterClient
   ]]
--
Handlers.add(
    "RegisterClient",
    Handlers.utils.hasMatchingTag("Action", "RegisterClient"),
    function(msg)
      local client_register_form = json.decode(msg.Data)
      -- local schema_sql =  GetLatestSchemaManagement("client")
      AddClient(client_register_form.name, client_register_form.process_id, "v1.0")
      -- if schema_sql then
      --   ao.send({ Target = client_register_form.process_id, Action = "UpdateSchema", Data = schema_sql })
      -- end  
    end
)

--[[
     RegisterClientSchema
   ]]
--
Handlers.add(
    "RegisterClientSchema",
    Handlers.utils.hasMatchingTag("Action", "RegisterClientSchema"),
    function(msg)
      -- local client_register_form = json.decode(msg.Data)
      local schema_sql =  GetLatestSchemaManagement("client")
      if schema_sql then
        -- Send({ Target = client_register_form.process_id, Action = "UpdateSchema", Data = schema_sql })
        ao.send(
          {
              Target = msg.From,
              Data = schema_sql
          }
      )
  else     
    ao.send(
      {
          Target = msg.From,
          Data = "not ok"
      }
  )

      end  
    end
)
