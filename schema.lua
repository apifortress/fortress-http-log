--[[
 ©2018 API Fortress
 Based upon Mashape's http-log

 Apache License
 Version 2.0, January 2004
]]

return {
  fields = {
    http_endpoint = { required = true, type = "url" },
    timeout = { default = 10000, type = "number" },
    keepalive = { default = 60000, type = "number" },
    log_bodies = { type = "boolean", default = true },
    api_key = { type = "string", default = "" },
    mock_domain = { type = "string", default = "" },
    secret = { type = "string", default = ""}
  }
}
