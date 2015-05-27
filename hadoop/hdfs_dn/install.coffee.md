
# Hadoop HDFS DataNode Install

A DataNode manages the storage attached to the node it run on. There
are usually one DataNode per node in the cluster. HDFS exposes a file
system namespace and allows user data to be stored in files. Internally,
a file is split into one or more blocks and these blocks are stored in
a set of DataNodes. The DataNodes also perform block creation, deletion,
and replication upon instruction from the NameNode.

In a Hight Availabity (HA) enrironment, in order to provide a fast
failover, it is necessary that the Standby node have up-to-date
information regarding the location of blocks in the cluster. In order
to achieve this, the DataNodes are configured with the location of both
NameNodes, and send block location information and heartbeats to both.

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/iptables'
    module.exports.push 'ryba/hadoop/hdfs'
    module.exports.push require('./index').configure
    module.exports.push require '../../lib/hconfigure'
    module.exports.push require '../../lib/hdp_service'

## IPTables

| Service   | Port       | Proto     | Parameter                  |
|-----------|------------|-----------|----------------------------|
| datanode  | 50010/1004 | tcp/http  | dfs.datanode.address       |
| datanode  | 50075/1006 | tcp/http  | dfs.datanode.http.address  |
| datanode  | 50475      | tcp/https | dfs.datanode.https.address |
| datanode  | 50020      | tcp       | dfs.datanode.ipc.address   |

The "dfs.datanode.address" default to "50010" in non-secured mode. In non-secured
mode, it must be set to a value below "1024" and default to "1004".

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

    module.exports.push name: 'HDFS DN # IPTables', handler: (ctx, next) ->
      {hdfs} = ctx.config.ryba
      [_, dn_address] = hdfs.site['dfs.datanode.address'].split ':'
      [_, dn_http_address] = hdfs.site['dfs.datanode.http.address'].split ':'
      [_, dn_https_address] = hdfs.site['dfs.datanode.https.address'].split ':'
      [_, dn_ipc_address] = hdfs.site['dfs.datanode.ipc.address'].split ':'
      ctx.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: dn_address, protocol: 'tcp', state: 'NEW', comment: "HDFS DN Data" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: dn_http_address, protocol: 'tcp', state: 'NEW', comment: "HDFS DN HTTP" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: dn_https_address, protocol: 'tcp', state: 'NEW', comment: "HDFS DN HTTPS" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: dn_ipc_address, protocol: 'tcp', state: 'NEW', comment: "HDFS DN Meta" }
        ]
        if: ctx.config.iptables.action is 'start'
      .then next

## Service

Install the "hadoop-hdfs-datanode" service, symlink the rc.d startup script
inside "/etc/init.d" and activate it on startup.

    module.exports.push name: 'HDFS DN # Service', handler: (ctx, next) ->
      {hdfs} = ctx.config.ryba
      ctx.hdp_service
        name: 'hadoop-hdfs-datanode'
        write: [
          match: /^\. \/etc\/default\/hadoop-hdfs-datanode .*$/m
          replace: '. /etc/default/hadoop-hdfs-datanode # RYBA FIX rc.d, DONT OVERWRITE'
          append: ". /lib/lsb/init-functions"
        ,
          match: /^export HADOOP_IDENT_STRING=.*$/m
          replace: "export HADOOP_IDENT_STRING=${HADOOP_SECURE_DN_USER:-$HADOOP_DATANODE_USER} # RYBA FIX"
        ]
        etc_default:
          'hadoop-hdfs-datanode':
            write: [
              match: /^export HADOOP_PID_DIR=.*$/m # HDP default is "/var/run/hadoop-hdfs"
              replace: "export HADOOP_PID_DIR=#{hdfs.pid_dir} # RYBA"
            ,
              match: /^export HADOOP_LOG_DIR=.*$/m # HDP default is "/var/log/hadoop-hdfs"
              replace: "export HADOOP_LOG_DIR=#{hdfs.log_dir} # RYBA"
            ,
              match: /^export HADOOP_IDENT_STRING=.*$/m # HDP default is "hdfs"
              replace: "export HADOOP_IDENT_STRING=#{hdfs.user.name} # RYBA"
            ,
              match: /^export HADOOP_SECURE_DN_USER=.*$/m # HDP default is "hdfs"
              replace: "export HADOOP_SECURE_DN_USER=#{hdfs.secure_dn_user} # RYBA"
              append: true
            ,
              match: /^export HADOOP_SECURE_DN_PID_DIR=.*$/m # HDP default is "hdfs"
              replace: "export HADOOP_SECURE_DN_PID_DIR=#{hdfs.secure_dn_pid_dir} # RYBA"
              append: true
            ,
              match: /^export HADOOP_SECURE_DN_LOG_DIR=.*$/m # HDP default is "hdfs"
              replace: "export HADOOP_SECURE_DN_LOG_DIR=#{hdfs.log_dir} # RYBA"
              append: true
            ]
      .then next

