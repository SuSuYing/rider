require "rider.apisix.core.ctx"
require "rider.apisix.core.json"
require "rider.apisix.core.lrucache"
require "rider.apisix.core.plugin"
require "rider.apisix.core.re"
require "rider.apisix.schema_def"
require "rider.apisix.core.string"
require "rider.apisix.core.table"
require "rider.apisix.core.version"

return {
    ctx      = require("rider.apisix.core.ctx"),
    json     = require("rider.apisix.core.json"),   -- need a better json lib
    lrucache = require("rider.apisix.core.lrucache"),
    plugin   = require("rider.apisix.core.plugin"),
    re       = require("rider.apisix.core.re"),
    schema   = require("rider.apisix.schema_def"),
    string   = require("rider.apisix.core.string"),
    table    = require("rider.apisix.core.table"),
    version  = require("rider.apisix.core.version"),

    empty_tab= {},
}
