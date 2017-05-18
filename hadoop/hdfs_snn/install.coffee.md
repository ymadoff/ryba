
# Hadoop HDFS SecondaryNameNode Install

    module.exports = header: 'HDFS SNN', handler: ->
      {host} = @config
      {realm, hdfs, hadoop_group} = @config.ryba
      krb5 = @config.krb5.etc_krb5_conf.realms[realm]

## Register

      @registry.register 'hconfigure', 'ryba/lib/hconfigure'
      @registry.register 'hdp_select', 'ryba/lib/hdp_select'

## IPTables

| Service    | Port | Proto  | Parameter                  |
|------------|------|--------|----------------------------|
| namenode  | 50070 | tcp    | dfs.namdnode.http-address  |
| namenode  | 50470 | tcp    | dfs.namenode.https-address |
| namenode  | 8020  | tcp    | fs.defaultFS               |
| namenode  | 8019  | tcp    | dfs.ha.zkfc.port           |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      [_, http_port] = hdfs.site['dfs.namenode.secondary.http-address'].split ':'
      [_, https_port] = hdfs.site['dfs.namenode.secondary.https-address'].split ':'
      @tools.iptables
        header: 'IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: http_port, protocol: 'tcp', state: 'NEW', comment: "HDFS SNN HTTP" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: https_port, protocol: 'tcp', state: 'NEW', comment: "HDFS SNN HTTPS" }
        ]
        if: @config.iptables.action is 'start'

## Service

Install the "hadoop-hdfs-secondarynamenode" service, symlink the rc.d startup
script inside "/etc/init.d" and activate it on startup.

      @call header: 'Service', ->
        @service
          name: 'hadoop-hdfs-secondarynamenode'
        @hdp_select
          name: 'hadoop-hdfs-client' # Not checked
          name: 'hadoop-hdfs-secondarynamenode'
        @service.init
          if_os: name: ['redhat','centos'], version: '6'
          header: 'Initd script'
          target: '/etc/init.d/hadoop-hdfs-secondarynamenode'
          source: "#{__dirname}/../resources/secondarynamenode.j2"
          local: true
          context: @config
          mode: 0o0755
        @call
          if_os: name: ['redhat','centos'], version: '7'
        , ->
          @service.init
            header: 'Systemd Script'
            target: '/usr/lib/systemd/system/hadoop-hdfs-secondarynamenode.service'
            source: "#{__dirname}/../resources/hadoop-hdfs-secondarynamenode-systemd.j2"
            local: true
            context: @config.ryba
            mode: 0o0755
          @system.tmpfs
            mount: "#{hdfs.pid_dir}"
            uid: hdfs.user.name
            gid: hadoop_group.name
            perm: '0755'

      @call header: 'Layout', timeout: -1, ->
        @system.mkdir
          target: for dir in hdfs.site['dfs.namenode.checkpoint.dir'].split ','
            if dir.indexOf('file://') is 0
            then dir.substr(7) else dir
          uid: hdfs.user.name
          gid: hadoop_group.name
          mode: 0o755
        @system.mkdir
          target: "#{hdfs.pid_dir.replace '$USER', hdfs.user.name}"
          uid: hdfs.user.name
          gid: hadoop_group.name
          mode: 0o755
        @system.mkdir
          target: "#{hdfs.log_dir}" #/#{hdfs.user.name}
          uid: hdfs.user.name
          gid: hdfs.group.name
          parent: true

      @krb5.addprinc krb5,
        header: 'Kerberos'
        principal: "nn/#{host}@#{realm}"
        randkey: true
        keytab: hdfs.site['dfs.secondary.namenode.keytab.file']
        uid: 'hdfs'
        gid: 'hadoop'

# Configure

      @hconfigure
        header: 'Configuration'
        target: "#{hdfs.snn.conf_dir}/hdfs-site.xml"
        source: "#{__dirname}/../../resources/core_hadoop/hdfs-site.xml"
        local: true
        properties: hdfs.site
        uid: hdfs.user
        gid: hadoop_group
        backup: true
