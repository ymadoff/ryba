
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
    # module.exports.push require('./index').configure
    module.exports.push 'ryba/lib/hconfigure'
    # module.exports.push require '../../lib/hdp_service'
    module.exports.push 'ryba/lib/hdp_select'

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

    module.exports.push header: 'HDFS DN # IPTables', handler: ->
      {hdfs} = @config.ryba
      [_, dn_address] = hdfs.site['dfs.datanode.address'].split ':'
      [_, dn_http_address] = hdfs.site['dfs.datanode.http.address'].split ':'
      [_, dn_https_address] = hdfs.site['dfs.datanode.https.address'].split ':'
      [_, dn_ipc_address] = hdfs.site['dfs.datanode.ipc.address'].split ':'
      @iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: dn_address, protocol: 'tcp', state: 'NEW', comment: "HDFS DN Data" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: dn_http_address, protocol: 'tcp', state: 'NEW', comment: "HDFS DN HTTP" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: dn_https_address, protocol: 'tcp', state: 'NEW', comment: "HDFS DN HTTPS" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: dn_ipc_address, protocol: 'tcp', state: 'NEW', comment: "HDFS DN Meta" }
        ]
        if: @config.iptables.action is 'start'

## Service

Install the "hadoop-hdfs-datanode" service, symlink the rc.d startup script
inside "/etc/init.d" and activate it on startup.

    module.exports.push header: 'HDFS DN # Service', timeout: -1, handler: ->
      @service
        name: 'hadoop-hdfs-datanode'
      @hdp_select
        name: 'hadoop-hdfs-client' # Not checked
        name: 'hadoop-hdfs-datanode'
      @render
        destination: '/etc/init.d/hadoop-hdfs-datanode'
        source: "#{__dirname}/../resources/hadoop-hdfs-datanode"
        local_source: true
        context: @config
        mode: 0o0755
        unlink: true
      @execute
        cmd: "service hadoop-hdfs-datanode restart"
        if: -> @status -3

## Layout

Create the DataNode data and pid directories. The data directory is set by the
"hdp.hdfs.site['dfs.datanode.data.dir']" and default to "/var/hdfs/data". The
pid directory is set by the "hdfs\_pid\_dir" and default to "/var/run/hadoop-hdfs"

    module.exports.push header: 'HDFS DN # Layout', timeout: -1, handler: ->
      {hdfs, hadoop_group} = @config.ryba
      # no need to restrict parent directory and yarn will complain if not accessible by everyone
      pid_dir = hdfs.secure_dn_pid_dir
      pid_dir = pid_dir.replace '$USER', hdfs.user.name
      pid_dir = pid_dir.replace '$HADOOP_SECURE_DN_USER', hdfs.user.name
      pid_dir = pid_dir.replace '$HADOOP_IDENT_STRING', hdfs.user.name
      # TODO, in HDP 2.1, datanode are started as root but in HDP 2.2, we should
      # start it as HDFS and use JAAS
      @mkdir
        destination: "#{hdfs.dn.conf_dir}"
      @mkdir
        destination: for dir in hdfs.site['dfs.datanode.data.dir'].split ','
          if dir.indexOf('file://') is 0
          then dir.substr(7) else dir
        uid: hdfs.user.name
        gid: hadoop_group.name
        mode: 0o0750
        parent: true
      @mkdir
        destination: "#{pid_dir}"
        uid: hdfs.user.name
        gid: hadoop_group.name
        mode: 0o0755
        parent: true
      @mkdir
        destination: "#{hdfs.log_dir}" #/#{hdfs.user.name}
        uid: hdfs.user.name
        gid: hdfs.group.name
        parent: true

## Configure

    module.exports.push header: 'HDFS DN', handler: ->
      {core_site, hdfs, hadoop_group, hadoop_metrics} = @config.ryba

## Core Site

