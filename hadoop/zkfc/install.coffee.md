
# Hadoop ZKFC Install

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/iptables'
    module.exports.push 'ryba/hadoop/hdfs'
    module.exports.push require '../../lib/hdp_service'
    module.exports.push require('./index').configure

## IPTables

| Service   | Port | Proto  | Parameter                  |
|-----------|------|--------|----------------------------|
| namenode  | 8019  | tcp   | dfs.ha.zkfc.port           |

    module.exports.push name: 'HDFS ZKFC # IPTables', handler: (ctx, next) ->
      ctx.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: 8019, protocol: 'tcp', state: 'NEW', comment: "ZKFC IPC" }
        ]
        if: ctx.config.iptables.action is 'start'
      , next

## Service

Install the "hadoop-hdfs-zkfc" service, symlink the rc.d startup script
in "/etc/init.d/hadoop-hdfs-datanode" and define its startup strategy.

    module.exports.push name: 'HDFS ZKFC # Service', handler: (ctx, next) ->
      {hdfs} = ctx.config.ryba
      ctx.hdp_service
        name: 'hadoop-hdfs-zkfc'
        version_name: 'hadoop-hdfs-namenode'
        write: [
          match: /^USER=".*?".*CONF_DIR.*$/mg
          replace: "USER=\"$SVC_USER\"; . $CONF_DIR/hadoop-env.sh # RYBA FIX rc.d"
          before: /^DAEMON=.*$/mg
        ,
          # HDP default is "/usr/lib/hadoop/sbin/hadoop-daemon.sh"
          match: /^EXEC_PATH=.*$/m
          replace: "EXEC_PATH=\"${HADOOP_HOME}/sbin/hadoop-daemon.sh\" # RYBA HONORS /etc/default, DONT OVEWRITE"
        ,
          match: /^PIDFILE=".*".*$/mg
          replace: "PIDFILE=\"$HADOOP_PID_DIR/hadoop-$HADOOP_IDENT_STRING-zkfc.pid\" # RYBA FIX rc.d"
        ]
        etc_default:
          'hadoop': true
          'hadoop-hdfs-zkfc': 
            write: [
              match: /^export HADOOP_PID_DIR=.*$/m # HDP default is "/var/run/hadoop-hdfs"
              replace: "export HADOOP_PID_DIR=#{hdfs.pid_dir} # RYBA"
            ,
              match: /^export HADOOP_LOG_DIR=.*$/m # HDP default is "/var/log/hadoop-hdfs"
              replace: "export HADOOP_LOG_DIR=#{hdfs.log_dir} # RYBA"
            ,
              match: /^export HADOOP_IDENT_STRING=.*$/m # HDP default is "hdfs"
              replace: "export HADOOP_IDENT_STRING=#{hdfs.user.name} # RYBA"
            ]
      , next

## Configure

    module.exports.push name: 'HDFS ZKFC # Configure', timeout: -1, handler: (ctx, next) ->
      {hdfs, hadoop_conf_dir, hadoop_group} = ctx.config.ryba
      ctx.hconfigure
        destination: "#{hadoop_conf_dir}/hdfs-site.xml"
        default: "#{__dirname}/../../resources/core_hadoop/hdfs-site.xml"
        local_default: true
        properties: hdfs.site
        uid: hdfs.user.name
        gid: hadoop_group.name
        merge: true
        backup: true
      , next


## Zookeeper JAAS

