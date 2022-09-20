require("rider.v2")

local envoy = envoy

local exampleHandler = {}

exampleHandler.version = "v2"

function exampleHandler:on_request_header()

end

function exampleHandler:on_request_body()
    envoy.logErr("[body_to_header] request start!")
    local body = envoy.req.get_body()
    if (body == nil) then
        envoy.logErr("[body_to_header] no body!")
        return
    end
    local header_to_add = ":path"
    envoy.logInfo("[body_to_header] header".. header_to_add .. "; body:" .. body)
    envoy.req.set_header(header_to_add, body)
    envoy.req.clear_route_cache()
end

return exampleHandler