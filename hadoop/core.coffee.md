
# Hadoop Core

The Hadoop distribution used is the Hortonwork distribution named HDP. The
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
*   `test_user` (object|string)   
    The Unix Test user name or a user object (see Mecano User documentation).   
*   `hadoop_group` (object|string)   
    The Unix Hadoop group name or a group object (see Mecano Group documentation).   
*   `hdfs.group` (object|string)   
    The Unix HDFS group name or a group object (see Mecano Group documentation).   
*   `yarn.group` (object|string)   
    The Unix YARN group name or a group object (see Mecano Group documentation).   
*   `mapred.group` (object|string)   
    The Unix MapReduce group name or a group object (see Mecano Group documentation).   
*   `test_group` (object|string)   
    The Unix Test group name or a group object (see Mecano Group documentation).   

Default configuration:

```json
{
  "ryba": {
    "hdfs": {
      user": {
        "name": "hdfs", "system": true, "gid": "hdfs",
        "comment": "HDFS User", "home": "/var/lib/hadoop-hdfs"
      },
      group": {
      "name": "hdfs", "system": true
      }
    },
    "yarn: {
      user": {
        "name": "yarn", "system": true, "gid": "yarn",
        "comment": "YARN User", "home": "/var/lib/hadoop-yarn"
      },
      group": {
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
    "test_user": {
      "name": "ryba", "system": true, "gid": "ryba",
      "comment": "ryba User", "home": "/home/ryba"
    },
    "hadoop_group": {
      "name": "hadoop", "system": true
    },
    "test_group": {
      "name": "ryba", "system": true
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
      # User
      ctx.config.ryba.hdfs.user ?= {}
      ctx.config.ryba.hdfs.user = name: ctx.config.ryba.hdfs.user if typeof ctx.config.ryba.hdfs.user is 'string'
      ctx.config.ryba.hdfs.user.name ?= 'hdfs'
      ctx.config.ryba.hdfs.user.system ?= true
      ctx.config.ryba.hdfs.user.gid ?= 'hdfs'
      ctx.config.ryba.hdfs.user.groups ?= 'hadoop'
      ctx.config.ryba.hdfs.user.comment ?= 'Hadoop HDFS User'
      ctx.config.ryba.hdfs.user.home ?= '/var/lib/hadoop-hdfs'
      
      ctx.config.ryba.hdfs.krb5_user ?= {}
      ctx.config.ryba.hdfs.krb5_user.name ?= ctx.config.ryba.hdfs.user.name
      ctx.config.ryba.hdfs.krb5_user.password ?= 'hdfs123'
      ctx.config.ryba.yarn ?= {}
      ctx.config.ryba.yarn.user ?= {}
      ctx.config.ryba.yarn.user = name: ctx.config.ryba.yarn.user if typeof ctx.config.ryba.yarn.user is 'string'
      ctx.config.ryba.yarn.user.name ?= 'yarn'
      ctx.config.ryba.yarn.user.system ?= true
      ctx.config.ryba.yarn.user.gid ?= 'yarn'
      ctx.config.ryba.yarn.user.groups ?= 'hadoop'
      ctx.config.ryba.yarn.user.comment ?= 'Hadoop YARN User'
      ctx.config.ryba.yarn.user.home ?= '/var/lib/hadoop-yarn'
      
      ctx.config.ryba.mapred ?= {}
      ctx.config.ryba.mapred.user ?= {}
      ctx.config.ryba.mapred.user = name: ctx.config.ryba.mapred.user if typeof ctx.config.ryba.mapred.user is 'string'
      ctx.config.ryba.mapred.user.name ?= 'mapred'
      ctx.config.ryba.mapred.user.system ?= true
      ctx.config.ryba.mapred.user.gid ?= 'mapred'
      ctx.config.ryba.mapred.user.groups ?= 'hadoop'
      ctx.config.ryba.mapred.user.comment ?= 'Hadoop MapReduce User'
      ctx.config.ryba.mapred.user.home ?= '/var/lib/hadoop-mapreduce'
      # Groups
      ctx.config.ryba.hadoop_group = name: ctx.config.ryba.hadoop_group if typeof ctx.config.ryba.hadoop_group is 'string'
      ctx.config.ryba.hadoop_group ?= {}
      ctx.config.ryba.hadoop_group.name ?= 'hadoop'
      ctx.config.ryba.hadoop_group.system ?= true
      ctx.config.ryba.hdfs.group ?= {}
      ctx.config.ryba.hdfs.group = name: ctx.config.ryba.hdfs.group if typeof ctx.config.ryba.hdfs.group is 'string'
      ctx.config.ryba.hdfs.group.name ?= 'hdfs'
      ctx.config.ryba.hdfs.group.system ?= true
      ctx.config.ryba.yarn.group ?= {}
      ctx.config.ryba.yarn.group = name: ctx.config.ryba.yarn.group if typeof ctx.config.ryba.yarn.group is 'string'
      ctx.config.ryba.yarn.group.name ?= 'yarn'
      ctx.config.ryba.yarn.group.system ?= true
      ctx.config.ryba.mapred.group ?= {}
      ctx.config.ryba.mapred.group = name: ctx.config.ryba.mapred.group if typeof ctx.config.ryba.mapred.group is 'string'
      ctx.config.ryba.mapred.group.name ?= 'mapred'
      ctx.config.ryba.mapred.group.system ?= true
      ctx.config.ryba.test_group = name: ctx.config.ryba.test_group if typeof ctx.config.ryba.test_group is 'string'
      ctx.config.ryba.test_group ?= {}
      ctx.config.ryba.test_group.name ?= 'ryba'
      ctx.config.ryba.test_group.system ?= true
      # Layout
      ctx.config.ryba.hadoop_conf_dir ?= '/etc/hadoop/conf'
      ctx.config.ryba.hdfs.log_dir ?= '/var/log/hadoop-hdfs'
      ctx.config.ryba.hdfs.pid_dir ?= '/var/run/hadoop-hdfs'
      ctx.config.ryba.mapred.log_dir ?= '/var/log/hadoop-mapreduce' # required by hadoop-env.sh
      # HA Configuration
      ctx.config.ryba.nameservice ?= null
      ctx.config.ryba.active_nn ?= false
      throw new Error "Invalid Service Name" unless ctx.config.ryba.nameservice
      namenodes = ctx.hosts_with_module 'ryba/hadoop/hdfs_nn'
      # throw new Error "Need at least 2 namenodes" if namenodes.length < 2
      # active_nn_hosts = ctx.config.servers.filter( (server) -> server.ryba?.active_nn ).map( (server) -> server.host )
      # standby_nn_hosts = ctx.config.servers.filter( (server) -> ! server.ryba?.active_nn ).map( (server) -> server.host )
      standby_nn_hosts = namenodes.filter( (server) -> ! ctx.config.servers[server].ryba?.active_nn )
      # throw new Error "Invalid Number of Passive NameNodes: #{standby_nn_hosts.length}" unless standby_nn_hosts.length is 1
      ctx.config.ryba.standby_nn_host = standby_nn_hosts[0]
      ctx.config.ryba.static_host = 
        if ctx.config.ryba.static_host and ctx.config.ryba.static_host isnt '_HOST'
        then ctx.config.host
        else '_HOST'
      # Configuration
      core_site = ctx.config.ryba.core_site ?= {}
      unless ctx.hosts_with_module('ryba/hadoop/hdfs_nn').length > 1
        core_site['fs.defaultFS'] ?= "hdfs://#{namenodes[0]}:8020"
      else
        core_site['fs.defaultFS'] ?= "hdfs://#{ctx.config.ryba.nameservice}:8020"
        active_nn_hosts = namenodes.filter( (server) -> ctx.config.servers[server].ryba?.active_nn )
        throw new Error "Invalid Number of Active NameNodes: #{active_nn_hosts.length}" unless active_nn_hosts.length is 1
        ctx.config.ryba.active_nn_host = active_nn_hosts[0]
      core_site['net.topology.script.file.name'] ?= "#{ctx.config.ryba.hadoop_conf_dir}/rack_topology.sh"
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
      # Proxy users
      falcon_cts = ctx.contexts 'ryba/falcon', require('../falcon').configure
      if falcon_cts.length
        {user} = falcon_cts[0].config.ryba.falcon
        core_site["hadoop.proxyuser.#{user.name}.groups"] = '*'
        core_site["hadoop.proxyuser.#{user.name}.hosts"] = '*'
      # Environment
      ctx.config.ryba.hadoop_opts ?= 'java.net.preferIPv4Stack': 'true'
      hadoop_opts = "export HADOOP_OPTS=\""
      for k, v of ctx.config.ryba.hadoop_opts
        hadoop_opts += "-D#{k}=#{v} "
      hadoop_opts += "${HADOOP_OPTS}\""
      ctx.config.ryba.hadoop_opts = hadoop_opts
      hadoop_client_opts = ctx.config.ryba.hadoop_client_opts ?= '-Xmx2048m'
      ctx.config.ryba.hadoop_client_opts = "export HADOOP_CLIENT_OPTS=\"#{hadoop_client_opts} $HADOOP_CLIENT_OPTS\""

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

    module.exports.push name: 'Hadoop Core # Users & Groups', callback: (ctx, next) ->
      {hadoop_group, hdfs, yarn, mapred} = ctx.config.ryba
      ctx.group [hadoop_group, hdfs.group, yarn.group, mapred.group], (err, gmodified) ->
        return next err if err
        ctx.user [hdfs.user, yarn.user, mapred.user], (err, umodified) ->
          next err, gmodified or umodified

## Test User

Create a Unix and Kerberos test user, by default "ryba". Its HDFS home directory
will be created by one of the datanode.

    module.exports.push name: 'Hadoop HDFS DN # HDFS Layout User Test', timeout: -1, callback: (ctx, next) ->
      {test_group, test_user, test_password, security, realm} = ctx.config.ryba
      {kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5.etc_krb5_conf.realms[realm]
      modified = false
      # ryba group and user may already exist in "/etc/passwd" or in any sssd backend
      ctx.group test_group, (err, gmodified) ->
        return next err if err
        ctx.user test_user, (err, umodified) ->
          return next err if err
          ctx.krb5_addprinc
            principal: "#{test_user.name}@#{realm}"
            password: "#{test_password}"
            kadmin_principal: kadmin_principal
            kadmin_password: kadmin_password
            kadmin_server: admin_server
          , (err, pmodified) ->
            next err, gmodified or umodified or pmodified

## Install

Install the "hadoop-client" and "openssl" packages as well as their
dependecies.   

The environment script "hadoop-env.sh" from the HDP companion files is also
uploaded when the package is first installed or upgraded. Be careful, the
original file will be overwritten with and user modifications. A copy will be
made available in the same directory after any modification.

    module.exports.push name: 'Hadoop Core # Install', timeout: -1, callback: (ctx, next) ->
      ctx.service [
        name: 'openssl'
      ,
        name: 'hadoop-client'
      ], next

## Env

Upload the "hadoop-env.sh" file present in the HDP companion File.

Note, this is wrong. Problem is that multiple module modify this file. We shall
instead enrich the original file installed by the package.

    module.exports.push name: 'Hadoop Core # Env', timeout: -1, callback: (ctx, next) ->
      {hadoop_conf_dir, hdfs, hadoop_group} = ctx.config.ryba
      ctx.fs.readFile "#{hadoop_conf_dir}/hadoop-env.sh", 'ascii', (err, content) ->
        return next null, false if /HDP/.test content
        ctx.upload
          source: "#{__dirname}/../resources/core_hadoop/hadoop-env.sh"
          destination: "#{hadoop_conf_dir}/hadoop-env.sh"
          local_source: true
          uid: hdfs.user.name
          gid: hadoop_group.name
          mode: 0o755
          backup: true
          eof: true
        , next

## Configuration

Update the "core-site.xml" configuration file with properties from the
"ryba.core_site" configuration.   

    module.exports.push name: 'Hadoop Core # Configuration', callback: (ctx, next) ->
      {core_site, hadoop_conf_dir} = ctx.config.ryba
      ctx.hconfigure
        destination: "#{hadoop_conf_dir}/core-site.xml"
        default: "#{__dirname}/../resources/core_hadoop/core-site.xml"
        local_default: true
        properties: core_site
        merge: true
        backup: true
      , next

    module.exports.push name: 'Hadoop Core # Topology', callback: (ctx, next) ->
      {hdfs, hadoop_group, hadoop_conf_dir} = ctx.config.ryba
      ctx.upload
        destination: "#{hadoop_conf_dir}/rack_topology.sh"
        source: "#{__dirname}/../resources/rack_topology.sh"
        uid: hdfs.user.name
        gid: hadoop_group.name
        mode: 0o755
        backup: true
      , (err, uploaded) ->
        return next err if err
        hosts = ctx.hosts_with_module 'ryba/hadoop/hdfs_dn', 'ryba/hadoop/yarn_nm'
        content = []
        for host in hosts
          {config} = ctx.hosts[host]
          rack = if config.ryba?.rack? then config.ryba.rack else ''
          content.push "#{host}  #{rack}"
          content.push "#{config.ip}  #{rack}"
        ctx.write
          destination: "#{hadoop_conf_dir}/rack_topology.data"
          content: content.join("\n")
          uid: hdfs.user.name
          gid: hadoop_group.name
          mode: 0o755
          backup: true
          eof: true
        , (err, written) ->
          next err, uploaded or written

## Hadoop OPTS

Update the "/etc/hadoop/conf/hadoop-env.sh" file.

The location for JSVC depends on the platform. The Hortonworks documentation
mentions "/usr/libexec/bigtop-utils" for RHEL/CentOS/Oracle Linux. While this is
correct for RHEL, it is installed in "/usr/lib/bigtop-utils" on my CentOS.

    module.exports.push name: 'Hadoop Core # Hadoop OPTS', timeout: -1, callback: (ctx, next) ->
      {java_home} = ctx.config.java
      {hadoop_conf_dir, hdfs, hadoop_group, hadoop_opts, hadoop_client_opts} = ctx.config.ryba
      ctx.fs.exists '/usr/libexec/bigtop-utils', (err, exists) ->
        return next err if err
        jsvc = if exists then '/usr/libexec/bigtop-utils' else '/usr/lib/bigtop-utils'
        write = [
          { match: /^export JAVA_HOME=.*$/mg, replace: "export JAVA_HOME=#{java_home}" }
          { match: /^export HADOOP_OPTS=.*$/mg, replace: hadoop_opts }
          { match: /\/var\/log\/hadoop\//mg, replace: "#{hdfs.log_dir}/" }
          { match: /\/var\/run\/hadoop\//mg, replace: "#{hdfs.pid_dir}/" }
          { match: /^export JSVC_HOME=.*$/mg, replace: "export JSVC_HOME=#{jsvc}" }
          { match: /^export HADOOP_CLIENT_OPTS=.*$/mg, replace: hadoop_client_opts}
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
        , next

    module.exports.push name: 'Hadoop Core # Environnment', timeout: -1, callback: (ctx, next) ->
      ctx.write
        destination: '/etc/profile.d/hadoop.sh'
        content: """
        #!/bin/bash
        export HADOOP_HOME=/usr/lib/hadoop
        """
        mode: 0o0644
      , next

    module.exports.push name: 'Hadoop Core # Keytabs', timeout: -1, callback: (ctx, next) ->
      {hadoop_group} = ctx.config.ryba
      ctx.mkdir
        destination: '/etc/security/keytabs'
        uid: 'root'
        gid: hadoop_group.name
        mode: 0o0755
      , next

    module.exports.push name: 'Hadoop Core # Compression', timeout: -1, callback: (ctx, next) ->
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
          , (err, executed) ->
            return next err if err
            modified = true
            do_lzo()
      do_lzo = ->
        ctx.service [
          name: 'lzo'
        ,
          name: 'lzo-devel'
        ,
          name: 'hadoop-lzo'
        ,
          name: 'hadoop-lzo-native'
        ], (err, serviced) ->
          return next err if err
          modified = true if serviced
          do_core()
      do_core = ->
        core_site = {}
        core_site['io.compression.codecs'] ?= "org.apache.hadoop.io.compress.GzipCodec,org.apache.hadoop.io.compress.DefaultCodec,org.apache.hadoop.io.compress.SnappyCodec"
        ctx.hconfigure
          destination: "#{hadoop_conf_dir}/core-site.xml"
          properties: core_site
          merge: true
          backup: true
        , (err, configured) ->
          return next err if err
          modified = true if configured
          do_end()
      do_end = ->
        next null, modified
      do_snappy()

    module.exports.push name: 'Hadoop Core # Kerberos', timeout: -1, callback: (ctx, next) ->
      {hadoop_conf_dir, core_site, realm} = ctx.config.ryba
      # TODO, discover and generate cross-realm settings
      core_site['hadoop.security.auth_to_local'] ?= """
      
            RULE:[2:$1@$0]([rn]m@.*)s/.*/yarn/
            RULE:[2:$1@$0](jhs@.*)s/.*/mapred/
            RULE:[2:$1@$0]([nd]n@.*)s/.*/hdfs/
            RULE:[2:$1@$0](hm@.*)s/.*/hbase/
            RULE:[2:$1@$0](rs@.*)s/.*/hbase/
            DEFAULT

        """
      # Allow the superuser hive to impersonate any members of the group users. Required only when installing Hive.
      core_site['hadoop.proxyuser.hive.groups'] ?= '*'
      # Hostname from where superuser hive can connect. Required 
      # only when installing Hive.
      core_site['hadoop.proxyuser.hive.hosts'] ?= '*'
      # Allow the superuser oozie to impersonate any members of 
      # the group users. Required only when installing Oozie.
      core_site['hadoop.proxyuser.oozie.groups'] ?= '*'
      # Hostname from where superuser oozie can connect. Required 
      # only when installing Oozie.
      core_site['hadoop.proxyuser.oozie.hosts'] ?= '*'
      # Hostname from where superuser hcat can connect. Required 
      # only when installing WebHCat.
      core_site['hadoop.proxyuser.hcat.hosts'] ?= '*'
      # Hostname from where superuser HTTP can connect.
      core_site['hadoop.proxyuser.HTTP.groups'] ?= '*'
      # Allow the superuser hcat to impersonate any members of the 
      # group users. Required only when installing WebHCat.
      core_site['hadoop.proxyuser.hcat.groups'] ?= '*'
      # Hostname from where superuser hcat can connect. This is 
      # required only when installing webhcat on the cluster.
      core_site['hadoop.proxyuser.hcat.hosts'] ?= '*'
      core_site['hadoop.proxyuser.hue.groups'] ?= '*'
      core_site['hadoop.proxyuser.hue.hosts'] ?= '*'
      core_site['hadoop.proxyuser.hbase.groups'] ?= '*'
      core_site['hadoop.proxyuser.hbase.hosts'] ?= '*'
      core_site['hadoop.proxyuser.HTTP.hosts'] = '*'
      core_site['hadoop.proxyuser.HTTP.groups'] ?= '*'
      # Todo, find a better place for this one
      # http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.3.2/bk_installing_manually_book/content/rpm-chap14-2-3-hue.html
      core_site['hue.kerberos.principal.shortname'] ?= 'hue'
      ctx.hconfigure
        destination: "#{hadoop_conf_dir}/core-site.xml"
        properties: core_site
        merge: true
        backup: true
      , next

Configure Web
-------------

This action follow the ["Authentication for Hadoop HTTP web-consoles" 
recommandations](http://hadoop.apache.org/docs/r1.2.1/HttpAuthentication.html).

    module.exports.push name: 'Hadoop Core # Kerberos Web UI', callback: (ctx, next) ->
      {core_site, realm} = ctx.config.ryba
      # Cluster domain
      unless core_site['hadoop.http.authentication.cookie.domain']
        domains = ctx.hosts_with_module('ryba/hadoop/core').map( (host) -> host.split('.').slice(1).join('.') ).filter( (el, pos, self) -> self.indexOf(el) is pos )
        return next new Error "Multiple domains, set 'hadoop.http.authentication.cookie.domain' manually" if domains.length isnt 1
        core_site['hadoop.http.authentication.cookie.domain'] = domains[0]
      ctx.execute
        cmd: 'dd if=/dev/urandom of=/etc/hadoop/hadoop-http-auth-signature-secret bs=1024 count=1'
        not_if_exists: '/etc/hadoop/hadoop-http-auth-signature-secret'
      , (err, executed) ->
        return next err if err
        ctx.hconfigure
          destination: '/etc/hadoop/conf/core-site.xml'
          properties:
            'hadoop.http.filter.initializers': 'org.apache.hadoop.security.AuthenticationFilterInitializer'
            'hadoop.http.authentication.type': 'kerberos'
            'hadoop.http.authentication.token.validity': 36000
            'hadoop.http.authentication.signature.secret.file': '/etc/hadoop/hadoop-http-auth-signature-secret'
            'hadoop.http.authentication.cookie.domain': core_site['hadoop.http.authentication.cookie.domain']
            'hadoop.http.authentication.simple.anonymous.allowed': 'false'
            # For some reason, _HOST isnt leveraged
            # TODO, this is now fix in HDP-1.3.9
            'hadoop.http.authentication.kerberos.principal': "HTTP/#{ctx.config.host}@#{realm}"
            'hadoop.http.authentication.kerberos.keytab': '/etc/security/keytabs/spnego.service.keytab'
          merge: true
          backup: true
        , next

    module.exports.push 'ryba/hadoop/core_ssl'

    module.exports.push name: 'Hadoop Core # Check auth_to_local', label_true: 'CHECKED', callback: (ctx, next) ->
      {test_user, realm} = ctx.config.ryba
      ctx.execute
        cmd: "hadoop org.apache.hadoop.security.HadoopKerberosName #{test_user.name}@#{realm}"
      , (err, _, stdout) ->
        err = Error "Invalid mapping" if not err and stdout.indexOf("#{test_user.name}@#{realm} to #{test_user.name}") is -1
        next err, true










