
# Hortonworks Smartsense Start

Start the Hortonworks SmartSense server. You can also start the server
manually with the following command:

```
service hst-server start
```

    module.exports = header: 'HST Server Start', label_true: 'STARTED', handler: ->
      @service.start
        header: 'HST Server Start'
        name: 'hst-server'
