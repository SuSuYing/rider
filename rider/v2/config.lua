local ffi = require("ffi")
local cjson = require("cjson")
local base = require("rider.base")

local cjson_decode = cjson.decode
local C = ffi.C
local ffi_new = ffi.new
local ffi_str = ffi.string
local FFI_OK = base.FFI_OK
local FFI_NotFound = base.FFI_NotFound

local exports = {}

ffi.cdef[[
    int envoy_http_lua_ffi_v2_get_configuration(envoy_lua_ffi_str_t* buffer);

    uint64_t envoy_http_lua_ffi_v2_get_route_config_hash();
    int envoy_http_lua_ffi_v2_get_route_configuration(envoy_lua_ffi_str_t* buffer);
]]

local VALIDATE_OK = 0
local VALIDATE_FAIL = 1
exports.VALIDATE_OK = VALIDATE_OK
exports.VALIDATE_FAIL = VALIDATE_FAIL

local function null_validator(config_object)

    return VALIDATE_OK
end
local base_config_validator = null_validator
local route_config_validator = null_validator

local function register_config_validator(new_base_config_validator, new_route_config_validator)
    if new_base_config_validator ~= nil then
        base_config_validator = new_base_config_validator
    end

    if new_route_config_validator ~= nil then
        route_config_validator = new_route_config_validator
    end

    -- Validate the base config.
    envoy.get_base_config()
end
exports.register_config_validator = register_config_validator

local cache = {}
setmetatable(cache, { __mode = 'v' })
local base_config

function envoy.get_base_config()
    if base_config ~= nil then
        if base_config.validate_error ~= nil then
            error(base_config.validate_error, 2)
        end
        return base_config.data
    end

    local buffer = ffi_new("envoy_lua_ffi_str_t[1]")
    local rc = C.envoy_http_lua_ffi_v2_get_configuration(buffer)
    if rc ~= FFI_OK then
        error("error get base config: "..rc)
    end

    local config_json_object = cjson_decode(ffi_str(buffer[0].data, buffer[0].len))
    local result, err = base_config_validator(config_json_object)
    if result == VALIDATE_OK then
        base_config = {
            data = config_json_object,
        }
    else
        base_config = {
            validate_error = err,
        }
        error(err, 2)
    end
    return config_json_object
end

function envoy.get_route_config()
    C.envoy_http_lua_ffi_v2_log(2, "[get_route_config] v2 start")
    local hash = C.envoy_http_lua_ffi_v2_get_route_config_hash()
    -- No route config.
    if not hash then return nil end

    local entry = cache[hash]
    if entry ~= nil then
        if entry.validate_error == nil then
            return entry.data.config
        end
        error(entry.validate_error, 2)
    end

    local buffer = ffi_new("envoy_lua_ffi_str_t[1]")
    local rc = C.envoy_http_lua_ffi_v2_get_route_configuration(buffer)

    C.envoy_http_lua_ffi_v2_log(2, "[get route config] get buffer result " .. rc)

    if rc == FFI_NotFound then
        return nil
    end

    if rc ~= FFI_OK then
        error("error get route config: "..rc)
    end

    local config_json_object = cjson_decode(ffi_str(buffer[0].data, buffer[0].len))
    local result, err = route_config_validator(config_json_object.config)
    C.envoy_http_lua_ffi_v2_log(2, "[get route config] get result " .. result)
    if result == VALIDATE_OK then
        cache[hash] = {
            data = config_json_object,
        }
    else
        cache[hash] = {
            validate_error = err,
        }
        error(err, 2)
    end
    C.envoy_http_lua_ffi_v2_log(2, "[get_route_config] config:" .. table.concat(config_json_object.config,","))
    return config_json_object.config
end

return exports
