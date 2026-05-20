local M = {}

-- "given_a_valid_cert_chain_when_running_filter_then_tls_config_is_set"
-- → "Given a valid cert chain | When running filter | Then tls config is set"
function M.format(name)
  if name:lower():match("^given_") then
    local rest = name:sub(7) -- skip "given_"

    local ws, we = rest:lower():find("_when_")
    if ws then
      local given_part = rest:sub(1, ws - 1):gsub("_", " ")
      rest = rest:sub(we + 1)

      local ts, te = rest:lower():find("_then_")
      if ts then
        local when_part = rest:sub(1, ts - 1):gsub("_", " ")
        local then_part = rest:sub(te + 1):gsub("_", " ")
        return "Given " .. given_part .. " | When " .. when_part .. " | Then " .. then_part
      end

      return "Given " .. given_part .. " | When " .. rest:gsub("_", " ")
    end

    return "Given " .. rest:gsub("_", " ")
  end

  -- Non-GWT: replace underscores, capitalize first letter
  local s = name:gsub("_", " ")
  return s:sub(1, 1):upper() .. s:sub(2)
end

-- Returns lines for the indented preview pane
function M.preview_lines(name)
  local display = M.format(name)
  if not display:find("^Given ") then
    return { display }
  end

  local parts = {}
  for part in display:gmatch("([^|]+)") do
    table.insert(parts, vim.trim(part))
  end

  local lines = {}
  if parts[1] then table.insert(lines, parts[1]) end
  if parts[2] then table.insert(lines, "  " .. parts[2]) end
  if parts[3] then table.insert(lines, "    " .. parts[3]) end
  return lines
end

-- Converts a (possibly edited) GWT display string back to a Rust snake_case identifier
function M.to_snake(display)
  local is_gwt = display:find("^Given ") or display:find("| When ") or display:find("| Then ")
  if is_gwt then
    local parts = {}
    for part in display:gmatch("([^|]+)") do
      part = vim.trim(part)
      part = part:gsub("^Given ", ""):gsub("^When ", ""):gsub("^Then ", "")
      table.insert(parts, (part:gsub(" +", "_"):lower()))
    end
    if #parts == 1 then
      return "given_" .. parts[1]
    elseif #parts == 2 then
      return "given_" .. parts[1] .. "_when_" .. parts[2]
    else
      return "given_" .. parts[1] .. "_when_" .. parts[2] .. "_then_" .. parts[3]
    end
  end
  return display:gsub(" +", "_"):lower()
end

return M
