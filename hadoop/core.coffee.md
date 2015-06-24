
# Hadoop Core

The [Hadoop distribution](http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.2.4/bk_getting-started-guide/content/ch_hdp1_getting_started_chp2_1.html) used is the Hortonwork distribution named HDP. The
installation is leveraging the Yum repositories. [Individual tarballs][tar]
are also available as an alternative with the benefit of including the source
code.


*   http://bigdataprocessing.wordpress.com/2013/07/30/hadoop-rack-awareness-and-configuration/
*   http://ofirm.wordpress.com/2014/01/09/exploring-the-hadoop-network-topology/

[tar]: http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.0.9.1/bk_installing_manually_book/content/rpm-chap13.html

    url = require 'url'
    path = require 'path'
    misc = require 'mecano/lib/misc'
    each = require 'each'

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/yum'
    # Install kerberos clients to create/test new HDFS and Yarn principals
    module.exports.push 'masson/core/krb5_client'
    module.exports.push 'masson/commons/java'
    module.exports.push 'ryba/lib/base'
    module.exports.push require '../lib/hconfigure'

## Configuration

*   `ryba.static_host` (boolean)
    Write the host name of the server instead of the Hadoop "_HOST"
    placeholder accross all the configuration files, default to false.
*   `hdfs.user` (object|string)
    The Unix HDFS login name or a user object (see Mecano User documentation).
*   `yarn.user` (object|string)
    The Unix YARN login name or a user object (see Mecano User documentation).
*   `mapred.user` (object|string)
    The Unix MapReduce login name or a user object (see Mecano User documentation).
*   `user` (object|string)
    The Unix Test user name or a user object (see Mecano User documentation).
*   `hadoop_group` (object|string)
    The Unix Hadoop group name or a group object (see Mecano Group documentation).
*   `hdfs.group` (object|string)
    The Unix HDFS group name or a group object (see Mecano Group documentation).
*   `yarn.group` (object|string)
    The Unix YARN group name or a group object (see Mecano Group documentation).
*   `mapred.group` (object|string)
    The Unix MapReduce group name or a group object (see Mecano Group documentation).
*   `group` (object|string)
    The Unix Test group name or a group object (see Mecano Group documentation).

Default configuration:

```json
{
  "ryba": {
    "user": {
      "name": "ryba", "system": true, "gid": "ryba",
      "comment": "ryba User", "home": "/home/ryba"
    },
    "group": {
      "name": "ryba", "system": true
    },
    "hdfs": {
      "user": {
        "name": "hdfs", "system": true, "gid": "hdfs",
        "comment": "HDFS User", "home": "/var/lib/hadoop-hdfs"
      },
      "group": {
        "name": "hdfs", "system": true
      }
    },
    "yarn: {
      "user": {
        "name": "yarn", "system": true, "gid": "yarn",
        "comment": "YARN User", "home": "/var/lib/hadoop-yarn"
      },
      "group": {
        "name": "yarn", "system": true
      }
    },
    "mapred": {
      "user": {
        "name": "mapred", "system": true, "gid": "mapred",
        "comment": "MapReduce User", "home": "/var/lib/hadoop-mapreduce"
      },
      "group": {
        "name": "mapred", "system": true
      }
    },
    "hadoop_group": {
      "name": "hadoop", "system": true
    }
  }
}
```

    module.exports.push module.exports.configure = (ctx) ->
      return if ctx.core_configured
      ctx.core_configured = true
      require('masson/commons/java').configure ctx
      require('masson/core/krb5_client').configure ctx
      require('../lib/base').configure ctx
      {realm} = ctx.config.ryba
      ryba = ctx.config.ryba ?= {}
      ryba.yarn ?= {}
      ryba.mapred ?= {}

