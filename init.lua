-- ~/.config/nvim/lua/neostats/init.lua
local M = {}
local session_start_time

function M.neostats_start()
    session_start_time = os.time()
end

function M.neostats_end()
    local session_end_time = os.time()
    local current_duration = os.difftime(session_end_time, session_start_time)
    local today = os.date("%Y-%m-%d")
    
    local file_path = vim.fn.stdpath('data') .. '/sessions.csv'
    local lines = {}
    local last_line_updated = false

    -- Read existing data and prepare to update or append new data
    local file = io.open(file_path, "r")
    if file then
        for line in file:lines() do
            table.insert(lines, line)
        end
        file:close()
        
        if #lines > 1 then
            local last_line = lines[#lines]
            local parts = vim.split(last_line, ",")
            local last_date = parts[2]

            if last_date == today then
                -- Update the last line if the date is the same
                local last_duration = tonumber(parts[1])
                local new_duration = last_duration + current_duration
                lines[#lines] = new_duration .. "," .. today
                last_line_updated = true
            end
        end
    end

    -- Append new line if the last line's date is different or no data exists
    if not last_line_updated then
        table.insert(lines, current_duration .. "," .. today)
    end

    -- Write updated content to the file
    file = io.open(file_path, "w")
    if file then
        for _, line in ipairs(lines) do
            file:write(line .. "\n")
        end
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

