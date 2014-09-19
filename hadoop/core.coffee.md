---
title: 
layout: module
---

# Core

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
    hconfigure = require '../lib/hconfigure'

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/core/yum'
    # Install kerberos clients to create/test new HDFS and Yarn principals
    module.exports.push 'masson/core/krb5_client'
    module.exports.push 'masson/commons/java'

## Configuration

*   `ryba.static_host` (boolean)   
    Write the host name of the server instead of the Hadoop "_HOST" 
    placeholder accross all the configuration files, default to false.   
*   `hdfs_user` (object|string)   
    The Unix HDFS login name or a user object (see Mecano User documentation).   
*   `yarn_user` (object|string)   
    The Unix YARN login name or a user object (see Mecano User documentation).   
*   `mapred_user` (object|string)   
    The Unix MapReduce login name or a user object (see Mecano User documentation).   
*   `test_user` (object|string)   
    The Unix Test user name or a user object (see Mecano User documentation).   
*   `hadoop_group` (object|string)   
    The Unix Hadoop group name or a group object (see Mecano Group documentation).   
*   `hdfs_group` (object|string)   
    The Unix HDFS group name or a group object (see Mecano Group documentation).   
*   `yarn_group` (object|string)   
    The Unix YARN group name or a group object (see Mecano Group documentation).   
*   `mapred_group` (object|string)   
    The Unix MapReduce group name or a group object (see Mecano Group documentation).   
*   `test_group` (object|string)   
    The Unix Test group name or a group object (see Mecano Group documentation).   

Default configuration:

