
# Capacity Planning for Hadoop Cluster

Capacity planning is the science and art of estimating the space, computer
hardware, software and connection infrastructure resources that will be needed
over some future period of time.

In the Hadoop context of this script, Capacity Planning is about discovering
the Memory, Disk and CPU resources for every node of the cluster and estimating
default setting for Yarn and its client application such as MapReduce or Tez.

## Source Code

    exports = module.exports = (config, callback) ->
      exports.contexts config, (err, ctxs) ->
        return callback err if err
        return callback Error 'No Servers Configured' unless Object.keys(ctxs).length
        do_configure = ->
          exports.configure ctxs, (err) ->
            return callback err if err
            do_disks ctxs
        do_disks = ->
          exports.disks ctxs, (err) ->
            return callback err if err
            do_cores ctxs
        do_cores = ->
          exports.cores ctxs, (err) ->
            return callback err if err
            do_memory ctxs
        do_memory = ->
          exports.memory ctxs, (err) ->
            return callback err if err
            do_yarn_nm ctxs
        do_yarn_nm = ->
          exports.yarn_nm ctxs, (err) ->
            return callback err if err
            do_yarn_rm ctxs
        do_yarn_rm = ->
          exports.yarn_rm ctxs, (err) ->
            return callback err if err
            do_hdfs_nn ctxs
        do_hdfs_nn = ->
          exports.hdfs_nn ctxs, (err) ->
            return callback err if err
            do_hdfs_dn ctxs
        do_hdfs_dn = ->
          exports.hdfs_dn ctxs, (err) ->
            return callback err if err
            do_mapred_client ctxs
        do_mapred_client = ->
          exports.mapred_client ctxs, (err) ->
            return callback err if err
            do_hive_client ctxs
        do_hive_client = ->
          exports.hive_client ctxs, (err) ->
            return callback err if err
            do_remote ctxs
        do_remote = ->
          exports.remote ctxs, (err) ->
            return callback err if err
            do_write ctxs
        # do_report = ->
        #   exports.report ctxs, (err) ->
        #     return callback err if err
        #     do_write()
        do_write = ->
          exports.write config, ctxs, (err) ->
            return callback err if err
            do_end()
        do_end = ->
          callback null
        do_configure()

## Parameters

    exports.params = 
      name: 'capacity'
      description: 'Hadoop Tool for Capacity Planning'
      options: [
        name: 'config', shortcut: 'c', type: 'array'
        description: 'One or multiple configuration files'
        required: true
      ,
        name: 'save', shortcut: 's'
        description: 'Write the configuration to a file, valid extension are xml, json, js and coffee'
      ,
        name: 'format', shortcut: 'f' # default: 'text'
        description: 'Output format are text (default), xml, json, js and coffee'
      ,
        name: 'overwrite', shortcut: 'o', type: 'boolean' # default: 'text'
        description: 'Overwrite any existing file'
      ,
        name: 'hdfs_nn_name_dir' # default: './hdfs/name'
        description: 'Relative path to the HDFS NameNode name directories'
      ,
        name: 'hdfs_dn_data_dir' # default: './hdfs/data'
        description: 'Relative path to the HDFS DataNode local directories'
      ,
        name: 'yarn_nm_local_dir' # default: './yarn/local'
        description: 'Relative path to the YARN NodeManager local directories'
      ,
        name: 'yarn_nm_log_dir' # default: './yarn/log'
        description: 'Relative path to the YARN NodeManager local directories'
      ]

          
          

## SSH

    exports.contexts = (config, next) ->
      config.log ?= {}
      config.log.disabled ?= true
      config.connection.end = false
      contexts = []
      config.params.modules = ['masson/bootstrap/connection', 'masson/bootstrap/info']
      run(config)
      .on 'context', (ctx) ->
        contexts.push ctx
      .on 'error', next
      .on 'end', -> next null, contexts

## Configuration

*   `total_memory` (int|string)   
    Total Memory available on the server.   
*   `memory_system` (int|string)   
    Total Memory allocated to the system.   
*   `memory_hbase` (int|string)   
    Total Memory allocated to the Yarn NodeManagers.   
*   `memory_yarn` (int|string)   
    Total Memory allocated to the HBase RegionServers.   
*   `cores` (int)   
    Number of available cores to the Yarn NodeManagers.   
