
# Zookeeper Client Install

    module.exports = header: 'ZooKeeper Client Install', handler: ->
      {zookeeper, hadoop_group} = @config.ryba

## Register

      @register 'hdp_select', 'ryba/lib/hdp_select'
      @register ['file', 'jaas'], 'ryba/lib/file_jaas'

## Users & Groups

By default, the "zookeeper" package create the following entries:

```bash
cat /etc/passwd | grep zookeeper
zookeeper:x:497:498:ZooKeeper:/var/run/zookeeper:/bin/bash
cat /etc/group | grep hadoop
hadoop:x:498:hdfs
```

      @group zookeeper.group
      @group hadoop_group
      @user zookeeper.user

## Packages

Follow the [HDP recommandations][install] to install the "zookeeper" package
which has no dependency.

      @call header: 'ZooKeeper Client # Packages', timeout: -1, handler: ->
        @service
          name: 'zookeeper'
        @hdp_select
          name: 'zookeeper-client'

## Kerberos

Create the JAAS client configuration file.

      @file.jaas
        header: 'ZooKeeper Client # Kerberos'
        target: "#{zookeeper.conf_dir}/zookeeper-client.jaas"
        content: Client:
          useTicketCache: 'true'
        mode: 0o644

## Environment

Generate the "zookeeper-env.sh" file.

      @file
        header: 'Environment'
        target: "#{zookeeper.conf_dir}/zookeeper-env.sh"
        content: ("export #{k}=\"#{v}\"" for k, v of zookeeper.env).join '\n'
        backup: true
        eof: true
