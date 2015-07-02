
# Zookeeper Client Install

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/bootstrap/utils'
    module.exports.push 'masson/core/yum'
    module.exports.push 'masson/core/iptables'
    module.exports.push 'masson/commons/java'
    # module.exports.push 'ryba/hadoop/core'
    module.exports.push 'ryba/lib/base'
    module.exports.push require('./index').configure
    module.exports.push require '../../lib/hdp_select'
    module.exports.push require '../../lib/write_jaas'

## Users & Groups

By default, the "zookeeper" package create the following entries:

```bash
cat /etc/passwd | grep zookeeper
zookeeper:x:497:498:ZooKeeper:/var/run/zookeeper:/bin/bash
cat /etc/group | grep hadoop
hadoop:x:498:hdfs
```

    module.exports.push name: 'ZooKeeper Client # Users & Groups', handler: (ctx, next) ->
      {zookeeper, hadoop_group} = ctx.config.ryba
      ctx
      .group zookeeper.group
      .group hadoop_group
      .user zookeeper.user
      .then next

## Install

Follow the [HDP recommandations][install] to install the "zookeeper" package
which has no dependency.

    module.exports.push name: 'ZooKeeper Client # Install', timeout: -1, handler: (ctx, next) ->
      ctx
      .service
        name: 'zookeeper'
      .hdp_select
        name: 'zookeeper-client'
      .then next

    module.exports.push name: 'ZooKeeper Client # Kerberos', timeout: -1, handler: (ctx, next) ->
      {zookeeper, hadoop_group, realm} = ctx.config.ryba
      {kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5.etc_krb5_conf.realms[realm]
      ctx
      .krb5_addprinc
        principal: "zookeeper/#{ctx.config.host}@#{realm}"
        randkey: true
        keytab: "#{zookeeper.conf_dir}/zookeeper.keytab"
        uid: zookeeper.user.name
        gid: hadoop_group.name
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
      .write_jaas
        destination: "#{zookeeper.conf_dir}/zookeeper-client.jaas"
        content: Client:
          useTicketCache: 'true'
        mode: 0o644
      .then next

    module.exports.push name: 'ZooKeeper Client # Environment', handler: (ctx, next) ->
      {zookeeper} = ctx.config.ryba
      write = for k, v of zookeeper.env
        match: RegExp "^export\\s+(#{quote k})=(.*)$", 'mg'
        replace: "export #{k}=\"#{v}\""
        append: true
      ctx.write
        destination: "#{zookeeper.conf_dir}/zookeeper-env.sh"
        write: write
        backup: true
      , next

## Dependencies

    quote = require 'regexp-quote'
