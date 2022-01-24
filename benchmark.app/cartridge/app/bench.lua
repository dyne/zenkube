local BENCH = { }
BENCH.entropy = function()
   -- use standard ECP size
   local s = #ECP.random():octet()
   return { PRNG = OCTET.random(256):entropy(),
	    OCTET = OCTET.random(s):entropy(),
	    BIG = BIG.random():octet():entropy(),
	    ECP = ECP.random():octet():entropy(),
	    ECP2 = ECP2.random():octet():entropy() }
end

BENCH.random_hamming_freq = function (s, q)
   local _s = s or 97
   local _q = q or 5000

   -- ECP coordinates are 97 bytes
   local new = O.random(_s)
   local tot = 0
   local old
   for i=_q,1,-1 do
	  old = new
	  new = O.random(_s)
	  tot = tot + O.hamming(old,new)
   end
   return tot / _q
end

BENCH.random_kdf = function()
   -- KDF2 input can be any, output
   local r = O.random(64)
   HASH.kdf2(HASH.new('SHA256'),r)
   HASH.kdf2(HASH.new('SHA512'),r)
end


-- find primes
local square = {} for i=0,9 do square[i]=i*i end
local function sqrsum(n)
   local sum = 0
   while n > 0 do sum, n = sum + square[n % 10], math.floor(n / 10) end
   return sum
end
local function isHappy(n)
   while n ~= 1 and n ~= 4 do n = sqrsum(n) end
   return n == 1
end
local prime_numbers = { 2, 3 }
local function isPrime(n)
   if n == 1 then return true end
   for _,i in ipairs(prime_numbers) do
	  if n == i then return true end
	  if n%i == 0 then return false end
   end
   for i = prime_numbers[#prime_numbers], math.floor(n/2)+1, 2 do
	  if n%i == 0 then return false end
   end
   if n > prime_numbers[#prime_numbers] then
	  table.insert(prime_numbers, n)
   end
   return true
end
BENCH.math = function(a, b, c)

   local _a = a or 50000
   local _b = b or _a+50000
   local _c = c or 1
   local res = { }
   for n=_a,_b,_c do 
	  if isHappy(n) and isPrime(n) then
		 table.insert(res, n)
	  end
   end
   return res
end
return BENCH