*   `disks` (array)   
    List of disk partitions available to the HDFS DataNodes and YARN NodeManagers.   

Example

```json
{
  "capacity": {
    total_memory: '2GB'
  }
}
```

    exports.configure = (ctxs, next) ->
      for ctx in ctxs
        ctx.config.capacity ?= {}
        ctx.config.capacity.total_memory ?= null
        ctx.config.capacity.memory_system ?= null
        ctx.config.capacity.memory_hbase ?= null
        ctx.config.capacity.memory_yarn ?= null
        ctx.config.ryba ?= {}
        ctx.config.capacity ?= {}
        ctx.config.capacity.remote ?= {}
        for conf in ['hdfs_site', 'yarn_site', 'mapred_site', 'hive_site', 'capacity_scheduler', 'hbase_site']
          ctx.config.capacity[conf] ?= {}
          ctx.config.capacity.remote[conf] ?= {}
        ctx.config.capacity.capacity_scheduler['yarn.scheduler.capacity.resource-calculator'] ?= 'org.apache.hadoop.yarn.util.resource.DominantResourceCalculator'
      next()

## Capacity Planning for Disks

    exports.disks = (ctxs, next) ->
      for ctx in ctxs
        # continue unless ctx.has_any_modules 'ryba/hadoop/yarn_nm'
        continue if ctx.config.capacity.disks
        # Search common partition names
        found_common_names = []
        for disk in ctx.diskinfo
          found_common_names.push disk if /^\/data\/\d+/.test disk.mountpoint # Cloudera style, eg /data/1
          found_common_names.push disk if /^\/grid\/\d+/.test disk.mountpoint # HDP style, eg /data/1
        found_large_partitions_with_spaces = []
        found_large_partitions_with_spaces_is_root = null
        for disk in ctx.diskinfo
          available = disk.available / 1024 / 1024 / 1024 # Go
          found_large_partitions_with_spaces.push disk if available > prink.filesize.parse '200 MB'
          found_large_partitions_with_spaces_and_root = disk if available > 200 and disk.mountpoint is '/'
        found_root = null
        for disk in ctx.diskinfo
          found_root = disk if disk.mountpoint is '/'
        # Choose
        if found_common_names.length
          ctx.config.capacity.disks = found_common_names
        else if found_large_partitions_with_spaces > 4 and found_large_partitions_with_spaces_and_root
          # Exclude root partition
          ctx.config.capacity.disks = for disk in found_large_partitions_with_spaces
            continue if disk.mountpoint is '/'
            disk
        else if found_large_partitions_with_spaces > 2
          ctx.config.capacity.disks = found_large_partitions_with_spaces
        else if found_root
          ctx.config.capacity.disks = [found_root]
        else next Error 'No Appropriate Disk Found'
        ctx.config.capacity.disks = ctx.config.capacity.disks.map (disk) -> disk.mountpoint
      next()

## Capacity Planning for CPU

    exports.cores = (ctxs, next) ->
      for ctx in ctxs
        ctx.config.capacity.cores ?= ctx.cpuinfo.length
      next()

## Capacity Planning for Memory

    exports.memory_system_gb = [[1,.2], [2,.4], [4,1], [7,2], [8,2], [16,2], [24,4], [48,6], [64,8], [72,8], [96,12], [128,24], [256,32], [512,64]]
    exports.memory_hbase_gb = [[1,.2], [2,.4], [4,1], [8,1], [16,2], [24,4], [48,8], [64,8], [72,8], [96,16], [128,24], [256,32], [512,64]]
    exports.memory = (ctxs, next) ->
      for ctx in ctxs
        ctx.config.capacity.total_memory ?= ctx.meminfo.MemTotal
        continue unless ctx.has_any_modules 'ryba/hadoop/yarn_nm'
        {total_memory} = ctx.config.capacity
        total_memory_gb = total_memory / 1024 / 1024 / 1024
        memory_system_gb = 0
        if total_memory_gb < exports.memory_system_gb[0][0] # Memory less than first item (1GB)
          memory_system_gb += exports.memory_system_gb[0][1]
        else if total_memory_gb >= exports.memory_system_gb[exports.memory_system_gb.length-1][0] # Memory greater than last item (512GB)
          memory_system_gb += exports.memory_system_gb[exports.memory_system_gb.length-1][1]
        else
          for mem in exports.memory_system_gb
            [total, reserved] = mem
            if total_memory_gb < total
              memory_system_gb = reserved
              break
        memory_hbase_gb = 0
        if ctx.has_module 'ryba/hbase/regionserver'
          if total_memory_gb < exports.memory_hbase_gb[0][0]
            memory_hbase_gb += exports.memory_hbase_gb[0][1] # Memory less than minimal expectation
          else if total_memory_gb >= exports.memory_hbase_gb[exports.memory_hbase_gb.length-1][0]
            memory_hbase_gb += exports.memory_hbase_gb[exports.memory_hbase_gb.length-1][1]
          else
            for mem in exports.memory_hbase_gb
              [total, reserved] = mem
              if total_memory_gb < total
                memory_hbase_gb = reserved
                break
        ctx.config.capacity.memory_system ?= memory_system = Math.round memory_system_gb * 1024 * 1024 * 1024
        ctx.config.capacity.memory_hbase ?= memory_hbase = Math.round memory_hbase_gb * 1024 * 1024 * 1024
        ctx.config.capacity.memory_yarn ?= total_memory - memory_system - memory_hbase
      next()

