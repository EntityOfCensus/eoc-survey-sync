--[[
    Imports -- Required Libraries
]] --
local json = require("json")
local ao = require("ao")
local sqlite3 = require("lsqlite3")

-- Open the database
local db = db or sqlite3.open_memory()

-- Function to Initialize the Database
function InitDb(schema_sql)
  db:exec(schema_sql)
  return "Script executed"
end

-- Utility Functions
function InsertToolInstance(instance_id, client_tool_id, instance_name, target_age_range, target_sex, target_geolocation, deployment_date, expiration_date)
    -- SQL Insert into ClientToolInstances table
    local stmt = db:prepare([[
        INSERT INTO ClientToolInstances (instance_id, client_tool_id, instance_name, target_age_range, target_sex, target_geolocation, deployment_date, expiration_date)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]])
    stmt:bind_values(instance_id, client_tool_id, instance_name, target_age_range, target_sex, target_geolocation, deployment_date, expiration_date)
    stmt:step()
    stmt:finalize()
end

function UpdateToolInstance(instance_id, instance_name, target_age_range, target_sex, target_geolocation, deployment_date, expiration_date)
    -- SQL Update for ClientToolInstances
    local stmt = db:prepare([[
        UPDATE ClientToolInstances
        SET instance_name = ?, target_age_range = ?, target_sex = ?, target_geolocation = ?, deployment_date = ?, expiration_date = ?
        WHERE instance_id = ?
    ]])
    stmt:bind_values(instance_name, target_age_range, target_sex, target_geolocation, deployment_date, expiration_date, instance_id)
    stmt:step()
    stmt:finalize()
end

function DeleteToolInstance(instance_id)
    -- SQL Delete from ClientToolInstances
    local stmt = db:prepare([[ DELETE FROM ClientToolInstances WHERE instance_id = ? ]])
    stmt:bind_values(instance_id)
    stmt:step()
    stmt:finalize()
end

-- Function to insert a new client category
function InsertClientCategory(client_category_id, instance_id, category_name)
    local stmt = db:prepare([[
        INSERT INTO ClientCategories (client_category_id, instance_id, category_name)
        VALUES (?, ?, ?)
    ]])
    stmt:bind_values(client_category_id, instance_id, category_name)
    stmt:step()
    stmt:finalize()
    return "Client category inserted"
end

-- Function to update an existing client category
function UpdateClientCategory(client_category_id, category_name)
    local stmt = db:prepare([[
        UPDATE ClientCategories
        SET category_name = ?
        WHERE client_category_id = ?
    ]])
    stmt:bind_values(category_name, client_category_id)
    stmt:step()
    stmt:finalize()
    return "Client category updated"
end

-- Function to delete a client category
function DeleteClientCategory(client_category_id)
    local stmt = db:prepare([[ DELETE FROM ClientCategories WHERE client_category_id = ? ]])
    stmt:bind_values(client_category_id)
    stmt:step()
    stmt:finalize()
    return "Client category deleted"
end

-- Function to get all client categories for a specific tool instance
function GetClientCategories(instance_id)
    print("instanceId: " .. instance_id)

    local stmt = db:prepare([[
        INSERT INTO ClientCategories (client_category_id, instance_id, category_name)
        VALUES (?, ?, ?)
    ]])
  
    -- local stmt = db:prepare([[
    --     SELECT client_category_id, category_name, instance_id
    --     FROM ClientCategories
    -- ]])
    print("------------ stmt: " .. stmt)
    -- stmt:bind_values(page_size, offset)
    -- local result = stmt:step()
    -- local instances = {}
  
    -- while result == sqlite3.ROW do
    --     table.insert(instances, {
    --         instance_id = stmt:get_value(0),
    --         client_tool_id = stmt:get_value(1),
    --         instance_name = stmt:get_value(2),
    --         target_age_range = stmt:get_value(3),
    --         target_sex = stmt:get_value(4),
    --         target_geolocation = stmt:get_value(5),
    --         deployment_date = stmt:get_value(6),
    --         expiration_date = stmt:get_value(7),
    --         created_at = stmt:get_value(8)
    --     })
    --     result = stmt:step()
    -- end
  
    -- stmt:finalize()
    -- return instances
  

    -- local stmt = db:prepare([[
    --     SELECT client_category_id, category_name, instance_id
    --     FROM ClientCategories
    -- ]])
  
    -- local stmts = db:prepare([[
    --     SELECT client_category_id, category_name, instance_id
    --     FROM ClientCategories
    --     WHERE instance_id = ?
    -- ]])
  
    -- stmts:bind_values(instance_id)

    -- local result = stmt:step()

    local categories = {}
    -- while result == sqlite3.ROW do
    --     table.insert(categories, {
    --         client_category_id = stmt:get_value(0),
    --         category_name = stmt:get_value(1),
    --         instance_id = stmt:get_value(2)
    --     })
    --     result = stmt:step()
    -- end

    -- stmt:finalize()
    return categories
