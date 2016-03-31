
## Configuration

    module.exports = handler: ->
      {hbase} = @config.ryba
      phoenix = @config.ryba.phoenix ?= {}
      phoenix.conf_dir ?= '/etc/phoenix/conf'


## Optimisation

Set "hbase.bucketcache.ioengine" to "offheap".
