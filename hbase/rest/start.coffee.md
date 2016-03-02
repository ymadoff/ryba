
# HBase Rest Gateway Start

Start the Rest server. You can also start the server manually with one of the
following two commands:

```
service hbase-rest start
su -l hbase -c "/usr/hdp/current/hbase-client/bin/hbase-daemon.sh --config /etc/hbase/conf start rest"
```

The file storing the PID is "/var/run/hbase/hbase-hbase-rest.pid".

    module.exports = header: 'HBase Rest Start', label_true: 'STARTED', handler: ->
      @service_start
        name: 'hbase-rest'
        if_exists: '/etc/init.d/hbase-rest'