end

function InsertQuestion(client_question_id, instance_id, client_category_id, question_text, question_type, order_number, additional_context)
    -- SQL Insert into ClientQuestions
    local stmt = db:prepare([[
        INSERT INTO ClientQuestions (client_question_id, instance_id, client_category_id, question_text, question_type, order_number, additional_context)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ]])
    stmt:bind_values(instance_id, client_category_id, question_text, question_type, order_number, additional_context)
    stmt:step()
    stmt:finalize()
end

function UpdateQuestion(client_question_id, client_category_id, question_text, question_type, order_number, additional_context)
    -- SQL Update for ClientQuestions
    local stmt = db:prepare([[
        UPDATE ClientQuestions
        SET client_category_id = ?, question_text = ?, question_type = ?, order_number = ?, additional_context = ?
        WHERE client_question_id = ?
    ]])
    stmt:bind_values(client_category_id, question_text, question_type, order_number, additional_context, client_question_id)
    stmt:step()
    stmt:finalize()
end

function DeleteQuestion(client_question_id)
    -- SQL Delete from ClientQuestions
    local stmt = db:prepare([[ DELETE FROM ClientQuestions WHERE client_question_id = ? ]])
    stmt:bind_values(client_question_id)
    stmt:step()
    stmt:finalize()
end

function InsertAnswerOption(client_question_id, answer_text)
    -- SQL Insert into ClientAnswerOptions
    local stmt = db:prepare([[
        INSERT INTO ClientAnswerOptions (client_question_id, answer_text)
        VALUES (?, ?)
    ]])
    stmt:bind_values(client_question_id, answer_text)
    stmt:step()
    stmt:finalize()
end

function DeleteAnswerOption(answer_option_id)
    -- SQL Delete from ClientAnswerOptions
    local stmt = db:prepare([[ DELETE FROM ClientAnswerOptions WHERE answer_option_id = ? ]])
    stmt:bind_values(answer_option_id)
    stmt:step()
    stmt:finalize()
end

function DeployToolInstance(instance_id, target_nodes)
    -- Custom logic for deploying tool instance to respondent nodes
    -- This might involve network or API calls to make the instance available on other nodes
    -- Here we'll simulate the action with a simple print statement
    print("Tool instance " .. instance_id .. " deployed to nodes: " .. target_nodes)
end

function GetToolInstanceDetails(instance_id)
    print("instance_id" .. instance_id)
  -- SQL Select tool instance details
    local stmt = db:prepare([[
        SELECT instance_id, client_tool_id, instance_name, target_age_range, target_sex, 
              target_geolocation, deployment_date, expiration_date, created_at 
        FROM ClientToolInstances
        WHERE instance_id = ? 
    ]])
    
    -- [[ SELECT instance_id, client_tool_id, instance_name, target_age_range, target_sex, 
    --          target_geolocation, deployment_date, expiration_date, created_at 
    --     FROM ClientToolInstances WHERE instance_id = ? ]]
    stmt:bind_values(instance_id)
    local result = stmt:step()
    local details = {}
    while result == sqlite3.ROW do
        details = {
            instance_id = stmt:get_value(0),
            client_tool_id = stmt:get_value(1),
            instance_name = stmt:get_value(2),
            target_age_range = stmt:get_value(3),
            target_sex = stmt:get_value(4),
            target_geolocation = stmt:get_value(5),
            deployment_date = stmt:get_value(6),
            expiration_date = stmt:get_value(7),
            created_at = stmt:get_value(8)
        }
        result = stmt:step()
    end

    stmt:finalize()
    return details