## Yarn ResourceManager

    exports.yarn_nm = (ctxs, next) ->
      minimum_allocation_mb = null
      maximum_allocation_mb = 0
      maximum_allocation_vcores = 0
      for ctx in ctxs
        continue unless ctx.has_any_modules 'ryba/hadoop/yarn_nm'
        {cores, disks, memory_yarn, yarn_site} = ctx.config.capacity

        minimum_container_size = if memory_yarn <= 2*1024*1024*1024 then 128*1024*1024 # 128 MB
        else if memory_yarn <= 4*1024*1024*1024 then 256*1024*1024 # 256 MB
        else if memory_mb <= 8*1024*1024*1024 then 512*1024*1024 # 512 MB
        else if memory_mb <= 24*1024*1024*1024 then 1024*1024*1024 # 1 GB
        else 2*1024*1024*1024 # 2 GB
        
        # # min (2*CORES, 1.8*DISKS, (Total available RAM / MIN_CONTAINER_SIZE) )
        unless max_number_of_containers = ctx.config.capacity.max_number_of_containers
          # Possible incoherence, here we multiply number of cores by 2 while
          # NodeManager vcores is set to number of cores only
          max_number_of_containers = Math.floor Math.min cores*2, disks.length * 1.8, (memory_yarn / minimum_container_size)
        ctx.config.capacity.max_number_of_containers = max_number_of_containers

        # Amount of RAM per container
        # max(MIN_CONTAINER_SIZE, (Total Available RAM) / containers))
        unless memory_per_container = ctx.config.capacity.memory_per_container
          memory_per_container = Math.floor Math.max minimum_container_size, memory_yarn / max_number_of_containers
        ctx.config.capacity.memory_per_container = memory_per_container

        minimum_allocation_mb ?= Math.round memory_per_container / 1024 / 1024
        minimum_allocation_mb = Math.min minimum_allocation_mb, memory_per_container

Amount of physical memory, in MB, dedicated by the node and that can be allocated for containers.

        yarn_site['yarn.nodemanager.resource.memory-mb'] ?= Math.round memory_per_container * max_number_of_containers / 1024 / 1024
        maximum_allocation_mb = Math.max maximum_allocation_mb, yarn_site['yarn.nodemanager.resource.memory-mb']

The property "yarn.nodemanager.vmem-pmem-rati" defines the virtual memory
(physical + paged memory) upper limit for each Map and  Reduce task is
determined by the virtual memory ratio each YARN Container is allowed. The
default value "2.1" means virtual memory will be double the size of physical
memory.

        yarn_site['yarn.nodemanager.vmem-pmem-ratio'] ?= '2.1'

Number of Virtual Cores dedicated by the node and that can be allocated for containers.
        
        yarn_site['yarn.nodemanager.resource.cpu-vcores'] ?= cores

