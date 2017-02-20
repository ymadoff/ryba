
# OpenTSDB Install

    module.exports = header: 'OpenTSDB Install', handler: -> 
      {opentsdb, realm} = @config.ryba
      krb5 = @config.krb5.etc_krb5_conf.realms[realm] 

## Register

      @registry.register ['file', 'jaas'], 'ryba/lib/file_jaas'

## Users & Groups

      @system.group opentsdb.group
      @system.user opentsdb.user

## IPTables

| Service  | Port | Proto | Info               |
|----------|------|-------|--------------------|
| opentsdb | 4242 | http  | OpenTSDB HTTP GUI  |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      @tools.iptables
        header: 'IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: opentsdb.config['tsd.network.port'], protocol: 'tcp', state: 'NEW', comment: "OpenTSDB HTTP GUI" }
        ]
        if: @config.iptables.action is 'start'

## Install

OpenTSDB archive comes with an RPM

      @call header: 'Packages', handler: ->
        @file.download
          source: opentsdb.source
          target: "/var/tmp/opentsdb-#{opentsdb.version}.noarch.rpm"
        @execute
          cmd: "yum localinstall -y --nogpgcheck /var/tmp/opentsdb-#{opentsdb.version}.noarch.rpm"
          unless_exec: "rpm -q --queryformat '%{VERSION}' opentsdb | grep '#{opentsdb.version}'"
        @system.chmod
          header: 'Fix permissions'
          target: "#{opentsdb.user.home}/etc/init.d/opentsdb"
          mode: 0o755
        @execute
          cmd: """
          if ! ls #{opentsdb.user.home}/lib/zookeeper-*.jar | wc -l; then exit 3; fi
          rm -f #{opentsdb.user.home}/lib/zookeeper-*.jar
          """
          code_skipped: 3
        @system.link
          source: '/usr/hdp/current/zookeeper-client/zookeeper.jar'
          target: "#{opentsdb.user.home}/lib/zookeeper.jar"

## Kerberos

      @call
        header: 'Kerberos'
        if: opentsdb.config['hbase.security.authentication'] is 'kerberos'
        handler: ->
          @krb5_addprinc krb5,
            principal: "#{opentsdb.user.name}/#{@config.host}@#{realm}"
            randkey: true
            keytab: '/etc/security/keytabs/opentsdb.service.keytab'
            uid: opentsdb.user.name
            gid: opentsdb.group.name
          @file.jaas
            target: '/etc/opentsdb/opentsdb.jaas'
            content: "#{opentsdb.config['hbase.sasl.clientconfig']}":
              principal: "#{opentsdb.user.name}/#{@config.host}@#{realm}"
              useTicketCache: true
            uid: opentsdb.user.name
            gid: opentsdb.group.name
          @cron.add
            cmd: "/usr/bin/kinit #{opentsdb.user.name}/#{@config.host}@#{realm} -k -t /etc/security/keytabs/opentsdb.service.keytab"
            when: '0 */9 * * *'
            user: opentsdb.user.name
            exec: true

## Ulimit

Increase ulimit for the OpenTSDB user. By default, ryba will create the file:

```bash
cat /etc/security/limits.d/opentsdb.conf
opentsdb   - nofile 65535
opentsdb   - nproc  24576
```

If not configured, the following message appear on startup:

```
Starting opentsdb: /etc/init.d/opentsdb: line 69: ulimit: open files: cannot modify limit: Operation not permitted
'ulimit -n' must be greater than or equal to 65535, is 1024
```

      @system.limits
        header: 'Ulimit'
        user: opentsdb.user.name
      , opentsdb.user.limits

## Fix Service

      # Some config properties aren't honored, force JVM Arguments
      @file
        header: 'Fix Service Init Script'
        target: '/etc/init.d/opentsdb'
        write: [
          match: /^USER=.*$/mg
          replace: "USER=#{opentsdb.user.name} # RYBA CONF `user`, DON'T OVERWRITE"
        ,
          match: /^.*# RYBA CONF `env` and `java_opts`, DON'T OVERWRITE$/m
          replace: "  JVMARGS=\"${JVMARGS}#{" -D#{k}=#{v}" for k, v of opentsdb.env} #{opentsdb.java_opts}\" # RYBA CONF `env` and `java_opts`, DON'T OVERWRITE"
          place_before: /^( *)export JVMARGS$/m
        ]

## Configure

      @file.properties
        header: 'opentsdb conf'
        target: '/etc/opentsdb/opentsdb.conf'
        content: opentsdb.config
        backup: true

## HBase Table

      @call once: true, 'ryba/hbase/master/wait'
      namespaces = []
      tables = {}
      for table in ['data', 'uid', 'tree', 'meta']
        tables[table] = opentsdb.config["tsd.storage.hbase.#{table}_table"]
        split = tables[table].split ':'
        genericErr = new Error "Incorrect table name for table '#{table}': must be [<ns>:]<table>"
        if split.length > 2
          throw genericErr
        else if split.length is 2
          namespaces.push split[0]
      @call if: namespaces.length > 0, header: 'Create HBase namespaces', handler: ->
        for ns in namespaces
          @execute
            cmd: mkcmd.hbase @, """
            hbase shell -n <<< "create_namespace '#{ns}'"
            """
            unless_exec: mkcmd.hbase @, "hbase shell -n <<< 'list_namespace' | grep '#{ns}'"
          @execute
            cmd: mkcmd.hbase @, """
            hbase shell -n <<< "grant '#{opentsdb.user.name}', 'RWXCA', '@#{ns}'"
            """
            shy: true
      @execute
        header: 'Create HBase tables'
        # hbase shell -n : quit on ERROR with non-zero status
        cmd: mkcmd.hbase @, """
        hbase shell -n <<CMD
          create '#{tables['uid']}',
            {NAME => 'id', COMPRESSION => '#{opentsdb.hbase.compression}', BLOOMFILTER => '#{opentsdb.hbase.bloomfilter}'},
            {NAME => 'name', COMPRESSION => '#{opentsdb.hbase.compression}', BLOOMFILTER => '#{opentsdb.hbase.bloomfilter}'}
          create '#{tables['data']}',
            {NAME => 't', VERSIONS => 1, COMPRESSION => '#{opentsdb.hbase.compression}', BLOOMFILTER => '#{opentsdb.hbase.bloomfilter}'}
          create '#{tables['tree']}',
            {NAME => 't', VERSIONS => 1, COMPRESSION => '#{opentsdb.hbase.compression}', BLOOMFILTER => '#{opentsdb.hbase.bloomfilter}'}    
          create '#{tables['meta']}',
            {NAME => 'name', COMPRESSION => '#{opentsdb.hbase.compression}', BLOOMFILTER => '#{opentsdb.hbase.bloomfilter}'}
          grant '#{opentsdb.user.name}', 'RWXCA', '#{tables['uid']}'
          grant '#{opentsdb.user.name}', 'RWXCA', '#{tables['data']}'
          grant '#{opentsdb.user.name}', 'RWXCA', '#{tables['tree']}'
          grant '#{opentsdb.user.name}', 'RWXCA', '#{tables['meta']}'
        CMD
        """
        unless_exec: mkcmd.hbase @, "[ `hbase shell -n <<< 'list' | egrep '^(#{tables['uid']}|#{tables['data']}|#{tables['tree']}|#{tables['meta']})' | sort | uniq | wc -l` -eq 4 ]"

## Dependencies

    mkcmd = require '../lib/mkcmd'
