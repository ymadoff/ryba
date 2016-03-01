
# Hadoop YARN ResourceManager Status

## Status

Check if the ResourceManager is running. The process ID is located by default
inside "/var/run/hadoop-yarn/yarn-yarn-resourcemanager.pid".

    module.exports = header: 'YARN RM Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @service_status
        name: 'hadoop-yarn-resourcemanager'
        if_exists: '/etc/init.d/hadoop-yarn-resourcemanager'
