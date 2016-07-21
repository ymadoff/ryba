
## Hbase Thrift server check

    module.exports = header: 'HBase Thrift Check', label_true: 'CHECKED', handler: ->
      {hbase} = @config.ryba

## Wait

      @wait once: true, 'ryba/hbase/thrift/wait'

## Check Shell

      @execute
        header: 'TCP'
        cmd: "echo > /dev/tcp/#{@config.host}/#{hbase.thrift.site['hbase.thrift.port']}"

# TODO: Novembre 2015 check Thrift  server by interacting with hbase

For now Hbase provided example does not work with SSL enabled Hbase Thrift Server.
