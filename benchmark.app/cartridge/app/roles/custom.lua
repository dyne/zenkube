local cartridge = require('cartridge')

require'zenroom'
JSON = require'json'
BENCH = require'bench'

local function init(opts) -- luacheck: no unused args
    -- if opts.is_master then
    -- end

    local httpd = assert(cartridge.service_get('httpd'), "Failed to get httpd service")
    httpd:route({method = 'GET', path = '/test'}, function()
	  local res = { }
	  local prime_start = os.clock()
	  BENCH.math(1,100000)
	  local prime_done = os.clock()
	  res.prime_generation_100k =
	     string.format("%.2f", prime_done - prime_start)

	  local kdf_start = os.clock()
	  BENCH.random_kdf()
	  local kdf_done = os.clock()
	  res.kdf2_sha256_sha512 =
	     string.format("%.2f", kdf_done - kdf_start)

	  res.entropy = BENCH.entropy()
	  -- TODO: BENCH.entropy()

        return {body = JSON.encode(res)}
    end)

    return true
end

local function stop()
    return true
end

local function validate_config(conf_new, conf_old) -- luacheck: no unused args
    return true
end

local function apply_config(conf, opts) -- luacheck: no unused args
    -- if opts.is_master then
    -- end

    return true
end

return {
    role_name = 'app.roles.custom',
    init = init,
    stop = stop,
    validate_config = validate_config,
    apply_config = apply_config,
    -- dependencies = {'cartridge.roles.vshard-router'},
}
