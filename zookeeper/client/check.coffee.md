
# Zookeeper Client Check

TODO: Cloudera provides some interesting [tests](http://www.cloudera.com/content/cloudera/en/documentation/cloudera-manager/v5-latest/Cloudera-Manager-Health-Tests/ht_zookeeper.html).

    module.exports = header: 'Zookeeper Client Check', label_true: 'CHECKED', handler: ->

## Wait

      @call once: true, 'ryba/zookeeper/server/wait'

## Telnet

      zk_cxns = @contexts('ryba/zookeeper/server').map((ctx) -> "#{ctx.config.host}:#{ctx.config.ryba.zookeeper.port}").join ','
      @execute
        header: 'Shell'
        cmd: """
        zookeeper-client -server #{zk_cxns} <<< 'ls /' | egrep '\\[.*zookeeper.*\\]'
        """
