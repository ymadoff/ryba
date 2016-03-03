
# Falcon Start

Start the Falcon server. You can also start the server manually with the
following command:

```
su -l falcon -c "/usr/hdp/current/falcon-server/bin/service-start.sh falcon"
```

    module.exports = header: 'Falcon Start', timeout: -1, label_true: 'STARTED', handler: ->
      @service_start name: 'falcon'