end

function GetQuestionsForInstance(instance_id)
    -- SQL Select all questions for the instance
    local stmt = db:prepare([[ SELECT * FROM ClientQuestions WHERE instance_id = ? ]])
    stmt:bind_values(instance_id)
    local result = stmt:step()
    local questions = {}

    while result == sqlite3.ROW do
        table.insert(questions, {
            client_question_id = stmt:get_value(0),
            instance_id = stmt:get_value(1),
            client_category_id = stmt:get_value(2),
            question_text = stmt:get_value(3),
            question_type = stmt:get_value(4),
            order_number = stmt:get_value(5),
            additional_context = stmt:get_value(6)
        })
        result = stmt:step()
    end

    stmt:finalize()
    return questions
end

function GetAnswerOptionsForQuestion(client_question_id)
    -- SQL Select all answer options for a question
    local stmt = db:prepare([[ SELECT * FROM ClientAnswerOptions WHERE client_question_id = ? ]])
    stmt:bind_values(client_question_id)
    local result = stmt:step()
    local answer_options = {}

    while result == sqlite3.ROW do
        table.insert(answer_options, {
            answer_option_id = stmt:get_value(0),
            client_question_id = stmt:get_value(1),
            answer_text = stmt:get_value(2)
        })
        result = stmt:step()
    end

    stmt:finalize()
    return answer_options
end

-- Utility Function for getting instance_id by instance_name and client_tool_id
function GetInstanceIdByNameAndToolId(instance_name, client_tool_id)
  local stmt = db:prepare([[
      SELECT instance_id FROM ClientToolInstances 
      WHERE instance_name = ? AND client_tool_id = ?
  ]])
  stmt:bind_values(instance_name, client_tool_id)
  local result = stmt:step()
  local instance_id = nil

  if result == sqlite3.ROW then
      instance_id = stmt:get_value(0)
  end

  stmt:finalize()
  return instance_id
end

-- Utility Function for paginated results
function GetPaginatedToolInstances(page, page_size)
  local offset = (page - 1) * page_size
  local stmt = db:prepare([[
      SELECT instance_id, client_tool_id, instance_name, target_age_range, target_sex, 
             target_geolocation, deployment_date, expiration_date, created_at 
      FROM ClientToolInstances
      LIMIT ? OFFSET ?
  ]])
  stmt:bind_values(page_size, offset)
  local result = stmt:step()
  local instances = {}

  while result == sqlite3.ROW do
      table.insert(instances, {
          instance_id = stmt:get_value(0),
          client_tool_id = stmt:get_value(1),
          instance_name = stmt:get_value(2),
          target_age_range = stmt:get_value(3),
          target_sex = stmt:get_value(4),
          target_geolocation = stmt:get_value(5),
          deployment_date = stmt:get_value(6),
          expiration_date = stmt:get_value(7),
          created_at = stmt:get_value(8)
      })
      result = stmt:step()
  end

  stmt:finalize()
  return instances
end

-- Handler Definitions

-- InitDb Handler
Handlers.add(
    "InitDb",
    Handlers.utils.hasMatchingTag("Action", "InitDb"),
    function(msg)
        local resutl = InitDb(msg.Data)
        ao.send(
            {
                Target = msg.From,
                Data = result
            }
        )
    end
)

