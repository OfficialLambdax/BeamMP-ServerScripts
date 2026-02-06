--[[
 SJSON Parser for Lua 5.1

 Copyright (c) BeamNG GmbH
 All Rights Reserved.

 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or
 sell copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following conditions:

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR
 ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
 CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

 It decodes SJON format:
  https://github.com/Autodesk/sjson

 Usage:

 local t = json.decode(jsontext)
--]]

local M = {}

if not pcall(require, "table.new") then
  table.new = function() return {} end
end

if not pcall(require, "table.clear") then
  table.clear = function() return {} end
end

local byte, sub, tconcat, tablenew, tableclear = string.byte, string.sub, table.concat, table.new, table.clear

local escapes = {[116] = '\t', [110] = '\n', [102] = '\f', [114] = '\r', [98] = '\b', [34] = '"', [92] = '\\', [10] = '\n', [57] = '\t', [48] = '\r'}
local peekTable, gcrunning = tablenew(256,0), true
local concatTable
local s

local function jsonError(msg, i)
  if gcrunning then collectgarbage("restart") end
  local curlen = 0
  local n = 1
  for w in s:gmatch("([^\n]*)") do
    curlen = curlen + #w
    if curlen >= i then
      error(string.format("%s near line %d, '%s'",msg, n, w:match'^%s*(.*%S)' or ''))
    end
    if w == '' then
      n = n + 1
      curlen = curlen + 1
    end
  end
end

local function error_input(si)
  jsonError('Invalid input', si)
end

local function readNumber(si)
  local c, i, r = byte(s, si), si, 0
  while c >= 48 and c <= 57 do -- \d
    i = i + 1
    r = r * 10 + (c - 48)
    c = byte(s, i)
  end
  if c == 46 then -- .
    i = i + 1
    c = byte(s, i)
    local f, scale = 0, 0.1
    while c >= 48 and c <= 57 do -- \d
      i = i + 1
      f = f + (c - 48) * scale
      c = byte(s, i)
      scale = scale * 0.1
    end
    r = r + f
  elseif c == 35 then -- #
    local infend = si + 6
    if sub(s, si, infend) == "1#INF00" then
      return math.huge, infend + 1
    else
      local pm = byte(s, si - 1)
      jsonError(string.format("Invalid number: '%s'", sub(s, si - ((pm == 45 or pm == 43) and 1 or 0), infend)), si)
    end
  end
  if c == 101 or c == 69 then -- e E
    i = i + 1
    c = byte(s, i)
    while (c >= 45 and c <= 57) or c == 43 do -- \d-+
      i = i + 1
      c = byte(s, i)
    end
    r = tonumber(sub(s, si, i - 1))
    if r == nil then
      local pm = byte(s, si - 1)
      jsonError(string.format("Invalid number: '%s'", sub(s, si - ((pm == 45 or pm == 43) and 1 or 0), i-1)), si)
    end
  end
  return r, i
end

local function readString(si)
  -- fast path
  local si1 = si + 1 -- "
  local ch, i = byte(s, si1), si + 2
  while ch ~= 34 and ch ~= 92 and ch ~= nil do  -- " \
    ch = byte(s, i)
    i = i + 1
  end

  if ch == 34 then -- "
    return sub(s, si1, i - 2), i
  end

  -- slow path for strings with escape chars
  if ch ~= 92 then -- \
    jsonError("String not having an end-quote", si)
    return nil, si1 + 1
  end

  if concatTable then
    tableclear(concatTable)
  else
    concatTable = tablenew(i - si,0)
  end
  local resultidx = 1
  i = si1
  ch = byte(s, i)
  while ch ~= 34 do -- "
    ch = s:match('^[^"\\]*', i)
    i = i + (ch and ch:len() or 0)
    concatTable[resultidx] = ch
    resultidx = resultidx + 1
    ch = byte(s, i)
    if ch == 92 then -- \
      local ch1 = escapes[byte(s, i+1)]
      if ch1 then
        concatTable[resultidx] = ch1
        resultidx = resultidx + 1
        i = i + 1
      else
        concatTable[resultidx] = '\\'
        resultidx = resultidx + 1
      end
      i = i + 1 -- "
    end
  end

  return tconcat(concatTable), i + 1
end

