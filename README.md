diso.core
===========

0.0.10

Notes
-----

The top level export includes an object with two properties:
```js
var Core = require('diso.core');
var Client = Core.Client;
var Server = Core.Server;
```

However, this introduces an issue for clientside bundlers such as
[Browserify](http://browserify.org), which would try to include Server 
code in the client bundle, causing failures from serverside-only libs

For this reason the js builds are exported to the top level of the package 
so that client and server directories can be required independently as follows

```js
var Client = require('diso.core/Client');
var Server = require('diso.core/Server');
```

Description
-----------
Client/Server/Derp


Research
--------
## frameworks to check out
- https://github.com/walmartlabs/lazojs/wiki/Overview
- http://facebook.github.io/react/docs/flux-todo-list.html
- http://react-components.com

## security
- http://www.christian-schneider.net/CrossSiteWebSocketHijacking.html


## production environments
- http://docs.strongloop.com/display/SLC/slc+run
- https://www.phusionpassenger.com/node_weekly

## queues to decouple server and workers / message handlers
- https://github.com/topcloud/socketcluster
- http://www.bravenewgeek.com/dissecting-message-queues/
- http://stackoverflow.com/questions/10620976/rabbitmq-amqp-single-queue-multiple-consumers-for-same-message
- http://www.rabbitmq.com/tutorials/tutorial-one-python.html
- http://www.squaremobius.net/rabbit.js/#zeromq


## derp rest

http://en.wikipedia.org/wiki/Representational_state_transfer
http://en.wikipedia.org/wiki/HATEOAS
http://roy.gbiv.com/untangled/2008/rest-apis-must-be-hypertext-driven
http://www.ics.uci.edu/~fielding/pubs/dissertation/rest_arch_style.htm
http://en.wikipedia.org/wiki/HTTP
https://github.com/prettymuchbryce/node-http-status/blob/master/lib/httpstatus.js
http://en.wikipedia.org/wiki/List_of_HTTP_status_codes
https://dev.twitter.com/docs/error-codes-responses
https://github.com/visionmedia/express/blob/master/examples/route-map/index.js#L47

Todo
-----


- If page needs user, skip initial request
- How to handle that redirect in requesthandler
- headers, status from page load -> container
- styles, scripts
- metadata updating / between redirects / client page changes
- IF USER REQUIRED, SAVE ORIGINAL REQUEST AND REROUTE AFTER SUCCESSFUL AUTH
- LET PAGES / VIEWS PUBSUB TO CLIENT STORE
- PAGE TRANSITIONS
- PAGE MODALS




- Introduce queue / messaging intermediary so that socket connections can be scaled across multiple servers. in process, requesthandler / ServerActions need to be replaceable with acceptor pattern that converts http request into "pageRequest" that is pushed onto queue and handled by consumers

- where should session setup / token verify occur? seems like consumers would be better choice, since likely will need to pull the user record from db, and request handling layer shouldn't be concerned