
# Shinken Poller Start

Start the Shinken Poller service.

    module.exports = header: 'Shinken Poller Start', label_true: 'STARTED', handler: ->
      {shinken} = @config.ryba
      @service.start name: 'shinken-poller'

## Start Executor

Start the docker executors (normal and admin)

      @call header: 'Docker Executor', ->
        @docker.start
          container: 'poller-executor'
        @docker.exec
          container: 'poller-executor'
          cmd: "kinit #{shinken.poller.executor.krb5.unprivileged.principal} -kt #{shinken.poller.executor.krb5.unprivileged.keytab}"
          shy: true
