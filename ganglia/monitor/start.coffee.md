
# Ganglia Monitor Start

Execute this command on all the nodes in your Hadoop cluster.

    module.exports = []
    module.exports.push 'masson/bootstrap/connection'
    module.exports.push 'masson/bootstrap/mecano'

## Start

Start the Ganglia Monitor server. You can also start the server manually with
the following command:

```
service hdp-gmond start
```

    module.exports.push header: 'Ganglia Monitor # Start', label_true: 'STARTED', handler: ->
      @service_start
        name: 'hdp-gmond'
        code_stopped: 1
      # On error, it is often necessary to remove pid files
      # this hasnt been tested yet:
      # .execute
      #   cmd: "rm -rf /var/run/ganglia/hdp/*/*.pid"
      #   if: @retry
