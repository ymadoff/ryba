
# YARN NodeManager Status

Check if the Yarn NodeManager server is running. The process ID is located by
default inside "/var/run/hadoop-yarn/yarn-yarn-nodemanager.pid".

    module.exports = header: 'YARN NM # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @service_status
        name: 'hadoop-yarn-nodemanager'
        if_exists: '/etc/init.d/hadoop-yarn-nodemanager'
