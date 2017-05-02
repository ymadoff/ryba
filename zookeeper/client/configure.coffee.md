
# Zookeeper Client Configure

    module.exports = ->
      [zk_ctx] = @contexts 'ryba/zookeeper/server'
      zookeeper_client = @config.ryba.zookeeper_client ?= {}

## Environnment
      
      zookeeper_client.conf_dir ?= zk_ctx.config.ryba.zookeeper.conf_dir
      
## Identities

      zookeeper_client.group = merge zk_ctx.config.ryba.zookeeper.group, zookeeper_client.group
      zookeeper_client.hadoop_group = merge zk_ctx.config.ryba.hadoop_group, zookeeper_client.hadoop_group
      zookeeper_client.user = merge zk_ctx.config.ryba.zookeeper.user, zookeeper_client.user

## Configuration

      zookeeper_client.env ?= {}
      zookeeper_client.env['JAVA_HOME'] ?= zk_ctx.config.ryba.zookeeper.env['JAVA_HOME']
      zookeeper_client.env['CLIENT_JVMFLAGS'] ?= '-Djava.security.auth.login.config=/etc/zookeeper/conf/zookeeper-client.jaas'
      

## Dependencies

    {merge} = require 'nikita/lib/misc'
