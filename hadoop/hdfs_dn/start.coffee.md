
# Hadoop HDFS DataNode Start

Start the DataNode service. It is recommended to start a DataNode after its associated
NameNodes. The DataNode doesn't wait for any NameNode to be started. Inside a
federated cluster, the DataNode may be dependant of multiple NameNode clusters
and some may be inactive.

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/krb5_client/wait'
    # module.exports.push 'ryba/hadoop/hdfs_nn/wait' # DN shall be independent from NN
    module.exports.push require('./index').configure

    module.exports.push name: 'HDFS DN # Start', label_true: 'STARTED', handler: (ctx, next) ->
      return next new Error "Not an DataNode" unless ctx.has_module 'ryba/hadoop/hdfs_dn'
      lifecycle.dn_start ctx, next

## Module Dependencies

    lifecycle = require '../../lib/lifecycle'
