
## Init

There is 4 phoenix 'SYSTEM.*' tables. If they don't exist in HBase, we launch
phoenix with hbase admin user.
Independently, if 'ryba' hasn't CREATE right on these 4 tables, it will be granted

    module.exports = header: 'Phoenix Client Init', timeout: 200000, handler: ->
      {hbase} = @config.ryba
      zk_path = "#{hbase.site['hbase.zookeeper.quorum']}"
      zk_path += ":#{hbase.site['hbase.zookeeper.property.clientPort']}"
      zk_path += "#{hbase.site['zookeeper.znode.parent']}"
      @execute
        cmd: mkcmd.hbase @, """
        code=3
        if [ `hbase shell 2>/dev/null <<< "list 'SYSTEM.*'" | egrep '^SYSTEM.' | wc -l` -lt "4" ]; then
          /usr/hdp/current/phoenix-client/bin/sqlline.py #{zk_path} <<< '!q' # 2>/dev/null
          echo 'Phoenix tables now created'
          code=0
        fi
        if [ `hbase shell 2>/dev/null <<< "user_permission 'SYSTEM.*'" | egrep 'ryba.*(CREATE|READ|WRITE).*(CREATE|READ|WRITE).*(CREATE|READ|WRITE)' | wc -l` -lt "4" ]; then
        hbase shell 2>/dev/null <<-CMD
        grant 'ryba', 'RWC', 'SYSTEM.CATALOG'
        grant 'ryba', 'RWC', 'SYSTEM.FUNCTION'
        grant 'ryba', 'RWC', 'SYSTEM.SEQUENCE'
        grant 'ryba', 'RWC', 'SYSTEM.STATS'
        CMD
        code=0
        fi
        exit $code
        """
        code_skipped: 3

## Dependencies

    mkcmd = require '../../lib/mkcmd'
