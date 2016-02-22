
# Shinken Poller Start

    module.exports = []
    module.exports.push 'masson/bootstrap/'

## Start

Start the Shinken Poller service.

    module.exports.push header: 'Shinken Poller # Start', label_true: 'STARTED', handler: ->
      @service_start name: 'shinken-poller'

## Start Executor

Start the docker executors (normal and admin)

    module.exports.push header: 'Shinken Poller # Start Executor', label_true: 'STARTED', handler: ->
      {shinken} = @config.ryba
      @docker_start container: 'poller-executor'
      @docker_exec
        container: 'poller-executor'
        cmd: "kinit #{shinken.poller.executor.krb5.unprivileged.principal} -kt /etc/security/keytabs/crond.unprivileged.keytab"
        shy: true
