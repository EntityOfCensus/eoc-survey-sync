--[[
    Imports -- Required Libraries
]] --

local json = require("json")
local ao = require("ao")
local sqlite3 = require("sqlite3")

-- Open the database
local db = sqlite3.open("client_node.db")

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

-- Function to Initialize the Client Node Database
function InitDb(schema_sql)
  db:exec(CLIENT_CATEGORIES)
  db:exec(CLIENT_QUESTIONS)
  db:exec(CLIENT_ANSWER_OPTIONS)

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

  -- Insert questions for the survey
  for _, question in ipairs(survey_data.questions) do
    local insert_question = [[
      INSERT INTO ClientQuestions (survey_id, standard_question_id)
      VALUES (?, ?);
    ]]
    local question_stmt = db:prepare(insert_question)
    question_stmt:bind_values(survey_id, question.standard_question_id)
    question_stmt:step()
    question_stmt:finalize()

    -- Insert answer options for the questions
    for _, option in ipairs(question.options) do
      local insert_option = [[
        INSERT INTO ClientAnswerOptions (client_question_id, standard_option_id)
        VALUES (?, ?);
      ]]
      local option_stmt = db:prepare(insert_option)
      option_stmt:bind_values(question_stmt:last_insert_rowid(), option.standard_option_id)
      option_stmt:step()
      option_stmt:finalize()
    end
  end

  print("Survey created with ID: " .. survey_id)
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
    SELECT * FROM SurveyMetadata WHERE survey_id = ?;
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

-- Close the database connection when done
function CloseDb()
  db:close()
end

-- Example Initialization
InitDb()
