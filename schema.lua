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
    api_key = { type = "string" },
    secret = { type = "string" },
    mock_domain = { type = "string" },
    enable_on_header = { type = "string" },
    disable_on_header = { type = "string" },
    mock_log_all = { type = "boolean", default = false },
    mock_criterion_headers = { type= "array" }
  }
}
