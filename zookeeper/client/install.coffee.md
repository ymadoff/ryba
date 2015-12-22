
# Zookeeper Client Install

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/bootstrap/utils'
    module.exports.push 'masson/core/yum'
    module.exports.push 'masson/core/iptables'
    module.exports.push 'masson/commons/java'
    module.exports.push 'ryba/lib/base'
    # module.exports.push require('./index').configure
    module.exports.push 'ryba/lib/hdp_select'
    module.exports.push 'ryba/lib/write_jaas'

## Users & Groups

By default, the "zookeeper" package create the following entries:

```bash
cat /etc/passwd | grep zookeeper
zookeeper:x:497:498:ZooKeeper:/var/run/zookeeper:/bin/bash
cat /etc/group | grep hadoop
hadoop:x:498:hdfs
```

    module.exports.push header: 'ZooKeeper Client # Users & Groups', handler: ->
      {zookeeper, hadoop_group} = @config.ryba
      @group zookeeper.group
      @group hadoop_group
      @user zookeeper.user

## Install

Follow the [HDP recommandations][install] to install the "zookeeper" package
which has no dependency.

    module.exports.push header: 'ZooKeeper Client # Install', timeout: -1, handler: ->
      @service
        name: 'zookeeper'
      @hdp_select
        name: 'zookeeper-client'

    module.exports.push header: 'ZooKeeper Client # Kerberos', timeout: -1, handler: ->
      {zookeeper, hadoop_group, realm} = @config.ryba
      {kadmin_principal, kadmin_password, admin_server} = @config.krb5.etc_krb5_conf.realms[realm]
      @krb5_addprinc
        principal: "zookeeper/#{@config.host}@#{realm}"
        randkey: true
        keytab: "#{zookeeper.conf_dir}/zookeeper.keytab"
        uid: zookeeper.user.name
        gid: hadoop_group.name
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
      @write_jaas
        destination: "#{zookeeper.conf_dir}/zookeeper-client.jaas"
        content: Client:
          useTicketCache: 'true'
        mode: 0o644

    module.exports.push header: 'ZooKeeper Client # Environment', handler: ->
      {zookeeper} = @config.ryba
      @write
        destination: "#{zookeeper.conf_dir}/zookeeper-env.sh"
        content: ("export #{k}=\"#{v}\"" for k, v of zookeeper.env).join '\n'
        backup: true
        eof: true

## Dependencies

    quote = require 'regexp-quote'