```json
{
  "ryba": {
    "hdfs_user": {
      "name": "hdfs", "system": true, "gid": "hdfs",
      "comment": "HDFS User", "home": "/var/lib/hadoop-hdfs"
    },
    "yarn_user": {
      "name": "yarn", "system": true, "gid": "yarn",
      "comment": "YARN User", "home": "/var/lib/hadoop-yarn"
    },
    "mapred_user": {
      "name": "mapred", "system": true, "gid": "mapred",
      "comment": "MapReduce User", "home": "/var/lib/hadoop-mapreduce"
    },
    "test_user": {
      "name": "ryba", "system": true, "gid": "ryba",
      "comment": "ryba User", "home": "/home/ryba"
    },
    "hadoop_group": {
      "name": "hadoop", "system": true
    },
    "hdfs_group": {
      "name": "hdfs", "system": true
    },
    "yarn_group": {
      "name": "yarn", "system": true
    },
    "mapred_group": {
      "name": "mapred", "system": true
    },
    "test_group": {
      "name": "ryba", "system": true
    }
  }
}
```

    module.exports.push retry: 0, callback: module.exports.configure = (ctx) ->
      return if ctx.core_configured
      ctx.core_configured = true
      require('masson/core/proxy').configure ctx
      require('masson/commons/java').configure ctx
      require('../zookeeper/server').configure ctx
      # require('./core_ssl').configure ctx
      ctx.config.ryba ?= {}
      ctx.config.ryba.format ?= false
      ctx.config.ryba.force_check ?= false
      # User
      ctx.config.ryba.hdfs_user = name: ctx.config.ryba.hdfs_user if typeof ctx.config.ryba.hdfs_user is 'string'
      ctx.config.ryba.hdfs_user ?= {}
      ctx.config.ryba.hdfs_user.name ?= 'hdfs'
      ctx.config.ryba.hdfs_user.system ?= true
      ctx.config.ryba.hdfs_user.gid ?= 'hdfs'
      ctx.config.ryba.hdfs_user.groups ?= 'hadoop'
      ctx.config.ryba.hdfs_user.comment ?= 'Hadoop HDFS User'
      ctx.config.ryba.hdfs_user.home ?= '/var/lib/hadoop-hdfs'
      ctx.config.ryba.yarn_user = name: ctx.config.ryba.yarn_user if typeof ctx.config.ryba.yarn_user is 'string'
      ctx.config.ryba.yarn_user ?= {}
      ctx.config.ryba.yarn_user.name ?= 'yarn'
      ctx.config.ryba.yarn_user.system ?= true
      ctx.config.ryba.yarn_user.gid ?= 'yarn'
      ctx.config.ryba.yarn_user.groups ?= 'hadoop'
      ctx.config.ryba.yarn_user.comment ?= 'Hadoop YARN User'
      ctx.config.ryba.yarn_user.home ?= '/var/lib/hadoop-yarn'
      ctx.config.ryba.mapred_user = name: ctx.config.ryba.mapred_user if typeof ctx.config.ryba.mapred_user is 'string'
      ctx.config.ryba.mapred_user ?= {}
      ctx.config.ryba.mapred_user.name ?= 'mapred'
      ctx.config.ryba.mapred_user.system ?= true
      ctx.config.ryba.mapred_user.gid ?= 'mapred'
      ctx.config.ryba.mapred_user.groups ?= 'hadoop'
      ctx.config.ryba.mapred_user.comment ?= 'Hadoop MapReduce User'
      ctx.config.ryba.mapred_user.home ?= '/var/lib/hadoop-mapreduce'
      ctx.config.ryba.test_user = name: ctx.config.ryba.test_user if typeof ctx.config.ryba.test_user is 'string'
      ctx.config.ryba.test_user ?= {}
      ctx.config.ryba.test_user.name ?= 'ryba'
      ctx.config.ryba.test_user.system ?= true
      ctx.config.ryba.test_user.gid ?= 'ryba'
      ctx.config.ryba.test_user.comment ?= 'ryba User'
      ctx.config.ryba.test_user.home ?= '/home/ryba'
      # Groups
      ctx.config.ryba.hadoop_group = name: ctx.config.ryba.hadoop_group if typeof ctx.config.ryba.hadoop_group is 'string'
      ctx.config.ryba.hadoop_group ?= {}
      ctx.config.ryba.hadoop_group.name ?= 'hadoop'
      ctx.config.ryba.hadoop_group.system ?= true
      ctx.config.ryba.hdfs_group = name: ctx.config.ryba.hdfs_group if typeof ctx.config.ryba.hdfs_group is 'string'
      ctx.config.ryba.hdfs_group ?= {}
      ctx.config.ryba.hdfs_group.name ?= 'hdfs'
      ctx.config.ryba.hdfs_group.system ?= true
      ctx.config.ryba.yarn_group = name: ctx.config.ryba.yarn_group if typeof ctx.config.ryba.yarn_group is 'string'
      ctx.config.ryba.yarn_group ?= {}
      ctx.config.ryba.yarn_group.name ?= 'yarn'
      ctx.config.ryba.yarn_group.system ?= true
      ctx.config.ryba.mapred_group = name: ctx.config.ryba.mapred_group if typeof ctx.config.ryba.mapred_group is 'string'
      ctx.config.ryba.mapred_group ?= {}
      ctx.config.ryba.mapred_group.name ?= 'mapred'
      ctx.config.ryba.mapred_group.system ?= true
      ctx.config.ryba.test_group = name: ctx.config.ryba.test_group if typeof ctx.config.ryba.test_group is 'string'
      ctx.config.ryba.test_group ?= {}
      ctx.config.ryba.test_group.name ?= 'ryba'
      ctx.config.ryba.test_group.system ?= true
      # Layout
      hadoop_conf_dir = ctx.config.ryba.hadoop_conf_dir ?= '/etc/hadoop/conf'
      ctx.config.ryba.hdfs_log_dir ?= '/var/log/hadoop-hdfs'
      ctx.config.ryba.hdfs_pid_dir ?= '/var/run/hadoop-hdfs'
      ctx.config.ryba.mapred_log_dir ?= '/var/log/hadoop-mapreduce' # required by hadoop-env.sh
      # Repository
      ctx.config.ryba.proxy = ctx.config.proxy.http_proxy if typeof ctx.config.ryba.http_proxy is 'undefined'
      ctx.config.ryba.hdp_repo ?= 'http://public-repo-1.hortonworks.com/HDP/centos5/2.x/GA/2.1-latest/hdp.repo'
      # HA Configuration
      ctx.config.ryba.nameservice ?= null
      ctx.config.ryba.active_nn ?= false
      throw new Error "Invalid Service Name" unless ctx.config.ryba.nameservice
      namenodes = ctx.hosts_with_module 'ryba/hadoop/hdfs_nn'
      throw new Error "Need at least 2 namenodes" if namenodes.length < 2
      # active_nn_hosts = ctx.config.servers.filter( (server) -> server.ryba?.active_nn ).map( (server) -> server.host )
      active_nn_hosts = namenodes.filter( (server) -> ctx.config.servers[server].ryba?.active_nn )
      throw new Error "Invalid Number of Active NameNodes: #{active_nn_hosts.length}" unless active_nn_hosts.length is 1
      ctx.config.ryba.active_nn_host = active_nn_hosts[0]
      # standby_nn_hosts = ctx.config.servers.filter( (server) -> ! server.ryba?.active_nn ).map( (server) -> server.host )
      standby_nn_hosts = namenodes.filter( (server) -> ! ctx.config.servers[server].ryba?.active_nn )
      throw new Error "Invalid Number of Passive NameNodes: #{standby_nn_hosts.length}" unless standby_nn_hosts.length is 1
      ctx.config.ryba.standby_nn_host = standby_nn_hosts[0]
      ctx.config.ryba.static_host = 
        if ctx.config.ryba.static_host and ctx.config.ryba.static_host isnt '_HOST'
        then ctx.config.host
        else '_HOST'
      # Configuration
      core_site = ctx.config.ryba.core_site ?= {}
      core_site['fs.defaultFS'] ?= "hdfs://#{ctx.config.ryba.nameservice}:8020"
      core_site['net.topology.script.file.name'] ?= "#{hadoop_conf_dir}/rack_topology.sh"
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
      # Context
      ctx.hconfigure = (options, callback) ->
        options = [options] unless Array.isArray options
        for opt in options
          opt.ssh = ctx.ssh if typeof opt.ssh is 'undefined'
          opt.log ?= ctx.log
          opt.stdout ?= ctx.stdout
          opt.stderr ?= ctx.stderr
        hconfigure options, callback
      # Environment
      ctx.config.ryba.hadoop_opts ?= 'java.net.preferIPv4Stack': 'true'
      hadoop_opts = "export HADOOP_OPTS=\""
      for k, v of ctx.config.ryba.hadoop_opts
        hadoop_opts += "-D#{k}=#{v} "
      hadoop_opts += "${HADOOP_OPTS}\""
      ctx.config.ryba.hadoop_opts = hadoop_opts
      hadoop_client_opts = ctx.config.ryba.hadoop_client_opts ?= '-Xmx2048m'
      ctx.config.ryba.hadoop_client_opts = "export HADOOP_CLIENT_OPTS=\"#{hadoop_client_opts} $HADOOP_CLIENT_OPTS\""
      # Database administration
      # todo: `require('masson/commons/mysql_server').configure ctx` and use returned values as default values
      ctx.config.ryba.db_admin ?= {}
      ctx.config.ryba.db_admin.engine ?= 'mysql'
      switch ctx.config.ryba.db_admin.engine
        when 'mysql'
          unless ctx.config.ryba.db_admin.host
            mysql_hosts = ctx.hosts_with_module 'masson/commons/mysql_server'
            throw new Error "Expect at least one server with action \"masson/commons/mysql_server\"" if mysql_hosts.length is 0
            mysql_host = ctx.config.ryba.db_admin.host = if mysql_hosts.length is 1 then mysql_hosts[0] else
              i = mysql_hosts.indexOf(ctx.config.host)
              if i isnt -1 then mysql_hosts[i] else throw new Error "Failed to find a Mysql Server"
            mysql_conf = ctx.hosts[mysql_host].config.mysql_server
          ctx.config.ryba.db_admin.path ?= 'mysql'
          ctx.config.ryba.db_admin.port ?= '3306'
          ctx.config.ryba.db_admin.username ?= 'root'
          ctx.config.ryba.db_admin.password ?= mysql_conf.password
        else throw new Error "Database engine not supported: #{ctx.config.ryba.engine}"

