
# Oozie Server Status

Run the command `./bin/ryba status -m ryba/oozie/server` to retrieve the status
of the Oozie server using Ryba.

By default, the pid of the running server is stored in
"/var/run/oozie/oozie.pid".

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push require('./server').configure

## Status

Discover the server status.

    module.exports.push name: 'Oozie Server # Status', label_true: 'STARTED', label_false: 'STOPPED', timeout: -1, callback: (ctx, next) ->
      {oozie_pid_dir} = ctx.config.ryba
      ctx.execute
        cmd: """
        if [ ! -f #{oozie_pid_dir}/oozie.pid ]; then exit 3; fi
        if ! kill -0 >/dev/null 2>&1 `cat #{oozie_pid_dir}/oozie.pid`; then exit 3; fi
        """
        code_skipped: 3
      , next

