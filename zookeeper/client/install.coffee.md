
# Zookeeper Client Install

    module.exports = header: 'ZooKeeper Client Install', handler: (options) ->
      [zk_ctx] = @contexts 'ryba/zookeeper/server'
      {zookeeper_client} = @config.ryba

## Register

      @registry.register 'hdp_select', 'ryba/lib/hdp_select'
      @registry.register ['file', 'jaas'], 'ryba/lib/file_jaas'

## Users & Groups

By default, the "zookeeper" package create the following entries:

```bash
cat /etc/passwd | grep zookeeper
zookeeper:x:497:498:ZooKeeper:/var/run/zookeeper:/bin/bash
cat /etc/group | grep hadoop
hadoop:x:498:hdfs
```

      @system.group header: "Group #{zookeeper_client.hadoop_group.name}", zookeeper_client.hadoop_group
      @system.group header: "Group #{zookeeper_client.group.name}", zookeeper_client.group
      @system.user header: "User #{zookeeper_client.user.name}", zookeeper_client.user

## Packages

Follow the [HDP recommandations][install] to install the "zookeeper" package
which has no dependency.

      @call header: 'Packages', timeout: -1, ->
        @service
          name: 'zookeeper'
        @hdp_select
          name: 'zookeeper-client'

## Kerberos

Create the JAAS client configuration file.

      @file.jaas
        header: 'Kerberos'
        target: "#{zookeeper_client.conf_dir}/zookeeper-client.jaas"
        content: Client:
          useTicketCache: 'true'
        mode: 0o644

## Environment

Generate the "zookeeper-env.sh" file.

      @file
        header: 'Environment'
        target: "#{zookeeper_client.conf_dir}/zookeeper-env.sh"
        content: ("export #{k}=\"#{v}\"" for k, v of zookeeper_client.env).join '\n'
        backup: true
        eof: true
