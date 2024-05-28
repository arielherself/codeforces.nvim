local curl = require('plenary.curl')
local helpers = require('codeforces.helpers')

local M = {}

local function _debug(any)
    vim.notify(vim.inspect(any), vim.log.levels.INFO)
end

local function _failed_parse()
    vim.notify("Error parsing the response from Codeforces.", vim.log.levels.ERROR)
end

local function _failed_credential()
    vim.notify("Invalid username/password", vim.log.levels.ERROR)
end

local function _hello()
    vim.notify("Hello Codeforces!", vim.log.levels.INFO)
end

local function _with_csrf_token(callback)
    curl.get {
        url = "https://codeforces.com/enter",
        callback = function(res)
            local _, start = res.body:find("data-csrf='", 1, true)
            if start then
                start = start + 1
                local tail, _ = res.body:sub(start):find("'", 1, true)
                if tail then
                    tail = tail - 2
                    local csrf = res.body:sub(start, start + tail)
                    M._csrf = csrf
                    callback(csrf)
                else
                    _failed_parse()
                end
            else
                _failed_parse()
            end
        end,
    }
end

local function _with_login_status(callback)
    curl.post {
        url = "https://codeforces.com/enter",
        form = {
            csrf_token = M._csrf,
            action = "enter",
            ftaa = M._ftaa,
            bfaa = M._bfaa,
            handleOrEmail = M._username,
            password = M._password,
            _tta = 760,
        },
        callback = function(res)
            local status = res.status == 302
            M._logged_in = status
            callback(status)
        end,
        redirect = false,
    }
end

local function _gen_token()
    M._ftaa = helpers:generate_random_string(18)
    M._bfaa = 'f1b3f18c715565b589b7823cda7448ce'
end

local function _auth()
    if not M._username or not M._password then
        _failed_credential()
        return
    end
    _gen_token()
    _with_csrf_token(function()
        _with_login_status(function(status)
            if status == true then
                _hello()
            else
                _failed_credential()
            end
        end)
    end)
end

local function _read_local_credential()
    if vim.fn.filereadable('.codeforces-credential') == 1 then
        local lines = vim.fn.readfile('.codeforces-credential')
        if #lines == 2 then
            return helpers:rstrip(lines[1]), helpers:rstrip(lines[2])
        end
    end
end

local function _write_local_credential()
    if M._username and M._password then
        vim.fn.writefile({ M._username, M._password }, '.codeforces-credential')
    end
end

function M:auth()
    local u, p = _read_local_credential()
    if u and p then
        M._username = u
        M._password = p
        _auth()
        return
    end
    vim.ui.input({
        prompt = "Enter Codeforces handle/email: ",
    }, function(input)
        M._username = input
        vim.ui.input({
            prompt = "Enter password: ",
            secret = true,
        }, function(input)
            M._password = input
            _write_local_credential()
            _auth()
        end)
    end)
end

M:auth()

return M
