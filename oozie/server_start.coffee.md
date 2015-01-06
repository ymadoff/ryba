
# Oozie Server Start

Run the command `./bin/ryba start -m ryba/oozie/server` to start the Oozie
server using Ryba.

By default, the pid of the running server is stored in
"/var/run/oozie/oozie.pid".

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push require('./server').configure

## Start

Start the Oozie server. You can also start the server manually with the
following command:

```
su -l oozie -c "/usr/lib/oozie/bin/oozied.sh start"
```

Note, there is no need to clean a zombie pid file before starting the server.

    module.exports.push name: 'Oozie Server # Start', label_true: 'STARTED', timeout: -1, callback: (ctx, next) ->
      {oozie_user, oozie_pid_dir} = ctx.config.ryba
      ctx.execute
        cmd: """
        if [ -f #{oozie_pid_dir}/oozie.pid ]; then
          if kill -0 >/dev/null 2>&1 `cat #{oozie_pid_dir}/oozie.pid`; then exit 3; fi
        fi
        su -l #{oozie_user.name} -c "/usr/lib/oozie/bin/oozied.sh start"
        """
        code_skipped: 3
      , next

