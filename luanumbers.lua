local M = {
  version = "0.5.0",
  decimals = 2,
  rounding = "half-up",
  pad_zeroes = true,
  integers = false,
  preserve_exponent = true,
  normalize_negative_zero = true,
  input_decimal = "dot",
  warnings = "once",
  enabled = false,
  registered = false,
  auto_protect = true,
  protected_stack = {},
  protected_command_depth = 0,
  warned = {},
  protected_environments = {
    axis = true,
    filecontents = true,
    ["filecontents*"] = true,
    luanumbersexclude = true,
    lstlisting = true,
    minted = true,
    pgfpicture = true,
    tikzpicture = true,
    verbatim = true,
    ["verbatim*"] = true,
  },
  protected_commands = {
    addbibresource = true,
    addcontentsline = true,
    addtolength = true,
    bibliography = true,
    cite = true,
    eqref = true,
    geometry = true,
    href = true,
    include = true,
    includegraphics = true,
    input = true,
    label = true,
    lstinputlisting = true,
    pageref = true,
    path = true,
    pgfkeys = true,
    pgfplotsset = true,
    ref = true,
    setlength = true,
    tikzset = true,
    url = true,
  },
}

local valid_rounding = {
  ["half-up"] = true,
  ["half-even"] = true,
  truncate = true,
  floor = true,
  ceil = true,
}

local generated_extensions = {
  aux = true,
  bbl = true,
  idx = true,
  ind = true,
  lof = true,
  lot = true,
  nav = true,
  out = true,
  snm = true,
  toc = true,
}

local function fail(message)
  if tex and tex.error then
    tex.error("luanumbers: " .. message)
  else
    error("luanumbers: " .. message, 2)
  end
end

local function trim(value)
  return value:match("^%s*(.-)%s*$")
end

local function parse_boolean(value, key)
  value = value:lower()
  if value == "true" or value == "yes" or value == "on" then
    return true
  end
  if value == "false" or value == "no" or value == "off" then
    return false
  end
  fail("'" .. key .. "' must be true or false")
  return false
end

local function warn(kind, message)
  if M.warnings == "off" then
    return
  end
  if M.warnings == "once" and M.warned[kind] then
    return
  end
  M.warned[kind] = true
  local line = status and status.inputlineno
  if line and line > 0 then
    message = message .. " (input line " .. line .. ")"
  end
  if M.warnings == "error" then
    fail(message)
  elseif texio and texio.write_nl then
    texio.write_nl("term and log", "Package luanumbers Warning: " .. message)
  end
end

function M.configure(settings)
  for item in settings:gmatch("[^,]+") do
    local key, value = item:match("^%s*([%w%-_]+)%s*=%s*(.-)%s*$")
    if not key then
      fail("invalid setting '" .. trim(item) .. "'")
      return
    end
    key = key:gsub("_", "-"):lower()
    value = trim(value)
    if key == "decimals" then
      local number = tonumber(value)
      if not number or number < 0 or number > 100 or number % 1 ~= 0 then
        fail("'decimals' must be an integer from 0 to 100")
        return
      end
      M.decimals = number
    elseif key == "rounding" then
      value = value:lower()
      if not valid_rounding[value] then
        fail("unknown rounding mode '" .. value .. "'")
        return
      end
      M.rounding = value
    elseif key == "pad-zeroes" or key == "trailing-zeroes" then
      M.pad_zeroes = parse_boolean(value, key)
    elseif key == "integers" then
      M.integers = parse_boolean(value, key)
    elseif key == "auto-protect" then
      M.auto_protect = parse_boolean(value, key)
    elseif key == "preserve-exponent" then
      M.preserve_exponent = parse_boolean(value, key)
    elseif key == "normalize-negative-zero" then
      M.normalize_negative_zero = parse_boolean(value, key)
    elseif key == "input-decimal" then
      value = value:lower()
      if value ~= "dot" and value ~= "comma" and value ~= "both" then
        fail("'input-decimal' must be dot, comma, or both")
        return
      end
      M.input_decimal = value
    elseif key == "warnings" then
      value = value:lower()
      if value ~= "off" and value ~= "once" and value ~= "all"
          and value ~= "error" then
        fail("'warnings' must be off, once, all, or error")
        return
      end
      M.warnings = value
    else
      fail("unknown setting '" .. key .. "'")
      return
    end
  end
