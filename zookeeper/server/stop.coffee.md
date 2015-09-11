
# Zookeeper Server Stop

    lifecycle = require '../../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap'
    # module.exports.push require('./index').configure

## Stop

Stop the Zookeeper server. You can also stop the server manually with one of
the following two commands:

```
service zookeeper-server stop
su - zookeeper -c "export ZOOCFGDIR=/usr/hdp/current/zookeeper-server/conf; export ZOOCFG=zoo.cfg; source /usr/hdp/current/zookeeper-server/conf/zookeeper-env.sh; /usr/hdp/current/zookeeper-server/bin/zkServer.sh stop"
```

    module.exports.push name: 'ZooKeeper Server # Stop', label_true: 'STOPPED', handler: ->
      @service
        srv_name: 'zookeeper-server'
        action: 'stop'
        if_exists: '/etc/init.d/zookeeper-server'

## Stop Clean Logs

    module.exports.push name: 'ZooKeeper Server # Stop Clean Logs', label_true: 'CLEANED', handler: ->
      return next() unless @config.ryba.clean_logs
      @execute
        cmd: 'rm /var/log/zookeeper/*'
        code_skipped: 1
