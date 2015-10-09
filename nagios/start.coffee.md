
# Nagios Start

    module.exports = []
    module.exports.push 'masson/bootstrap'
    # module.exports.push require('./index').configure

## Start

Start the Nagios server. You can also start the server
manually with the following command:

```
service nagios start
```

    module.exports.push name: 'Nagios # Start', label_true: 'STARTED', handler: ->
      @service_start
        name: 'nagios'
