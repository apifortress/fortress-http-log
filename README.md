# Fortress-HTTP-Log
## A request / response logger for the Kong API Gateway
The objective of this plugin is to provide a way to capture complete HTTP requests and responses (including the **request
  and response bodies** is required) as they transit in the Kong API Gateway.
Once the data is captured, the plugin will send it to a specified endpoint via HTTP.

### Configuration keys

* `http_endpoint` (**url,required**): the endpoint to send the data to;
* `timeout` (**milliseconds**): the request timeout for the connection to http_endpoint;
* `keepalive` (**milliseconds**): for how long the plugin should keep the conection alive;
* `log_bodies` (**boolean**): set to true if you want to log request / response bodies;
* `api_key` (**string, API Fortress specific**): turns into the x-api-key header;
* `secret` (**string, API Fortress specific**): turns into the x-secret header;
* `mock_domain` (**url, API Fortress specific**): turns into the x-mock-domain header. Set this value if you're using the plugin
to create mock responses in API Fortress;
* `mock_log_all` (**boolean, API Fortress specific**): turns into the x-log-all header. Set this value if you're using the plugin
to create mock responses in API Fortress. If set API Fortress will log each call separately and avoid overwrites;
* `mock_criterion_headers` (**array, API Fortress specific**): turns into the x-mock-criterion-headers. Set this value if you're using the plugin to create mock responses in API Fortress. If set, API Fortress will use this list of headers to create expression filters
* `enable_on_header` (**string**): if set with a header name as value, the plugin will operate only if that header is present
in the request;
* `disable_on_header` (**string**): if set with a header name as value, the plugin will disable itself if that header is present
in the request. Note: this setting has higher priority than *enable_on_header*.

### Compatibility and interactions
* The plugin has been developed against **Kong 0.14**;
