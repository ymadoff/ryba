
# Ranger Admin Start

Start the ranger admin service server. You can also start the server
manually with the following command:

```
service ranger-admin start
```

    module.exports = header: 'Rander Admin Start', label_true: 'STARTED', handler: ->
      @service.start
        header: 'Ranger Admin Start' #Do not modify (ranger hook)
        name: 'ranger-admin'
