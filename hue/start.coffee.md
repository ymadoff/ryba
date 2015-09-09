
# Hue Start

    module.exports = []
    module.exports.push 'masson/bootstrap'

## Start Server

Start the Hue server. You can also start the server manually with the following
command:

```
service hue start
```

    module.exports.push name: 'Hue # Start', label_true: 'STARTED', handler: ->
      @service_start
        name: 'hue'
