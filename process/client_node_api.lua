--[[
    Imports -- Required Libraries
]] --

local json = require("json")
local ao = require("ao")
local sqlite3 = require("lsqlite3")

-- Open the database
local db = db or sqlite3.open_memory()

-- Function to Initialize the Client Node Database
function InitDb(schema_sql)
  -- Execute schema_sql if provided (e.g., schema updates)
  if schema_sql then
    db:exec(schema_sql)
  end
end

-- Function to Create a New Survey
function CreateSurvey(survey_data, target_criteria)
  -- Insert survey details into the SurveyMetadata (centralized in Main AO Process)
  local insert_survey = [[
    INSERT INTO SurveyMetadata (client_id, title, target_geolocation, target_age_range, target_sex, advanced_target_criteria, status, created_at)
    VALUES (?, ?, ?, ?, ?, ?, 'draft', CURRENT_TIMESTAMP);
  ]]

  -- Assuming survey_data contains the necessary fields
  local stmt = db:prepare(insert_survey)
  stmt:bind_values(
    survey_data.client_id,
    survey_data.title,
    survey_data.target_geolocation,
    survey_data.target_age_range,
    survey_data.target_sex,
    target_criteria
  )
  stmt:step()
  stmt:finalize()

  -- Get survey ID for further operations
  local survey_id = db:last_insert_rowid()

  -- Insert categories for the survey
  for _, category in ipairs(survey_data.categories) do
    local insert_category = [[
      INSERT INTO ClientCategories (survey_id, standard_category_id)
      VALUES (?, ?);
    ]]
    local category_stmt = db:prepare(insert_category)
    category_stmt:bind_values(survey_id, category.standard_category_id)
    category_stmt:step()
    category_stmt:finalize()
  end

  -- -- Insert questions for the survey
  -- for _, question in ipairs(survey_data.questions) do
  --   local insert_question = [[
  --     INSERT INTO ClientQuestions (survey_id, standard_question_id)
  --     VALUES (?, ?);
  --   ]]
  --   local question_stmt = db:prepare(insert_question)
  --   question_stmt:bind_values(survey_id, question.standard_question_id)
  --   question_stmt:step()
  --   question_stmt:finalize()

  --   -- Insert answer options for the questions
  --   for _, option in ipairs(question.options) do
  --     local insert_option = [[
  --       INSERT INTO ClientAnswerOptions (client_question_id, standard_option_id)
  --       VALUES (?, ?);
  --     ]]
  --     local option_stmt = db:prepare(insert_option)
  --     option_stmt:bind_values(question_stmt:last_insert_rowid(), option.standard_option_id)
  --     option_stmt:step()
  --     option_stmt:finalize()
  --   end
  -- end

  print("Survey created with ID: " .. survey_id)
  return survey_id
end

-- Function to Publish a Survey
function PublishSurvey(survey_id)
  local publish_query = [[
    UPDATE SurveyMetadata
    SET status = 'published'
    WHERE survey_id = ?;
  ]]

  local stmt = db:prepare(publish_query)
  stmt:bind_values(survey_id)
  stmt:step()
  stmt:finalize()

  print("Survey with ID: " .. survey_id .. " has been published.")
end

-- Function to Get the Survey Details
function GetSurveyDetails(survey_id)
  -- Fetch survey details
  local survey_query = [[
    SELECT survey_id, client_id, title, target_geolocation, target_age_range, target_sex, advanced_target_criteria, status, created_at FROM SurveyMetadata
    WHERE survey_id = ? LIMIT 1;
  ]]
  local stmt = db:prepare(survey_query)
  stmt:bind_values(survey_id)
  stmt:step()
  
  local survey_details = {
    survey_id = stmt:get_value(0),
    client_id = stmt:get_value(1),
    title = stmt:get_value(2),
    target_geolocation = stmt:get_value(3),
    target_age_range = stmt:get_value(4),
    target_sex = stmt:get_value(5),
    advanced_target_criteria = stmt:get_value(6),
    status = stmt:get_value(7),
    created_at = stmt:get_value(8)
  }
  stmt:finalize()

  print("Survey Details: ", survey_details)
  return survey_details
end

-- Function to Retrieve All Records from SchemaManagement Table as JSON
function RetrieveAllSurveyAsJson()
  -- SQL query to select all records from SchemaManagement
  local query = [[
      SELECT survey_id, client_id, title, target_geolocation, target_age_range, target_sex, advanced_target_criteria, status, created_at FROM SurveyMetadata;
  ]]

  -- Prepare a table to hold the results
  local survey_records = {}
  print("query: " .. query)

  -- Prepare and execute the query
  for row in db:nrows(query) do
      -- Create a table for each record
      local record = {
        survey_id = row.survey_id,
        client_id = row.client_id,
        title = row.title,
        target_geolocation = row.target_geolocation,
        target_age_range = row.target_age_range,
        target_sex = row.target_sex,
        advanced_target_criteria = row.advanced_target_criteria,
        status = row.status,
        created_at = row.created_at
      }
      -- Insert each record into the result table
      table.insert(survey_records, record)
  end

  -- Convert the result table to a JSON string
  local json_result = json.encode(survey_records, { indent = true })

  -- Print the JSON result
  print("json_result: " .. json_result)

  -- Return the JSON string
  return json_result
end

-- Close the database connection when done
function CloseDb()
  db:close()
end

--[[
     UpdateSchema
   ]]
--
Handlers.add(
    "UpdateSchema",
    Handlers.utils.hasMatchingTag("Action", "UpdateSchema"),
    function(msg)
      InitDb(msg.Data)
      ao.send(
        {
            Target = msg.From,
            Data = msg.Data
        }
    )
  end
)

--[[
     CreateSurvey
   ]]
--
Handlers.add(
    "CreateSurvey",
    Handlers.utils.hasMatchingTag("Action", "CreateSurvey"),
    function(msg)
      local survey_data = json.decode(msg.Data)
      if(survey_data) then
        survey_data.survey_id = CreateSurvey(survey_data, json.encode(survey_data.advanced_target_criteria))
        ao.send(
          {
              Target = msg.From,
              Data = json.encode(survey_data)
          })
      end
end
)

--[[
     GetSurveyDetails
   ]]
--
Handlers.add(
    "GetSurveyDetails",
    Handlers.utils.hasMatchingTag("Action", "GetSurveyDetails"),
    function(msg)
      local survey_id = msg.Tags.survey_id
      local script_details =  GetSurveyDetails(survey_id);
      if script_details then
          ao.send(
              {
                  Target = msg.From,
                  Data = script_details
              }
          )     
      end      
  end
)
