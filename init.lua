-- ~/.config/nvim/lua/neostats/init.lua
local M = {}
local session_start_time

-- Define days and months to handle leap years
local function is_leap_year(year)
  return (year % 4 == 0 and year % 100 ~= 0) or (year % 400 == 0)
end

local function get_days_in_year(year)
  if is_leap_year(year) then
    return 366
  else
    return 365
  end
end

local function generate_year_days(year)
  local days = {}
  local date = os.date("*t")
  date.year = year
  date.month = 1
  date.day = 1
  local day_of_year_start = os.time(date)
  for day = 0, get_days_in_year(year) - 1 do
    table.insert(days, os.date("%Y-%m-%d", os.time({year = date.year, month = 1, day = 1}) + day * 86400))
  end
  return days
end

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
  local session_durations = {}
  if file then
    for line in file:lines() do
      local parts = vim.split(line, ",")
      if #parts >= 2 then
        local date = parts[2]
        local duration = tonumber(parts[1])
        if session_durations[date] then
          session_durations[date] = session_durations[date] + duration
        else
          session_durations[date] = duration
        end
      end
    end
    file:close()
  end

  local year_days = generate_year_days(os.date("*t").year)
  local visualization = {}
  local last_month = nil
  for _, day in ipairs(year_days) do
    local current_month = day:sub(6, 7)  -- Extract the month from "YYYY-MM-DD"
    if last_month and last_month ~= current_month then
      table.insert(visualization, '\n')  -- Add a new line at the end of a month
    end
    last_month = current_month
    local duration = session_durations[day] or 0
    local symbol
    if duration == 0 then
      symbol = '·'
  elseif duration < 3600 then
      symbol = '░'
    elseif duration < 10800 then
      symbol = '▒'
    elseif duration < 21600 then
      symbol = '▓'
    else
      symbol = '█'
    end
    table.insert(visualization, symbol)
  end
  print(table.concat(visualization))
end

-- Autocommands
vim.api.nvim_create_autocmd("VimEnter", {
  callback = M.neostats_start
})

vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = M.neostats_end
})

-- Command to display the NeoStats visualization
vim.api.nvim_create_user_command('NeoStats', M.neostats, {})

return M