end

local function register(set, name)
  name = trim(name)
  if name == "" then
    fail("protected name must not be empty")
    return
  end
  set[name] = true
end

function M.protect_environment(name) register(M.protected_environments, name) end
function M.unprotect_environment(name) M.protected_environments[trim(name)] = nil end
function M.protect_command(name) register(M.protected_commands, name:gsub("^\\", "")) end
function M.unprotect_command(name)
  M.protected_commands[trim(name):gsub("^\\", "")] = nil
end

local function apply_list(value, callback)
  for name in tostring(value):gmatch("[^,]+") do
    callback(trim(name))
  end
end

function M.protect_environments(value)
  apply_list(value, M.protect_environment)
end

function M.unprotect_environments(value)
  apply_list(value, M.unprotect_environment)
end

function M.protect_commands(value)
  apply_list(value, M.protect_command)
end

function M.unprotect_commands(value)
  apply_list(value, M.unprotect_command)
end

local function increment_digits(digits)
  local output = {}
  local carry = 1
  for index = #digits, 1, -1 do
    local digit = tonumber(digits:sub(index, index)) + carry
    if digit >= 10 then
      output[index] = "0"
      carry = 1
    else
      output[index] = tostring(digit)
      carry = 0
    end
  end
  return (carry == 1 and "1" or "") .. table.concat(output)
end

local function parse_decimal(value)
  local unicode_minus = value:sub(1, 3) == "−"
  if unicode_minus then value = "-" .. value:sub(4) end
  local sign, body = value:match("^([+-]?)(.+)$")
  local mantissa, marker, exponent = body:match("^(.-)([eE])([+-]?%d+)$")
  if not mantissa then
    mantissa, marker, exponent = body, "", ""
  end
  local decimal = mantissa:find(".", 1, true) and "."
    or (mantissa:find(",", 1, true) and ",")
  local integer, fraction
  if decimal then
    integer, fraction = mantissa:match("^(%d*)[.,](%d*)$")
  else
    integer, fraction = mantissa:match("^(%d+)$"), ""
  end
  if not integer or (integer == "" and fraction == "") then
    return nil
  end
  return {
    sign = sign,
    integer = integer == "" and "0" or integer,
    fraction = fraction,
    decimal = decimal,
    exponent_marker = marker,
    exponent = exponent,
    unicode_minus = unicode_minus,
  }
end

local function discarded_is_nonzero(discarded)
  return discarded:find("[1-9]") ~= nil
end

local function should_increment(parsed, kept, discarded)
  if discarded == "" or not discarded_is_nonzero(discarded) then
    return false
  end
  if M.rounding == "truncate" then
    return false
  elseif M.rounding == "floor" then
    return parsed.sign == "-"
  elseif M.rounding == "ceil" then
    return parsed.sign ~= "-"
  end
  local first = tonumber(discarded:sub(1, 1))
  if first > 5 then
    return true
  elseif first < 5 then
    return false
  elseif discarded:sub(2):find("[1-9]") then
    return true
  elseif M.rounding == "half-up" then
    return true
  end
  local previous = kept:sub(-1)
  return previous ~= "" and tonumber(previous) % 2 == 1
end

local function all_zero(integer, fraction)
  return not (integer .. fraction):find("[1-9]")
end

