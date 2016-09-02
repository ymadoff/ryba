
# Oozie Server Start

Run the command `./bin/ryba start -m ryba/oozie/server` to start the Oozie
server using Ryba.

By default, the pid of the running server is stored in
"/var/run/oozie/oozie.pid".

Start the Oozie server. You can also start the server manually with the
following command:

```
service oozie start
su -l oozie -c "/usr/hdp/current/oozie-server/bin/oozied.sh start"
```

Note, there is no need to clean a zombie pid file before starting the server.

    module.exports = header: 'Oozie Server Start', label_true: 'STARTED', timeout: -1, handler: ->

Wait for all the dependencies.

      @call once: true, 'masson/core/krb5_client/wait'
      @call once: true, 'ryba/zookeeper/server/wait'
      @call once: true, 'ryba/hadoop/hdfs_nn/wait'
      @call once: true, 'ryba/hbase/master/wait'
      @call once: true, 'ryba/hive/hcatalog/wait'
      @call once: true, 'ryba/hive/server2/wait'
      @call once: true, 'ryba/hive/webhcat/wait'

Start the service

      @service.start
        name: 'oozie'
