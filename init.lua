-- ~/.config/nvim/lua/neostats/init.lua
local M = {}
local session_start_time

function M.neostats_start()
    session_start_time = os.time()
end

function M.neostats_end()
    local session_end_time = os.time()
    -- Calculate duration in seconds as an integer
    local duration = os.difftime(session_end_time, session_start_time)
    local date = os.date("%Y-%m-%d")
    local line = tostring(duration) .. "," .. date .. "\n" -- Ensure duration is a string without decimals
    local file_path = vim.fn.stdpath('data') .. '/sessions.csv'
    local file = io.open(file_path, "a+")
    if file then
        file:write(line)
        file:close()
    end
end

function M.neostats()
    local file_path = vim.fn.stdpath('data') .. '/sessions.csv'
    local file = io.open(file_path, "r")
    if file then
        for line in file:lines() do
            print(line)
        end
        file:close()
    else
        print("No session data found.")
    end
end

-- Autocommands
vim.api.nvim_create_autocmd("VimEnter", {
    callback = M.neostats_start
})

vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = M.neostats_end
})

-- Command
vim.api.nvim_create_user_command('NeoStats', M.neostats, {})

return M