The property "yarn.nodemanager.local-dirs" define multiple disks for
localization. It enforces fail-over, preventing one disk to affect the
containers, and load-balancing by spliting the access to the disks.

        yarn_site['yarn.nodemanager.local-dirs'] ?= disks.map (disk) ->
          path.resolve disk, ctx.config.params.yarn_nm_local_dir or './yarn/local'
        yarn_site['yarn.nodemanager.log-dirs'] ?= disks.map (disk) ->
          path.resolve disk, ctx.config.params.yarn_nm_log_dir or './yarn/log'

        maximum_allocation_vcores = Math.max maximum_allocation_vcores, yarn_site['yarn.nodemanager.resource.cpu-vcores']

      memory_per_container_mean = for ctx in ctxs
        continue unless ctx.has_any_modules 'ryba/hadoop/yarn_nm'
        ctx.config.capacity.memory_per_container
      memory_per_container_mean = Math.round memory_per_container_mean.reduce( (a, b) -> a + b ) / memory_per_container_mean.length
      for ctx in ctxs
        ctx.config.capacity.memory_per_container_mean = memory_per_container_mean
        ctx.config.capacity.minimum_allocation_mb = minimum_allocation_mb
        ctx.config.capacity.maximum_allocation_mb = maximum_allocation_mb
        ctx.config.capacity.maximum_allocation_vcores = maximum_allocation_vcores

      next()

## Yarn ResourceManager

    exports.yarn_rm = (ctxs, next) ->
      for ctx in ctxs
        continue unless ctx.has_any_modules 'ryba/hadoop/yarn_rm'
        {minimum_allocation_mb, maximum_allocation_mb, maximum_allocation_vcores, yarn_site} = ctx.config.capacity
        yarn_site['yarn.scheduler.minimum-allocation-mb'] ?= minimum_allocation_mb
        yarn_site['yarn.scheduler.maximum-allocation-mb'] ?= maximum_allocation_mb
        yarn_site['yarn.scheduler.minimum-allocation-vcores'] ?= 1

The property "yarn.scheduler.maximum-allocation-vcores" should not be larger
than the value for the yarn.nodemanager.resource.cpu-vcores parameter on any
NodeManager. Document states that resource requests are capped at the maximum
allocation limit and a container is eventually granted. Tests in version 2.4
instead shows that the containers are never granted, and no progress is made by
the application (zombie state).

        yarn_site['yarn.scheduler.maximum-allocation-vcores'] ?= maximum_allocation_vcores
      next()

## HDFS DataNode

    exports.hdfs_dn = (ctxs, next) ->
      for ctx in ctxs
        continue unless ctx.has_any_modules 'ryba/hadoop/hdfs_dn'
        {disks, hdfs_site} = ctx.config.capacity
        hdfs_site['dfs.datanode.data.dir'] ?= disks.map (disk) ->
          path.resolve disk, ctx.config.params.hdfs_dn_data_dir or './hdfs/data'
      next()

## HDFS NameNode

    exports.hdfs_nn = (ctxs, next) ->
      for ctx in ctxs
        continue unless ctx.has_any_modules 'ryba/hadoop/hdfs_nn'
        {disks, hdfs_site} = ctx.config.capacity
        hdfs_site['dfs.namenode.name.dir'] ?= disks.map (disk) ->
          disk = '/var' if disk is '/'
          path.resolve disk, ctx.config.params.hdfs_nn_name_dir or './hdfs/name'
      next()

## MapReduce Client

    exports.mapred_client = (ctxs, next) ->
      for ctx in ctxs
        continue unless ctx.has_any_modules 'ryba/hadoop/mapred_client'
        {memory_per_container_mean, maximum_allocation_mb, mapred_site} = ctx.config.capacity
        memory_per_container_mean_mb = Math.round memory_per_container_mean / 1024 / 1024

