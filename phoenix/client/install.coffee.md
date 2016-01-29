
# Phoenix Install

Please refer to the Hortonworks [documentation][phoenix-doc]. Kerberos
deployment is heavily inspired by [Anil Gupta instruction][agi].

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/yum'
    module.exports.push 'masson/commons/java'
    module.exports.push 'ryba/hbase/client/install'
    # module.exports.push require('../../hadoop/core').configure
    # module.exports.push require('../../hbase/client').configure
    # module.exports.push require('./index').configure
    module.exports.push 'ryba/lib/hconfigure'
    module.exports.push 'ryba/lib/write_jaas'
    module.exports.push 'ryba/lib/hdp_select'

## Packages

    module.exports.push header: 'Phoenix Client # Install', handler: ->
      @service name: 'phoenix'
      @hdp_select name: 'phoenix-client'

    module.exports.push header: 'Phoenix Client # Hadoop Configuration', handler: ->
      {hadoop_conf_dir} = @config.ryba
      @execute
        cmd:"""
        ln -sf #{path.join hadoop_conf_dir, 'core-site.xml'} /usr/hdp/current/phoenix-client/bin/core-site.xml
        """
        unless_exists: '/usr/hdp/current/phoenix-client/bin/core-site.xml'

    module.exports.push header: 'Phoenix Client # HBase Configuration', handler: ->
      {hbase} = @config.ryba
      @execute
        cmd:"""
        ln -sf #{path.join hbase.conf_dir, 'hbase-site.xml'} /usr/hdp/current/phoenix-client/bin/hbase-site.xml
        """
        unless_exists: '/usr/hdp/current/phoenix-client/bin/hbase-site.xml'

## Kerberos

Thanks to [Anil Gupta](http://bigdatanoob.blogspot.fr/2013/09/connect-phoenix-to-secure-hbase-cluster.html)
for its instructions.

    module.exports.push header: 'Phoenix Client # Kerberos', handler: ->
      {hadoop_conf_dir, hbase, phoenix} = @config.ryba
      @write_jaas
        destination: "#{phoenix.conf_dir}/phoenix-client.jaas"
        content: Client:
          useTicketCache: 'true'
      @write
        destination: '/usr/hdp/current/phoenix-client/bin/psql.py'
        write: [
          replace: "    os.pathsep + '#{hadoop_conf_dir}' + os.pathsep + '#{hbase.conf_dir}' + os.pathsep + '/usr/hdp/current/hadoop-client/hadoop-auth-*.jar' \\"
          match: ///^.*#{quote '/usr/hdp/current/hadoop-client/hadoop-auth'}.*$///m
          before: 'log4j.configuration'
        ,
          replace: "    \" -Djava.security.auth.login.config=\'#{phoenix.conf_dir}/phoenix-client.jaas\'\" + \\"
          match: ///^.*#{quote '-Djava.security.auth.login.config='}.*$///m
          before: 'org.apache.phoenix.util.PhoenixRuntime'
        ]
        backup: true
      @write
        destination: '/usr/hdp/current/phoenix-client/bin/sqlline.py'
        write: [
          replace: "    os.pathsep + '#{hadoop_conf_dir}' + os.pathsep + '#{hbase.conf_dir}' + os.pathsep + '/usr/hdp/current/hadoop-client/hadoop-auth-*.jar' \\"
          match: ///^.*#{quote '/usr/hdp/current/hadoop-client/hadoop-auth'}.*$///m
          before: 'log4j.configuration'
        ,
          replace: "    \" -Djava.security.auth.login.config=\'#{phoenix.conf_dir}/phoenix-client.jaas\'\" + \\"
          match: ///^.*#{quote '-Djava.security.auth.login.config='}.*$///m
          before: 'sqlline.SqlLine'
        ]
        backup: true

## Wait for HBase

    module.exports.push 'ryba/hbase/regionserver/wait'
    module.exports.push 'ryba/hbase/master/wait'

## Init

There is 4 phoenix 'SYSTEM.*' tables. If they don't exist in HBase, we launch
phoenix with hbase admin user.
Independently, if 'ryba' hasn't CREATE right on these 4 tables, it will be granted

    module.exports.push header: 'Phoenix Client # Init', timeout: 200000, handler: ->
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

    path = require 'path'
    quote = require 'regexp-quote'
    mkcmd = require '../../lib/mkcmd'

[phoenix-doc]: http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.2.4/HDP_Man_Install_v224/index.html#installing_phoenix
[agi]: http://bigdatanoob.blogspot.fr/2013/09/connect-phoenix-to-secure-hbase-cluster.html
