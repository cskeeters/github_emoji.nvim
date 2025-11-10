-- local utf8 = require 'lua-utf8'
local fmt = string.format

EMOJI_PATH = "data/emoji.txt"

local emoji = nil -- Loaded when this is not nil

local M = {}

M.default_opts = {
    notify_min_level = vim.log.levels.INFO,
}

M.opts = {}

local NOTIFICATION_NAME = "github_emoji.nvim"
local function log(msg, level)
    -- Filtering for this plugin only
    if level >= M.opts.notify_min_level then
        vim.notify(NOTIFICATION_NAME.. ": " .. msg, level);
    end
end

local function log_trace(msg)
    log(msg, vim.log.levels.TRACE)
end

local function log_debug(msg)
    log(msg, vim.log.levels.DEBUG)
end

local function log_info(msg)
    log(msg, vim.log.levels.INFO)
end

local function log_warn(msg)
    log(msg, vim.log.levels.WARN)
end

local function log_error(msg)
    log(msg, vim.log.levels.ERROR)
end


function path_exists(rpath)
    local paths = vim.api.nvim_get_runtime_file(rpath, false)
    return #paths > 0
end

function get_path(rpath)
    local paths = vim.api.nvim_get_runtime_file(rpath, false)
    if #paths == 0 then
        error("Error loading: "..rpath)
    end
    return paths[1]
end

function contains(table, value)
  for i = 1,#table do
    if (table[i] == value) then
      return true
    end
  end
  return false
end

function get_lines(data)
    local lines = {}
    for s in data:gmatch("[^\r\n]+") do
        table.insert(lines, s)
    end
    return lines
end

function load_emoji()
    local options = {}
    for line in io.lines(get_path(EMOJI_PATH)) do
        local data = split(line, "	")

        -- Generate Name
        local symbol = data[1]
        local markup = data[2]

        -- Change the order for selection
        local fzf_line = string.format("%s	%s", markup, symbol)
        table.insert(options, fzf_line)
    end

    return options
end



load_data = function()
    -- Set the globals in one shot
    emoji = load_emoji()
    log_info("Loaded GitHub Emoji");
end

M.select_emoji = function()
    if emoji == nil then
        log_error("GitHub Emoji not loaded")
        return
    end

    -- detect if telescope is loaded
    local telescope = pcall(require, "telescope") and package.loaded["telescope._extensions.ui-select"]

    local start_mode = vim.api.nvim_get_mode().mode
    log_trace("Starting in mode: "..start_mode)

    if not telescope then
        if vim.api.nvim_get_mode().mode == 'i' then
            key = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
            -- n: no remap
            -- x: Execute commands until typeahead is empty (critical)
            vim.api.nvim_feedkeys(key, 'nx', false)
        end
    end

    local mode = vim.api.nvim_get_mode().mode
    log_trace("Starting select in mode: "..mode)

    local _, start_col = unpack(vim.api.nvim_win_get_cursor(0))
    log_trace("Starting col: "..start_col)

    vim.ui.select(emoji, {
        prompt = "Select an emoji to enter:",
        kind = "emoji_select",
    }, function(choice)
        if choice then
            local s, e, markup = string.find(choice, "([^%s]+)	")

            if s == nil then
                log_error("Error parsing choice")
            else
                log_trace(string.format("Found %s at (%d, %d) in %s", markup, s, e, choice))
                -- telescope will always be in normal mode (n)
                -- fzf-lua   will always be in terminal mode (t)
                local callback_mode = vim.api.nvim_get_mode().mode
                log_trace("Handling selection in mode: "..callback_mode)

                if callback_mode == 'n' then
                    -- Handle telescope
                    if start_mode == 'n' then
                        vim.api.nvim_feedkeys("i", "n", true)
                    else
                        if start_mode == 'i' then
                            vim.api.nvim_feedkeys("a", "n", true)
                        end
                    end
                end

                if callback_mode == 't' then
                    -- Handle fzf-lua
                    local row, col = unpack(vim.api.nvim_win_get_cursor(0))

                    if col ~= start_col then
                        -- We were at the end of a line and the cursor was backed up
                        vim.api.nvim_feedkeys("a", "n", true)
                    else
                        vim.api.nvim_feedkeys("i", "n", true)
                    end
                end

                vim.api.nvim_feedkeys(markup, "n", true)

                if start_mode == 'n' then
                    key = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
                    vim.api.nvim_feedkeys(key, 'n', false)

                    -- move to the left one char (may not work if we're at the end of a line, but no error)
                    vim.api.nvim_feedkeys("l", "n", true)
                end
            end
        end
    end)
end

M.setup = function(opts)
    M.opts = vim.tbl_deep_extend('keep', opts, M.default_opts)

    if not path_exists(EMOJI_PATH) then
        log_error("Could not find " .. EMOJI_PATH)
        return
    end

    vim.schedule(load_data)
end

return M