Repository
----------
Declare the HDP repository.

    module.exports.push name: 'HDP Core # Repository', timeout: -1, callback: (ctx, next) ->
      {proxy, hdp_repo} = ctx.config.ryba
      # Is there a repo to download and install
      return next null, ctx.INAPPLICABLE unless hdp_repo
      modified = false
      do_repo = ->
        ctx.log "Download #{hdp_repo} to /etc/yum.repos.d/hdp.repo"
        u = url.parse hdp_repo
        ctx[if u.protocol is 'http:' then 'download' else 'upload']
          source: hdp_repo
          destination: '/etc/yum.repos.d/hdp.repo'
          proxy: proxy
        , (err, downloaded) ->
          return next err if err
          return next null, ctx.PASS unless downloaded
          do_update()
      do_update = ->
          ctx.log 'Clean up metadata and update'
          ctx.execute
            cmd: "yum clean metadata; yum update -y"
          , (err, executed) ->
            # next err, ctx.OK
            return next err if err
            do_keys()
      do_keys = ->
        ctx.log 'Upload PGP keys'
        ctx.fs.readFile "/etc/yum.repos.d/hdp.repo", (err, content) ->
          return next err if err
          keys = {}
          reg = /^pgkey=(.*)/gm
          while matches = reg.exec content
            keys[matches[1]] = true
          keys = Object.keys keys
          return next() unless keys.length
          each(keys)
          .on 'item', (key, next) ->
            ctx.execute
              cmd: """
              curl #{key} -o /etc/pki/rpm-gpg/#{path.basename key}
              rpm --import  /etc/pki/rpm-gpg/#{path.basename key}
              """
            , (err, executed) ->
              next err
          .on 'both', (err) ->
            next err, ctx.OK
      do_repo()

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

    module.exports.push name: 'HDP Core # Users & Groups', callback: (ctx, next) ->
      {hadoop_group, hdfs_group, yarn_group, mapred_group,
       hdfs_user, yarn_user, mapred_user} = ctx.config.ryba
      ctx.group [hadoop_group, hdfs_group, yarn_group, mapred_group], (err, gmodified) ->
        return next err if err
        ctx.user [hdfs_user, yarn_user, mapred_user], (err, umodified) ->
          next err, if gmodified or umodified then ctx.OK else ctx.PASS

    module.exports.push name: 'HDP Core # Install', timeout: -1, callback: (ctx, next) ->
      ctx.service [
        name: 'openssl'
      ,
        name: 'hadoop-client'
      ], (err, serviced) ->
        next err, if serviced then ctx.OK else ctx.PASS

    module.exports.push name: 'HDP Core # Configuration', callback: (ctx, next) ->
      {core_site, hadoop_conf_dir} = ctx.config.ryba
      ctx.hconfigure
        destination: "#{hadoop_conf_dir}/core-site.xml"
        default: "#{__dirname}/files/core_hadoop/core-site.xml"
        local_default: true
        properties: core_site
        merge: true
        backup: true
      , (err, configured) ->
        next err, if configured then ctx.OK else ctx.PASS

    module.exports.push name: 'HDP Core # Topology', callback: (ctx, next) ->
      {hdfs_user, hadoop_group, hadoop_conf_dir} = ctx.config.ryba
      # return next() unless ctx.has_any_modules 'ryba/hadoop/hdfs_nn', 'ryba/hadoop/yarn_rm', 'ryba/hadoop/hdfs_dn', 'ryba/hadoop/yarn_nm'
      ctx.upload
        destination: "#{hadoop_conf_dir}/rack_topology.sh"
        source: "#{__dirname}/files/rack_topology.sh"
        uid: hdfs_user.name
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
          uid: hdfs_user.name
          gid: hadoop_group.name
          mode: 0o755
          backup: true
          eof: true
        , (err, written) ->
          next err, if uploaded or written then ctx.OK else ctx.PASS

