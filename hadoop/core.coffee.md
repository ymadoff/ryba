---
title: 
layout: module
---

# Core

The Hadoop distribution used is the Hortonwork distribution named HDP. The
installation is leveraging the Yum repositories. [Individual tarballs][tar] 
are also available as an alternative with the benefit of including the source 
code.

[tar]: http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.0.9.1/bk_installing_manually_book/content/rpm-chap13.html

    url = require 'url'
    path = require 'path'
    misc = require 'mecano/lib/misc'
    each = require 'each'
    hconfigure = require './lib/hconfigure'

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/core/yum'
    # Install kerberos clients to create/test new HDFS and Yarn principals
    module.exports.push 'masson/core/krb5_client'
    module.exports.push 'masson/commons/java'

## Configuration

*   `hdp.static_host` (boolean)   
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
  "hdp": {
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
      "name": "phyla", "system": true, "gid": "phyla",
      "comment": "Phyla User", "home": "/home/phyla"
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
      "name": "phyla", "system": true
    }
  }
}
```

    module.exports.push module.exports.configure = (ctx) ->
      return if ctx.core_configured
      ctx.core_configured = true
      require('masson/core/proxy').configure ctx
      ctx.config.hdp ?= {}
      ctx.config.hdp.format ?= false
      ctx.config.hdp.force_check ?= false
      # User
      ctx.config.hdp.hdfs_user = name: ctx.config.hdp.hdfs_user if typeof ctx.config.hdp.hdfs_user is 'string'
      ctx.config.hdp.hdfs_user ?= {}
      ctx.config.hdp.hdfs_user.name ?= 'hdfs'
      ctx.config.hdp.hdfs_user.system ?= true
      ctx.config.hdp.hdfs_user.gid ?= 'hdfs'
      ctx.config.hdp.hdfs_user.groups ?= 'hadoop'
      ctx.config.hdp.hdfs_user.comment ?= 'Hadoop HDFS User'
      ctx.config.hdp.hdfs_user.home ?= '/var/lib/hadoop-hdfs'
      ctx.config.hdp.yarn_user = name: ctx.config.hdp.yarn_user if typeof ctx.config.hdp.yarn_user is 'string'
      ctx.config.hdp.yarn_user ?= {}
      ctx.config.hdp.yarn_user.name ?= 'yarn'
      ctx.config.hdp.yarn_user.system ?= true
      ctx.config.hdp.yarn_user.gid ?= 'yarn'
      ctx.config.hdp.yarn_user.groups ?= 'hadoop'
      ctx.config.hdp.yarn_user.comment ?= 'Hadoop YARN User'
      ctx.config.hdp.yarn_user.home ?= '/var/lib/hadoop-yarn'
      ctx.config.hdp.mapred_user = name: ctx.config.hdp.mapred_user if typeof ctx.config.hdp.mapred_user is 'string'
      ctx.config.hdp.mapred_user ?= {}
      ctx.config.hdp.mapred_user.name ?= 'mapred'
      ctx.config.hdp.mapred_user.system ?= true
      ctx.config.hdp.mapred_user.gid ?= 'mapred'
      ctx.config.hdp.mapred_user.groups ?= 'hadoop'
      ctx.config.hdp.mapred_user.comment ?= 'Hadoop MapReduce User'
      ctx.config.hdp.mapred_user.home ?= '/var/lib/hadoop-mapreduce'
      ctx.config.hdp.test_user = name: ctx.config.hdp.test_user if typeof ctx.config.hdp.test_user is 'string'
      ctx.config.hdp.test_user ?= {}
      ctx.config.hdp.test_user.name ?= 'phyla'
      ctx.config.hdp.test_user.system ?= true
      ctx.config.hdp.test_user.gid ?= 'phyla'
      ctx.config.hdp.test_user.comment ?= 'Phyla User'
      ctx.config.hdp.test_user.home ?= '/home/phyla'
      # Groups
      ctx.config.hdp.hadoop_group = name: ctx.config.hdp.hadoop_group if typeof ctx.config.hdp.hadoop_group is 'string'
      ctx.config.hdp.hadoop_group ?= {}
      ctx.config.hdp.hadoop_group.name ?= 'hadoop'
      ctx.config.hdp.hadoop_group.system ?= true
      ctx.config.hdp.hdfs_group = name: ctx.config.hdp.hdfs_group if typeof ctx.config.hdp.hdfs_group is 'string'
      ctx.config.hdp.hdfs_group ?= {}
      ctx.config.hdp.hdfs_group.name ?= 'hdfs'
      ctx.config.hdp.hdfs_group.system ?= true
      ctx.config.hdp.yarn_group = name: ctx.config.hdp.yarn_group if typeof ctx.config.hdp.yarn_group is 'string'
      ctx.config.hdp.yarn_group ?= {}
      ctx.config.hdp.yarn_group.name ?= 'yarn'
      ctx.config.hdp.yarn_group.system ?= true
      ctx.config.hdp.mapred_group = name: ctx.config.hdp.mapred_group if typeof ctx.config.hdp.mapred_group is 'string'
      ctx.config.hdp.mapred_group ?= {}
      ctx.config.hdp.mapred_group.name ?= 'mapred'
      ctx.config.hdp.mapred_group.system ?= true
      ctx.config.hdp.test_group = name: ctx.config.hdp.test_group if typeof ctx.config.hdp.test_group is 'string'
      ctx.config.hdp.test_group ?= {}
      ctx.config.hdp.test_group.name ?= 'phyla'
      ctx.config.hdp.test_group.system ?= true
      # Layout
      ctx.config.hdp.hadoop_conf_dir ?= '/etc/hadoop/conf'
      ctx.config.hdp.hdfs_log_dir ?= '/var/log/hadoop-hdfs'
      ctx.config.hdp.hdfs_pid_dir ?= '/var/run/hadoop-hdfs'
      ctx.config.hdp.mapred_log_dir ?= '/var/log/hadoop-mapreduce' # required by hadoop-env.sh
      # Repository
      ctx.config.hdp.proxy = ctx.config.proxy.http_proxy if typeof ctx.config.hdp.http_proxy is 'undefined'
      ctx.config.hdp.hdp_repo ?= 'http://public-repo-1.hortonworks.com/HDP/centos5/2.x/GA/2.1-latest/hdp.repo'
      # HA Configuration
      ctx.config.hdp.nameservice ?= null
      throw new Error "Invalid Service Name" unless ctx.config.hdp.nameservice
      namenodes = ctx.hosts_with_module 'phyla/hadoop/hdfs_nn'
      throw new Error "Need at least 2 namenodes" if namenodes.length < 2
      ctx.config.hdp.active_nn ?= false
      active_nn_hosts = ctx.config.servers.filter( (server) -> server.hdp?.active_nn ).map( (server) -> server.host )
      throw new Error "Invalid Number of Active NameNodes: #{active_nn_hosts.length}" unless active_nn_hosts.length is 1
      ctx.config.hdp.active_nn_host = active_nn_hosts[0]
      ctx.config.hdp.static_host = 
        if ctx.config.hdp.static_host and ctx.config.hdp.static_host isnt '_HOST'
        then ctx.config.host
        else '_HOST'
      # Configuration
      ctx.config.hdp.core_site ?= {}
      ctx.config.hdp.core_site['fs.defaultFS'] ?= "hdfs://#{ctx.config.hdp.nameservice}"
      # Context
      ctx.hconfigure = (options, callback) ->
        options.ssh = ctx.ssh if typeof options.ssh is 'undefined'
        options.log ?= ctx.log
        options.stdout ?= ctx.stdout
        options.stderr ?= ctx.stderr
        hconfigure options, callback
      # Environment
      ctx.config.hdp.hadoop_opts ?= 'java.net.preferIPv4Stack': true
      hadoop_opts = "export HADOOP_OPTS=\""
      for k, v of ctx.config.hdp.hadoop_opts
        hadoop_opts += "-D#{k}=#{v} "
      hadoop_opts += "${HADOOP_OPTS}\""
      ctx.config.hdp.hadoop_opts = hadoop_opts

Repository
----------
Declare the HDP repository.

    module.exports.push name: 'HDP Core # Repository', timeout: -1, callback: (ctx, next) ->
      {proxy, hdp_repo} = ctx.config.hdp
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
       hdfs_user, yarn_user, mapred_user} = ctx.config.hdp
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
      { core_site, hadoop_conf_dir } = ctx.config.hdp
      ctx.log 'Configure core-site.xml'
      # Determines where on the local filesystem the DFS secondary
      # name node should store the temporary images to merge.
      # If this is a comma-delimited list of directories then the image is
      # replicated in all of the directories for redundancy.
      # core_site['fs.checkpoint.edits.dir'] ?= fs_checkpoint_edit_dir.join ','
      # A comma separated list of paths. Use the list of directories from $FS_CHECKPOINT_DIR. 
      # For example, /grid/hadoop/hdfs/snn,sbr/grid1/hadoop/hdfs/snn,sbr/grid2/hadoop/hdfs/snn
      # core_site['fs.checkpoint.dir'] ?= fs_checkpoint_dir.join ','
      ctx.hconfigure
        destination: "#{hadoop_conf_dir}/core-site.xml"
        default: "#{__dirname}/files/core_hadoop/core-site.xml"
        local_default: true
        properties: core_site
        merge: true
      , (err, configured) ->
        next err, if configured then ctx.OK else ctx.PASS

## Hadoop OPTS

Update the "/etc/hadoop/conf/hadoop-env.sh" file.

The location for JSVC depends on the platform. The Hortonworks documentation
mentions "/usr/libexec/bigtop-utils" for RHEL/CentOS/Oracle Linux. While this is
correct for RHEL, it is installed in "/usr/lib/bigtop-utils" on my CentOS.

    module.exports.push name: 'HDP Core # Hadoop OPTS', timeout: -1, callback: (ctx, next) ->
      {hadoop_conf_dir, hdfs_user, hadoop_group, hadoop_opts, hdfs_log_dir, hdfs_pid_dir} = ctx.config.hdp
      ctx.fs.exists '/usr/libexec/bigtop-utils', (err, exists) ->
        return next err if err
        jsvc = if exists then '/usr/libexec/bigtop-utils' else '/usr/lib/bigtop-utils'
        ctx.write
          source: "#{__dirname}/files/core_hadoop/hadoop-env.sh"
          destination: "#{hadoop_conf_dir}/hadoop-env.sh"
          local_source: true
          uid: hdfs_user.name
          gid: hadoop_group.name
          mode: 0o755
          write: [
            match: /^export HADOOP_OPTS.*$/mg
            replace: hadoop_opts
          ,
            match: /\/var\/log\/hadoop\//mg
            replace: "#{hdfs_log_dir}/"
          , 
            match: /\/var\/run\/hadoop\//mg
            replace: "#{hdfs_pid_dir}/"
          # ,
          #   match: /^export JSVC_HOME=.*$/mg
          #   replace: "export JSVC_HOME=/usr/libexec/bigtop-utils"
          ,
            match: /^export JSVC_HOME=.*$/mg
            replace: "export JSVC_HOME=#{jsvc}"
          ]
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

    module.exports.push name: 'HDP Core # Compression', timeout: -1, callback: (ctx, next) ->
      { hadoop_conf_dir } = ctx.config.hdp
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
      {hadoop_conf_dir, core_site, realm} = ctx.config.hdp
      # Set the authentication for the cluster. Valid values are: simple or kerberos
      core_site['hadoop.security.authentication'] ?= 'kerberos'
      # This is an [OPTIONAL] setting. If not set, defaults to 
      # authentication.authentication= authentication only; the client and server 
      # mutually authenticate during connection setup.integrity = authentication 
      # and integrity; guarantees the integrity of data exchanged between client 
      # and server aswell as authentication.privacy = authentication, integrity, 
      # and confidentiality; guarantees that data exchanged between client andserver 
      # is encrypted and is not readable by a “man in the middle”.
      core_site['hadoop.rpc.protection'] ?= 'authentication'
      # Enable authorization for different protocols.
      core_site['hadoop.security.authorization'] ?= 'true'
      # The mapping from Kerberos principal names to local OS user names.
      # Default mapping is referenced here: http://mail-archives.apache.org/mod_mbox/incubator-ambari-commits/201308.mbox/%3Cc82889130fc54e1e8aeabfeedf99dcb3@git.apache.org%3E
      # Here's an example enabling cross-realm:
      # 'hadoop.security.auth_to_local': """
      # 
      #       RULE:[1:$1@$0](^.*@REALM\\.DOMAIN\\.COM$)s/^(.*)@REALM\\.DOMAIN\\.COM$/$1/g
      #       RULE:[2:$1@$0](^.*@REALM\\.DOMAIN\\.COM$)s/^(.*)@REALM\\.DOMAIN\\.COM$/$1/g
      #       RULE:[2:$1@$0]([rn]m@.*)s/.*/yarn/
      #       RULE:[2:$1@$0](jhs@.*)s/.*/mapred/
      #       RULE:[2:$1@$0]([nd]n@.*)s/.*/hdfs/
      #       RULE:[2:$1@$0](hm@.*)s/.*/hbase/
      #       RULE:[2:$1@$0](rs@.*)s/.*/hbase/
      #       DEFAULT
      # 
      # """
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

    module.exports.push  name: 'HDP Core # Kerberos Web UI', callback:(ctx, next) ->
      {core_site, realm} = ctx.config.hdp
      # Cluster domain
      unless core_site['hadoop.http.authentication.cookie.domain']
        domains = ctx.config.servers.map( (server) -> server.host.split('.').slice(1).join('.') ).filter( (el, pos, self) -> self.indexOf(el) is pos )
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


    










