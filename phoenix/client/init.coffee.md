
## Init

There is 4 phoenix 'SYSTEM.*' tables. If they don't exist in HBase, we launch
phoenix with hbase admin user.
Independently, if 'ryba' hasn't CREATE right on these 4 tables, it will be granted

    module.exports = header: 'Phoenix Client Init', timeout: 200000, handler: ->
      {hbase} = @config.ryba

Wait for HBase to be started.

      @call once: true, 'ryba/hbase/regionserver/wait'
      @call once: true, 'ryba/hbase/master/wait'

Trigger Phoenix tables creation.

      zk_path = "#{hbase.site['hbase.zookeeper.quorum']}"
      zk_path += ":#{hbase.site['hbase.zookeeper.property.clientPort']}"
      zk_path += "#{hbase.site['zookeeper.znode.parent']}"
      @system.execute
        header: 'Namespace'
        cmd: mkcmd.hbase @, """
        code=3
        if ! hbase shell 2>/dev/null <<< "list_namespace_tables 'SYSTEM'" | egrep '^CATALOG$'; then
          /usr/hdp/current/phoenix-client/bin/sqlline.py #{zk_path} <<< '!q' # 2>/dev/null
          echo 'Phoenix tables now created'
          code=0
        fi
        if ! hbase shell 2>/dev/null <<< "user_permission '@SYSTEM'" | egrep 'ryba.* actions=(CREATE|READ|WRITE|ADMIN),(CREATE|READ|WRITE|ADMIN),(CREATE|READ|WRITE|ADMIN),(CREATE|READ|WRITE|ADMIN)'; then
          hbase shell 2>/dev/null <<< "grant 'ryba', 'RWCA', '@SYSTEM'"
          code=0
        fi
        exit $code
        """
        code_skipped: 3

## Dependencies

    mkcmd = require '../../lib/mkcmd'
