
# Phoenix Check

CSV data can be bulk loaded with built in utility named "psql.py". A shell is
available with the utility named "sqlline.py"

## Check Import and Select

Phoenix requires "RWXCA" permissions on the HBase table. Permission "execute" is
required for coprocessor execution and permission "admin" is required to grant
new permission to additionnal users.

Phoenix table are automatically converted to uppercase.

Refer to the [sqlline] documentation for a complete list of supported command
instructions.

    module.exports = header: 'Phoenix Client Check', label_true: 'CHECKED', handler: ->
      {force_check, user, hbase} = @config.ryba
      zk_path = "#{hbase.site['hbase.zookeeper.quorum']}"
      zk_path += ":#{hbase.site['hbase.zookeeper.property.clientPort']}"
      zk_path += "#{hbase.site['zookeeper.znode.parent']}"

## Wait

      @call once: true, 'ryba/hbase/master/wait'
      @call once: true, 'ryba/hbase/regionserver/wait'

## Check SQL Query

      # ../doc/examples/WEB_STAT_QUERIES.sql
      table = "ryba_check_phoenix_#{@config.shortname}".toUpperCase()
      check = false
      @execute
        cmd: mkcmd.hbase @, """
        hdfs dfs -rm -skipTrash check-#{@config.host}-phoenix
        # Drop table if it exists
        # if hbase shell 2>/dev/null <<< "list" | grep '#{table}'; then echo "disable '#{table}'; drop '#{table}'" | hbase shell 2>/dev/null; fi
        echo "disable '#{table}'; drop '#{table}'" | hbase shell 2>/dev/null
        # Create table with dummy column family and grant access to ryba
        echo "create '#{table}', 'cf1'; grant 'ryba', 'RWXCA', '#{table}'" | hbase shell 2>/dev/null;
        """
        # unless_exec: unless force_check then mkcmd.test @, "hbase shell 2>/dev/null <<< \"list\" | grep -w '#{table}'"
        unless_exec: unless force_check then mkcmd.test @, "hdfs dfs -test -f check-#{@config.host}-phoenix"
      , (err, status) ->
        check = status unless err
      @write
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
      @write
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
      @execute
        cmd: mkcmd.test @, """
        cd /usr/hdp/current/phoenix-client/bin
        ./psql.py -t #{table} #{zk_path} \
          #{user.home}/check_phoenix/create.sql \
          ../doc/examples/WEB_STAT.csv \
        >/dev/null 2>&1
        ./sqlline.py #{zk_path} \
          #{user.home}/check_phoenix/select.sql \
        | egrep "^'" | tail -n+2
        hdfs dfs -touchz check-#{@config.host}-phoenix
        """
        if: -> check
        trap_on_error: true
      , (err, check, data) ->
        throw err if err
        throw Error "Invalid output" if check and string.lines(data.trim()).length isnt 3

## Dependencies

    mkcmd = require '../../lib/mkcmd'
    string = require 'mecano/lib/misc/string'

[sqlline]: http://sqlline.sourceforge.net/#commands
