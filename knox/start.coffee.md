
# Knox Start

You can also start the server manually with the following command:

```
service knox-server start
su -l knox -c "/usr/hdp/current/knox-server/bin/gateway.sh start"
```

    module.exports = header: 'Knox # Start', label_true: 'STARTED', handler: ->
      @service_start name: 'knox-server'
