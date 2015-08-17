
# Phoenix Install

Please refer to the Hortonworks [documentation][phoenix-doc]. Kerberos
deployment is heavily inspired by [Anil Gupta instruction][agi].

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/yum'
    module.exports.push 'masson/commons/java'
    module.exports.push 'ryba/hbase/client/install'
    module.exports.push require('../../hadoop/core').configure
    module.exports.push require('../../hbase/client').configure
    module.exports.push require('./index').configure
    module.exports.push require '../../lib/hconfigure'
    module.exports.push require '../../lib/hdp_select'

## Packages

    module.exports.push name: 'Phoenix Client # Install', handler: (ctx, next) ->
      ctx
      .service name: 'phoenix'
      .hdp_select name: 'phoenix-client'
      .then next

    module.exports.push name: 'Phoenix Client # Hadoop Configuration', handler: (ctx, next) ->
      {hadoop_conf_dir} = ctx.config.ryba
      ctx.execute
        cmd:"""
        ln -sf #{path.join hadoop_conf_dir, 'core-site.xml'} /usr/hdp/current/phoenix-client/bin/core-site.xml
        """
        not_if_exists: '/usr/hdp/current/phoenix-client/bin/core-site.xml'
      .then next

    module.exports.push name: 'Phoenix Client # HBase Configuration', handler: (ctx, next) ->
      {hbase} = ctx.config.ryba
      ctx.execute
        cmd:"""
        ln -sf #{path.join hbase.conf_dir, 'hbase-site.xml'} /usr/hdp/current/phoenix-client/bin/hbase-site.xml
        """
        not_if_exists: '/usr/hdp/current/phoenix-client/bin/hbase-site.xml'
      .then next

## Kerberos

Thanks to [Anil Gupta](http://bigdatanoob.blogspot.fr/2013/09/connect-phoenix-to-secure-hbase-cluster.html)
for its instructions.

    module.exports.push name: 'Phoenix Client # Kerberos', handler: (ctx, next) ->
      {hadoop_conf_dir, hbase, phoenix} = ctx.config.ryba
      ctx
      .write
        destination: "#{phoenix.conf_dir}/phoenix-client.jaas"
        content: """
        Client {
          com.sun.security.auth.module.Krb5LoginModule required
          useKeyTab=false
          useTicketCache=true;
        };
        """
      .write
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
      .write
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
      .then next

## Wait for HBase

    module.exports.push 'ryba/hbase/regionserver/wait'

## Init

There is 3 phoenix 'SYSTEM.*' tables. If they don't exist in HBase, we launch
phoenix with hbase admin user.
Independently, if 'ryba' hasn't CREATE right on these 3 tables, it will be granted

    module.exports.push name: 'Phoenix Client # Init', timeout: 200000, handler: (ctx, next) ->
      {hbase} = ctx.config.ryba
      zk_path = "#{hbase.site['hbase.zookeeper.quorum']}"
      zk_path += ":#{hbase.site['hbase.zookeeper.property.clientPort']}"
      zk_path += "hbase.site['zookeeper.znode.parent']"
      ctx.execute
        cmd: mkcmd.hbase ctx, """
        code=3
        if [ `hbase shell 2>/dev/null <<< "list 'SYSTEM.*'" | egrep '^SYSTEM\.' | wc -l` -lt "2" ]; then
        /usr/hdp/current/phoenix-client/bin/sqlline.py #{zk_path} 2>/dev/null <<< '!q'
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
      .then next

## Dependencies

    path = require 'path'
    quote = require 'regexp-quote'
    mkcmd = require '../../lib/mkcmd'

[phoenix-doc]: http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.2.4/HDP_Man_Install_v224/index.html#installing_phoenix
[agi]: http://bigdatanoob.blogspot.fr/2013/09/connect-phoenix-to-secure-hbase-cluster.html