## HA

Update the "hdfs-site.xml" configuration file with the High Availabity properties
present inside the "hdp.ha\_client\_config" object.

    module.exports.push name: 'HDFS DN # HA', handler: (ctx, next) ->
      return next() unless ctx.hosts_with_module('ryba/hadoop/hdfs_nn').length > 1
      {hadoop_conf_dir, hdfs, hadoop_group} = ctx.config.ryba
      ctx
      .hconfigure
        destination: "#{hadoop_conf_dir}/hdfs-site.xml"
        default: "#{__dirname}/../../resources/core_hadoop/hdfs-site.xml"
        local_default: true
        properties: hdfs.site
        uid: hdfs.user.name
        gid: hadoop_group.name
        merge: true
        backup: true
      .then next

# Configure Master

Accoring to [Yahoo!](http://developer.yahoo.com/hadoop/tutorial/module7.html):
The conf/masters file contains the hostname of the
SecondaryNameNode. This should be changed from "localhost"
to the fully-qualified domain name of the node to run the
SecondaryNameNode service. It does not need to contain
the hostname of the JobTracker/NameNode machine;
Also some [interesting info about snn](http://blog.cloudera.com/blog/2009/02/multi-host-secondarynamenode-configuration/)

    module.exports.push name: 'HDFS SNN # Configure Master', handler: (ctx, next) ->
      {hdfs, hadoop_conf_dir, hadoop_group} = ctx.config.ryba
      secondary_namenode = ctx.host_with_module 'ryba/hadoop/hdfs_snn'
      return next() unless secondary_namenode
      ctx.write
        content: "#{secondary_namenode}"
        destination: "#{hadoop_conf_dir}/masters"
        uid: hdfs.user.name
        gid: hadoop_group.name
      .then next

## Layout

Create the DataNode data and pid directories. The data directory is set by the
"hdp.hdfs.site['dfs.datanode.data.dir']" and default to "/var/hdfs/data". The
pid directory is set by the "hdfs\_pid\_dir" and default to "/var/run/hadoop-hdfs"

    module.exports.push name: 'HDFS DN # Layout', timeout: -1, handler: (ctx, next) ->
      {hdfs, hadoop_group} = ctx.config.ryba
      # no need to restrict parent directory and yarn will complain if not accessible by everyone
      pid_dir = hdfs.secure_dn_pid_dir
      pid_dir = pid_dir.replace '$USER', hdfs.user.name
      pid_dir = pid_dir.replace '$HADOOP_SECURE_DN_USER', hdfs.user.name
      pid_dir = pid_dir.replace '$HADOOP_IDENT_STRING', hdfs.user.name
      # TODO, in HDP 2.1, datanode are started as root but in HDP 2.2, we should
      # start it as HDFS and use JAAS
      ctx
      .mkdir
        destination: hdfs.site['dfs.datanode.data.dir'].split ','
        uid: hdfs.user.name
        gid: hadoop_group.name
        mode: 0o0750
        parent: true
      .mkdir
        destination: "#{pid_dir}"
        uid: hdfs.user.name
        gid: hdfs.group.name # HDFS Group is forced by the system, hadoop_group can't be used
        mode: 0o0755
        parent: true
      .then next

## Kerberos

Create the DataNode service principal in the form of "dn/{host}@{realm}" and place its
keytab inside "/etc/security/keytabs/dn.service.keytab" with ownerships set to "hdfs:hadoop"
and permissions set to "0600".

    module.exports.push name: 'HDFS DN # Kerberos', timeout: -1, handler: (ctx, next) ->
      {hdfs, realm} = ctx.config.ryba
      {kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5.etc_krb5_conf.realms[realm]
      ctx.krb5_addprinc
        principal: "dn/#{ctx.config.host}@#{realm}"
        randkey: true
        keytab: "/etc/security/keytabs/dn.service.keytab"
        uid: hdfs.user.name
        gid: hdfs.group.name
        mode: 0o0600
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
      .then next

# Opts

Environment passed to the DataNode before it starts.

    module.exports.push name: 'HDFS DN # Opts', handler: (ctx, next) ->
      {hadoop_conf_dir, hdfs} = ctx.config.ryba
      # export HADOOP_SECURE_DN_PID_DIR="/var/run/hadoop/$HADOOP_SECURE_DN_USER" # RYBA CONF "ryba.hadoop_pid_dir", DONT OVEWRITE
      ctx.write
        destination: "#{hadoop_conf_dir}/hadoop-env.sh"
        write: [
          match: /^export HADOOP_SECURE_DN_PID_DIR=.*$/mg
          replace: "export HADOOP_SECURE_DN_PID_DIR=\"#{hdfs.secure_dn_pid_dir}\" # RYBA CONF \"ryba.hadoop_pid_dir\", DONT OVEWRITE"
        ,
          match: /^export HADOOP_SECURE_DN_USER=\${HADOOP_SECURE_DN_USER:-"(.*)"}.*/mg
          replace: "export HADOOP_SECURE_DN_USER=${HADOOP_SECURE_DN_USER:-\"#{hdfs.user.name}\"} # RYBA CONF \"ryba.hdfs.user.name\", DONT OVERWRITE"
        ,
          match: /^export HADOOP_DATANODE_OPTS="(.*) \$\{HADOOP_DATANODE_OPTS\}" # RYBA CONF ".*?", DONT OVERWRITE/mg
          replace: "export HADOOP_DATANODE_OPTS=\"#{hdfs.datanode_opts} ${HADOOP_DATANODE_OPTS}\" # RYBA CONF \"ryba.hdfs.datanode_opts\", DONT OVERWRITE"
          before: /^export HADOOP_DATANODE_OPTS=".*"$/mg
        ]
        backup: true
      .then next

# Kernel

Configure kernel parameters at runtime. A usefull resource is the Pivotal
presentation [Key Hadoop Cluster Configuration - OS (slide 15)][key_os] which
suggest:

*    vm.swappiness = 0
*    vm.overcommit_memory = 1
*    vm.overcommit_ratio = 100
*    net.core.somaxconn=1024 (default socket listen queue size 128)

Note, we might move this middleware to Masson.

    module.exports.push name: 'HDFS DN # Kernel', handler: (ctx, next) ->
      {hdfs} = ctx.config.ryba
      return next() unless Object.keys(hdfs.sysctl).length
      ctx.call (_, callback) ->
        ctx.execute
          cmd: 'sysctl -a'
          stdout: null
        , (err, _, content) ->
          return callback err if err
          content = misc.ini.parse content
          properties = {}
          for k, v of hdfs.sysctl
            v = "#{v}"
            properties[k] = v if content[k] isnt v
          return callback null, false unless Object.keys(properties).length
          writes = for k, v of properties
            match: ///^#{misc.regexp.escape k}?\s+=\s*.*?\s///mg
            replace: "#{k} = #{v}"
            append: true
          ctx.write
            destination: '/etc/sysctl.conf'
            write: writes
            backup: true
          , (err) ->
            return callback err if err
            properties = for k, v of properties then "#{k}=#{v}"
            properties = properties.join ' '
            ctx.execute
              cmd: "sysctl #{properties}"
            , callback
      .then next


## Module dependencies

    misc = require 'mecano/lib/misc'

[key_os]: http://fr.slideshare.net/vgogate/hadoop-configuration-performance-tuning
