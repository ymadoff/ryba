
# Old stuff

Do not import this module. It is a sink for old code.

## HDP HDFS NN # Upgrade

Extracted from "ryba/hadoop/hdfs_nn"

    module.exports.push name: 'HDP HDFS NN # Upgrade', timeout: -1, callback: (ctx, next) ->
      # TODO, we have never tested migration in HA mode
      return next null, ctx.INAPPLICABLE
      {active_nn, hdfs_log_dir} = ctx.config.ryba
      # Shall only be executed on the leader namenode
      return next null, ctx.INAPPLICABLE unless active_nn
      count = (callback) ->
        ctx.execute
          cmd: "cat #{hdfs_log_dir}/*/*.log | grep 'upgrade to version' | wc -l"
        , (err, executed, stdout) ->
          callback err, parseInt(stdout.trim(), 10) or 0
      ctx.log 'Dont try to upgrade if namenode is running'
      lifecycle.nn_status ctx, (err, started) ->
        return next err if err
        return next null, ctx.DISABLED if started
        ctx.log 'Count how many upgrade msg in log'
        count (err, c1) ->
          return next err if err
          ctx.log 'Start namenode'
          lifecycle.nn_start ctx, (err, started) ->
            return next err if err
            return next null, ctx.PASS if started
            ctx.log 'Count again'
            count (err, c2) ->
              return next err if err
              return next null, ctx.PASS if c1 is c2
              return next new Error 'Upgrade manually'

## HA Init JournalNodes

This action is disabled, it is only usefull when transitionning from a non HA environment. We
kept it here in case we wish to implement HA (de)activation.

Initialize the JournalNodes with the edits data from the local NameNode edits directories
This is executed from the active NameNode. It wait for 
all the JouralNode servers to be started and is only executed if none of 
the directory named after the nameservice is created on each JournalNode host.

    module.exports.push name: 'HDP HDFS NN # HA Init JournalNodes', timeout: -1, callback: (ctx, next) ->
      {nameservice, active_nn} = ctx.config.ryba
      # Shall only be executed on the leader namenode
      journalnodes = ctx.hosts_with_module 'ryba/hadoop/hdfs_jn'
      return next null, ctx.INAPPLICABLE unless active_nn
      do_wait = ->
        # all the JournalNodes shall be started
        options = Object.keys(ctx.config.servers)
          .filter( (server) -> journalnodes.indexOf(server.host) isnt -1 )
          .map( (server) -> host: server.host, port: 8485 )
        ctx.waitIsOpen options, (err) ->
          return next err if err
          do_init()
      do_init = ->
        exists = 0
        each(journalnodes)
        .on 'item', (journalnode, next) ->
          ctx.connect journalnode, (err, ssh) ->
            return next err if err
            dir = "#{ctx.config.ryba.hdfs_site['dfs.journalnode.edits.dir']}/#{nameservice}"
            ctx.fs.exists dir, (err, exist) ->
              exists++ if exist
              next()
        .on 'error', (err) ->
          next err
        .on 'end', ->
          return next null, ctx.PASS if exists is journalnodes.length
          return next null, ctx.TODO if exists > 0 and exists < journalnodes.length
          lifecycle.nn_stop ctx, (err, stopped) ->
            return next err if err
            ctx.execute
              cmd: "su -l hdfs -c \"hdfs namenode -initializeSharedEdits -nonInteractive\""
            , (err, executed, stdout) ->
              return next err if err
              next null, ctx.OK
      do_wait()