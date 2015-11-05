
# Falcon Start

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/krb5_client/wait'
    # module.exports.push require('./index').configure

## Start

Start the Falcon server. You can also start the server manually with the
following command:

```
su -l falcon -c "/usr/hdp/current/falcon-server/bin/service-start.sh falcon"
```

    module.exports.push header: 'Falcon # Start Service', timeout: -1, label_true: 'STARTED', handler: ->
      {user} = @config.ryba.falcon
      @execute
        cmd: """
        su -l #{user.name} -c '/usr/hdp/current/falcon-server/bin/service-status.sh falcon'
        if [ $? -eq 254 ]; then exit 3; fi
        su -l #{user.name} -c '/usr/hdp/current/falcon-server/bin/service-start.sh falcon'
        """
        code_skipped: 3
        if_exists: '/usr/hdp/current/falcon-server/bin/service-status.sh'
