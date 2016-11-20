
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
      @iptables
        header: 'IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: http_port, protocol: 'tcp', state: 'NEW', comment: "HDFS SNN HTTP" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: https_port, protocol: 'tcp', state: 'NEW', comment: "HDFS SNN HTTPS" }
        ]
        if: @config.iptables.action is 'start'

## Service

Install the "hadoop-hdfs-secondarynamenode" service, symlink the rc.d startup
script inside "/etc/init.d" and activate it on startup.

      @call header: 'HDFS SNN # Service', handler: ->
        @service
          name: 'hadoop-hdfs-secondarynamenode'
        @hdp_select
          name: 'hadoop-hdfs-client' # Not checked
          name: 'hadoop-hdfs-secondarynamenode'
        @render
          target: '/etc/init.d/hadoop-hdfs-secondarynamenode'
          source: "#{__dirname}/../resources/secondarynamenode"
          local_source: true
          context: @config
          mode: 0o0755
          unlink: true
        @execute
          cmd: "service hadoop-hdfs-secondarynamenode restart"
          if: -> @status -3

      @call header: 'HDFS SNN # Layout', timeout: -1, handler: ->
        @mkdir
          target: for dir in hdfs.site['dfs.namenode.checkpoint.dir'].split ','
            if dir.indexOf('file://') is 0
            then dir.substr(7) else dir
          uid: hdfs.user.name
          gid: hadoop_group.name
          mode: 0o755
        @mkdir
          target: "#{hdfs.pid_dir.replace '$USER', hdfs.user.name}"
          uid: hdfs.user.name
          gid: hadoop_group.name
          mode: 0o755
        @mkdir
          target: "#{hdfs.log_dir}" #/#{hdfs.user.name}
          uid: hdfs.user.name
          gid: hdfs.group.name
          parent: true

      @krb5_addprinc krb5,
        header: 'HDFS SNN # Kerberos'
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
        local_source: true
        properties: hdfs.site
        uid: hdfs.user
        gid: hadoop_group
        backup: true
