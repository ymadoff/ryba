
# Hadoop YARN ResourceManager Status

    module.exports = []
    module.exports.push 'masson/bootstrap'
    # module.exports.push require('./index').configure

## Status

Check if the ResourceManager is running. The process ID is located by default
inside "/var/run/hadoop-yarn/yarn-yarn-resourcemanager.pid".

    module.exports.push header: 'YARN RM # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @service_status
        name: 'hadoop-yarn-resourcemanager'
        if_exists: '/etc/init.d/hadoop-yarn-resourcemanager'