## Configuration for users and groups

      # Group for hadoop
      ryba.hadoop_group = name: ryba.hadoop_group if typeof ryba.hadoop_group is 'string'
      ryba.hadoop_group ?= {}
      ryba.hadoop_group.name ?= 'hadoop'
      ryba.hadoop_group.system ?= true
      # Unix user hdfs
      ryba.hdfs.user ?= {}
      ryba.hdfs.user = name: ryba.hdfs.user if typeof ryba.hdfs.user is 'string'
      ryba.hdfs.user.name ?= 'hdfs'
      ryba.hdfs.user.system ?= true
      ryba.hdfs.user.gid ?= 'hdfs'
      ryba.hdfs.user.groups ?= 'hadoop'
      ryba.hdfs.user.comment ?= 'Hadoop HDFS User'
      ryba.hdfs.user.home ?= '/var/lib/hadoop-hdfs'
      # Kerberos user for hdfs
      ryba.hdfs.krb5_user ?= {}
      ryba.hdfs.krb5_user.principal ?= "#{ryba.hdfs.user.name}@#{realm}"
      ryba.hdfs.krb5_user.password ?= 'hdfs123'
      # Unix user for yarn
      ryba.yarn.user ?= {}
      ryba.yarn.user = name: ryba.yarn.user if typeof ryba.yarn.user is 'string'
      ryba.yarn.user.name ?= 'yarn'
      ryba.yarn.user.system ?= true
      ryba.yarn.user.gid ?= 'yarn'
      ryba.yarn.user.groups ?= 'hadoop'
      ryba.yarn.user.comment ?= 'Hadoop YARN User'
      ryba.yarn.user.home ?= '/var/lib/hadoop-yarn'
      # Unix user for mapred
      ryba.mapred.user ?= {}
      ryba.mapred.user = name: ryba.mapred.user if typeof ryba.mapred.user is 'string'
      ryba.mapred.user.name ?= 'mapred'
      ryba.mapred.user.system ?= true
      ryba.mapred.user.gid ?= 'mapred'
      ryba.mapred.user.groups ?= 'hadoop'
      ryba.mapred.user.comment ?= 'Hadoop MapReduce User'
      ryba.mapred.user.home ?= '/var/lib/hadoop-mapreduce'
      # Groups
      ryba.hdfs.group ?= {}
      ryba.hdfs.group = name: ryba.hdfs.group if typeof ryba.hdfs.group is 'string'
      ryba.hdfs.group.name ?= 'hdfs'
      ryba.hdfs.group.system ?= true
      ryba.yarn.group ?= {}
      ryba.yarn.group = name: ryba.yarn.group if typeof ryba.yarn.group is 'string'
      ryba.yarn.group.name ?= 'yarn'
      ryba.yarn.group.system ?= true
      ryba.mapred.group ?= {}
      ryba.mapred.group = name: ryba.mapred.group if typeof ryba.mapred.group is 'string'
      ryba.mapred.group.name ?= 'mapred'
      ryba.mapred.group.system ?= true
      ryba.group ?= {}
      ryba.group = name: ryba.group if typeof ryba.group is 'string'
      ryba.group.name ?= 'ryba'
      ryba.group.system ?= true
      # Layout
      ryba.hadoop_conf_dir ?= '/etc/hadoop/conf'
      ryba.hdfs.log_dir ?= '/var/log/hadoop-hdfs'
      ryba.hdfs.pid_dir ?= '/var/run/hadoop-hdfs'
      ryba.hdfs.secure_dn_pid_dir ?= '/var/run/hadoop-hdfs' # /$HADOOP_SECURE_DN_USER
      ryba.hdfs.secure_dn_user ?= ryba.hdfs.user.name
      # HA Configuration
      ryba.nameservice ?= null
      ryba.active_nn ?= false
      throw new Error "Invalid Service Name" unless ryba.nameservice
      namenodes = ctx.hosts_with_module 'ryba/hadoop/hdfs_nn'
      # throw new Error "Need at least 2 namenodes" if namenodes.length < 2
      # active_nn_hosts = ctx.config.servers.filter( (server) -> server.ryba?.active_nn ).map( (server) -> server.host )
      # standby_nn_hosts = ctx.config.servers.filter( (server) -> ! server.ryba?.active_nn ).map( (server) -> server.host )
      standby_nn_hosts = namenodes.filter( (server) -> ! ctx.config.servers[server].ryba?.active_nn )
      # throw new Error "Invalid Number of Passive NameNodes: #{standby_nn_hosts.length}" unless standby_nn_hosts.length is 1
      ryba.standby_nn_host = standby_nn_hosts[0]
      ryba.static_host =
        if ryba.static_host and ryba.static_host isnt '_HOST'
        then ctx.config.host
        else '_HOST'
      # Configuration
      core_site = ryba.core_site ?= {}
      core_site['io.compression.codecs'] ?= "org.apache.hadoop.io.compress.GzipCodec,org.apache.hadoop.io.compress.DefaultCodec,org.apache.hadoop.io.compress.SnappyCodec"
      unless ctx.hosts_with_module('ryba/hadoop/hdfs_nn').length > 1
        core_site['fs.defaultFS'] ?= "hdfs://#{namenodes[0]}:8020"
      else
        core_site['fs.defaultFS'] ?= "hdfs://#{ryba.nameservice}:8020"
        active_nn_hosts = namenodes.filter( (server) -> ctx.config.servers[server].ryba?.active_nn )
        throw new Error "Invalid Number of Active NameNodes: #{active_nn_hosts.length}" unless active_nn_hosts.length is 1
        ryba.active_nn_host = active_nn_hosts[0]
      core_site['net.topology.script.file.name'] ?= "#{ryba.hadoop_conf_dir}/rack_topology.sh"
      # Set the authentication for the cluster. Valid values are: simple or kerberos
      core_site['hadoop.security.authentication'] ?= 'kerberos'
      # Enable authorization for different protocols.
      core_site['hadoop.security.authorization'] ?= 'true'
      # A comma-separated list of protection values for secured sasl
      # connections. Possible values are authentication, integrity and privacy.
      # authentication means authentication only and no integrity or privacy;
      # integrity implies authentication and integrity are enabled; and privacy
      # implies all of authentication, integrity and privacy are enabled.
      # hadoop.security.saslproperties.resolver.class can be used to override
      # the hadoop.rpc.protection for a connection at the server side.
      core_site['hadoop.rpc.protection'] ?= 'authentication'
      # Get ZooKeeper Quorum
      zoo_ctxs = ctx.contexts 'ryba/zookeeper/server', require('../zookeeper/server').configure
      zookeeper_quorum = for zoo_ctx in zoo_ctxs
        "#{zoo_ctx.config.host}:#{zoo_ctx.config.ryba.zookeeper.port}"
      core_site['ha.zookeeper.quorum'] ?= zookeeper_quorum