The property "yarn.app.mapreduce.am.resource.mb" defines the amount of memory
that the Application Master for MR framework would need. This needs to be set
with care as a larger allocation for the AM would mean lesser concurrency, as
you can spin up only so many AMs before exhausting the containers on a busy
system. This value also needs to be less than what is defined in
"yarn.scheduler.maximum-allocation-mb", if not, it will create an error
condition.  Can be set at site level with "mapred-site.xml", or
can be set at the job level. This change does not require a service restart.

        mapreduce_am_memory_mb = mapred_site['yarn.app.mapreduce.am.resource.mb'] or 2 * memory_per_container_mean_mb
        mapreduce_am_memory_mb = Math.min mapreduce_am_memory_mb, maximum_allocation_mb
        mapred_site['yarn.app.mapreduce.am.resource.mb'] = mapreduce_am_memory_mb

        mapreduce_am_opts = /-Xmx(.*?)m/.exec(mapred_site['yarn.app.mapreduce.am.command-opts'])?[1] or Math.floor .8 * 2 * memory_per_container_mean_mb
        mapreduce_am_opts = Math.min mapreduce_am_opts, maximum_allocation_mb
        mapred_site['yarn.app.mapreduce.am.command-opts'] = "-Xmx#{mapreduce_am_opts}m"

        map_memory_mb = mapred_site['mapreduce.map.memory.mb'] or memory_per_container_mean_mb
        map_memory_mb = Math.min map_memory_mb, maximum_allocation_mb
        mapred_site['mapreduce.map.memory.mb'] = "#{map_memory_mb}"

        reduce_memory_mb = mapred_site['mapreduce.reduce.memory.mb'] or 2 * memory_per_container_mean_mb
        reduce_memory_mb = Math.min reduce_memory_mb, maximum_allocation_mb
        mapred_site['mapreduce.reduce.memory.mb'] = "#{reduce_memory_mb}"

The value of "mapreduce.map.java.opts" and "mapreduce.reduce.java.opts" are used
to configure the maximum and minimum JVM heap size with respectively the java
options "-Xmx" and "-Xms". The values must be less than their
"mapreduce.map.memory.mb" and "mapreduce.reduce.memory.mb" counterpart.

        mapred_site['mapreduce.map.java.opts'] ?= "-Xmx#{Math.floor .8 * map_memory_mb}m" # 0.8 * RAM-per-container
        mapred_site['mapreduce.reduce.java.opts'] ?= "-Xmx#{Math.floor .8 * reduce_memory_mb}m" # 0.8 * 2 * RAM-per-container

        mapred_site['mapreduce.task.io.sort.mb'] = "#{Math.floor .4 * memory_per_container_mean_mb}"

        # The number of virtual CPU cores allocated for each map task of a job
        mapred_site['mapreduce.map.cpu.vcores'] ?= 1
        #  The number of virtual CPU cores for each reduce task of a job
        mapred_site['mapreduce.reduce.cpu.vcores'] ?= 1
      next()

## Hive Client

    exports.hive_client = (ctxs, next) ->
      for ctx in ctxs
        continue unless ctx.has_any_modules 'ryba/hive/client'
        {memory_per_container_mean, maximum_allocation_mb, hive_site} = ctx.config.capacity
        memory_per_container_mean_mb = Math.round memory_per_container_mean / 1024 / 1024

The memory (in MB) to be used for Tez tasks. If this is not specified (-1), the
memory settings from the MapReduce configurations (mapreduce.map.memory.mb) will
be used by default for map tasks.

        tez_memory_mb = hive_site['hive.tez.container.size'] or memory_per_container_mean_mb
        tez_memory_mb = Math.min tez_memory_mb, maximum_allocation_mb
        hive_site['hive.tez.container.size'] = "#{tez_memory_mb}"

