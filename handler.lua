--[[
 ©2018 API Fortress
 Based upon Mashape's http-log

 Apache License
 Version 2.0, January 2004
]]
local cjson = require "cjson"

local url = require "socket.url"
local string_format = string.format
local cjson_encode = cjson.encode
local HTTP = "http"
local HTTPS = "https"
local NAME = "[ fhttp-log ] "

local system_constants = require "lua_system_constants"
local serializer = require "kong.plugins.fhttp-log.serializer"
local BasePlugin = require "kong.plugins.base_plugin"
local req_read_body = ngx.req.read_body
local req_get_body_data = ngx.req.get_body_data

local ngx_timer = ngx.timer.at
local string_len = string.len
local O_CREAT = system_constants.O_CREAT()
local O_WRONLY = system_constants.O_WRONLY()
local O_APPEND = system_constants.O_APPEND()
local S_IRUSR = system_constants.S_IRUSR()
local S_IWUSR = system_constants.S_IWUSR()
local S_IRGRP = system_constants.S_IRGRP()
local S_IROTH = system_constants.S_IROTH()

local oflags = bit.bor(O_WRONLY, O_CREAT, O_APPEND)
local mode = bit.bor(S_IRUSR, S_IWUSR, S_IRGRP, S_IROTH)


-- Generates the raw http message.
-- @param `parsed_url` contains the host details
-- @param `body`  Body of the message as a string
-- @return raw http message
local function generate_post_payload(parsed_url, body, conf)
  local url
  if parsed_url.query then
    url = parsed_url.path .. "?" .. parsed_url.query
  else
    url = parsed_url.path
  end
  local headers = string_format(
    "%s %s HTTP/1.1\r\nHost: %s\r\nConnection: Keep-Alive\r\nContent-Type: application/json\r\nContent-Length: %s\r\nx-api-key: %s\r\nx-secret: %s\r\n",
    "POST", url, parsed_url.host, #body, conf.api_key, conf.secret)
  if conf.mock_domain then
    headers = headers..string_format("x-mock-domain: %s\r\n",conf.mock_domain)
  end

  return string_format("%s\r\n%s", headers, body)
end

-- Parse host url.
-- @param `url` host url
-- @return `parsed_url` a table with host details like domain name, port, path etc
local function parse_url(host_url)
  local parsed_url = url.parse(host_url)
  if not parsed_url.port then
    if parsed_url.scheme == HTTP then
      parsed_url.port = 80
     elseif parsed_url.scheme == HTTPS then
      parsed_url.port = 443
     end
  end
  if not parsed_url.path then
    parsed_url.path = "/"
  end
  return parsed_url
end


-- Log to a file. Function used as callback from an nginx timer.
-- @param `premature` see OpenResty `ngx.timer.at()`
-- @param `conf`     Configuration table, holds http endpoint details
-- @param `body`  Message to be logged
local function log(premature, conf, body)
  if premature then return end
  local ok, err
  local parsed_url = parse_url(conf.http_endpoint)
  local host = parsed_url.host
  local port = tonumber(parsed_url.port)

  local sock = ngx.socket.tcp()
  sock:settimeout(conf.timeout)

  ok, err = sock:connect(host, port)
  if not ok then
    ngx.log(ngx.ERR, NAME .. "failed to connect to " .. host .. ":" .. tostring(port) .. ": ", err)
    return
  end

  if parsed_url.scheme == HTTPS then
    local _, err = sock:sslhandshake(true, host, false)
    if err then
      ngx.log(ngx.ERR, NAME .. "failed to do SSL handshake with " .. host .. ":" .. tostring(port) .. ": ", err)
    end
  end

  ok, err = sock:send(generate_post_payload(parsed_url, body, conf))
  if not ok then
    ngx.log(ngx.ERR, NAME .. "failed to send data to " .. host .. ":" .. tostring(port) .. ": ", err)
  end

  ok, err = sock:setkeepalive(conf.keepalive)
  if not ok then
    ngx.log(ngx.ERR, NAME .. "failed to keepalive to " .. host .. ":" .. tostring(port) .. ": ", err)
    return
  end
end

local FHttpLogHandler = BasePlugin:extend()

FHttpLogHandler.PRIORITY = 1

function FHttpLogHandler:new()
  FHttpLogHandler.super.new(self, "fhttp-log")
end

function FHttpLogHandler:access(conf)
  FHttpLogHandler.super.access(self)


  local ctx = ngx.ctx
  ctx.fhttp_log = { q_body = "", res_body = "" }
  if conf.log_bodies then
    req_read_body()
    ctx.fhttp_log.req_body = req_get_body_data()
  end
end

function FHttpLogHandler:body_filter(conf)
  FHttpLogHandler.super.body_filter(self)

  if conf.log_bodies then
    local chunk = ngx.arg[1]
    local ctx = ngx.ctx
    local res_body = ctx.fhttp_log and ctx.fhttp_log.res_body or ""
    res_body = res_body .. (chunk or "")
    ctx.fhttp_log.res_body = res_body
  end
end

function FHttpLogHandler:log(conf)
  FHttpLogHandler.super.log(self)
  local mock = ngx.req.get_headers()["x-mock"]
  if not mock or mock~="true" then
    local message = cjson_encode(serializer.serialize(ngx))
    local ok, err = ngx_timer(0, log, conf, message)
    if not ok then
      ngx.log(ngx.ERR, "[fhttp-log] failed to create timer: ", err)
    end
  end

end

return FHttpLogHandler