Configuration for HTTP

      core_site['hadoop.http.filter.initializers'] ?= 'org.apache.hadoop.security.AuthenticationFilterInitializer'
      core_site['hadoop.http.authentication.type'] ?= 'kerberos'
      core_site['hadoop.http.authentication.token.validity'] ?= '36000'
      core_site['hadoop.http.authentication.signature.secret.file'] ?= '/etc/hadoop/hadoop-http-auth-signature-secret'
      core_site['hadoop.http.authentication.simple.anonymous.allowed'] ?= 'false'
      core_site['hadoop.http.authentication.kerberos.principal'] ?= "HTTP/#{ryba.static_host}@#{ryba.realm}"
      core_site['hadoop.http.authentication.kerberos.keytab'] ?= '/etc/security/keytabs/spnego.service.keytab'
      # Cluster domain
      unless core_site['hadoop.http.authentication.cookie.domain']
        domains = ctx.hosts_with_module('ryba/hadoop/core').map( (host) -> host.split('.').slice(1).join('.') ).filter( (el, pos, self) -> self.indexOf(el) is pos )
        throw Error "Multiple domains, set 'hadoop.http.authentication.cookie.domain' manually" if domains.length isnt 1
        core_site['hadoop.http.authentication.cookie.domain'] = domains[0]

