--[[
    Imports -- Required Libraries
]] --

local json = require("json")
local ao = require("ao")
local sqlite3 = require("lsqlite3")

-- Open the database
local db = db or sqlite3.open_memory()

-- Schema Definitions
CLIENTS = [[
  CREATE TABLE IF NOT EXISTS Clients (
    client_id INTEGER PRIMARY KEY AUTOINCREMENT,
    client_name TEXT NOT NULL,
    assigned_node_id INTEGER,
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
    status TEXT DEFAULT 'draft',
    FOREIGN KEY (client_id) REFERENCES Clients(client_id)
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

-- Function to Initialize the Database
function InitDb()
  db:exec(CLIENTS)
  db:exec(RESPONDENTS)
  db:exec(SURVEY_METADATA)
  db:exec(SCHEMA_MANAGEMENT)
  db:exec(STANDARD_CATEGORIES)
  db:exec(STANDARD_QUESTIONS)
  db:exec(STANDARD_ANSWER_OPTIONS)
  db:exec(AUDIT_LOG)

  local initial_main_schema_sql = CLIENTS .. RESPONDENTS .. STANDARD_CATEGORIES .. STANDARD_QUESTIONS .. STANDARD_ANSWER_OPTIONS .. SURVEY_METADATA .. AUDIT_LOG
  InsertSchemaVersion("v1.0", "main", initial_main_schema_sql, "Initial schema for main AO process")

end

-- Function to Register a New Client
function RegisterClient(client_name)
  -- Insert a new client into the Clients table
  local insert_client = [[
    INSERT INTO Clients (client_name, schema_version, created_at, status)
    VALUES (?, 'v1.0', CURRENT_TIMESTAMP, 'active');
  ]]
  local stmt = db:prepare(insert_client)
  stmt:bind_values(client_name)
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

-- Function to Retrieve All Records from SchemaManagement Table as JSON
function RetrieveAllSchemaManagementAsJson()
    -- SQL query to select all records from SchemaManagement
    local query = [[
        SELECT schema_id, schema_version, schema_sql, description, applied_at FROM SchemaManagement;
    ]]

    -- Prepare a table to hold the results
    local schema_management_records = {}

    -- Prepare and execute the query
    for row in db:nrows(query) do
        -- Create a table for each record
        local record = {
            schema_id = row.schema_id,
            schema_version = row.schema_version,
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
     Info
   ]]
--
Handlers.add(
    "info",
    Handlers.utils.hasMatchingTag("Action", "Info"),
    function(msg)
        ao.send(
            {
                Target = msg.From,
                Tags = {
                    Name = "ON aiR",
                },
                Data = "Echo info"  
            }
        )
    end
)


--[[
     EncryptIntegerValue
   ]]
--
Handlers.add(
    "EncryptIntegerValue",
    Handlers.utils.hasMatchingTag("Action", "EncryptIntegerValue"),
    function(msg)
        local local_s = "test"
        print(local_s)
        print(msg)
        if local_s then
            ao.send(
                {
                    Target = msg.From,
                    Tags = {
                        Action = "GetSchemaManagement"
                    },
                    Data = local_s
                }
            )
        end
    end
)

Handlers.add(
    "GetSchemaManagement",
    Handlers.utils.hasMatchingTag("Action", "GetSchemaManagement"),
    function(msg)
        local schema_management_records =  RetrieveAllSchemaManagementAsJson();
        print(schema_management_records)
        print(msg)
        if schema_management_records then
            ao.send(
                {
                    Target = msg.From,
                    Tags = {
                        Action = "GetSchemaManagement"
                    },
                    Data = schema_management_records
                }
            )
        end
    end
)
