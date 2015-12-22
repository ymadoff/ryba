
# YARN NodeManager Status

    module.exports = []
    module.exports.push 'masson/bootstrap'
    # module.exports.push require('./index').configure

## Status

Check if the Yarn NodeManager server is running. The process ID is located by
default inside "/var/run/hadoop-yarn/yarn-yarn-nodemanager.pid".

    module.exports.push header: 'YARN NM # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @service_status
        name: 'hadoop-yarn-nodemanager'
        if_exists: '/etc/init.d/hadoop-yarn-nodemanager'
