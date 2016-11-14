
## Configuration

    module.exports = (options) ->
      {ryba} = @config
      hdfs_url = ryba.core_site['fs.defaultFS']
      [rm_context] = @contexts 'ryba/hadoop/yarn_rm'
      tez_ui = @contexts 'ryba/tez/ui'
      ryba.tez ?= {}
      ryba.tez.env ?= {}
      ryba.tez.env['TEZ_CONF_DIR'] ?= '/etc/tez/conf'
      ryba.tez.env['TEZ_JARS'] ?= '/usr/hdp/current/tez-client/*:/usr/hdp/current/tez-client/lib/*'
      ryba.tez.env['HADOOP_CLASSPATH'] ?= '$TEZ_CONF_DIR:$TEZ_JARS:$HADOOP_CLASSPATH'
      ryba.tez.site ?= {}
      # ryba.tez.site['tez.lib.uris'] ?= "#{hdfs_url}/apps/tez/,#{hdfs_url}/apps/tez/lib/"
      ryba.tez.site['tez.lib.uris'] ?= "/hdp/apps/${hdp.version}/tez/tez.tar.gz"
      # For documentation purpose in case we HDFS_DELEGATION_TOKEN in hive queries
      # Following line: ryba.tez.site['tez.am.am.complete.cancel.delegation.tokens'] ?= 'false'
      # Renamed to: ryba.tez.site['tez.cancel.delegation.tokens.on.completion'] ?= 'false'
      # Validation
      # Java.lang.IllegalArgumentException: tez.runtime.io.sort.mb 512 should be larger than 0 and should be less than the available task memory (MB):364
      # throw Error '' ryba.tez.site['tez.runtime.io.sort.mb']
      # Tez UI
      ryba.tez.site['tez.runtime.convert.user-payload.to.history-text'] ?= 'true' if tez_ui.length

## Configuration for Resource Allocation

      memory_per_container = 512
      rm_memory_max_mb = rm_context.config.ryba.yarn.rm.site['yarn.scheduler.maximum-allocation-mb']
      rm_memory_min_mb = rm_context.config.ryba.yarn.rm.site['yarn.scheduler.minimum-allocation-mb']
      am_memory_mb = ryba.tez.site['tez.am.resource.memory.mb'] or memory_per_container
      am_memory_mb = Math.min rm_memory_max_mb, am_memory_mb
      am_memory_mb = Math.max rm_memory_min_mb, am_memory_mb
      ryba.tez.site['tez.am.resource.memory.mb'] = am_memory_mb
      tez_memory_xmx = /-Xmx(.*?)m/.exec(ryba.tez.site['hive.tez.java.opts'])?[1] or Math.floor .8 * am_memory_mb
      tez_memory_xmx = Math.min rm_memory_max_mb, tez_memory_xmx
      ryba.tez.site['hive.tez.java.opts'] ?= "-Xmx#{tez_memory_xmx}m"

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
        continue unless ryba.tez.site[previous]
        ryba.tez.site[current] = ryba.tez.site[previous]
        ctx.log? "Deprecated property '#{previous}' [WARN]"

[tez]: http://tez.apache.org/
[instructions]: (http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.2.0/HDP_Man_Install_v22/index.html#Item1.8.4)
[dep]: http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.2.4/bk_upgrading_hdp_manually/content/start-tez-21.html
