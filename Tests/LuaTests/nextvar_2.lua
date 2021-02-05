-- test size operation on empty tables
assert(#{} == 0)
assert(#{nil} == 0)
assert(#{nil, nil} == 0)
assert(#{nil, nil, nil} == 0)
assert(#{nil, nil, nil, nil} == 0)
print'+'


local nofind = {}

a,b,c = 1,2,3
a,b,c = nil


-- next uses always the same iteraction function
assert(next{} == next{})

local function find (name)
  local n,v
  while 1 do
    n,v = next(_G, n)
    if not n then return nofind end
    assert(v ~= nil)
    if n == name then return v end
  end
end

local function find1 (name)
  for n,v in pairs(_G) do
    if n==name then return v end
  end
  return nil  -- not found
end


assert(print==find("print") and print == find1("print"))
assert(_G["print"]==find("print"))
assert(assert==find1("assert"))
assert(nofind==find("return"))
assert(not find1("return"))
_G["ret" .. "urn"] = nil
assert(nofind==find("return"))
_G["xxx"] = 1
assert(xxx==find("xxx"))

print('+')

a = {}
for i=0,10 do --WAS: for i=0,10000 do
  if math.fmod(i,10) ~= 0 then
    a['x'..i] = i
  end
end

n = {n=0}
for i,v in pairs(a) do
  n.n = n.n+1
  assert(i and v and a[i] == v)
end
assert(n.n == 9)
a = nil

------------------------------------------
-- TODO: package, string.find
------------------------------------------
-- do   -- clear global table
--   local a = {}
--   for n,v in pairs(_G) do a[n]=v end
--   for n,v in pairs(a) do
--     if not package.loaded[n] and type(v) ~= "function" and
--        not string.find(n, "^[%u_]") then
--      _G[n] = nil
--     end
--     collectgarbage()
--   end
-- end
