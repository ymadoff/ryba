
# Hortonworks Smartsense Stop

Stop the Hortonworks SmartSense server. You can also start the server
manually with the following command:

```
service hst-server stop
```

    module.exports = header: 'HST Server Stop', label_true: 'STARTED', handler: ->
      @service.start
        header: 'HST Server Stop'
        name: 'hst-server'