## Hadoop OPTS

Update the "/etc/hadoop/conf/hadoop-env.sh" file.

The location for JSVC depends on the platform. The Hortonworks documentation
mentions "/usr/libexec/bigtop-utils" for RHEL/CentOS/Oracle Linux. While this is
correct for RHEL, it is installed in "/usr/lib/bigtop-utils" on my CentOS.

    module.exports.push name: 'HDP Core # Hadoop OPTS', timeout: -1, callback: (ctx, next) ->
      {java_home} = ctx.config.java
      {hadoop_conf_dir, hdfs_user, hadoop_group, hadoop_opts, hadoop_client_opts, hdfs_log_dir, hdfs_pid_dir} = ctx.config.ryba
      ctx.fs.exists '/usr/libexec/bigtop-utils', (err, exists) ->
        return next err if err
        jsvc = if exists then '/usr/libexec/bigtop-utils' else '/usr/lib/bigtop-utils'
        write = [
          { match: /^export JAVA_HOME=.*$/mg, replace: "export JAVA_HOME=#{java_home}" }
          { match: /^export HADOOP_OPTS=.*$/mg, replace: hadoop_opts }
          { match: /\/var\/log\/hadoop\//mg, replace: "#{hdfs_log_dir}/" }
          { match: /\/var\/run\/hadoop\//mg, replace: "#{hdfs_pid_dir}/" }
          { match: /^export JSVC_HOME=.*$/mg, replace: "export JSVC_HOME=#{jsvc}" }
          { match: /^export HADOOP_CLIENT_OPTS=.*$/mg, replace: hadoop_client_opts}
        ]
        if ctx.has_module 'ryba/xasecure/hdfs'
          write.push
            replace: '. /etc/hadoop/conf/xasecure-hadoop-env.sh'
            append: true
        ctx.write
          source: "#{__dirname}/files/core_hadoop/hadoop-env.sh"
          destination: "#{hadoop_conf_dir}/hadoop-env.sh"
          local_source: true
          write: write
          uid: hdfs_user.name
          gid: hadoop_group.name
          mode: 0o755
          backup: true
          eof: true
        , (err, written) ->
          next err, if written then ctx.OK else ctx.PASS

    module.exports.push name: 'HDP Core # Environnment', timeout: -1, callback: (ctx, next) ->
      ctx.write
        destination: '/etc/profile.d/hadoop.sh'
        content: """
        #!/bin/bash
        export HADOOP_HOME=/usr/lib/hadoop
        """
        mode: '644'
      , (err, written) ->
        next null, if written then ctx.OK else ctx.PASS

    module.exports.push name: 'HDP Core # Keytabs', timeout: -1, callback: (ctx, next) ->
      {hadoop_group} = ctx.config.ryba
      ctx.mkdir
        destination: '/etc/security/keytabs'
        uid: 'root'
        gid: hadoop_group.name
        mode: 0o0755
      , (err, created) ->
        next null, if created then ctx.OK else ctx.PASS

    module.exports.push name: 'HDP Core # Compression', timeout: -1, callback: (ctx, next) ->
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
        ctx.log 'Configure core-site.xml'
        core_site = {}
        core_site['io.compression.codecs'] ?= "org.apache.hadoop.io.compress.GzipCodec,org.apache.hadoop.io.compress.DefaultCodec,org.apache.hadoop.io.compress.SnappyCodec"
        ctx.hconfigure
          destination: "#{hadoop_conf_dir}/core-site.xml"
          properties: core_site
          merge: true
        , (err, configured) ->
          return next err if err
          modified = true if configured
          do_end()
      do_end = ->
        next null, if modified then ctx.OK else ctx.PASS
      do_snappy()

    module.exports.push name: 'HDP Core # Kerberos', timeout: -1, callback: (ctx, next) ->
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
      , (err, configured) ->
        next err, if configured then ctx.OK else ctx.PASS

Configure Web
-------------

This action follow the ["Authentication for Hadoop HTTP web-consoles" 
recommandations](http://hadoop.apache.org/docs/r1.2.1/HttpAuthentication.html).

    module.exports.push name: 'HDP Core # Kerberos Web UI', callback: (ctx, next) ->
      {core_site, realm} = ctx.config.ryba
      # Cluster domain
      unless core_site['hadoop.http.authentication.cookie.domain']
        domains = Object.keys(ctx.config.servers).map( (host) -> host.split('.').slice(1).join('.') ).filter( (el, pos, self) -> self.indexOf(el) is pos )
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
            'hadoop.http.authentication.kerberos.principal': "HTTP/#{ctx.config.host}@#{realm}"
            'hadoop.http.authentication.kerberos.keytab': '/etc/security/keytabs/spnego.service.keytab'
          merge: true
        , (err, configured) ->
          next err, if configured then ctx.OK else ctx.PASS

    module.exports.push 'ryba/hadoop/core_ssl'

    module.exports.push name: 'HDP Core # Check auth_to_local', callback: (ctx, next) ->
      {test_user, realm} = ctx.config.ryba
      ctx.execute
        cmd: "hadoop org.apache.hadoop.security.HadoopKerberosName #{test_user.name}@#{realm}"
      , (err, _, stdout) ->
        err = Error "Invalid mapping" if not err and stdout.indexOf("#{test_user.name}@#{realm} to #{test_user.name}") is -1
        next err, ctx.PASS










