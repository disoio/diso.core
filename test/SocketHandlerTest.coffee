     "walk objects and arrays and call instance method on models in them when called via class" : ()->
        garth1 = new Garth(name: 'garth!')
        wayne1 = new Wayne(name: 'wayne!')
        garth2 = new Garth(name : 'garth2!')
        wayne2 = new Wayne(name : 'wayne2!')

        obj = {
          something : 'else'
          list : [garth1, wayne1]
          garth2 : garth2
          dorf : {
            wayne2 : wayne2
          }
        }

        actual = Model.deflate(obj)
        
        expected = { 
          something: 'else'
          list: [
            {
              name     : 'garth!'
              _id      : garth1._id
              '$model' : 'Garth'
            }
            {
              name     : 'wayne!'
              _id      : wayne1._id
              '$model' : 'Wayne'
            }
          ]
          garth2: {
            name     : 'garth2!'
            _id      : garth2._id
            '$model' : 'Garth'
          }
          dorf: {
            wayne2: { 
              name     : 'wayne2!',
              _id      : wayne2._id,
              '$model' : 'Wayne'
            } 
          }
        }

        Assert.deepEqual(actual, expected)
    }