-- GetInstanceIdByNameAndToolId Handler
Handlers.add(
    "GetInstanceIdByNameAndToolId",
    Handlers.utils.hasMatchingTag("Action", "GetInstanceIdByNameAndToolId"),
    function(msg)
        local data = json.decode(msg.Data)
        local instance_id = GetInstanceIdByNameAndToolId(data.instance_name, data.client_tool_id)
        ao.send(
            {
                Target = msg.From,
                Data = json.encode({ instance_id = instance_id })
            }
        )
    end
)

-- PaginateToolInstances Handler
Handlers.add(
    "PaginateToolInstances",
    Handlers.utils.hasMatchingTag("Action", "PaginateToolInstances"),
    function(msg)
        local data = json.decode(msg.Data)
        local page = data.page or 1
        local page_size = data.page_size or 10
        local paginated_instances = GetPaginatedToolInstances(page, page_size)

        ao.send(
            {
                Target = msg.From,
                Data = json.encode(paginated_instances)
            }
        )
    end
)

-- CreateToolInstance Handler
Handlers.add(
    "CreateToolInstance",
    Handlers.utils.hasMatchingTag("Action", "CreateToolInstance"),
    function(msg)
        local instance_data = json.decode(msg.Data)
        InsertToolInstance(
            msg.Id,
            instance_data.client_tool_id,
            instance_data.instance_name,
            instance_data.target_age_range,
            instance_data.target_sex,
            instance_data.target_geolocation,
            instance_data.deployment_date,
            instance_data.expiration_date
        )
        ao.send({ Target = msg.From, Data = "Tool instance created" })
    end
)

-- UpdateToolInstance Handler
Handlers.add(
    "UpdateToolInstance",
    Handlers.utils.hasMatchingTag("Action", "UpdateToolInstance"),
    function(msg)
        local instance_data = json.decode(msg.Data)
        UpdateToolInstance(
            instance_data.instance_id,
            instance_data.instance_name,
            instance_data.target_age_range,
            instance_data.target_sex,
            instance_data.target_geolocation,
            instance_data.deployment_date,
            instance_data.expiration_date
        )
        ao.send({ Target = msg.From, Data = "Tool instance updated" })
    end
)

-- DeleteToolInstance Handler
Handlers.add(
    "DeleteToolInstance",
    Handlers.utils.hasMatchingTag("Action", "DeleteToolInstance"),
    function(msg)
        local instance_id = msg.Data.instance_id
        DeleteToolInstance(instance_id)
        ao.send({ Target = msg.From, Data = "Tool instance deleted" })
    end
)

-- CreateClientCategory Handler: Insert a new client category
Handlers.add(
    "CreateClientCategory",
    Handlers.utils.hasMatchingTag("Action", "CreateClientCategory"),
    function(msg)
        local category_data = json.decode(msg.Data)
        local result = InsertClientCategory(msg.Id, category_data.instance_id, category_data.category_name)

        ao.send({
            Target = msg.From,
            Data = result
        })
    end
)

-- UpdateClientCategory Handler: Update an existing client category
Handlers.add(
    "UpdateClientCategory",
    Handlers.utils.hasMatchingTag("Action", "UpdateClientCategory"),
    function(msg)
        local category_data = json.decode(msg.Data)
        local result = UpdateClientCategory(category_data.client_category_id, category_data.category_name)

        ao.send({
            Target = msg.From,
            Data = result
        })
    end
)

-- DeleteClientCategory Handler: Delete a client category
Handlers.add(
    "DeleteClientCategory",
    Handlers.utils.hasMatchingTag("Action", "DeleteClientCategory"),
    function(msg)
        local category_data = json.decode(msg.Data)
        local result = DeleteClientCategory(category_data.client_category_id)

        ao.send({
            Target = msg.From,
            Data = result
        })
    end
)

-- GetClientCategories Handler: Retrieve all client categories for a tool instance
Handlers.add(
    "GetClientCategories",
    Handlers.utils.hasMatchingTag("Action", "GetClientCategories"),
    function(msg)
        local instance_data = json.decode(msg.Data)
        print(instance_data.instance_id .. " :: " .. msg.Data)
        local categories = GetClientCategories(instance_data.instance_id)

        ao.send({
            Target = msg.From,
            Data = json.encode(categories)
        })
    end
)

