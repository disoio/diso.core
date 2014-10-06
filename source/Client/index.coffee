# Local dependencies
# ------------------ 
# [Client ](./Client .html)  
# [ClientModel](./ClientModel.html)  
# [ClientContainer](./ClientContainer.html)  
# [Mediator](./Mediator.html) 
Client    = require('./Client')
Model     = require('./ClientModel')
Container = require('./ClientContainer')
Mediator  = require('../Shared/Mediator')

Client.Model     = Model
Client.Container = Container
Client.Mediator  = Mediator

module.exports = Client