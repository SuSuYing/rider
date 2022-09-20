require('rider.v2')

-- 定义本地变量
local envoy = envoy
local request = envoy.req
local respond = envoy.respond

-- 定义本地常量
local NO_MATCH = 0
local MATCH_WHITELIST = 1
local MATCH_BLACKLIST = 2
local BAD_REQUEST = 400
local FORBIDDEN = 403

local uriRestrictionHandler = {}

uriRestrictionHandler.version = 'v2'
local json_validator = require('rider.json_validator')

-- 定义全局配置
local base_json_schema = {
    type = 'object',
    properties = {}
}

-- 定义路由级配置
local route_json_schema = {
    type = 'object',
    properties = {
        allowlist = {
            type = 'array',
            items = {
                type = 'string'
            }
        },
        denylist = {
            type = 'array',
            items = {
                type = 'string'
            }
        }
    }
}

json_validator.register_validator(base_json_schema, route_json_schema)

-- 定义本地校验uri黑白名单方法
local function checkUriPath(uriPath, allowlist, denylist)
    if allowlist then
        for _, rule in ipairs(allowlist) do
            envoy.logDebug('allowist: compare ' .. rule .. ' and ' .. uriPath)
            if string.find(uriPath, rule) then
                return MATCH_WHITELIST
            end
        end
    end

    if denylist then
        for _, rule in ipairs(denylist) do
            envoy.logDebug('denylist: compare ' .. rule .. ' and ' .. uriPath)
            if string.find(uriPath, rule) then
                return MATCH_BLACKLIST
            end
        end
    end

    return NO_MATCH
end

-- 定义request的header阶段处理函数
function uriRestrictionHandler:on_request_header()
    local uriPath = request.get_header(':path')
    local config = envoy.get_route_config()

    envoy.logInfo('start lua uriRestriction')
    if uriPath == nil then
        envoy.logErr('no uri path!')
        return
    end

    -- 配置未定义报错
    if config == nil then
        envoy.logErr('no route config!')
        return
    end

    local match = checkUriPath(uriPath, config.allowlist, config.denylist)

    envoy.logDebug('on_request_header, uri path: ' .. uriPath .. ', match result: ' .. match)

    if match > 1 then
        envoy.logDebug('path is now allowed: ' .. uriPath)
        return respond({ [':status'] = FORBIDDEN }, 'Forbidden')
    end
end

return uriRestrictionHandler