function M.format(value)
  local parsed = parse_decimal(trim(tostring(value)))
  if not parsed then
    fail("cannot format '" .. tostring(value) .. "' as a decimal number")
    return value
  end

  if parsed.exponent_marker ~= "" and not M.preserve_exponent then
    warn("exponent-conversion",
      "preserve-exponent=false may change notation and significant figures")
    local numeric = tonumber(value:gsub(",", "."))
    if not numeric then
      fail("cannot expand exponent in '" .. tostring(value) .. "'")
      return value
    end
    parsed = parse_decimal(string.format("%.100f", numeric):gsub("0+$", ""))
  end

  local fraction = parsed.fraction
  local kept_fraction = fraction:sub(1, M.decimals)
  local discarded = fraction:sub(M.decimals + 1)
  if #kept_fraction < M.decimals then
    kept_fraction = kept_fraction .. string.rep("0", M.decimals - #kept_fraction)
  end

  local combined = parsed.integer .. kept_fraction
  if should_increment(parsed, combined, discarded) then
    combined = increment_digits(combined)
  end
  local split = #combined - M.decimals
  local integer = M.decimals == 0 and combined or combined:sub(1, split)
  local output_fraction = M.decimals == 0 and "" or combined:sub(split + 1)
  integer = integer:gsub("^0+(%d)", "%1")

  if not M.pad_zeroes then
    output_fraction = output_fraction:gsub("0+$", "")
  end
  local sign = parsed.sign
  if M.normalize_negative_zero and sign == "-" and all_zero(integer, output_fraction) then
    sign = ""
  end
  local decimal = parsed.decimal == "," and "," or "."
  if sign == "-" and parsed.unicode_minus then sign = "−" end
  local result = sign .. integer
  if output_fraction ~= "" then
    result = result .. decimal .. output_fraction
  elseif M.pad_zeroes and M.decimals > 0 then
    result = result .. decimal .. string.rep("0", M.decimals)
  end
  return result .. parsed.exponent_marker .. parsed.exponent
end

local function find_comment(line)
  local start = 1
  while true do
    local position = line:find("%", start, true)
    if not position then return nil end
    local slashes, cursor = 0, position - 1
    while cursor > 0 and line:sub(cursor, cursor) == "\\" do
      slashes, cursor = slashes + 1, cursor - 1
    end
    if slashes % 2 == 0 then return position end
    start = position + 1
  end
end

local function pop_environment(name)
  for index = #M.protected_stack, 1, -1 do
    if M.protected_stack[index] == name then
      table.remove(M.protected_stack, index)
      return
    end
  end
end

local function update_environment_state(source)
  if not M.auto_protect then
    M.protected_stack = {}
    return false
  end
  local protect_line = #M.protected_stack > 0
  local position = 1
  while true do
    local begin_at, begin_end, begin_name = source:find(
      "\\begin%s*{%s*([^}]+)%s*}", position)
    local end_at, end_end, end_name = source:find(
      "\\end%s*{%s*([^}]+)%s*}", position)
    if not begin_at and not end_at then break end
    if begin_at and (not end_at or begin_at < end_at) then
      begin_name = trim(begin_name)
      if M.protected_environments[begin_name] then
        M.protected_stack[#M.protected_stack + 1] = begin_name
        protect_line = true
      end
      position = begin_end + 1
    else
      end_name = trim(end_name)
      if M.protected_environments[end_name] then
        protect_line = true
        pop_environment(end_name)
      end
      position = end_end + 1
    end
  end
  return protect_line
end

local function command_argument_end(source, position)
  local cursor = position
  while source:sub(cursor, cursor):match("%s") do cursor = cursor + 1 end
  while source:sub(cursor, cursor) == "[" do
    local close = source:find("]", cursor + 1, true)
    if not close then return #source end
    cursor = close + 1
    while source:sub(cursor, cursor):match("%s") do cursor = cursor + 1 end
  end
  while source:sub(cursor, cursor) == "{" do
    local depth, index = 0, cursor
    repeat
      local character = source:sub(index, index)
      if character == "{" then depth = depth + 1 end
      if character == "}" then depth = depth - 1 end
      index = index + 1
    until depth == 0 or index > #source + 1
    if depth ~= 0 then
      M.protected_command_depth = depth
      warn("multiline-command",
        "a protected command argument spans lines and is being preserved")
      return #source
    end
    cursor = index
    while source:sub(cursor, cursor):match("%s") do cursor = cursor + 1 end
  end
  return cursor - 1
end

local function update_multiline_command_state(source)
  if M.protected_command_depth == 0 then return false end
  for index = 1, #source do
    local character = source:sub(index, index)
    local previous = index > 1 and source:sub(index - 1, index - 1) or ""
    if previous ~= "\\" then
      if character == "{" then
        M.protected_command_depth = M.protected_command_depth + 1
      elseif character == "}" then
        M.protected_command_depth = M.protected_command_depth - 1
        if M.protected_command_depth == 0 then break end
      end
    end
  end
  return true
end

local function protected_command_at(source, position)
  if source:sub(position, position) ~= "\\" then return nil end
  local name = source:sub(position + 1):match("^([A-Za-z@]+)")
  if not name or not M.protected_commands[name] then return nil end
  local command_end = position + #name
  return command_argument_end(source, command_end + 1)
end

local function number_at(source, position)
  local rest = source:sub(position)
  local unicode_minus = rest:sub(1, 3) == "−"
  local match_source = unicode_minus and ("-" .. rest:sub(4)) or rest
  local patterns = {}
  if M.input_decimal == "dot" or M.input_decimal == "both" then
    patterns[#patterns + 1] = "^[+-]?%d*%.%d+[eE][+-]?%d+"
    patterns[#patterns + 1] = "^[+-]?%d*%.%d+"
  end
  if M.input_decimal == "comma" or M.input_decimal == "both" then
    patterns[#patterns + 1] = "^[+-]?%d*,%d+[eE][+-]?%d+"
    patterns[#patterns + 1] = "^[+-]?%d*,%d+"
  end
  if M.integers then
    patterns[#patterns + 1] = "^[+-]?%d+[eE][+-]?%d+"
    patterns[#patterns + 1] = "^[+-]?%d+"
  end
  for _, pattern in ipairs(patterns) do
    local candidate = match_source:match(pattern)
    if candidate then
      return unicode_minus and ("−" .. candidate:sub(2)) or candidate
    end
  end
  return nil
end

local function is_identifier_character(character)
  return character ~= "" and character:match("[%w_@\\]") ~= nil
end

function M.process_input_buffer(line)
  local filename = status and status.filename or ""
  local extension = filename:match("%.([^.]+)$")
  if extension and generated_extensions[extension:lower()] then
    return line
  end

  local comment_at = find_comment(line)
  local source = comment_at and line:sub(1, comment_at - 1) or line
  local comment = comment_at and line:sub(comment_at) or ""
  local environment_protected = update_environment_state(source)
  local command_protected = update_multiline_command_state(source)
  if environment_protected or command_protected or not M.enabled then return line end

  local output, position = {}, 1
  while position <= #source do
    local protected_end = protected_command_at(source, position)
    if protected_end then
      output[#output + 1] = source:sub(position, protected_end)
      position = protected_end + 1
    else
      local candidate = number_at(source, position)
      local previous = position > 1 and source:sub(position - 1, position - 1) or ""
      local following = candidate
        and source:sub(position + #candidate, position + #candidate) or ""
      if candidate and not is_identifier_character(previous)
          and not is_identifier_character(following) then
        local before_previous = position > 2
          and source:sub(position - 2, position - 2) or ""
        local grouped = (previous == "," or previous == ".")
          and before_previous:match("%d") ~= nil
        local after_following = source:sub(
          position + #candidate + 1, position + #candidate + 1)
        local versioned = (following == "." or following == ",")
          and after_following:match("%d") ~= nil
        if grouped or versioned then
          warn("grouped-or-version",
            "a grouped or version-like number was left unchanged; use LuaNumber explicitly")
          output[#output + 1] = candidate
        elseif previous == "/" or previous == ":" or previous == "=" then
          warn("suspicious-context",
            "a number near '/', ':', or '=' was left unchanged; use LuaNumber explicitly")
          output[#output + 1] = candidate
        else
          output[#output + 1] = M.format(candidate)
        end
        position = position + #candidate
      else
        output[#output + 1] = source:sub(position, position)
        position = position + 1
      end
    end
  end
  return table.concat(output) .. comment
end

function M.enable() M.enabled = true end
function M.disable() M.enabled = false end

function M.register()
  if M.registered then return end
  luatexbase.add_to_callback(
    "process_input_buffer", M.process_input_buffer, "luanumbers.round-input")
  M.registered = true
end

return M