Configuration for proxy users

      core_site['hadoop.security.auth_to_local'] ?= """

            RULE:[2:$1@$0]([rn]m@.*)s/.*/yarn/
            RULE:[2:$1@$0](jhs@.*)s/.*/mapred/
            RULE:[2:$1@$0]([nd]n@.*)s/.*/hdfs/
            RULE:[2:$1@$0](hm@.*)s/.*/hbase/
            RULE:[2:$1@$0](rs@.*)s/.*/hbase/
            DEFAULT

        """
      core_site['hadoop.proxyuser.hcat.hosts'] = null
      core_site['hadoop.proxyuser.hcat.groups'] = null
      core_site['hadoop.proxyuser.HTTP.hosts'] ?= '*'
      core_site['hadoop.proxyuser.HTTP.groups'] ?= '*'
      hbase_ctxs = ctx.contexts 'ryba/hbase/master', require('../hbase/master').configure
      if hbase_ctxs.length
        {hbase} = hbase_ctxs[0].config.ryba
        core_site["hadoop.proxyuser.#{hbase.user.name}.groups"] ?= '*'
        core_site["hadoop.proxyuser.#{hbase.user.name}.hosts"] ?= '*'
      hive_ctxs = ctx.contexts 'ryba/hive/hcatalog', require('../hive/hcatalog').configure
      if hive_ctxs.length
        {hive} = hive_ctxs[0].config.ryba
        core_site["hadoop.proxyuser.#{hive.user.name}.groups"] ?= '*'
        core_site["hadoop.proxyuser.#{hive.user.name}.hosts"] ?= '*'
      oozie_ctxs = ctx.contexts 'ryba/oozie/server', require('../oozie/server').configure
      if oozie_ctxs.length
        {oozie} = oozie_ctxs[0].config.ryba
        core_site["hadoop.proxyuser.#{oozie.user.name}.groups"] ?= '*'
        core_site["hadoop.proxyuser.#{oozie.user.name}.hosts"] ?= '*'
      hue_ctxs = ctx.contexts 'ryba/hue', require('../hue').configure_system
      if hue_ctxs.length
        {hue} = hue_ctxs[0].config.ryba
        core_site["hadoop.proxyuser.#{hue.user.name}.groups"] ?= '*'
        core_site["hadoop.proxyuser.#{hue.user.name}.hosts"] ?= '*'
        core_site['hue.kerberos.principal.shortname'] ?= hue.user.name
      falcon_ctxs = ctx.contexts 'ryba/falcon', require('../falcon').configure
      if falcon_ctxs.length
        {user} = falcon_ctxs[0].config.ryba.falcon
        core_site["hadoop.proxyuser.#{user.name}.groups"] ?= '*'
        core_site["hadoop.proxyuser.#{user.name}.hosts"] ?= '*'

Configuration for environment

      ryba.hadoop_opts ?= '-Djava.net.preferIPv4Stack=true'
      ryba.hadoop_heap ?= '1024'
      ryba.hadoop_namenode_init_heap ?= '-Xms1024m'
      # if Array.isArray ryba.hadoop_opts
      #   ryba.hadoop_opts = ryba.hadoop_opts.join ' '
      # if typeof ryba.hadoop_opts is 'object'
      #   hadoop_opts = ''
      #   for k, v of ryba.hadoop_opts
      #     hadoop_opts += "-D#{k}=#{v} "
      #   ryba.hadoop_opts = hadoop_opts
      # hadoop_opts = "export HADOOP_OPTS=\""
      # for k, v of ryba.hadoop_opts
      #   hadoop_opts += "-D#{k}=#{v} "
      # hadoop_opts += "${HADOOP_OPTS}\""
      # ryba.hadoop_opts = hadoop_opts
      ryba.hadoop_client_opts ?= '-Xmx2048m'
      # hadoop_client_opts = ryba.hadoop_client_opts ?= '-Xmx2048m'
      # ryba.hadoop_client_opts = "export HADOOP_CLIENT_OPTS=\"#{hadoop_client_opts} $HADOOP_CLIENT_OPTS\""
      # Options for "hadoop-policy.xml"
      # Note, according to the doc, it apply to the NameNode and JobTracker
      # where JobTracker shall be understood as RerouceManager
      ryba.hadoop_policy ?= {}

## Users & Groups

By default, the "hadoop-client" package rely on the "hadoop", "hadoop-hdfs",
"hadoop-mapreduce" and "hadoop-yarn" dependencies and create the following
entries:

```bash
cat /etc/passwd | grep hadoop
hdfs:x:496:497:Hadoop HDFS:/var/lib/hadoop-hdfs:/bin/bash
yarn:x:495:495:Hadoop Yarn:/var/lib/hadoop-yarn:/bin/bash
mapred:x:494:494:Hadoop MapReduce:/var/lib/hadoop-mapreduce:/bin/bash
cat /etc/group | egrep "hdfs|yarn|mapred"
hadoop:x:498:hdfs,yarn,mapred
hdfs:x:497:
yarn:x:495:
mapred:x:494:
```

Note, the package "hadoop" will also install the "dbus" user and group which are
not handled here.

    module.exports.push name: 'Hadoop Core # Users & Groups', handler: (ctx, next) ->
      {hadoop_group, hdfs, yarn, mapred} = ctx.config.ryba
      ctx
      .group [hadoop_group, hdfs.group, yarn.group, mapred.group]
      .user [hdfs.user, yarn.user, mapred.user]
      .then next