Secure the Zookeeper connection with JAAS.

    module.exports.push name: 'HDFS ZKFC # Zookeeper JAAS', timeout: -1, handler: (ctx, next) ->
      {hdfs, hadoop_conf_dir, hadoop_group, zkfc_password} = ctx.config.ryba
      modified = false
      do_core = ->
        ctx.hconfigure
          destination: "#{hadoop_conf_dir}/core-site.xml"
          properties:
            'ha.zookeeper.auth': "@#{hadoop_conf_dir}/zk-auth.txt"
            'ha.zookeeper.acl': "@#{hadoop_conf_dir}/zk-acl.txt"
          merge: true
          backup: true
        , (err, configured) ->
          return next err if err
          modified = true if configured
          do_content()
      do_content = ->
        ctx.write [
          destination: "#{hadoop_conf_dir}/zk-auth.txt"
          content: "digest:hdfs-zkfcs:#{zkfc_password}"
          uid: hdfs.user.name
          gid: hadoop_group.name
          mode: 0o0700
        ], (err, written) ->
          return next err if err
          modified = true if written
          do_generate()
      do_generate = ->
          ctx.execute
            cmd: """
            export ZK_HOME=/usr/hdp/current/zookeeper-server
            java -cp $ZK_HOME/lib/*:$ZK_HOME/zookeeper.jar org.apache.zookeeper.server.auth.DigestAuthenticationProvider hdfs-zkfcs:#{zkfc_password}
            """
          , (err, _, stdout) ->
            digest = match[1] if match = /\->(.*)/.exec(stdout)
            return next Error "Failed to get digest" unless digest
            ctx.write
              destination: '/etc/hadoop/conf/zk-acl.txt'
              content: "digest:#{digest}:rwcda"
            , (err, written) ->
              return next err if err
              modified = true if written
              do_end()
      do_end = ->
        next null, modified
      do_core()

## SSH Fencing

Implement the SSH fencing strategy on each NameNode. To achieve this, the
"hdfs-site.xml" file is updated with the "dfs.ha.fencing.methods" and
"dfs.ha.fencing.ssh.private-key-files" properties.

For SSH fencing to work, the HDFS user must be able to log for each NameNode
into any other NameNode. Thus, the public and private SSH keys of the
HDFS user are deployed inside his "~/.ssh" folder and the
"~/.ssh/authorized_keys" file is updated accordingly.

We also make sure SSH access is not blocked by a rule defined
inside "/etc/security/access.conf". A specific rule for the HDFS user is
inserted if ALL users or the HDFS user access is denied.

    module.exports.push name: 'HDFS NN # SSH Fencing', handler: (ctx, next) ->
      {hdfs, hadoop_conf_dir, ssh_fencing, hadoop_group} = ctx.config.ryba
      return next() unless ctx.hosts_with_module('ryba/hadoop/hdfs_nn').length > 1
      modified = false
      do_mkdir = ->
        ctx.mkdir
          destination: "#{hdfs.user.home}/.ssh"
          uid: hdfs.user.name
          gid: hadoop_group.name
          mode: 0o700
        , (err, created) ->
          return next err if err
          do_upload_keys()
      do_upload_keys = ->
        ctx.upload [
          source: "#{ssh_fencing.private_key}"
          destination: "#{hdfs.user.home}/.ssh"
          uid: hdfs.user.name
          gid: hadoop_group.name
          mode: 0o600
        ,
          source: "#{ssh_fencing.public_key}"
          destination: "#{hdfs.user.home}/.ssh"
          uid: hdfs.user.name
          gid: hadoop_group.name
          mode: 0o655
        ], (err, written) ->
          return next err if err
          modified = true if written
          do_authorized()
      do_authorized = ->
        fs.readFile "#{ssh_fencing.public_key}", (err, content) ->
          return next err if err
          ctx.write
            destination: "#{hdfs.user.home}/.ssh/authorized_keys"
            content: content
            append: true
            uid: hdfs.user.name
            gid: hadoop_group.name
            mode: 0o600
          , (err, written) ->
            return next err if err
            modified = true if written
            do_access()
      do_access = ->
        ctx.fs.readFile '/etc/security/access.conf', (err, source) ->
          return next err if err
          content = []
          exclude = ///^\-\s?:\s?(ALL|#{hdfs.user.name})\s?:\s?(.*?)\s*?(#.*)?$///
          include = ///^\+\s?:\s?(#{hdfs.user.name})\s?:\s?(.*?)\s*?(#.*)?$///
          included = false
          for line, i in source = source.split /\r\n|[\n\r\u0085\u2028\u2029]/g
            if match = include.exec line
              included = true # we shall also check if the ip/fqdn match in origin
            if not included and match = exclude.exec line
              nn_hosts = ctx.hosts_with_module 'ryba/hadoop/hdfs_nn'
              content.push "+ : #{hdfs.user.name} : #{nn_hosts.join ','}"
            content.push line
          return do_end() if content.length is source.length
          ctx.write
            destination: '/etc/security/access.conf'
            content: content.join '\n'
          , (err, written) ->
            return next err if err
            modified = true if written
            do_end()
      do_end = ->
          next null, modified
      do_mkdir()

## Dependencies

    fs = require 'fs'
      