
# Phoenix Check

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/hadoop/yarn_rm/wait'
    module.exports.push 'ryba/hbase/master/wait'
    module.exports.push require('../../hbase/client').configure
    module.exports.push require('./index').configure

## Check Import and Select

Phoenix requires "RWXCA" permissions on the HBase table. Permission "execute" is
required for coprocessor execution and permission "admin" is required to grant
new permission to additionnal users.

Phoenix table are automatically converted to uppercase.

Refer to the [sqlline] documentation for a complete list of supported command
instructions.

    module.exports.push name: 'Phoenix # Check', handler: (ctx, next) ->
      {force_check, user, hbase} = ctx.config.ryba
      zk_path = "#{hbase.site['hbase.zookeeper.quorum']}"
      zk_path += ":#{hbase.site['hbase.zookeeper.property.clientPort']}"
      zk_path += "hbase.site['zookeeper.znode.parent']"
      # ../doc/examples/WEB_STAT_QUERIES.sql
      table = "ryba_check_phoenix_#{ctx.config.shortname}".toUpperCase()
      check = false
      ctx
      .execute
        cmd: mkcmd.hbase ctx, """
        # Drop table if it exists
        # if hbase shell 2>/dev/null <<< "list" | grep '#{table}'; then echo "disable '#{table}'; drop '#{table}'" | hbase shell 2>/dev/null; fi
        echo "disable '#{table}'; drop '#{table}'" | hbase shell 2>/dev/null
        # Create table with dummy column family and grant access to ryba
        echo "create '#{table}', 'cf1'; grant 'ryba', 'RWXCA', '#{table}'" | hbase shell 2>/dev/null;
        """
        not_if_exec: unless force_check then mkcmd.test ctx, "hbase shell 2>/dev/null <<< \"list\" | grep -w '#{table}'"
      , (err, status) ->
        check = status unless err
      .write
        destination: "#{user.home}/check_phoenix/create.sql"
        uid: user.name
        gid: user.group
        content: """
        CREATE TABLE IF NOT EXISTS #{table} (
          HOST CHAR(2) NOT NULL,
          DOMAIN VARCHAR NOT NULL,
          FEATURE VARCHAR NOT NULL,
          DATE DATE NOT NULL,
          USAGE.CORE BIGINT,
          USAGE.DB BIGINT,
          STATS.ACTIVE_VISITOR INTEGER
          CONSTRAINT PK PRIMARY KEY (HOST, DOMAIN, FEATURE, DATE)
        );
        """
      .write
        destination: "#{user.home}/check_phoenix/select.sql"
        uid: user.name
        gid: user.group
        content: """
        !outputformat csv
        SELECT DOMAIN, AVG(CORE) Average_CPU_Usage, AVG(DB) Average_DB_Usage 
        FROM #{table} 
        GROUP BY DOMAIN 
        ORDER BY DOMAIN DESC;
        """
      .execute
        cmd: mkcmd.test ctx, """
        cd /usr/hdp/current/phoenix-client/bin
        ./psql.py -t #{table} #{zk_path} \
          #{user.home}/check_phoenix/create.sql \
          ../doc/examples/WEB_STAT.csv \
        >/dev/null 2>&1
        ./sqlline.py #{zk_path} \
          #{user.home}/check_phoenix/select.sql \
        | egrep "^'" | tail -n+2
        """
        if: -> check
      , (err, check, data) ->
        throw err if err
        return unless check
        throw Error "Invalid output" unless string.lines(data.trim()).length is 3
      .then next

## Dependencies

    mkcmd = require '../../lib/mkcmd'
    string = require 'mecano/lib/misc/string'

[sqlline]: http://sqlline.sourceforge.net/#commands



