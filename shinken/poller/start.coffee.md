
# Shinken Poller Start

Start the Shinken Poller service.

    module.exports = header: 'Shinken Poller # Start', label_true: 'STARTED', handler: ->
      {shinken} = @config.ryba
      @service_start name: 'shinken-poller'

## Start Executor

Start the docker executors (normal and admin)

      @call header: 'Start Executor', handler: ->
        @docker_start
          container: 'poller-executor'
        @docker_exec
          container: 'poller-executor'
          cmd: "kinit #{shinken.poller.executor.krb5.unprivileged.principal} -kt /etc/security/keytabs/crond.unprivileged.keytab"
          shy: true
