-- tests of lexer (preliminary)
--
-- D.Manura.  Copyright (c) 2011, Fabien Fleutot <metalua@gmail.com>.
--
-- This software is released under the MIT Licence, see Metalua licence.txt
-- for details.


package.path = 'src/compiler/?.lua;src/lib/?.lua'

require 'mlp_lexer'
local LX = mlp.lexer

-- equality check.
local function checkeq(a, b)
  if a ~= b then
    error('not equal:\n' .. tostring(a) .. '\n' .. tostring(b), 2)
  end
end

-- reads file to string (with limited error handling)
local function readfile(filename)
  local fh = assert(io.open(filename, 'rb'))
  local text = fh:read'*a'
  fh:close()
  return text
end

-- formats token succinctly.
local function tokfmt(tok)
  local function fmt(o)
    return (type(o) == 'string') and ("%q"):format(o):sub(2,-2) or tostring(o)
  end
  return [[`]] .. tok.tag .. tostring(tok.lineinfo):gsub('%|L[^%|]*%|C[^%|]*', '') .. '{' .. fmt(tok[1]) .. '}'
end

-- utility function to lex code, returning string representation.
local function lex(code)
  local sm = LX:newstream(code)
  local toks = {}
  while 1 do
    local tok = sm:next()
    toks[#toks+1] = tokfmt(tok)
    if tok.tag == 'Eof' then
      break
    end
  end
  return table.concat(toks)
end
local function plex(code)
  return pcall(lex, code)
end

--FIX checkeq(nil, plex '====')

-- trivial tests
checkeq(lex[[]], [[`Eof<?|K1>{eof}]])
checkeq(lex'\t', [[`Eof<?|K2>{eof}]])
checkeq(lex'\n', [[`Eof<?|K2>{eof}]])
checkeq(lex'--', [[`Eof<C|?|K3>{eof}]])
checkeq(lex'\n -- \n--\n ', [[`Eof<C|?|K11>{eof}]])
checkeq(lex[[return]], [[`Keyword<?|K1-6>{return}`Eof<?|K7>{eof}]])

-- string tests
checkeq(lex[["\092b"]],  [[`String<?|K1-7>{\\b}`Eof<?|K8>{eof}]]) -- was bug
checkeq(lex[["\0\t\090\100\\\1004"]],  [[`String<?|K1-21>{\000	Zd\\d4}`Eof<?|K22>{eof}]]) -- decimal/escape

-- Lua 5.2
checkeq(lex'"a\\z \n ."', [[`String<?|K1-9>{a.}`Eof<?|K10>{eof}]])  -- \z
checkeq(lex'"\\z"', [[`String<?|K1-4>{}`Eof<?|K5>{eof}]])  -- \z

assert(lex(readfile(arg[0]))) -- lex self

print 'DONE'
