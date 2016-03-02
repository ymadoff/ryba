
# HBase RegionServer Start

Start the RegionServer server. You can also start the server manually with one of the
following two commands:

```
service hbase-regionserver start
su -l hbase -c "/usr/hdp/current/hbase-regionserver/bin/hbase-daemon.sh --config /etc/hbase/conf start regionserver"
```

    module.exports = header: 'HBase RegionServer Start', label_true: 'STARTED', handler: ->
      @service_start
        name: 'hbase-regionserver'
        if_exists: '/etc/init.d/hbase-regionserver'