local function skipCommentSpace(i)
  ::restart::
  local c = byte(s, i)
  if c == 47 then -- / -- single line comment "//"
    repeat
      i = i + 1
      c = byte(s, i)
    until c == 10 or c == 13 or c == nil
    i = i + 1
  elseif c == 42 then -- * -- block comment "/*  xxxxxxx */"
    while true do
      i = i + 1
      c = byte(s, i)
      if c == 42 then
        if byte(s, i+1) == 47 then -- */
          break
        elseif byte(s, i-1) == 47 then -- /*
          jsonError("'/*' inside another '/*' comment is not permitted", i)
        end
      end
      if c == nil then break end
    end
    i = i + 2
  else
    jsonError('Invalid comment', i)
  end
  repeat
    c = byte(s, i); i = i + 1
  until (c == nil or c > 32) and c ~= 44 -- matches space tab newline or comma
  if c == 47 then goto restart end
  return c, i
end

local function skipWhiteSpace(i)
  local c = byte(s, i); i = i + 1
  while (c ~= nil and c <= 32) or c == 44 do -- matches space tab newline or comma
    c = byte(s, i); i = i + 1
  end
  if c == 47 then c, i = skipCommentSpace(i) end -- / -- read comment
  return c, i - 1
end

local function readKey(si, c)
  local key
  local i
  if c == 34 then -- '"'
    key, i = readString(si)
  else
    if c == nil then
      jsonError(string.format("Expected dictionary key"), si)
    end
    i = si
    local ch = byte(s, i)
    while (ch >= 97 and ch <= 122) or (ch >= 65 and ch <= 90) or (ch >= 48 and ch <= 57) or ch == 95 do -- [a z] [A Z] or [0 9] or _
      i = i + 1
      ch = byte(s, i)
    end

    i = i - 1
    key = sub(s, si, i)

    if i < si then
      jsonError(string.format("Expected dictionary key"), i)
    end
    i = i + 1
  end
  -- skipWhiteSpace
  repeat
    c = byte(s, i); i = i + 1
  until (c == nil or c > 32) and c ~= 44 -- matches space tab newline or comma
  if c == 47 then c, i = skipCommentSpace(i) end -- / -- read comment

  if c ~= 58 and c ~= 61 then -- : =
    jsonError(string.format("Expected dictionary separator ':' or '=' instead of: '%s'", string.char(c)), i - 1)
  end
  return key, i
end

local function decode(si)
  if si == nil then return nil end
  gcrunning = collectgarbage("isrunning")
  collectgarbage("stop")
  s = si
  local c, i = skipWhiteSpace(1)
  local result
  if c == 123 or c == 91 then
      result, i = peekTable[c](i)
  else
    result = {}
    local key
    while c do
      key, i = readKey(i, c)
      c, i = skipWhiteSpace(i)
      result[key], i = peekTable[c](i)
      c, i = skipWhiteSpace(i)
    end
  end
  concatTable = nil
  s = nil
  if gcrunning then collectgarbage("restart") end
  return result
end

-- build dispatch table
do
  for i = 0, 255 do
    peekTable[i] = error_input
  end

  peekTable[73] = function(si) -- I
    local c1,c2,c3,c4,c5,c6,c7 = byte(s, si+1, si+7)
    if c1==110 and c2==102 and c3==105 and c4==110 and c5==105 and c6==116 and c7==121 then -- nfinity
      return math.huge, si + 8
    else
      jsonError('Error reading value: Infinity', si)
    end
  end
  peekTable[123] = function(si) -- {
      -- parse object
      local key
      local result = tablenew(0, 3)
      local c, i = skipWhiteSpace(si + 1)
      while c ~= 125 do -- }
        key, i = readKey(i, c)
        repeat -- skipWhiteSpace
          c = byte(s, i); i = i + 1
        until (c == nil or c > 32) and c ~= 44 -- matches space tab newline or comma
        result[key], i = peekTable[c](i - 1)
        repeat -- skipWhiteSpace
          c = byte(s, i); i = i + 1
        until c ~= 44 and (c == nil or c > 32) -- matches space tab newline or comma
        if c == 47 then c, i = skipCommentSpace(i) end -- / -- read comment
        i = i - 1
      end
      return result, i + 1
    end
  peekTable[116] = function(si) -- t
      local b1, b2, b3 = byte(s, si+1, si+3)
      if b1 == 114 and b2 == 117 and b3 == 101 then -- rue
        return true, si + 4
      else
        jsonError('Error reading value: true', si)
      end
    end
  peekTable[102] = function(si) -- f
      local b1, b2, b3, b4 = byte(s, si+1, si+4)
      if b1 == 97 and b2 == 108 and b3 == 115 and b4 == 101 then -- alse
        return false, si + 5
      else
        jsonError('Error reading value: false', si)
      end
    end
  peekTable[110] = function(si) -- n
      local b1, b2, b3 = byte(s, si+1, si+3)
      if b1 == 117 and b2 == 108 and b3 == 108 then -- ull
        return nil, si + 4
      else
        jsonError('Error reading value: null', si)
      end
    end
  peekTable[91] = function(si) -- [
      -- Read Array
      local result = tablenew(4, 0)
      local tidx = 1
      local c, i = skipWhiteSpace(si + 1)
      while c ~= 93 do -- ]
        result[tidx], i = peekTable[c](i)
        tidx = tidx + 1
        repeat -- skipWhiteSpace
          c = byte(s, i); i = i + 1
        until c ~= 44 and (c == nil or c > 32) -- matches space tab newline or comma
        if c == 47 then c, i = skipCommentSpace(i) end -- / -- read comment
        i = i - 1
      end
      return result, i + 1
    end
  peekTable[48] = readNumber -- 0
  peekTable[49] = readNumber -- 1
  peekTable[50] = readNumber -- 2
  peekTable[51] = readNumber -- 3
  peekTable[52] = readNumber -- 4
  peekTable[53] = readNumber -- 5
  peekTable[54] = readNumber -- 6
  peekTable[55] = readNumber -- 7
  peekTable[56] = readNumber -- 8
  peekTable[57] = readNumber -- 9
  peekTable[43] = function(i) -- +
      return readNumber(i + 1)
    end
  peekTable[45] = function(si) -- -
      si = si + 1
      local num
      if byte(s, si) == 73 then -- I
        num, si = peekTable[73](si)
      else
        num, si = readNumber(si)
      end
      return -num, si
    end
  peekTable[34] = readString  -- "
  peekTable[47] = function(si) -- /
      local c, i = skipCommentSpace(si + 1)
      return peekTable[c](i - 1)
    end
end

-- public interface
M.decode = decode

return M