-- CreateQuestion Handler
Handlers.add(
    "CreateQuestion",
    Handlers.utils.hasMatchingTag("Action", "CreateQuestion"),
    function(msg)
        local question_data = json.decode(msg.Data)
        InsertQuestion(
            msg.Id,
            question_data.instance_id,
            question_data.client_category_id,
            question_data.question_text,
            question_data.question_type,
            question_data.order_number,
            question_data.additional_context
        )
        ao.send({ Target = msg.From, Data = "Question created" })
    end
)

-- UpdateQuestion Handler
Handlers.add(
    "UpdateQuestion",
    Handlers.utils.hasMatchingTag("Action", "UpdateQuestion"),
    function(msg)
        local question_data = json.decode(msg.Data)
        UpdateQuestion(
            question_data.client_question_id,
            question_data.client_category_id,
            question_data.question_text,
            question_data.question_type,
            question_data.order_number,
            question_data.additional_context
        )
        ao.send({ Target = msg.From, Data = "Question updated" })
    end
)

-- DeleteQuestion Handler
Handlers.add(
    "DeleteQuestion",
    Handlers.utils.hasMatchingTag("Action", "DeleteQuestion"),
    function(msg)
        local client_question_id = msg.Data.client_question_id
        DeleteQuestion(client_question_id)
        ao.send({ Target = msg.From, Data = "Question deleted" })
    end
)

-- CreateAnswerOption Handler
Handlers.add(
    "CreateAnswerOption",
    Handlers.utils.hasMatchingTag("Action", "CreateAnswerOption"),
    function(msg)
        local answer_data = json.decode(msg.Data)
        InsertAnswerOption(answer_data.client_question_id, answer_data.answer_text)
        ao.send({ Target = msg.From, Data = "Answer option created" })
    end
)

-- DeleteAnswerOption Handler
Handlers.add(
    "DeleteAnswerOption",
    Handlers.utils.hasMatchingTag("Action", "DeleteAnswerOption"),
    function(msg)
        local answer_option_id = msg.Data.answer_option_id
        DeleteAnswerOption(answer_option_id)
        ao.send({ Target = msg.From, Data = "Answer option deleted" })
    end
)

-- DeployToolInstance Handler
Handlers.add(
    "DeployToolInstance",
    Handlers.utils.hasMatchingTag("Action", "DeployToolInstance"),
    function(msg)
        local deploy_data = json.decode(msg.Data)
        DeployToolInstance(deploy_data.instance_id, deploy_data.target_nodes)
        ao.send({ Target = msg.From, Data = "Tool instance deployed" })
    end
)

-- GetToolInstanceDetails Handler
Handlers.add(
    "GetToolInstanceDetails",
    Handlers.utils.hasMatchingTag("Action", "GetToolInstanceDetails"),
    function(msg)
        local instance_id = json.decode(msg.Data).instance_id
        print("instance_id" .. instance_id)
        local details = GetToolInstanceDetails(instance_id)
        ao.send({ Target = msg.From, Data = json.encode(details) })
    end
)

-- GetQuestionsForToolInstance Handler
Handlers.add(
    "GetQuestionsForToolInstance",
    Handlers.utils.hasMatchingTag("Action", "GetQuestionsForToolInstance"),
    function(msg)
        local instance_id = msg.Data.instance_id
        local questions = GetQuestionsForInstance(instance_id)
        ao.send({ Target = msg.From, Data = json.encode(questions) })
    end
)

-- GetAnswerOptionsForQuestion Handler
Handlers.add(
    "GetAnswerOptionsForQuestion",
    Handlers.utils.hasMatchingTag("Action", "GetAnswerOptionsForQuestion"),
    function(msg)
        local question_id = msg.Data.client_question_id
        local answer_options = GetAnswerOptionsForQuestion(question_id)
        ao.send({ Target = msg.From, Data = json.encode(answer_options) })
    end
)
