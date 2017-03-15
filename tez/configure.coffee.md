
## Configuration

    module.exports = ->
      hdfs_url = @config.ryba.core_site['fs.defaultFS']
      [rm_context] = @contexts 'ryba/hadoop/yarn_rm'
      nm_ctxs = @contexts 'ryba/hadoop/yarn_nm'
      tez = @config.ryba.tez ?= {}
      tez.env ?= {}
      tez.env['TEZ_CONF_DIR'] ?= '/etc/tez/conf'
      tez.env['TEZ_JARS'] ?= '/usr/hdp/current/tez-client/*:/usr/hdp/current/tez-client/lib/*'
      tez.env['HADOOP_CLASSPATH'] ?= '$TEZ_CONF_DIR:$TEZ_JARS:$HADOOP_CLASSPATH'
      tez.ui ?= {}
      tez.ui.enabled ?= @config.host in @contexts('masson/commons/httpd').map( (c) -> c.config.host )
      tez.site ?= {}
      # tez.site['tez.lib.uris'] ?= "#{hdfs_url}/apps/tez/,#{hdfs_url}/apps/tez/lib/"
      tez.site['tez.lib.uris'] ?= "/hdp/apps/${hdp.version}/tez/tez.tar.gz"
      # For documentation purpose in case we HDFS_DELEGATION_TOKEN in hive queries
      # Following line: ryba.tez.site['tez.am.am.complete.cancel.delegation.tokens'] ?= 'false'
      # Renamed to: ryba.tez.site['tez.cancel.delegation.tokens.on.completion'] ?= 'false'
      # Validation
      # Java.lang.IllegalArgumentException: tez.runtime.io.sort.mb 512 should be larger than 0 and should be less than the available task memory (MB):364
      # throw Error '' ryba.tez.site['tez.runtime.io.sort.mb']

## Configuration for Resource Allocation

      memory_per_container = 512
      rm_memory_max_mb = rm_context.config.ryba.yarn.rm.site['yarn.scheduler.maximum-allocation-mb']
      rm_memory_min_mb = rm_context.config.ryba.yarn.rm.site['yarn.scheduler.minimum-allocation-mb']
      am_memory_mb = tez.site['tez.am.resource.memory.mb'] or memory_per_container
      am_memory_mb = Math.min rm_memory_max_mb, am_memory_mb
      am_memory_mb = Math.max rm_memory_min_mb, am_memory_mb
      tez.site['tez.am.resource.memory.mb'] = am_memory_mb
      tez_memory_xmx = /-Xmx(.*?)m/.exec(tez.site['hive.tez.java.opts'])?[1] or Math.floor .8 * am_memory_mb
      tez_memory_xmx = Math.min rm_memory_max_mb, tez_memory_xmx
      tez.site['hive.tez.java.opts'] ?= "-Xmx#{tez_memory_xmx}m"

## Depracated warning

Convert [deprecated values][dep] between HDP 2.1 and HDP 2.2.

      deprecated = {}
      deprecated['tez.am.java.opts'] = 'tez.am.launch.cmd-opts'
      deprecated['tez.am.env'] = 'tez.am.launch.env'
      deprecated['tez.am.shuffle-vertex-manager.min-src-fraction'] = 'tez.shuffle-vertex-manager.min-src-fraction'
      deprecated['tez.am.shuffle-vertex-manager.max-src-fraction'] = 'tez.shuffle-vertex-manager.max-src-fraction'
      deprecated['tez.am.shuffle-vertex-manager.enable.auto-parallel'] = 'tez.shuffle-vertex-manager.enable.auto-parallel'
      deprecated['tez.am.shuffle-vertex-manager.desired-task-input-size'] = 'tez.shuffle-vertex-manager.desired-task-input-size'
      deprecated['tez.am.shuffle-vertex-manager.min-task-parallelism'] = 'tez.shuffle-vertex-manager.min-task-parallelism'
      deprecated['tez.am.grouping.split-count'] = 'tez.grouping.split-count'
      deprecated['tez.am.grouping.by-length'] = 'tez.grouping.by-length'
      deprecated['tez.am.grouping.by-count'] = 'tez.grouping.by-count'
      deprecated['tez.am.grouping.max-size'] = 'tez.grouping.max-size'
      deprecated['tez.am.grouping.min-size'] = 'tez.grouping.min-size'
      deprecated['tez.am.grouping.rack-split-reduction'] = 'tez.grouping.rack-split-reduction'
      deprecated['tez.am.am.complete.cancel.delegation.tokens'] = 'tez.cancel.delegation.tokens.on.completion'
      deprecated['tez.am.max.task.attempts'] = 'tez.am.task.max.failed.attempts'
      deprecated['tez.generate.dag.viz'] = 'tez.generate.debug.artifacts'
      deprecated['tez.runtime.intermediate-output.key.comparator.class'] = 'tez.runtime.key.comparator.class'
      deprecated['tez.runtime.intermediate-output.key.class'] = 'tez.runtime.key.class'
      deprecated['tez.runtime.intermediate-output.value.class'] = 'tez.runtime.value.class'
      deprecated['tez.runtime.intermediate-output.should-compress'] = 'tez.runtime.compress'
      deprecated['tez.runtime.intermediate-output.compress.codec'] = 'tez.runtime.compress.codec'
      deprecated['tez.runtime.intermediate-input.key.secondary.comparator.class'] = 'tez.runtime.key.secondary.comparator.class'
      deprecated['tez.runtime.broadcast.data-via-events.enabled'] = 'tez.runtime.transfer.data-via-events.enabled'
      deprecated['tez.runtime.broadcast.data-via-events.max-size'] = 'tez.runtime.transfer.data-via-events.max-size'
      deprecated['tez.runtime.shuffle.input.buffer.percent'] = 'tez.runtime.shuffle.fetch.buffer.percent'
      deprecated['tez.runtime.task.input.buffer.percent'] = 'tez.runtime.task.input.post-merge.buffer.percent'
      deprecated['tez.runtime.job.counters.max'] = 'tez.am.counters.max.keys'
      deprecated['tez.runtime.job.counters.group.name.max'] = 'tez.am.counters.group-name.max.keys'
      deprecated['tez.runtime.job.counters.counter.name.max'] = 'tez.am.counters.name.max.keys'
      deprecated['tez.runtime.job.counters.groups.max'] = 'tez.am.counters.groups.max.keys'
      deprecated['tez.task.merge.progress.records'] = 'tez.runtime.merge.progress.records'
      deprecated['tez.runtime.metrics.session.id'] = 'tez.runtime.framework.metrics.session.id'
      deprecated['tez.task.scale.memory.additional.reservation.fraction.per-io'] = 'tez.task.scale.memory.additional-reservation.fraction.per-io'
      deprecated['tez.task.scale.memory.additional.reservation.fraction.max'] = 'tez.task.scale.memory.additional-reservation.fraction.max'
      deprecated['tez.task.initial.memory.scale.ratios'] = 'tez.task.scale.memory.ratios'
      deprecated['tez.resource.calculator.process-tree.class'] = 'tez.task.resource.calculator.process-tree.class'
      for previous, current of deprecated
        continue unless tez.site[previous]
        tez.site[current] = tez.site[previous]
        @log? "Deprecated property '#{previous}' [WARN]"

