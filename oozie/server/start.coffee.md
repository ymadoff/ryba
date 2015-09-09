
# Oozie Server Start

Run the command `./bin/ryba start -m ryba/oozie/server` to start the Oozie
server using Ryba.

By default, the pid of the running server is stored in
"/var/run/oozie/oozie.pid".

    module.exports = []
    module.exports.push 'masson/bootstrap'
    # module.exports.push require('./index').configure

## Start

Start the Oozie server. You can also start the server manually with the
following command:

```
service oozie start
su -l oozie -c "/usr/hdp/current/oozie-server/bin/oozied.sh start"
```

Note, there is no need to clean a zombie pid file before starting the server.

    module.exports.push name: 'Oozie Server # Start', label_true: 'STARTED', timeout: -1, handler: ->
      {oozie} = @config.ryba
      @service_start
        name: 'oozie'
