local integer = 4
local float = 4.0

print(math.maxinteger)
print(math.mininteger)
print(math.tointeger("1.0"))
print(">> 10 1")
print(10 >> 1)
print("<< 10 1")
print(10 << 1)
print("& 10 1")
print(10 & 1)
print("| 10 1")
print(10 | 1)
print("~ 10 1")
print(10 ~ 1)
print("~ 14 16")
print(14 ~ 16)

if integer == float then
    print("Integer 4 is equal to float 4.0")
else
    print("Integer 4 is not equal to float 4.0")
end

local number1 = 4
local number2 = 4.0

if number1 == number2 then
    print("Number 4 is equal to number 4.0")
else
    print("Number 4 is not equal to number 4.0")
end