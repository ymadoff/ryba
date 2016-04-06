
## Configuration

    module.exports = handler: ->
      ms_ctxs = @contexts 'ryba/hbase/master', require('../../hbase/master/configure').handler
      # Avoid message "Class org.apache.hadoop.hbase.regionserver.LocalIndexSplitter
      # cannot be loaded Set hbase.table.sanity.checks to false at conf or table
      # descriptor if you want to bypass sanity checks"
      for ms_ctx in ms_ctxs
        ms_ctx.config.ryba.hbase.master.site['hbase.table.sanity.checks'] = 'true'
        ms_ctx.config.ryba.hbase.master.site['hbase.defaults.for.version.skip'] = 'true'
        ms_ctx.config.ryba.hbase.master.site['phoenix.functions.allowUserDefinedFunctions'] = 'true'
        ms_ctx.config.ryba.hbase.master.site['hbase.rpc.controllerfactory.class'] = 'org.apache.hadoop.hbase.ipc.controller.ServerRpcControllerFactory'
      # [Local Indexing](http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.3.2/bk_installing_manually_book/content/configuring-hbase-for-phoenix.html)
      # The local indexing feature is a technical preview and considered under development.
      # As of dec 2015, dont activate or it will prevent permission from working, displaying a message like
      # "ERROR: DISABLED: Security features are not available" after a grant 
      # hbase.site['hbase.master.loadbalancer.class'] ?= 'org.apache.phoenix.hbase.index.balancer.IndexLoadBalancer'
      # hbase.site['hbase.coprocessor.master.classes'] ?= 'org.apache.phoenix.hbase.index.master.IndexMasterObserver'
      @after
        # TODO: add header support to aspect in mecano
        type: 'service'
        name: 'hbase-master'
      , ->
        @service name: 'phoenix'
        @hdp_select name: 'phoenix-client'
        @call require '../lib/hbase_restart'
