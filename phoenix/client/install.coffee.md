
# Phoenix Install

Please refer to the Hortonworks [documentation][phoenix-doc]. Kerberos
deployment is heavily inspired by [Anil Gupta instruction][agi].

    module.exports =  header: 'Phoenix Client Install', handler: ->
      {hadoop_conf_dir, phoenix} = @config.ryba
      {hbase} = @config.ryba

## Register

      @register 'hdp_select', 'ryba/lib/hdp_select'
      @register 'write_jaas', 'ryba/lib/write_jaas'

## Packages

      @service name: 'phoenix'
      @hdp_select name: 'phoenix-client'

      @execute
        header: 'Hadoop Configuration'
        cmd:"""
        ln -sf #{path.join hadoop_conf_dir, 'core-site.xml'} /usr/hdp/current/phoenix-client/bin/core-site.xml
        """
        unless_exists: '/usr/hdp/current/phoenix-client/bin/core-site.xml'

      @execute
        header: 'HBase Configuration'
        cmd:"""
        ln -sf #{path.join hbase.conf_dir, 'hbase-site.xml'} /usr/hdp/current/phoenix-client/bin/hbase-site.xml
        """
        unless_exists: '/usr/hdp/current/phoenix-client/bin/hbase-site.xml'

## Kerberos

Thanks to [Anil Gupta](http://bigdatanoob.blogspot.fr/2013/09/connect-phoenix-to-secure-hbase-cluster.html)
for its instructions.

      @call header: 'Kerberos', handler: ->
        @write_jaas
          target: "#{phoenix.conf_dir}/phoenix-client.jaas"
          content: Client:
            useTicketCache: 'true'
        @write
          target: '/usr/hdp/current/phoenix-client/bin/psql.py'
          write: [
            replace: "    os.pathsep + '#{hadoop_conf_dir}' + os.pathsep + '#{hbase.conf_dir}' + os.pathsep + '/usr/hdp/current/hadoop-client/hadoop-auth-*.jar' + \\"
            match: ///^.*#{quote '/usr/hdp/current/hadoop-client/hadoop-auth'}.*$///m
            before: 'log4j.configuration'
          ,
            replace: "    \" -Djava.security.auth.login.config=\'#{phoenix.conf_dir}/phoenix-client.jaas\'\" + \\"
            match: ///^.*#{quote '-Djava.security.auth.login.config='}.*$///m
            before: 'org.apache.phoenix.util.PhoenixRuntime'
          ]
          backup: true
        @write
          target: '/usr/hdp/current/phoenix-client/bin/sqlline.py'
          write: [
            replace: "    os.pathsep + '#{hadoop_conf_dir}' + os.pathsep + '#{hbase.conf_dir}' + os.pathsep + '/usr/hdp/current/hadoop-client/hadoop-auth-*.jar' + \\"
            match: ///^.*#{quote '/usr/hdp/current/hadoop-client/hadoop-auth'}.*$///m
            before: 'log4j.configuration'
          ,
            replace: "    \" -Djava.security.auth.login.config=\'#{phoenix.conf_dir}/phoenix-client.jaas\'\" + \\"
            match: ///^.*#{quote '-Djava.security.auth.login.config='}.*$///m
            before: 'sqlline.SqlLine'
          ]
          backup: true

## Dependencies

    path = require 'path'
    quote = require 'regexp-quote'
    mkcmd = require '../../lib/mkcmd'

[phoenix-doc]: http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.2.4/HDP_Man_Install_v224/index.html#installing_phoenix
[agi]: http://bigdatanoob.blogspot.fr/2013/09/connect-phoenix-to-secure-hbase-cluster.html