## Tez Ports

      # Range of ports that the AM can use when binding for client connections
      tez.site['tez.am.client.am.port-range'] ?= '34816-36864'
      for nm_ctx in nm_ctxs
        nm_ctx
        .after
          type: ['hconfigure']
          target: "#{nm_ctx.config.ryba.yarn.nm.conf_dir}/yarn-site.xml"
          handler: (options, callback) ->
            @tools.iptables
              ssh: options.ssh
              header: 'Tez AM Port Opening'
              rules: [
                { chain: 'INPUT', jump: 'ACCEPT', dport: tez.site['tez.am.client.am.port-range'].replace('-',':'), protocol: 'tcp', state: 'NEW', comment: "Tez AM Range" }
              ]
              if: nm_ctx.config.iptables.action is 'start'
            @then callback

## Tez UI

      if tez.ui.enabled
        tez.ui.env ?= {}
        tez.ui.env.hosts ?= {}
        unless tez.site['tez.tez-ui.history-url.base'] and tez.ui.html_path
          unless @config.host in @contexts('masson/commons/httpd').map( (c) -> c.config.host )
            throw 'Install masson/commons/httpd on ' + @config.host + ' or specify tez.site[\'tez.tez-ui.history-url.base\'] and tez.ui.html_path if tez.ui.enabled'
          tez.site['tez.tez-ui.history-url.base'] ?= "http://#{@config.host}/tez-ui"
          tez.ui.html_path ?= "#{@config.httpd.user.home}/tez-ui"
        yarn_ts_ctxs = @contexts 'ryba/hadoop/yarn_ts'
        yarn_rm_ctxs = @contexts 'ryba/hadoop/yarn_rm'
        throw Error 'Cannot install Tez UI without Yarn TS' unless yarn_ts_ctxs.length
        throw Error 'Cannot install Tez UI without YARN RM' unless yarn_rm_ctxs.length
        ats_ctx = yarn_ts_ctxs[0]
        rm_ctx = yarn_rm_ctxs[0]
        id = if rm_ctx.config.ryba.yarn.rm.site['yarn.resourcemanager.ha.enabled'] is 'true' then ".#{rm_ctx.config.ryba.yarn.rm.site['yarn.resourcemanager.ha.id']}" else ''
        tez.ui.env.hosts.timeline ?= if ats_ctx.config.ryba.yarn.site['yarn.http.policy'] is 'HTTP_ONLY'
        then "http://" + ats_ctx.config.ryba.yarn.site['yarn.timeline-service.webapp.address']
        else "https://"+ ats_ctx.config.ryba.yarn.site['yarn.timeline-service.webapp.https.address']
        tez.ui.env.hosts.rm ?= if rm_ctx.config.ryba.yarn.site['yarn.http.policy'] is 'HTTP_ONLY'
        then "http://" + rm_ctx.config.ryba.yarn.rm.site["yarn.resourcemanager.webapp.address#{id}"]
        else "https://"+ rm_ctx.config.ryba.yarn.rm.site["yarn.resourcemanager.webapp.https.address#{id}"]
        ## Tez Site when UI is enabled
        tez.site['tez.runtime.convert.user-payload.to.history-text'] ?= 'true'
        tez.site['tez.history.logging.service.class'] ?= 'org.apache.tez.dag.history.logging.ats.ATSHistoryLoggingService'

[tez]: http://tez.apache.org/
[instructions]: (http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.2.0/HDP_Man_Install_v22/index.html#Item1.8.4)
[dep]: http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.2.4/bk_upgrading_hdp_manually/content/start-tez-21.html