Java command line options for Tez. If this is not specified, the MapReduce java
opts settings (mapreduce.map.java.opts) will be used by default for map tasks.

        hive_site['hive.tez.java.opts'] ?= "-Xmx#{Math.floor .8 * tez_memory_mb}m" # 0.8 * RAM-per-container

      next()

    exports.remote = (ctxs, next) ->
      each(ctxs)
      .parallel(true)
      .on 'item', (ctx, next) ->
        do_hdfs = ->
          return do_yarn_capacity_scheduler() unless ctx.has_any_modules 'ryba/hadoop/hdfs_nn', 'ryba/hadoop/hdfs_dn'
          properties.read ctx.ssh, '/etc/hadoop/conf/hdfs-site.xml', (err, hdfs_site) ->
            ctx.config.capacity.remote.hdfs_site = hdfs_site unless err
            do_yarn_capacity_scheduler()
        do_yarn_capacity_scheduler = ->
          return do_yarn() unless ctx.has_any_modules 'ryba/hadoop/yarn_nm'
          properties.read ctx.ssh, '/etc/hadoop/conf/yarn-site.xml', (err, capacity_scheduler) ->
            ctx.config.capacity.remote.capacity_scheduler = capacity_scheduler unless err
            do_yarn()
        do_yarn = ->
          return do_mapred() unless ctx.has_any_modules 'ryba/hadoop/yarn_rm', 'ryba/hadoop/yarn_nm'
          properties.read ctx.ssh, '/etc/hadoop/conf/yarn-site.xml', (err, yarn_site) ->
            ctx.config.capacity.remote.yarn_site = yarn_site unless err
            do_mapred()
        do_mapred = ->
          return do_hive() unless ctx.has_any_modules 'ryba/hadoop/mapred_client'
          properties.read ctx.ssh, '/etc/hadoop/conf/mapred-site.xml', (err, mapred_site) ->
            ctx.config.capacity.remote.mapred_site = mapred_site unless err
            do_hive()
        do_hive = ->
          return do_end() unless ctx.has_any_modules 'ryba/hive/client'
          properties.read ctx.ssh, '/etc/hive/conf/hive-site.xml', (err, hive_site) ->
            ctx.config.capacity.remote.hive_site = hive_site unless err
            do_end()
        do_end = ->
          ctx.ssh.end()
          ctx.ssh.on 'end', next
        do_hdfs()
      .on 'both', next

    exports.write = (config, ctxs, next) ->
      # return next() unless config.params.save
      formats = ['xml', 'json', 'js', 'coffee']
      if config.params.format is 'text'
        # ok, print to stdout
      else if config.params.format
        return next Error "Insupported Extension #{extname}" unless config.params.format in formats
        # unless config.params.save
        #   # ok, print to stdout
        # else if (basename = path.basename(config.params.save, ".#{config.params.format}")) isnt config.params.save
        #   config.params.save = "#{basename}.#{config.params.format}" if config.params.format in ['json', 'js', 'coffee']
      else if config.params.save
        extname = path.extname config.params.save
        format = extname.substr 1
        return next Error "Could not guess format from arguments" unless format in formats
        config.params.format = format
      else
        config.params.format = 'text'      
      exports["write_#{config.params.format}"] config, ctxs, (err, content) ->
        return next err if err
        # return next() unless config.params.save
        # console.log 'SSSAAAVVVEEE', config.params.save
        # # fs.stat config.params.save
        next()

    exports.write_text = (config, ctxs, next) ->
      do_open = ->
        return do_write process.stdout unless config.params.save
        return next() unless config.params.save
        fs.stat config.params.save, (err, stat) ->
          return next err if err and err.code isnt 'ENOENT'
          return next Error 'File Already Exists, use --overwrite' unless err or config.params.overwrite
          do_write fs.createWriteStream config.params.save, encoding: 'utf8'
      do_write = (ws) ->
        print = (config, properties) ->
          for property in properties
            suggested_value = capacity[config][property]
            remote_value = capacity.remote[config][property]
            diff = if remote_value is "#{suggested_value}" then 'identical'
            else if remote_value? then "'#{remote_value}'"
            else 'not defined'
            diff = "(currently #{diff})"
            ws.write "    #{config}['#{property}'] = '#{suggested_value}' #{diff}\n"
        for ctx in ctxs
          {capacity} = ctx.config
          mods = [
            'ryba/hadoop/hdfs_nn', 'ryba/hadoop/hdfs_dn'
            'ryba/hadoop/yarn_rm', 'ryba/hadoop/yarn_nm'
            'ryba/hadoop/mapred_client', 'ryba/hadoop/hive_client'
          ]
          if ctx.has_any_modules mods
            ws.write "#{ctx.config.host}\n"
          if ctx.has_any_modules 'ryba/hadoop/hdfs_nn'
            ws.write "  HDFS NameNode\n"
            print 'hdfs_site', ['dfs.namenode.name.dir']
            # ws.write "    hdfs-site['dfs.namenode.name.dir'] = '#{capacity.hdfs_site['dfs.namenode.name.dir']}'\n"
          if ctx.has_any_modules 'ryba/hadoop/hdfs_dn'
            ws.write "  HDFS DataNode\n"
            print 'hdfs_site', ['dfs.datanode.data.dir']
            # ws.write "    hdfs-site['dfs.datanode.data.dir'] = '#{capacity.hdfs_site['dfs.datanode.data.dir']}'\n"
          if ctx.has_any_modules 'ryba/hadoop/yarn_nm'
            ws.write "  Memory Total: #{prink.filesize capacity.total_memory, 3}\n"
            ws.write "  Memory System: #{prink.filesize capacity.memory_system, 3}\n"
            ws.write "  Memory HBase: #{prink.filesize capacity.memory_hbase, 3}\n"
            ws.write "  Memory YARN: #{prink.filesize capacity.memory_yarn, 3}\n"
            ws.write "  Number of Cores: #{capacity.cores}\n"
            ws.write "  Number of Containers: #{capacity.max_number_of_containers}\n"
            ws.write "  Memory per Containers: #{prink.filesize capacity.memory_per_container, 3}\n"
          if ctx.has_any_modules 'ryba/hadoop/yarn_rm'
            ws.write "  YARN ResourceManager\n"
            print 'capacity_scheduler', ['yarn.scheduler.capacity.resource-calculator']
            print 'yarn_site', ['yarn.scheduler.minimum-allocation-mb', 'yarn.scheduler.maximum-allocation-mb', 'yarn.scheduler.minimum-allocation-vcores', 'yarn.scheduler.maximum-allocation-vcores']
            # ws.write "    capacity-scheduler['yarn.scheduler.capacity.resource-calculator'] = '#{capacity.capacity_scheduler['yarn.scheduler.capacity.resource-calculator']}'"
            # ws.write "    yarn-site['yarn.scheduler.minimum-allocation-mb'] = '#{capacity.yarn_site['yarn.scheduler.minimum-allocation-mb']}'"
            # ws.write "    yarn-site['yarn.scheduler.maximum-allocation-mb'] = '#{capacity.yarn_site['yarn.scheduler.maximum-allocation-mb']}'"
            # ws.write "    yarn-site['yarn.scheduler.minimum-allocation-vcores'] = '#{capacity.yarn_site['yarn.scheduler.minimum-allocation-vcores']}'"
            # ws.write "    yarn-site['yarn.scheduler.maximum-allocation-vcores'] = '#{capacity.yarn_site['yarn.scheduler.maximum-allocation-vcores']}'"
          if ctx.has_any_modules 'ryba/hadoop/yarn_nm'
            ws.write "  YARN NodeManager\n"
            print 'yarn_site', ['yarn.nodemanager.resource.memory-mb', 'yarn.nodemanager.vmem-pmem-ratio', 'yarn.nodemanager.resource.cpu-vcores', 'yarn.nodemanager.local-dirs', 'yarn.nodemanager.log-dirs']
            # ws.write "    yarn-site['yarn.nodemanager.resource.memory-mb'] = '#{capacity.yarn_site['yarn.nodemanager.resource.memory-mb']}'"
            # ws.write "    yarn-site['yarn.nodemanager.vmem-pmem-ratio'] = '#{capacity.yarn_site['yarn.nodemanager.vmem-pmem-ratio']}'"
            # ws.write "    yarn-site['yarn.nodemanager.resource.cpu-vcores'] = '#{capacity.yarn_site['yarn.nodemanager.resource.cpu-vcores']}'"
            # ws.write "    yarn-site['yarn.nodemanager.local-dirs'] = '#{capacity.yarn_site['yarn.nodemanager.local-dirs']}'"
            # ws.write "    yarn-site['yarn.nodemanager.log-dirs'] = '#{capacity.yarn_site['yarn.nodemanager.log-dirs']}'"
          if ctx.has_any_modules 'ryba/hadoop/mapred_client'
            ws.write "  MapReduce Client\n"
            print 'mapred_site', ['yarn.app.mapreduce.am.resource.mb', 'yarn.app.mapreduce.am.command-opts', 'mapreduce.map.memory.mb', 'mapreduce.map.java.opts', 'mapreduce.reduce.memory.mb', 'mapreduce.reduce.java.opts', 'mapreduce.task.io.sort.mb', 'mapreduce.map.cpu.vcores', 'mapreduce.reduce.cpu.vcores']
          if ctx.has_any_modules 'ryba/hive/client'
            ws.write "  Hive Client\n"
            print 'hive_site', ['hive.tez.container.size', 'hive.tez.container.size', 'hive.tez.java.opts']
        do_end ws
      do_end = (ws) ->
        ws.end() if config.params.save
        next()
      do_open()


    exports.write_json = (config, ctxs, next) ->
      do_open = ->
        return do_write process.stdout unless config.params.save
        return next() unless config.params.save
        fs.stat config.params.save, (err, stat) ->
          return next err if err and err.code isnt 'ENOENT'
          return next Error 'File Already Exists, use --overwrite' unless err or config.params.overwrite
          do_write fs.createWriteStream config.params.save, encoding: 'utf8'
      do_write = (ws) ->
        servers = exports.capacity_to_ryba ctxs
        ws.write JSON.stringify servers, null, 2
      do_end = (ws) ->
        ws.end() if config.params.save
        next()
      do_open()

    exports.write_js = (config, ctxs, next) ->
      do_open = ->
        return do_write process.stdout unless config.params.save
        return next() unless config.params.save
        fs.stat config.params.save, (err, stat) ->
          return next err if err and err.code isnt 'ENOENT'
          return next Error 'File Already Exists, use --overwrite' unless err or config.params.overwrite
          do_write fs.createWriteStream config.params.save, encoding: 'utf8'
      do_write = (ws) ->
        servers = exports.capacity_to_ryba ctxs
        source = JSON.stringify servers, null, 2
        source = "module.exports = #{source};"
        ws.write source
      do_end = (ws) ->
        ws.end() if config.params.save
        next()
      do_open()

    exports.write_coffee = (config, ctxs, next) ->
      do_open = ->
        return do_write process.stdout unless config.params.save
        return next() unless config.params.save
        fs.stat config.params.save, (err, stat) ->
          return next err if err and err.code isnt 'ENOENT'
          return next Error 'File Already Exists, use --overwrite' unless err or config.params.overwrite
          do_write fs.createWriteStream config.params.save, encoding: 'utf8'
      do_write = (ws) ->
        servers = exports.capacity_to_ryba ctxs
        source = JSON.stringify servers
        source = "module.exports = #{source}"
        ws.write js2coffee.build(source).code
      do_end = (ws) ->
        ws.end() if config.params.save
        next()
      do_open()

    exports.write_xml = (config, ctxs, next) ->
      servers = exports.capacity_to_ryba ctxs
      console.log 'xml'
      next()

    exports.capacity_to_ryba = (ctxs) ->
      servers = {}
      for ctx in ctxs
        {capacity} = ctx.config
        server = ryba: {}
        if ctx.has_any_modules 'ryba/hadoop/yarn_rm'
          server.ryba.yarn ?= {}
          server.ryba.yarn.site = capacity.yarn_site
          server.ryba.yarn.capacity_scheduler = capacity.capacity_scheduler
        if ctx.has_any_modules 'ryba/hadoop/yarn_nm'
          server.ryba.yarn ?= {}
          server.ryba.yarn.site = capacity.yarn_site
        if ctx.has_any_modules 'ryba/hadoop/mapred_client'
          server.ryba.mapred ?= {}
          server.ryba.mapred.site = capacity.mapred_site
        if ctx.has_any_modules 'ryba/hive/client'
          server.ryba.hive ?= {}
          server.ryba.hive.site = capacity.hive_site
        servers[ctx.config.host] = server
      servers


## Resources

*   [HDP Configuration Utils](https://github.com/hortonworks/hdp-configuration-utils/blob/master/2.1/hdp-configuration-utils.py)
*   [12 key steps to keep your Hadoop Cluster running strong and performing optimum](https://cloudcelebrity.wordpress.com/2013/08/14/12-key-steps-to-keep-your-hadoop-cluster-running-strong-and-performing-optimum/)
*   [Commonly Used Yarn Memory Settings](http://blogs.msdn.com/b/bigdatasupport/archive/2014/11/11/some-commonly-used-yarn-memory-settings.aspx)
*   [How to Plan and Configure YARN and MapReduce](http://hortonworks.com/blog/how-to-plan-and-configure-yarn-in-hdp-2-0/)
*   [Avoiding 6 Time-Consuming "Gotchas"](blog.cloudera.com/blog/2014/04/apache-hadoop-yarn-avoiding-6-time-consuming-gotchas/)


## Dependencies

    fs = require 'fs'
    run = require 'masson/lib/run'
    {merge} = require 'mecano/lib/misc'
    parameters = require 'parameters'
    each = require 'each'
    prink = require 'prink'
    path = require 'path'
    js2coffee = require 'js2coffee'
    properties = require './properties'





