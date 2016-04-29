
# OpenTSDB Install

    module.exports = header: 'OpenTSDB Install', handler: -> 
      {opentsdb, realm} = @config.ryba
      {kadmin_principal, kadmin_password, admin_server} = @config.krb5.etc_krb5_conf.realms[realm] 

## Users & Groups

      @group opentsdb.group
      @user opentsdb.user

## IPTables

| Service  | Port | Proto | Info               |
|----------|------|-------|--------------------|
| opentsdb | 4242 | http  | OpenTSDB HTTP GUI  |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      @iptables
        header: 'IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: opentsdb.config['tsd.network.port'], protocol: 'tcp', state: 'NEW', comment: "OpenTSDB HTTP GUI" }
        ]
        if: @config.iptables.action is 'start'

## Install

OpenTSDB archive comes with an RPM

      @call header: 'Packages', handler: ->
        @download
          source: opentsdb.source
          destination: "/var/tmp/opentsdb-#{opentsdb.version}.noarch.rpm"
          shy: true
          unless_exec: "rpm -q --queryformat '%{VERSION}' opentsdb | grep '#{opentsdb.version}'"
        @execute
          cmd: "yum localinstall -y --nogpgcheck /var/tmp/opentsdb-#{opentsdb.version}.noarch.rpm"
          unless_exec: "rpm -q --queryformat '%{VERSION}' opentsdb | grep '#{opentsdb.version}'"
        @remove
          destination: "/var/tmp/opentsdb-#{opentsdb.version}.noarch.rpm"
        @remove
          destination: "#{opentsdb.user.home}/lib/zookeeper-3.3.6.jar"
        @link
          source: '/usr/hdp/current/zookeeper-client/zookeeper.jar'
          destination: "#{opentsdb.user.home}/lib/zookeeper.jar"

## Kerberos

      @call
        header: 'Kerberos'
        if: opentsdb.config['hbase.security.authentication'] is 'kerberos'
        handler: ->
          @krb5_addprinc
            principal: "#{opentsdb.user.name}/#{@config.host}@#{realm}"
            randkey: true
            keytab: '/etc/security/keytabs/opentsdb.service.keytab'
            uid: opentsdb.user.name
            gid: opentsdb.group.name
            kadmin_principal: kadmin_principal
            kadmin_password: kadmin_password
            kadmin_server: admin_server
          @call once: true, 'ryba/lib/write_jaas'
          @write_jaas
            destination: '/etc/opentsdb/opentsdb.jaas'
            content: "#{opentsdb.config['hbase.sasl.clientconfig']}":
              principal: "#{opentsdb.user.name}/#{@config.host}@#{realm}"
              useTicketCache: true
            uid: opentsdb.user.name
            gid: opentsdb.group.name
          @cron_add
            cmd: "/usr/bin/kinit #{opentsdb.user.name}/#{@config.host}@#{realm} -k -t /etc/security/keytabs/opentsdb.service.keytab"
            when: '0 */9 * * *'
            user: opentsdb.user.name
            exec: true

## Fix Service

      # Some config properties aren't honored, force JVM Arguments
      @write
        header: 'Fix Service Init Script'
        destination: '/etc/init.d/opentsdb'
        write: [
          match: /^USER=.*$/mg
          replace: "USER=#{opentsdb.user.name} # RYBA CONF `user`, DON'T OVERWRITE"
        ,
          match: /^.*# RYBA CONF `env` and `java_opts`, DON'T OVERWRITE$/m
          replace: "  JVMARGS=\"${JVMARGS}#{" -D#{k}=#{v}" for k, v of opentsdb.env} #{opentsdb.java_opts}\" # RYBA CONF `env` and `java_opts`, DON'T OVERWRITE"
          before: /^( *)export JVMARGS$/m
        ]

## Configure

      @write_properties
        header: 'opentsdb conf'
        destination: '/etc/opentsdb/opentsdb.conf'
        content: opentsdb.config
        backup: true

## HBase Table

      @call once: true, 'ryba/hbase/master/wait'
      t_data = opentsdb.config['tsd.storage.hbase.data_table']
      t_uid = opentsdb.config['tsd.storage.hbase.uid_table']
      t_tree = opentsdb.config['tsd.storage.hbase.tree_table']
      t_meta = opentsdb.config['tsd.storage.hbase.meta_table']
      @execute
        header: 'Create HBase table'
        # hbase shell -n : quit on ERROR with non-zero status
        cmd: mkcmd.hbase @, """
        hbase shell -n <<EOF
        create '#{t_uid}',
          {NAME => 'id', COMPRESSION => '#{opentsdb.hbase.compression}', BLOOMFILTER => '#{opentsdb.hbase.bloomfilter}'},
          {NAME => 'name', COMPRESSION => '#{opentsdb.hbase.compression}', BLOOMFILTER => '#{opentsdb.hbase.bloomfilter}'}
        create '#{t_data}',
          {NAME => 't', VERSIONS => 1, COMPRESSION => '#{opentsdb.hbase.compression}', BLOOMFILTER => '#{opentsdb.hbase.bloomfilter}'}
        create '#{t_tree}',
          {NAME => 't', VERSIONS => 1, COMPRESSION => '#{opentsdb.hbase.compression}', BLOOMFILTER => '#{opentsdb.hbase.bloomfilter}'}    
        create '#{t_meta}',
          {NAME => 'name', COMPRESSION => '#{opentsdb.hbase.compression}', BLOOMFILTER => '#{opentsdb.hbase.bloomfilter}'}
        EOF
        """
        # OpenTSDB is not working without the hbase admin rights ! So we map its principal on hbase user for now (2.2.0 RC3)
        # TODO: Retest it for next versions
        # grant 'opentsdb', 'RWXCA', '#{t_data}'
        # grant 'opentsdb', 'RWXCA', '#{t_uid}'
        # grant 'opentsdb', 'RWXCA', '#{t_meta}'
        # grant 'opentsdb', 'RWXCA', '#{t_tree}'
        # EOF
        # """
        unless_exec: mkcmd.hbase @, "[ `hbase shell -n <<< 'list' | egrep '^(#{t_data}|#{t_uid}|#{t_tree}|#{t_meta})' | sort | uniq | wc -l` -eq 4 ]"

## Dependencies

    mkcmd = require '../lib/mkcmd'