Update the "core-site.xml" configuration file with properties from the
"ryba.core_site" configuration.

      @hconfigure
        header: 'Core Site'
        destination: "#{hdfs.dn.conf_dir}/core-site.xml"
        default: "#{__dirname}/../../resources/core_hadoop/core-site.xml"
        local_default: true
        properties: core_site
        backup: true

## HDFS Site

Update the "hdfs-site.xml" configuration file with the High Availabity properties
present inside the "hdp.ha\_client\_config" object.

      @hconfigure
        header: 'HDFS Site'
        destination: "#{hdfs.dn.conf_dir}/hdfs-site.xml"
        default: "#{__dirname}/../../resources/core_hadoop/hdfs-site.xml"
        local_default: true
        properties: hdfs.site
        uid: hdfs.user.name
        gid: hadoop_group.name
        backup: true

## Environment

Maintain the "hadoop-env.sh" file present in the HDP companion File.

The location for JSVC depends on the platform. The Hortonworks documentation
mentions "/usr/libexec/bigtop-utils" for RHEL/CentOS/Oracle Linux. While this is
correct for RHEL, it is installed in "/usr/lib/bigtop-utils" on my CentOS.
      
      @render
        header: 'Environment'
        destination: "#{hdfs.dn.conf_dir}/hadoop-env.sh"
        source: "#{__dirname}/../resources/hadoop-env.sh"
        local_source: true
        context: @config
        uid: hdfs.user.name
        gid: hadoop_group.name
        mode: 0o755
        backup: true
        eof: true

## Log4j

      @write
        header: 'Log4j'
        destination: "#{hdfs.dn.conf_dir}/log4j.properties"
        source: "#{__dirname}/../resources/log4j.properties"
        local_source: true

## Hadoop Metrics

Configure the "hadoop-metrics2.properties" to connect Hadoop to a Metrics collector like Ganglia or Graphite.

      @write_properties
        header: 'Metrics'
        destination: "#{hdfs.dn.conf_dir}/hadoop-metrics2.properties"
        content: hadoop_metrics.config
        backup: true

# Configure Master

