
# WebHCat Start

Run the command `./bin/ryba start -m ryba/hive/webhcat` to start the WebHCat
server using Ryba.

By default, the pid of the running server is stored in
"/var/run/webhcat/webhcat.pid".

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/hive/hcatalog/wait'
    # module.exports.push require('./index').configure

## Start Server

Start the WebHCat server. You can also start the server manually with one of the
following two commands:

```
service hive-webhcat-server start
su -l hive -c "/usr/hdp/current/hive-webhcat/sbin/webhcat_server.sh start"
```

    module.exports.push name: 'WebHCat # Start', label_true: 'STARTED', handler: ->
      @service_start
        name: 'hive-webhcat-server'