## Test User

Create a Unix and Kerberos test user, by default "ryba". Its HDFS home directory
will be created by one of the datanode.

    module.exports.push name: 'Hadoop Core # User Test', timeout: -1, handler: (ctx, next) ->
      {krb5_user, user, group, security, realm} = ctx.config.ryba
      {kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5.etc_krb5_conf.realms[realm]
      modified = false
      # ryba group and user may already exist in "/etc/passwd" or in any sssd backend
      ctx
      .group group
      .user user
      .krb5_addprinc
        principal: "#{krb5_user.name}@#{realm}"
        password: "#{krb5_user.password}"
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
      .then next

## Install

Install the "hadoop-client" and "openssl" packages as well as their
dependecies.

The environment script "hadoop-env.sh" from the HDP companion files is also
uploaded when the package is first installed or upgraded. Be careful, the
original file will be overwritten with and user modifications. A copy will be
made available in the same directory after any modification.

    module.exports.push name: 'Hadoop Core # Install', timeout: -1, handler: (ctx, next) ->
      ctx
      .service
        name: 'openssl'
      .service
        name: 'hadoop-client'
      .then next

## Env

Upload the "hadoop-env.sh" file present in the HDP companion File.

Note, this is wrong. Problem is that multiple module modify this file. We shall
instead enrich the original file installed by the package.

    module.exports.push name: 'Hadoop Core # Env', timeout: -1, handler: (ctx, next) ->
      {hadoop_conf_dir, hdfs, hadoop_group} = ctx.config.ryba
      ctx.fs.readFile "#{hadoop_conf_dir}/hadoop-env.sh", 'ascii', (err, content) ->
        return next null, false if /HDP/.test content
        ctx.upload
          source: "#{__dirname}/../resources/core_hadoop/hadoop-env.sh"
          local_source: true
          destination: "#{hadoop_conf_dir}/hadoop-env.sh"
          uid: hdfs.user.name
          gid: hadoop_group.name
          mode: 0o755
          backup: true
          eof: true
        .then next

## Configuration

Update the "core-site.xml" configuration file with properties from the
"ryba.core_site" configuration.

    module.exports.push name: 'Hadoop Core # Configuration', handler: (ctx, next) ->
      {core_site, hadoop_conf_dir} = ctx.config.ryba
      ctx.hconfigure
        destination: "#{hadoop_conf_dir}/core-site.xml"
        default: "#{__dirname}/../resources/core_hadoop/core-site.xml"
        local_default: true
        properties: core_site
        merge: true
        backup: true
      .then next

    module.exports.push name: 'Hadoop Core # Topology', handler: (ctx, next) ->
      {hdfs, hadoop_group, hadoop_conf_dir} = ctx.config.ryba
      h_ctxs = ctx.contexts modules: ['ryba/hadoop/hdfs_dn', 'ryba/hadoop/yarn_nm']
      topology = []
      for h_ctx in h_ctxs
        rack = if h_ctx.config.ryba?.rack? then h_ctx.config.ryba.rack else ''
        # topology.push "#{host}  #{rack}"
        topology.push "#{h_ctx.config.ip}  #{rack}"
      topology = topology.join("\n")
      ctx
      .upload
        destination: "#{hadoop_conf_dir}/rack_topology.sh"
        source: "#{__dirname}/../resources/rack_topology.sh"
        uid: hdfs.user.name
        gid: hadoop_group.name
        mode: 0o755
        backup: true
      .write
        destination: "#{hadoop_conf_dir}/rack_topology.data"
        content: topology
        uid: hdfs.user.name
        gid: hadoop_group.name
        mode: 0o755
        backup: true
        eof: true
      .then next

## Hadoop OPTS

Update the "/etc/hadoop/conf/hadoop-env.sh" file.

The location for JSVC depends on the platform. The Hortonworks documentation
mentions "/usr/libexec/bigtop-utils" for RHEL/CentOS/Oracle Linux. While this is
correct for RHEL, it is installed in "/usr/lib/bigtop-utils" on my CentOS.

    module.exports.push name: 'Hadoop Core # Hadoop OPTS', timeout: -1, handler: (ctx, next) ->
      {java_home} = ctx.config.java
      {hadoop_conf_dir, hdfs, hadoop_group, hadoop_opts, hadoop_client_opts, hadoop_namenode_init_heap, hadoop_heap} = ctx.config.ryba
      ctx.fs.exists '/usr/libexec/bigtop-utils', (err, exists) ->
        return next err if err
        jsvc = if exists then '/usr/libexec/bigtop-utils' else '/usr/lib/bigtop-utils'
        write = [
          match: /\/var\/log\/hadoop\//mg
          replace: "#{hdfs.log_dir}/"
        ,
          match: /^export JSVC_HOME=.*$/m
          replace: "export JSVC_HOME=#{jsvc}"
        ,
          match: /^export JAVA_HOME=.*$/m
          replace: "export JAVA_HOME=\"#{java_home}\" # RYBA CONF \"java.java_home\", DONT OVEWRITE"
        ,
          match: /^export HADOOP_PID_DIR=.*$/m
          replace: "export HADOOP_PID_DIR=\"#{hdfs.pid_dir}\" # RYBA CONF \"hdfs.pid_dir\", DONT OVEWRITE"
        ,
          match: /^export HADOOP_HEAPSIZE="(.*)".*$/m
          replace: "export HADOOP_HEAPSIZE=\"#{hadoop_heap}\" # RYBA CONF \"ryba.hadoop_heap\", DONT OVEWRITE"
          # match: /^export HADOOP_HEAPSIZE="(.*)" # RYBA CONF ".*?", DONT OVEWRITE/m
          # replace: "export HADOOP_HEAPSIZE=\"#{hadoop_heap}\" # RYBA CONF \"ryba.hadoop_heap\", DONT OVEWRITE"
          # append: /^export HADOOP_HEAPSIZE=".*"$/m
        ,
          match: /^export HADOOP_NAMENODE_INIT_HEAPSIZE=".*".*$/m
          replace: "export HADOOP_NAMENODE_INIT_HEAPSIZE=\"#{hadoop_namenode_init_heap}\" # RYBA CONF \"ryba.hadoop_namenode_init_heap\", DONT OVEWRITE"
        #   match: /^export HADOOP_NAMENODE_INIT_HEAPSIZE="(.*)" # RYBA CONF ".*?", DONT OVEWRITE/m
        #   replace: "export HADOOP_NAMENODE_INIT_HEAPSIZE=\"#{hadoop_namenode_init_heap}\" # RYBA CONF \"ryba.hadoop_namenode_init_heap\", DONT OVEWRITE"
        #   append: /^export HADOOP_NAMENODE_INIT_HEAPSIZE=".*"$/m
        ,
          match: /^export HADOOP_OPTS="(.*) \$\{HADOOP_OPTS\}" # RYBA CONF ".*?", DONT OVEWRITE/m
          replace: "export HADOOP_OPTS=\"#{hadoop_opts} ${HADOOP_OPTS}\" # RYBA CONF \"ryba.hadoop_opts\", DONT OVEWRITE"
          before: /^export HADOOP_OPTS=".*"$/m
        ,
          match: /^export HADOOP_CLIENT_OPTS="(.*) \$\{HADOOP_CLIENT_OPTS\}" # RYBA CONF ".*?", DONT OVEWRITE/m
          replace: "export HADOOP_CLIENT_OPTS=\"#{hadoop_client_opts} ${HADOOP_CLIENT_OPTS}\" # RYBA CONF \"ryba.hadoop_client_opts\", DONT OVEWRITE"
          before: /^export HADOOP_CLIENT_OPTS=".*"$/m
        ]
        if ctx.has_module 'ryba/xasecure/hdfs'
          write.push
            replace: '. /etc/hadoop/conf/xasecure-hadoop-env.sh'
            append: true
        ctx.write
          destination: "#{hadoop_conf_dir}/hadoop-env.sh"
          write: write
          backup: true
          eof: true
        .then next

## Policy

By default the service-level authorization is disabled in hadoop, to enable that
we need to set/configure the hadoop.security.authorization to true in
${HADOOP_CONF_DIR}/core-site.xml

    module.exports.push name: 'Hadoop Core # Policy', handler: (ctx, next) ->
      {core_site, hadoop_conf_dir, hadoop_policy} = ctx.config.ryba
      ctx.hconfigure
        destination: "#{hadoop_conf_dir}/hadoop-policy.xml"
        default: "#{__dirname}/../resources/core_hadoop/hadoop-policy.xml"
        local_default: true
        properties: hadoop_policy
        merge: true
        backup: true
        if: core_site['hadoop.security.authorization'] is 'true'
      .then (err, status) ->
        return next err, status if err or not status
        ctx.execute
          cmd: mkcmd.hdfs ctx, 'hdfs dfsadmin -refreshServiceAcl'
        .then (err) ->
          return next err, true

    # module.exports.push name: 'Hadoop Core # Environnment', timeout: -1, handler: (ctx, next) ->
    #   ctx.write
    #     destination: '/etc/profile.d/hadoop.sh'
    #     content: """
    #     #!/bin/bash
    #     export HADOOP_HOME=/usr/lib/hadoop
    #     """
    #     mode: 0o0644
    #   , next

    module.exports.push name: 'Hadoop Core # Keytabs', timeout: -1, handler: (ctx, next) ->
      {hadoop_group} = ctx.config.ryba
      ctx.mkdir
        destination: '/etc/security/keytabs'
        uid: 'root'
        gid: hadoop_group.name
        mode: 0o0755
      .then next

    module.exports.push name: 'Hadoop Core # Compression', timeout: -1, handler: (ctx, next) ->
      { hadoop_conf_dir } = ctx.config.ryba
      modified = false
      do_snappy = ->
        ctx.service [
          name: 'snappy'
        ,
          name: 'snappy-devel'
        ], (err, serviced) ->
          return next err if err
          return do_lzo() unless serviced
          ctx.execute
            cmd: 'ln -sf /usr/lib64/libsnappy.so /usr/lib/hadoop/lib/native/.'
          , (err) ->
            return next err if err
            modified = true
            do_lzo()
      do_lzo = ->
        ctx
        .service
          name: 'lzo'
        .service
          name: 'lzo-devel'
        .service
          name: 'hadoop-lzo'
        .service
          name: 'hadoop-lzo-native'
        .then (err, serviced) ->
          return next err if err
          modified = true if serviced
          do_end()
      do_end = ->
        next null, modified
      do_snappy()

## Web UI

This action follow the ["Authentication for Hadoop HTTP web-consoles"
recommendations](http://hadoop.apache.org/docs/r1.2.1/HttpAuthentication.html).

    module.exports.push name: 'Hadoop Core # Web UI', handler: (ctx, next) ->
      {core_site, realm} = ctx.config.ryba
      ctx.execute
        cmd: 'dd if=/dev/urandom of=/etc/hadoop/hadoop-http-auth-signature-secret bs=1024 count=1'
        not_if_exists: '/etc/hadoop/hadoop-http-auth-signature-secret'
      .then next

    module.exports.push 'ryba/hadoop/core_ssl'

    module.exports.push name: 'Hadoop Core # Jars', handler: (ctx, next) ->
      {core_jars} = ctx.config.ryba
      core_jars = Object.keys(core_jars).map (k) -> core_jars[k]
      remote_files = null
      ctx
      .call ({}, callback) ->
        ctx.fs.readdir '/usr/hdp/current/hadoop-hdfs-datanode/lib', (err, files) ->
          remote_files = files unless err
          callback err
      .call ({}, callback) ->
        remove_files = []
        core_jars = for jar in core_jars
          filtered_files = multimatch remote_files, jar.match
          remove_files.push (filtered_files.filter (file) -> file isnt jar.filename)...
          continue if jar.filename in remote_files
          jar
        # Remove jar if already uploaded
        for file in remove_files
          @remove destination: path.join '/usr/hdp/current/hadoop-hdfs-datanode/lib', file
        for jar in core_jars
          @upload
            source: jar.source
            destination: path.join '/usr/hdp/current/hadoop-hdfs-client/lib', "#{jar.filename}"
            binary: true
          @upload
            source: jar.source
            destination: path.join '/usr/hdp/current/hadoop-yarn-client/lib', "#{jar.filename}"
            binary: true
        @then callback
      ctx.then next

## Dependencies

    fs = require 'ssh2-fs'
    path = require 'path'
    multimatch = require 'multimatch'
    mkcmd = require '../lib/mkcmd'
