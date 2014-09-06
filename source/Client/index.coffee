# Local dependencies
# ------------------ 
# [Client ](./Client .html)  
# [ClientModel](./ClientModel.html)  
# [ClientStore](./ClientStore.html)  
# [ClientContainer](./ClientContainer.html)  
# [Mediator](../Shared/Mediator.html) 
Client    = require('./Client')
Model     = require('./ClientModel')
Store     = require('./ClientStore')
Container = require('./ClientContainer')
Mediator  = require('../Shared/Mediator')

Client.Model     = Model
Client.Store     = Store
Client.Container = Container
Client.Mediator  = Mediator

module.exports = Client