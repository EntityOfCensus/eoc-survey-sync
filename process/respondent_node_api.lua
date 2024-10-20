--[[
    Imports -- Required Libraries
]] --
local json = require("json")
local ao = require("ao")
local sqlite3 = require("lsqlite3")

-- Open the database
local db = db or sqlite3.open_memory()

-- Utility Functions

-- Function to insert a respondent's answer
function InsertRespondentAnswer(response_id, client_question_id, selected_option_id, answer_text)
    local stmt = db:prepare([[
        INSERT INTO RespondentAnswers (response_id, client_question_id, selected_option_id, answer_text)
        VALUES (?, ?, ?, ?)
    ]])
    stmt:bind_values(response_id, client_question_id, selected_option_id, answer_text)
    stmt:step()
    stmt:finalize()
end

-- Function to insert a respondent's vote
function InsertVotingRecord(respondent_id, tool_id, selected_option_id)
    local stmt = db:prepare([[
        INSERT INTO VotingRecords (respondent_id, tool_id, selected_option_id)
        VALUES (?, ?, ?)
    ]])
    stmt:bind_values(respondent_id, tool_id, selected_option_id)
    stmt:step()
    stmt:finalize()
end

-- Function to get a respondent's answer by respondent_id and client_question_id
function GetResponseByRespondentIdAndQuestionId(respondent_id, client_question_id)
    local stmt = db:prepare([[
        SELECT * FROM RespondentAnswers 
        WHERE respondent_id = ? AND client_question_id = ?
    ]])
    stmt:bind_values(respondent_id, client_question_id)
    local result = stmt:step()
    local response = {}

    if result == sqlite3.ROW then
        response = {
            answer_id = stmt:get_value(0),
            response_id = stmt:get_value(1),
            client_question_id = stmt:get_value(2),
            selected_option_id = stmt:get_value(3),
            answer_text = stmt:get_value(4),
            answered_at = stmt:get_value(5)
        }
    end

    stmt:finalize()
    return response
end

-- Utility function to paginate respondent answers
function GetPaginatedRespondentAnswers(page, page_size)
    local offset = (page - 1) * page_size
    local stmt = db:prepare([[
        SELECT * FROM RespondentAnswers
        LIMIT ? OFFSET ?
    ]])
    stmt:bind_values(page_size, offset)
    local result = stmt:step()
    local answers = {}

    while result == sqlite3.ROW do
        table.insert(answers, {
            answer_id = stmt:get_value(0),
            response_id = stmt:get_value(1),
            client_question_id = stmt:get_value(2),
            selected_option_id = stmt:get_value(3),
            answer_text = stmt:get_value(4),
            answered_at = stmt:get_value(5)
        })
        result = stmt:step()
    end

    stmt:finalize()
    return answers
end

-- Function to insert form submission data
function InsertFormSubmission(respondent_id, instance_id, client_category_id, submission_data)
    local stmt = db:prepare([[
        INSERT INTO FormSubmissions (respondent_id, instance_id, client_category_id, submission_data)
        VALUES (?, ?, ?, ?)
    ]])
    stmt:bind_values(respondent_id, instance_id, client_category_id, submission_data)
    stmt:step()
    stmt:finalize()
end

-- Handler Definitions

-- SubmitResponse Handler: Insert respondent's answer
Handlers.add(
    "SubmitResponse",
    Handlers.utils.hasMatchingTag("Action", "SubmitResponse"),
    function(msg)
        local response_data = json.decode(msg.Data)
        InsertRespondentAnswer(
            response_data.response_id,
            response_data.client_question_id,
            response_data.selected_option_id,
            response_data.answer_text
        )
        ao.send({ Target = msg.From, Data = "Response submitted" })
    end
)

-- SubmitVote Handler: Insert respondent's vote
Handlers.add(
    "SubmitVote",
    Handlers.utils.hasMatchingTag("Action", "SubmitVote"),
    function(msg)
        local vote_data = json.decode(msg.Data)
        InsertVotingRecord(
            vote_data.respondent_id,
            vote_data.tool_id,
            vote_data.selected_option_id
        )
        ao.send({ Target = msg.From, Data = "Vote submitted" })
    end
)

-- GetResponseByRespondentIdAndQuestionId Handler: Get respondent's answer by respondent_id and client_question_id
Handlers.add(
    "GetResponseByRespondentIdAndQuestionId",
    Handlers.utils.hasMatchingTag("Action", "GetResponseByRespondentIdAndQuestionId"),
    function(msg)
        local data = json.decode(msg.Data)
        local response = GetResponseByRespondentIdAndQuestionId(data.respondent_id, data.client_question_id)
        ao.send(
            {
                Target = msg.From,
                Data = json.encode(response)
            }
        )
    end
)

-- PaginateRespondentAnswers Handler: Paginate through respondent answers
Handlers.add(
    "PaginateRespondentAnswers",
    Handlers.utils.hasMatchingTag("Action", "PaginateRespondentAnswers"),
    function(msg)
        local data = json.decode(msg.Data)
        local page = data.page or 1
        local page_size = data.page_size or 10
        local paginated_answers = GetPaginatedRespondentAnswers(page, page_size)

        ao.send(
            {
                Target = msg.From,
                Data = json.encode(paginated_answers)
            }
        )
    end
)

-- SubmitForm Handler: Insert respondent's form submission
Handlers.add(
    "SubmitForm",
    Handlers.utils.hasMatchingTag("Action", "SubmitForm"),
    function(msg)
        local form_data = json.decode(msg.Data)
        InsertFormSubmission(
            form_data.respondent_id,
            form_data.instance_id,
            form_data.client_category_id,
            form_data.submission_data
        )
        ao.send({ Target = msg.From, Data = "Form submitted" })
    end
)

-- Existing handlers for other respondent actions like form submission, etc.
