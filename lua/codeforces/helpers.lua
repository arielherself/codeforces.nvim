local M = {}

function M:generate_random_string(length)
  local result = ""
  for _ = 1, length do
    local isalpha = math.random(1, 2)
    if isalpha == 1 then
      result = result .. string.char(math.random(97, 97 + 25))
    else
      result = result .. string.char(math.random(48, 48 + 9))
    end
  end
  return result
end

function M:rstrip(str)
    return str:gsub("[\n\r]", " ")
end

return M
