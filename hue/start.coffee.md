
# Hue Start

Start the Hue server. You can also start the server manually with the following
command:

```
service hue start
```

    module.exports = header: 'Hue # Start', label_true: 'STARTED', handler: ->
      @service.start name: 'hue'
