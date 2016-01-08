
## Hbase Thrift server check

    module.exports = []
    module.exports.push 'masson/bootstrap'

## Check TCP

    module.exports.push header: 'HBase Thrift # Check TCP', label_true: 'CHECKED', handler: ->
      {hbase} = @config.ryba
      @execute
        cmd: "echo > /dev/tcp/#{@config.host}/#{hbase.site['hbase.thrift.port']}"

# TODO: Novembre 2015 check Thrift  server by interacting with hbase

For now Hbase provided example does not work with SSL enabled Hbase Thrift Server.