Accoring to [Yahoo!](http://developer.yahoo.com/hadoop/tutorial/module7.html):
The conf/masters file contains the hostname of the
SecondaryNameNode. This should be changed from "localhost"
to the fully-qualified domain name of the node to run the
SecondaryNameNode service. It does not need to contain
the hostname of the JobTracker/NameNode machine;
Also some [interesting info about snn](http://blog.cloudera.com/blog/2009/02/multi-host-secondarynamenode-configuration/)

      @write
        header: 'SNN Master'
        if: (-> @host_with_module 'ryba/hadoop/hdfs_snn')
        content: "#{@host_with_module 'ryba/hadoop/hdfs_snn'}"
        destination: "#{hdfs.dn.conf_dir}/masters"
        uid: hdfs.user.name
        gid: hadoop_group.name

## SSL

    module.exports.push header: 'HDFS DN # SSL', retry: 0, handler: ->
      {ssl, ssl_server, ssl_client, hdfs} = @config.ryba
      ssl_client['ssl.client.truststore.location'] = "#{hdfs.dn.conf_dir}/truststore"
      ssl_server['ssl.server.keystore.location'] = "#{hdfs.dn.conf_dir}/keystore"
      ssl_server['ssl.server.truststore.location'] = "#{hdfs.dn.conf_dir}/truststore"
      @hconfigure
        destination: "#{hdfs.dn.conf_dir}/ssl-server.xml"
        properties: ssl_server
      @hconfigure
        destination: "#{hdfs.dn.conf_dir}/ssl-client.xml"
        properties: ssl_client
      # Client: import certificate to all hosts
      @java_keystore_add
        keystore: ssl_client['ssl.client.truststore.location']
        storepass: ssl_client['ssl.client.truststore.password']
        caname: "hadoop_root_ca"
        cacert: "#{ssl.cacert}"
        local_source: true
      # Server: import certificates, private and public keys to hosts with a server
      @java_keystore_add
        keystore: ssl_server['ssl.server.keystore.location']
        storepass: ssl_server['ssl.server.keystore.password']
        caname: "hadoop_root_ca"
        cacert: "#{ssl.cacert}"
        key: "#{ssl.key}"
        cert: "#{ssl.cert}"
        keypass: ssl_server['ssl.server.keystore.keypassword']
        name: @config.shortname
        local_source: true
      @java_keystore_add
        keystore: ssl_server['ssl.server.keystore.location']
        storepass: ssl_server['ssl.server.keystore.password']
        caname: "hadoop_root_ca"
        cacert: "#{ssl.cacert}"
        local_source: true

## Kerberos

Create the DataNode service principal in the form of "dn/{host}@{realm}" and place its
keytab inside "/etc/security/keytabs/dn.service.keytab" with ownerships set to "hdfs:hadoop"
and permissions set to "0600".

    module.exports.push header: 'HDFS DN # Kerberos', timeout: -1, handler: ->
      {hdfs, realm} = @config.ryba
      {kadmin_principal, kadmin_password, admin_server} = @config.krb5.etc_krb5_conf.realms[realm]
      @krb5_addprinc
        principal: "dn/#{@config.host}@#{realm}"
        randkey: true
        keytab: "/etc/security/keytabs/dn.service.keytab"
        uid: hdfs.user.name
        gid: hdfs.group.name
        mode: 0o0600
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server

# Kernel

Configure kernel parameters at runtime. A usefull resource is the Pivotal
presentation [Key Hadoop Cluster Configuration - OS (slide 15)][key_os] which
suggest:

*    vm.swappiness = 0
*    vm.overcommit_memory = 1
*    vm.overcommit_ratio = 100
*    net.core.somaxconn=1024 (default socket listen queue size 128)

Note, we might move this middleware to Masson.

    module.exports.push header: 'HDFS DN # Kernel', handler: (_, next) ->
      {hdfs} = @config.ryba
      return next() unless Object.keys(hdfs.sysctl).length
      @execute
        cmd: 'sysctl -a'
        stdout: null
      , (err, _, content) ->
        throw err if err
        content = misc.ini.parse content
        properties = {}
        for k, v of hdfs.sysctl
          v = "#{v}"
          properties[k] = v if content[k] isnt v
        return next null, false unless Object.keys(properties).length
        @write
          destination: '/etc/sysctl.conf'
          write: for k, v of properties
            match: ///^#{misc.regexp.escape k}?\s+=\s*.*?\s///mg
            replace: "#{k} = #{v}"
            append: true
          backup: true
          eof: true
        , (err) ->
          throw err if err
          properties = for k, v of properties then "#{k}=#{v}"
          properties = properties.join ' '
          @execute
            cmd: "sysctl #{properties}"
          , next

## Ulimit

Increase ulimit for the HFDS user. The HDP package create the following
files:

```bash
cat /etc/security/limits.d/hdfs.conf
hdfs   - nofile 32768
hdfs   - nproc  65536
```

The procedure follows [Kate Ting's recommandations][kate]. This is a cause
of error if you receive the message: 'Exception in thread "main" java.lang.OutOfMemoryError: unable to create new native thread'.

Also worth of interest are the [Pivotal recommandations][hawq] as well as the
[Greenplum recommandation from Nixus Technologies][greenplum], the
[MapR documentation][mapr] and [Hadoop Performance via Linux presentation][hpl].

Note, a user must re-login for those changes to be taken into account.

    module.exports.push header: 'HDFS DN # Ulimit', handler: ->
      {hdfs} = @config.ryba
      @system_limits
        user: hdfs.user.name
        nofile: hdfs.user.limits.nofile
        nproc: hdfs.user.limits.nproc


## Dependencies

    misc = require 'mecano/lib/misc'

[key_os]: http://fr.slideshare.net/vgogate/hadoop-configuration-performance-tuning
