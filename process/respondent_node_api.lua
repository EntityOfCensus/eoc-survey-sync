--[[
    Imports -- Required Libraries
]] --

local json = require("json")
local ao = require("ao")
local sqlite3 = require("sqlite3")

-- Open the database
local db = sqlite3.open("respondent_node.db")

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

-- Function to Initialize the Respondent Node Database
function InitDb(schema_sql)
  db:exec(RESPONDENT_QUESTIONNAIRE_ANSWERS)
  db:exec(SURVEY_RESPONSES)

  -- Execute schema_sql if provided (e.g., schema updates)
  if schema_sql then
    db:exec(schema_sql)
  end
end

-- Function for Respondent to Answer the Standard Questionnaire
function AnswerStandardQuestionnaire(respondent_id, answers)
  for _, answer in ipairs(answers) do
    local insert_answer = [[
      INSERT INTO RespondentQuestionnaireAnswers (respondent_id, question_id, selected_option_id, answer_timestamp)
      VALUES (?, ?, ?, CURRENT_TIMESTAMP);
    ]]
    local stmt = db:prepare(insert_answer)
    stmt:bind_values(respondent_id, answer.question_id, answer.selected_option_id)
    stmt:step()
    stmt:finalize()
  end

  print("Standardized questionnaire answers stored for respondent ID: " .. respondent_id)
end

-- Function to Get Available Surveys for Respondent
function GetAvailableSurveys(respondent_id)
  -- Fetch respondent details for demographic matching (geolocation, age, sex)
  local respondent_query = [[
    SELECT age, sex, geolocation FROM Respondents WHERE respondent_id = ?;
  ]]
  local stmt = db:prepare(respondent_query)
  stmt:bind_values(respondent_id)
  stmt:step()
  local age = stmt:get_value(0)
  local sex = stmt:get_value(1)
  local geolocation = stmt:get_value(2)
  stmt:finalize()

  -- Fetch eligible surveys from SurveyMetadata based on respondent's demographics
  local eligible_surveys = {}
  local survey_query = [[
    SELECT survey_id, title FROM SurveyMetadata
    WHERE (target_age_range IS NULL OR target_age_range = ?)
    AND (target_sex IS NULL OR target_sex = ?)
    AND (target_geolocation IS NULL OR target_geolocation = ?)
    AND status = 'published';
  ]]
  local survey_stmt = db:prepare(survey_query)
  survey_stmt:bind_values(age, sex, geolocation)

  for row in survey_stmt:nrows() do
    table.insert(eligible_surveys, {survey_id = row.survey_id, title = row.title})
  end
  survey_stmt:finalize()

  print("Eligible surveys for respondent ID: " .. respondent_id)
  for _, survey in ipairs(eligible_surveys) do
    print("Survey ID: " .. survey.survey_id .. ", Title: " .. survey.title)
  end

  return eligible_surveys
end

-- Function for Respondent to Submit Survey Responses
function SubmitSurveyResponse(respondent_id, survey_id, responses)
  for _, response in ipairs(responses) do
    local insert_response = [[
      INSERT INTO SurveyResponses (respondent_id, survey_id, question_id, selected_option_id, response_timestamp)
      VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP);
    ]]
    local stmt = db:prepare(insert_response)
    stmt:bind_values(respondent_id, survey_id, response.question_id, response.selected_option_id)
    stmt:step()
    stmt:finalize()
  end

  print("Survey responses stored for respondent ID: " .. respondent_id .. ", Survey ID: " .. survey_id)
end

-- Close the database connection when done
function CloseDb()
  db:close()
end

-- Example Initialization
InitDb()
