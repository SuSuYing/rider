require("rider.v2")

local core = require("rider.apisix.core")
local pairs       = pairs
local type        = type
local envoy = envoy
local logErr = envoy.logErr
local logInfo = envoy.logInfo
local set_resp_header = envoy.resp.set_header
local get_req_header = envoy.req.get_header

local json_validator = require("rider.json_validator")
local base_json_schema = {
    type = 'object',
    properties = {
        code = {
            type = 'table',
        },
        body = {
            type = 'string',
        },
        headers = {
            type = 'table',
        },
        defaultcode = {
            type = 'number',
        }
    },
    required = {"defaultcode"},
}

local route_json_schema = {
    type = 'object',
    properties = {
        code = {
            type = 'table',
        },
        body = {
            type = 'string',
        },
        headers = {
            type = 'table',
        },
        defaultcode = {
            type = 'number',
        }
    },
    required = {"defaultcode"},
}
json_validator.register_validator(base_json_schema, route_json_schema)

local mockHandler = {}
mockHandler.version = "v2"

function mockHandler.on_request_body()
    logInfo("[mock] request body start");
    local conf = envoy.get_route_config()
    if conf == nil then
        logInfo("[mock] no config");
        return
    end

    local body = "" .. conf.body

    local headers = {}
    if conf.headers then
        for field, value in pairs(conf.headers) do
            core.table.insert(headers, field)
            core.table.insert(headers, value)
        end
    end

    local code = conf.defaultcode
    if conf.code then
        for field, value in pairs(conf.code) do
            if get_req_header(':method') == string.upper(field) then
                code = tonumber(value)
                logInfo("[mock] code define:" .. field .. "   " .. code)
                break
            end
        end
    end
    local field_cnt = #headers
    for i = 1, field_cnt, 2 do
        logInfo("[mock] header:" .. headers[i]..":"..headers[i+1])
        --set_resp_header(headers[i], headers[i+1])
    end

    logInfo("[mock] request_body end");
    return envoy.respond({[":status"] = code}, body)
end

function mockHandler:on_request_header()

end

return mockHandler
