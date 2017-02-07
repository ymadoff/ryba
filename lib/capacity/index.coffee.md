
# Capacity Planning for Hadoop Cluster

Capacity planning is the science and art of estimating the space, computer
hardware, software and connection infrastructure resources that will be needed
over some future period of time.

In the Hadoop context of this script, Capacity Planning is about discovering
the Memory, Disk and CPU resources for every node of the cluster and estimating
default setting for Yarn and its client application such as MapReduce or Tez.

## Source Code

    exports = module.exports = (params, config, callback) ->
      exports.contexts params, config, (err, contexts) ->
        return callback err if err
        return callback Error 'No Node Configured' unless Object.keys(contexts).length
        each [
          'configure', 'disks', 'cores', 'memory'
          'yarn_nm', 'yarn_rm'
          'hdfs_client', 'hdfs_nn', 'hdfs_dn'
          'hbase_m', 'hbase_rs'
          'mapred_client', 'nifi','tez_client'
          'hive_client', 'kafka_broker'
          'remote' ]
        .call (handler, next) ->
          console.log "#{handler}: ok"
          handler = exports[handler]
          if handler.length is 2
            handler contexts, next
          else
            handler contexts
            next()
        .then (err) ->
          # ctx.emit 'end' for ctx in contexts
          return console.log 'ERROR', err.message, err.stack if err
          exports.write params, config, contexts, (err) ->
            return console.log 'ERROR', err if err
            console.log 'SUCCESS'

## SSH

    exports.contexts = (params, config, next) ->
      params.end = false
      contexts = run(params, config).contexts
      each contexts
      .parallel true
      .call (context, callback) ->
        context.log.cli host: context.config.host, pad: host: 20, header: 60
        context.ssh.open context.config.ssh, host: context.config.ip or context.config.host
        context.call 'masson/core/info'
        context.then callback
      .then (err) ->
        next err, contexts

## Configuration

Normalize configuration.

    exports.configure = (ctxs) ->
      for ctx in ctxs
        ctx.config.capacity ?= {}
        ctx.config.capacity.total_memory ?= null
        ctx.config.capacity.memory_system ?= null
        ctx.config.capacity.memory_hbase ?= null
        ctx.config.capacity.memory_yarn ?= null
        ctx.config.ryba ?= {}
        ctx.config.capacity ?= {}
        ctx.config.capacity.remote ?= {}
        for conf in ['nn_hdfs_site', 'hdfs_site', 'rm_yarn_site', 'yarn_site', 'mapred_site', 'tez_site', 'hive_site', 'capacity_scheduler', 'hbase_site', 'kafka_broker','nifi_properties']
          ctx.config.capacity[conf] ?= {}
          ctx.config.capacity.remote[conf] ?= {}
        ctx.config.capacity.capacity_scheduler['yarn.scheduler.capacity.resource-calculator'] ?= 'org.apache.hadoop.yarn.util.resource.DominantResourceCalculator'

## Capacity Planning for Disks

Discover the most relevant partitions on each node.

    exports.disks = (ctxs) ->
      for ctx in ctxs
        # continue unless ctx.has_service 'ryba/hadoop/yarn_nm'
        continue if ctx.config.capacity.disks
        # Provided by user
        if ctx.params.partitions
          ctx.config.capacity.disks = ctx.params.partitions
          continue
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

## Capacity Planning for CPU

    exports.cores = (ctxs) ->
      for ctx in ctxs
        ctx.config.capacity.cores ?= ctx.cpuinfo.length
        ctx.config.capacity.cores_yarn ?= 100

## Capacity Planning for Memory

Estimates the memory available to the system, YARN and HBase. The ratio vary
depending on the total amout of memory.

    exports.memory_system_gb = [[1,.2], [2,.2], [4,1], [7,2], [8,2], [16,2], [24,4], [48,6], [64,8], [72,8], [96,12], [128,24], [256,32], [512,64]]
    exports.memory_hbase_gb = [[1,.2], [2,.4], [4,1], [8,1], [16,2], [24,4], [48,8], [64,8], [72,8], [96,16], [128,24], [256,32], [512,64]]
    exports.memory = (ctxs) ->
      for ctx in ctxs
        ctx.config.capacity.total_memory ?= ctx.meminfo.MemTotal
        continue unless ctx.has_service 'ryba/hadoop/yarn_nm'
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
            break if total_memory_gb < total
            memory_system_gb = reserved
        memory_hbase_gb = 0
        if ctx.has_service 'ryba/hbase/regionserver'
          if total_memory_gb < exports.memory_hbase_gb[0][0]
            memory_hbase_gb += exports.memory_hbase_gb[0][1] # Memory less than minimal expectation
          else if total_memory_gb >= exports.memory_hbase_gb[exports.memory_hbase_gb.length-1][0]
            memory_hbase_gb += exports.memory_hbase_gb[exports.memory_hbase_gb.length-1][1]
          else
            for mem in exports.memory_hbase_gb
              [total, reserved] = mem
              break if total_memory_gb < total
              memory_hbase_gb = reserved
        memory_system = exports.rounded_memory memory_system_gb * 1024 * 1024 * 1024
        ctx.config.capacity.memory_hbase ?= memory_hbase = exports.rounded_memory memory_hbase_gb * 1024 * 1024 * 1024
        ctx.config.capacity.memory_yarn ?= memory_yarn = exports.rounded_memory total_memory - memory_system - memory_hbase
        ctx.config.capacity.memory_system ?= total_memory - memory_hbase - memory_yarn

## Yarn NodeManager

    exports.yarn_nm = (ctxs) ->
      minimum_allocation_mb = null
      maximum_allocation_mb = 0
      maximum_allocation_vcores = 0
      for ctx in ctxs
        continue unless ctx.has_service 'ryba/hadoop/yarn_nm'
        {cores, disks, cores_yarn, memory_yarn, rm_yarn_site, yarn_site} = ctx.config.capacity

        minimum_container_size = if memory_yarn <= 2*1024*1024*1024 then 128*1024*1024 # 128 MB
        else if memory_yarn <= 4*1024*1024*1024 then 256*1024*1024 # 256 MB
        else if memory_yarn <= 8*1024*1024*1024 then 512*1024*1024 # 512 MB
        else if memory_yarn <= 24*1024*1024*1024 then 1024*1024*1024 # 1 GB
        else 2*1024*1024*1024 # 2 GB

        # min (2*CORES, 1.8*DISKS, (Total available RAM / MIN_CONTAINER_SIZE) )
        unless max_number_of_containers = ctx.config.capacity.max_number_of_containers
          # Possible incoherence, here we multiply number of cores by 2 while
          # NodeManager vcores is set to number of cores only
          max_number_of_containers = Math.floor Math.min cores * 2, disks.length * 1.8, (memory_yarn / minimum_container_size)

        # Amount of RAM per container
        # max(MIN_CONTAINER_SIZE, (Total Available RAM) / containers))
        unless memory_per_container = ctx.config.capacity.memory_per_container
          memory_per_container = Math.floor Math.max minimum_container_size, memory_yarn / max_number_of_containers

        # # Work with small VM
        # if memory_per_container < 512 * 1024 * 1024
        #   unless max_number_of_containers = ctx.config.capacity.max_number_of_containers
        #     max_number_of_containers = Math.floor Math.min cores, disks.length, (memory_yarn / minimum_container_size)
        #   unless memory_per_container = ctx.config.capacity.memory_per_container
        #     memory_per_container = Math.floor Math.max minimum_container_size, memory_yarn / max_number_of_containers

        # Export number of containers
        ctx.config.capacity.max_number_of_containers = max_number_of_containers

        # Export RAM per container
        memory_per_container = exports.rounded_memory memory_per_container
        ctx.config.capacity.memory_per_container = memory_per_container

        minimum_allocation_mb ?= Math.round memory_per_container / 1024 / 1024
        minimum_allocation_mb = Math.round Math.min minimum_allocation_mb, memory_per_container / 1024 / 1024

Pourcent of CPU dedicated to yarn

        yarn_site['yarn.nodemanager.resource.percentage-physical-cpu-limit'] ?="#{cores_yarn}"

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

The property "yarn.nodemanager.local-dirs" defines multiple disks for
localization. It enforces fail-over, preventing one disk to affect the
containers, and load-balancing by spliting the access to the disks.

        {yarn_nm_local_dir, yarn_nm_log_dir} = ctx.params
        if /^\//.test yarn_nm_local_dir
          yarn_site['yarn.nodemanager.local-dirs'] ?= yarn_nm_local_dir.split ','
        else
          yarn_site['yarn.nodemanager.local-dirs'] ?= disks.map (disk) ->
            path.resolve disk, yarn_nm_local_dir or './yarn/local'
        if /^\//.test yarn_nm_log_dir
          yarn_site['dfs.datanode.data.dir'] ?= yarn_nm_log_dir.split ','
        else
          yarn_site['yarn.nodemanager.log-dirs'] ?= disks.map (disk) ->
            path.resolve disk, yarn_nm_log_dir or './yarn/log'

Raise the number of vcores later allocated for the ResourceManager.
        
        maximum_allocation_vcores = Math.max maximum_allocation_vcores, yarn_site['yarn.nodemanager.resource.cpu-vcores']
      
      memory_per_container_mean = for ctx in ctxs
        continue unless ctx.has_service 'ryba/hadoop/yarn_nm'
        ctx.config.capacity.memory_per_container
      memory_per_container_mean = Math.round memory_per_container_mean.reduce( (a, b) -> a + b ) / memory_per_container_mean.length

      for ctx in ctxs
        ctx.config.capacity.memory_per_container_mean = memory_per_container_mean
        ctx.config.capacity.minimum_allocation_mb = minimum_allocation_mb
        ctx.config.capacity.maximum_allocation_mb = maximum_allocation_mb
        ctx.config.capacity.maximum_allocation_vcores = maximum_allocation_vcores


## Yarn ResourceManager

    exports.yarn_rm = (ctxs) ->
      for ctx in ctxs
        continue unless ctx.has_service 'ryba/hadoop/yarn_rm'
        {minimum_allocation_mb, maximum_allocation_mb, maximum_allocation_vcores, rm_yarn_site} = ctx.config.capacity
        rm_yarn_site['yarn.scheduler.minimum-allocation-mb'] ?= minimum_allocation_mb
        rm_yarn_site['yarn.scheduler.maximum-allocation-mb'] ?= maximum_allocation_mb
        rm_yarn_site['yarn.scheduler.minimum-allocation-vcores'] ?= 1

The property "yarn.scheduler.maximum-allocation-vcores" should not be larger
than the value for the yarn.nodemanager.resource.cpu-vcores parameter on any
NodeManager. Document states that resource requests are capped at the maximum
allocation limit and a container is eventually granted. Tests in version 2.4
instead shows that the containers are never granted, and no progress is made by
the application (zombie state).

        rm_yarn_site['yarn.scheduler.maximum-allocation-vcores'] ?= maximum_allocation_vcores

## HDFS Client

    exports.hdfs_client = (ctxs) ->
      for ctx in ctxs
        continue unless ctx.has_service 'ryba/hadoop/hdfs_nn', 'ryba/hadoop/hdfs_dn', 'ryba/hadoop/hdfs_client'
        {hdfs_site} = ctx.config.capacity
        hdfs_site['dfs.replication'] ?= Math.min 3, ctx.contexts('ryba/hadoop/hdfs_dn').length # Not sure if this really is a client property

## HDFS DataNode

    exports.hdfs_dn = (ctxs) ->
      for ctx in ctxs
        continue unless ctx.has_service 'ryba/hadoop/hdfs_dn'
        {disks, hdfs_site} = ctx.config.capacity
        {hdfs_dn_data_dir} = ctx.params
        if /^\//.test hdfs_dn_data_dir
          hdfs_site['dfs.datanode.data.dir'] ?= hdfs_dn_data_dir.split ','
        else
          hdfs_site['dfs.datanode.data.dir'] ?= disks.map (disk) ->
            path.resolve disk, hdfs_dn_data_dir or './hdfs/data'

## HDFS NameNode

In HDFS High Availabity (HA) mode, we only set one name directory by default
located inside "/var/hdfs/name" because the Journal Node are responsible for
distributing logs into the passive NameNode (please get back to us if this isnt
safe enough). In non-HA mode, we store as many copies as partitions inside the 
partition "./hdfs/name" directory.

This behavior may be altered with the "hdfs_nn_name_dir" parameter.

    exports.hdfs_nn = (ctxs) ->
      for ctx in ctxs
        continue unless ctx.has_service 'ryba/hadoop/hdfs_nn'
        {disks, nn_hdfs_site} = ctx.config.capacity
        {hdfs_nn_name_dir} = ctx.params
        if /^\//.test hdfs_nn_name_dir
          nn_hdfs_site['dfs.namenode.name.dir'] ?= hdfs_nn_name_dir.split ','
        else
          if ctx.contexts('ryba/hadoop/hdfs_nn').length > 1
            nn_hdfs_site['dfs.namenode.name.dir'] ?= ['file://' + path.resolve '/var', hdfs_nn_name_dir or './hdfs/name']
          else
            nn_hdfs_site['dfs.namenode.name.dir'] ?= disks.map (disk) ->
              disk = '/var' if disk is '/'
              'file://' + path.resolve disk, hdfs_nn_name_dir or './hdfs/name'

## HBase Master

    exports.hbase_m = (ctxs) ->
      for ctx in ctxs
        continue unless ctx.has_service 'ryba/hbase/master'
        # Nothing to do for now, eg 'ryba.hbase.master_opts="..."'

## HBase RegionServer

    exports.hbase_rs = (ctxs) ->
      for ctx in ctxs
        continue unless ctx.has_service 'ryba/hbase/regionserver'
        {memory_hbase} = ctx.config.capacity
        memory_hbase_mb = Math.floor memory_hbase / 1024 / 1024
        ctx.config.capacity.regionserver_opts ?= "#{memory_hbase_mb}m" #i.e. 256m

## MapReduce Client

    exports.mapred_client = (ctxs) ->
      for ctx in ctxs
        continue unless ctx.has_service 'ryba/hadoop/mapred_client'
        {memory_per_container_mean, minimum_allocation_mb, maximum_allocation_mb, mapred_site} = ctx.config.capacity
        memory_per_container_mean_mb = Math.round memory_per_container_mean / 1024 / 1024

The property "yarn.app.mapreduce.am.resource.mb" defines the amount of memory
that the Application Master for MR framework would need. This needs to be set
with care as a larger allocation for the AM would mean lesser concurrency, as
you can spin up only so many AMs before exhausting the containers on a busy
system. This value also needs to be less than what is defined in
"yarn.scheduler.maximum-allocation-mb", if not, it will create an error
condition.  Can be set at site level with "mapred-site.xml", or
can be set at the job level. This change does not require a service restart.

        getAmMb = ->
          memory_per_container_mean_mb / 2
          # am_mb = memory_per_container_mean_mb
          # if am_mb < 1024
          #   am_mb = Math.max minimum_allocation_mb, 256
          # if memory_per_container_mean_mb > 1024 then 2 * memory_per_container_mean_mb else memory_per_container_mean_mb
        mapreduce_am_memory_mb = mapred_site['yarn.app.mapreduce.am.resource.mb'] or getAmMb()
        mapreduce_am_memory_mb = Math.min mapreduce_am_memory_mb, maximum_allocation_mb
        mapred_site['yarn.app.mapreduce.am.resource.mb'] = mapreduce_am_memory_mb

        mapreduce_am_opts = /-Xmx(.*?)m/.exec(mapred_site['yarn.app.mapreduce.am.command-opts'])?[1] or Math.floor .8 * mapreduce_am_memory_mb
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

## Tez

    exports.tez_client = (ctxs) ->
      for ctx in ctxs
        continue unless ctx.has_service 'ryba/tez' or ctx.has_service('ryba/hive/server2')
        continue unless ctx.config.ryba.hive.server2?.site['hive.execution.engine'] is 'tez'
        {mapred_site, tez_site} = ctx.config.capacity
        # Memory allocated for the Application Master
        tez_site['tez.am.resource.memory.mb'] ?= mapred_site['yarn.app.mapreduce.am.resource.mb']
        # Memory allocated for the task
        tez_site['tez.task.resource.memory.mb'] ?= mapred_site['mapreduce.map.memory.mb']
        tez_site['tez.runtime.io.sort.mb'] ?= mapred_site['mapreduce.task.io.sort.mb']

## Hive Client

    exports.hive_client = (ctxs) ->
      for ctx in ctxs
        continue unless ctx.has_service 'ryba/hive/client'
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

## Kafka Broker

    exports.kafka_broker = (ctxs) ->
      for ctx in ctxs
        continue unless ctx.has_service 'ryba/kafka/broker'
        {disks, kafka_broker} = ctx.config.capacity
        {kafka_data_dir} = ctx.params
        if /^\//.test kafka_data_dir
          kafka_broker['log.dirs'] ?= kafka_data_dir.split ','
        else
          kafka_broker['log.dirs'] ?= disks.map (disk) ->
            path.resolve disk, kafka_data_dir or './kafka'

## Nifi

    exports.nifi = (ctxs) ->
      for ctx in ctxs
        continue unless ctx.has_service 'ryba/nifi'
        {disks, nifi_properties} = ctx.config.capacity
        {nifi_content_dir,nifi_provenance_dir} = ctx.params
        if (nifi_content_dir? and nifi_max_partition?) or (nifi_content_dir? and nifi_max_partition?)
          throw Error 'Can not use conjointly nifi content/provenance dir and nifi_max_partition options'
        nifi_max_partition = ctx.params.nifi_max_partition ?= disks.length
        #Content Repository directories
        if /^\//.test nifi_content_dir
          for k,dir of nifi_content_dir.split ','
            nifi_properties["nifi.content.repository.directory.cr#{k+1}"] = dir
        else
          target_dirs = disks.map (disk) ->
            path.resolve disk, nifi_content_dir or './nifi/content_repository'
          for k in [0..Math.min(target_dirs.length,nifi_max_partition-1)]
            dir = target_dirs[k]
            nifi_properties["nifi.content.repository.directory.cr#{k+1}"] = dir
        #Provenance Repository directories
        if /^\//.test nifi_provenance_dir
          for k,dir of nifi_provenance_dir.split ','
            nifi_properties["nifi.provenance.repository.directory.pr#{k+1}"] = dir
        else
          target_dirs = disks.map (disk) ->
            path.resolve disk, nifi_provenance_dir or './nifi/provenance_repository'
          for k in [0..Math.min(target_dirs.length,nifi_max_partition-1)]
            dir = target_dirs[k]
            nifi_properties["nifi.provenance.repository.directory.pr#{k+1}"] = dir

    exports.remote = (ctxs, next) ->
      each(ctxs)
      .parallel(true)
      .call (ctx, next) ->
        do_hdfs = ->
          return do_yarn_capacity_scheduler() unless ctx.has_service 'ryba/hadoop/hdfs_nn', 'ryba/hadoop/hdfs_dn'
          properties.read ctx.ssh, '/etc/hadoop/conf/hdfs-site.xml', (err, hdfs_site) ->
            ctx.config.capacity.remote.hdfs_site = hdfs_site unless err
            do_yarn_capacity_scheduler()
        do_yarn_capacity_scheduler = ->
          return do_yarn() unless ctx.has_service 'ryba/hadoop/yarn_nm'
          properties.read ctx.ssh, '/etc/hadoop/conf/yarn-site.xml', (err, capacity_scheduler) ->
            ctx.config.capacity.remote.capacity_scheduler = capacity_scheduler unless err
            do_yarn()
        do_yarn = ->
          return do_mapred() unless ctx.has_service 'ryba/hadoop/yarn_rm', 'ryba/hadoop/yarn_nm'
          properties.read ctx.ssh, '/etc/hadoop/conf/yarn-site.xml', (err, yarn_site) ->
            ctx.config.capacity.remote.yarn_site = yarn_site unless err
            do_mapred()
        do_mapred = ->
          return do_tez() unless ctx.has_service 'ryba/hadoop/mapred_client'
          properties.read ctx.ssh, '/etc/hadoop/conf/mapred-site.xml', (err, mapred_site) ->
            ctx.config.capacity.remote.mapred_site = mapred_site unless err
            do_tez()
        do_tez = ->
          return do_hive() unless ctx.has_service 'ryba/tez'
          properties.read ctx.ssh, '/etc/tez/conf/tez-site.xml', (err, tez_site) ->
            ctx.config.capacity.remote.tez_site = tez_site unless err
            do_hive()
        do_hive = ->
          return do_kafka_broker() unless ctx.has_service 'ryba/hive/client'
          properties.read ctx.ssh, '/etc/hive/conf/hive-site.xml', (err, hive_site) ->
            ctx.config.capacity.remote.hive_site = hive_site unless err
            do_kafka_broker()
        do_kafka_broker = ->
          return do_nifi() unless ctx.has_service 'ryba/kafka/broker'
          ssh2fs.readFile ctx.ssh, '/etc/kafka-broker/conf/broker.properties', 'ascii', (err, content) ->
            return do_end() if err
            properties = {}
            for line in string.lines content
              continue if /^#.*$/.test line
              continue unless /.+=.+/.test line
              [key, value] = line.split '='
              properties[key.trim()] = value.trim()
            properties
            ctx.config.capacity.remote.kafka_broker = properties
            do_nifi()
        do_nifi = ->
          return do_end() unless ctx.has_service 'ryba/nifi'
          ssh2fs.readFile ctx.ssh, '/etc/nifi/conf/nifi.properties', 'ascii', (err, content) ->
            return do_end() if err
            properties = {}
            for line in string.lines content
              continue if /^#.*$/.test line
              continue unless /.+=.+/.test line
              [key, value] = line.split '='
              properties[key.trim()] = value.trim()
            properties
            ctx.config.capacity.remote.nifi_properties = properties
        # do_hbase = ->
        #   return do_end() unless ctx.has_service 'ryba/hbase/regionserver'
        #   properties.read ctx.ssh, '/etc/hive/conf/hbase-site.xml', (err, hive_site) ->
        #     ctx.config.capacity.remote.hive_site = hive_site unless err
        #     do_end()
        do_end = ->
          ctx.options.ssh.end()
          ctx.options.ssh.on 'end', next
        do_hdfs()
      .then next

    exports.write = (params, config, ctxs, next) ->
      # return next() unless params.output
      formats = ['xml', 'json', 'js', 'coffee']
      if params.format is 'text'
        # ok, print to stdout
      else if params.format
        return next Error "Insupported Extension #{extname}" unless params.format in formats
        # unless params.output
        #   # ok, print to stdout
        # else if (basename = path.basename(params.output, ".#{params.format}")) isnt params.output
        #   params.output = "#{basename}.#{params.format}" if params.format in ['json', 'js', 'coffee']
      else if params.output
        extname = path.extname params.output
        format = extname.substr 1
        return next Error "Could not guess format from arguments" unless format in formats
        params.format = format
      else
        params.format = 'text'
      exports["write_#{params.format}"] params, config, ctxs, (err, content) ->
        next err

    exports.write_text = (params, config, ctxs, next) ->
      do_open = ->
        return do_write process.stdout unless params.output
        return next() unless params.output
        fs.stat params.output, (err, stat) ->
          return next err if err and err.code isnt 'ENOENT'
          return next Error 'File Already Exists, use --overwrite' unless err or params.overwrite
          do_write fs.createWriteStream params.output, encoding: 'utf8'
      do_write = (ws) ->
        print = (config, properties) ->
          {capacity} = ctx.config
          for property in properties
            suggested_value = capacity[config][property]
            remote_value = capacity.remote[config][property]
            if Array.isArray suggested_value
              ws.write "    #{config}['#{property}'] = [\n"
              for v, i in suggested_value
                ws.write "      " if i % 3 is 0
                ws.write "#{v}"
                if i % 3 is 2 and i isnt suggested_value.length - 1
                  ws.write "\n" 
                else if i isnt suggested_value.length - 1
                  ws.write ', '
              ws.write "\n    ]"
              remote_value = remote_value.split(',') if typeof remote_value is 'string'
              if suggested_value.join(',') isnt remote_value?.join(',')
                ws.write " (currently [\n"
                if remote_value then for v, i in remote_value
                  ws.write "      " if i % 3 is 0
                  ws.write "#{v}"
                  if i % 3 is 2 and i isnt suggested_value.length# - 1
                    ws.write "\n" 
                  else if i isnt suggested_value.length# - 1
                    ws.write ', '
                else
                  ws.write '      undefined'
                ws.write "\n    ])"
              ws.write "\n"
            else
              diff = if remote_value is "#{suggested_value}" then 'identical'
              else if remote_value? then "'#{remote_value}'"
              else 'not defined'
              diff = "(currently #{diff})"
              ws.write "    #{config}['#{property}'] = '#{suggested_value}' #{diff}\n"
        for ctx in ctxs
          continue if params.hosts and not multimatch(params.hosts, ctx.config.host).length
          {capacity} = ctx.config
          # mods = [
          #   'ryba/hadoop/hdfs_nn', 'ryba/hadoop/hdfs_dn'
          #   'ryba/hadoop/yarn_rm', 'ryba/hadoop/yarn_nm'
          #   'ryba/hadoop/mapred_client', 'ryba/hadoop/hive_client'
          # ]
          # if ctx.has_service mods
          ws.write "#{ctx.config.host}\n"
          ws.write "  Number of core: #{capacity.cores}\n"
          ws.write "  Number of partitions: #{capacity.disks.length}\n"
          ws.write "  Memory Total: #{prink.filesize capacity.total_memory, 3}\n"
          ws.write "  Memory System: #{prink.filesize capacity.memory_system, 3}\n"
          print_hdfs_client = not params.modules or multimatch(params.modules, 'ryba/hadoop/hdfs_client').length
          if ctx.has_service('ryba/hadoop/hdfs_client') and print_hdfs_client
            ws.write "  HDFS Client\n"
            print 'hdfs_site', ['dfs.replication']
          print_hdfs_nn = not params.modules or multimatch(params.modules, 'ryba/hadoop/hdfs_nn').length
          if ctx.has_service('ryba/hadoop/hdfs_nn') and print_hdfs_nn
            ws.write "  HDFS NameNode\n"
            print 'nn_hdfs_site', ['dfs.namenode.name.dir']
          print_hdfs_dn = not params.modules or multimatch(params.modules, 'ryba/hadoop/hdfs_dn').length
          if ctx.has_service('ryba/hadoop/hdfs_dn') and print_hdfs_dn
            ws.write "  HDFS DataNode\n"
            print 'hdfs_site', ['dfs.datanode.data.dir']
          print_yarn_rm = not params.modules or multimatch(params.modules, 'ryba/hadoop/yarn_rm').length
          if ctx.has_service('ryba/hadoop/yarn_rm') and print_yarn_rm
            ws.write "  YARN ResourceManager\n"
            print 'capacity_scheduler', ['yarn.scheduler.capacity.resource-calculator']
            print 'rm_yarn_site', ['yarn.scheduler.minimum-allocation-mb', 'yarn.scheduler.maximum-allocation-mb', 'yarn.scheduler.minimum-allocation-vcores', 'yarn.scheduler.maximum-allocation-vcores']
          print_yarn_nm = not params.modules or multimatch(params.modules, 'ryba/hadoop/yarn_nm').length
          if ctx.has_service('ryba/hadoop/yarn_nm') and print_yarn_nm
            ws.write "  YARN NodeManager\n"
            ws.write "  Memory YARN: #{prink.filesize capacity.memory_yarn, 3}\n"
            ws.write "  Number of Cores: #{capacity.cores}\n"
            ws.write "  Number of Containers: #{capacity.max_number_of_containers}\n"
            ws.write "  Memory per Containers: #{prink.filesize capacity.memory_per_container, 3}\n"
            print 'yarn_site', ['yarn.nodemanager.resource.memory-mb', 'yarn.nodemanager.vmem-pmem-ratio', 'yarn.nodemanager.resource.cpu-vcores', 'yarn.nodemanager.local-dirs', 'yarn.nodemanager.log-dirs']
          print_mapred_client = not params.modules or multimatch(params.modules, 'ryba/hadoop/mapred_client').length
          if ctx.has_service('ryba/hadoop/mapred_client') and print_mapred_client
            ws.write "  MapReduce Client\n"
            print 'mapred_site', ['yarn.app.mapreduce.am.resource.mb', 'yarn.app.mapreduce.am.command-opts', 'mapreduce.map.memory.mb', 'mapreduce.map.java.opts', 'mapreduce.reduce.memory.mb', 'mapreduce.reduce.java.opts', 'mapreduce.task.io.sort.mb', 'mapreduce.map.cpu.vcores', 'mapreduce.reduce.cpu.vcores']
          print_tez_client = not params.modules or multimatch(params.modules, 'ryba/tez').length
          if ctx.has_service('ryba/tez') and print_tez_client
            ws.write "  Tez Client\n"
            print 'tez_site', ['tez.am.resource.memory.mb', 'tez.task.resource.memory.mb', 'tez.runtime.io.sort.mb']
          print_hive_client = not params.modules or multimatch(params.modules, 'ryba/hadoop/hive_client').length
          if ctx.has_service('ryba/hive/client') and print_hive_client
            ws.write "  Hive Client\n"
            print 'hive_site', ['hive.tez.container.size', 'hive.tez.java.opts']
          print_hbase_regionserver = not params.modules or multimatch(params.modules, 'ryba/hadoop/regionserver').length
          if ctx.has_service('ryba/hbase/regionserver') and print_hbase_regionserver
            ws.write "  Memory HBase: #{prink.filesize capacity.memory_hbase, 3}\n"
            ws.write "  HBase RegionServer\n"
            {regionserver_opts} = ctx.config.capacity
            ws.write "    hbase-env: -Xms#{regionserver_opts} -Xmx#{regionserver_opts}\n"
          print_kafka_broker = not params.modules or multimatch(params.modules, 'ryba/kafka/broker').length
          if ctx.has_service('ryba/kafka/broker') and print_kafka_broker
            ws.write "  Kafka Broker\n"
            print 'kafka_broker', ['log.dirs']
          print_nifi = not params.modules or multimatch(params.modules, 'ryba/nifi').length
          if ctx.has_service('ryba/nifi')
            print 'nifi_properties', 'Content/Provenance Repositories'
            ws.write "  Nifi\n", capacity.nifi_properties
        do_end ws
      do_end = (ws) ->
        ws.end() if params.output
        next()
      do_open()

    exports.write_json = (params, config, ctxs, next) ->
      do_open = ->
        return do_write process.stdout unless params.output
        return next() unless params.output
        fs.stat params.output, (err, stat) ->
          return next err if err and err.code isnt 'ENOENT'
          return next Error 'File Already Exists, use --overwrite' unless err or params.overwrite
          do_write fs.createWriteStream params.output, encoding: 'utf8'
      do_write = (ws) ->
        nodes = exports.capacity_to_ryba params, config, ctxs
        ws.write JSON.stringify nodes: nodes, null, 2
      do_end = (ws) ->
        ws.end() if params.output
        next()
      do_open()

    exports.write_js = (config, ctxs, next) ->
      do_open = ->
        return do_write process.stdout unless params.output
        return next() unless params.output
        fs.stat params.output, (err, stat) ->
          return next err if err and err.code isnt 'ENOENT'
          return next Error 'File Already Exists, use --overwrite' unless err or params.overwrite
          do_write fs.createWriteStream params.output, encoding: 'utf8'
      do_write = (ws) ->
        nodes = exports.capacity_to_ryba params, config, ctxs
        source = JSON.stringify nodes: nodes, null, 2
        source = "module.exports = #{source};"
        ws.write source
      do_end = (ws) ->
        ws.end() if params.output
        next()
      do_open()

    exports.write_coffee = (params, config, ctxs, next) ->
      do_open = ->
        return do_write process.stdout unless params.output
        return next() unless params.output
        fs.stat params.output, (err, stat) ->
          return next err if err and err.code isnt 'ENOENT'
          return next Error 'File Already Exists, use --overwrite' unless err or params.overwrite
          do_write fs.createWriteStream params.output, encoding: 'utf8'
      do_write = (ws) ->
        nodes = exports.capacity_to_ryba params, config, ctxs
        source = JSON.stringify nodes: nodes
        source = "module.exports = #{source}"
        argv = process.argv
        argv[1] = path.relative process.cwd(), argv[1]
        ws.write "# #{argv.join(' ')}\n"
        ws.write "\n"
        ws.write js2coffee.build(source).code
        for ctx in ctxs
          {capacity} = ctx.config
          ws.write "\n"
          ws.write "# #{ctx.config.host}\n"
          ws.write "#   Number of core: #{capacity.cores}\n"
          ws.write "#   Number of partitions: #{capacity.disks.length}\n"
          ws.write "#   Memory Total: #{prink.filesize capacity.total_memory, 3}\n"
          ws.write "#   Memory System: #{prink.filesize capacity.memory_system, 3}\n"
          print_yarn_nm = not params.modules or multimatch(params.modules, 'ryba/hbase/regionserve').length
          if ctx.has_service('ryba/hbase/regionserver') and print_yarn_nm
            ws.write "#   HBase RegionServer\n"
            ws.write "#     Memory HBase: #{prink.filesize capacity.memory_hbase, 3}\n"
          print_yarn_nm = not params.modules or multimatch(params.modules, 'ryba/hadoop/yarn_nm').length
          if ctx.has_service('ryba/hadoop/yarn_nm') and print_yarn_nm
            ws.write "#   YARN NodeManager\n"
            ws.write "#     Memory YARN: #{prink.filesize capacity.memory_yarn, 3}\n"
            ws.write "#     Number of Cores: #{capacity.cores}\n"
            ws.write "#     Number of Containers: #{capacity.max_number_of_containers}\n"
            ws.write "#     Memory per Containers: #{prink.filesize capacity.memory_per_container, 3}\n"
        do_end ws
      do_end = (ws) ->
        # ws.end() if params.output
        ws.end() # TODO, seems like we can close stdout
        next()
      do_open()

    exports.write_xml = (params, config, ctxs, next) ->
      nodes = exports.capacity_to_ryba params, config,ctxs
      next()

    exports.capacity_to_ryba = (params, config, ctxs) ->
      nodes = {}
      for ctx in ctxs
        continue if params.hosts and not multimatch(params.hosts, ctx.config.host).length
        {capacity} = ctx.config
        node = config: ryba: {}
        print_hdfs = not params.modules or multimatch(params.modules, ['ryba/hadoop/hdfs_client', 'ryba/hadoop/hdfs_nn', 'ryba/hadoop/hdfs_dn']).length
        if ctx.has_service('ryba/hadoop/hdfs_nn') and print_hdfs
          node.config.ryba.hdfs ?= {}
          node.config.ryba.hdfs.nn ?= {}
          node.config.ryba.hdfs.nn.site ?= capacity.nn_hdfs_site
        if ctx.has_service('ryba/hadoop/hdfs_client', 'ryba/hadoop/hdfs_nn', 'ryba/hadoop/hdfs_dn') and print_hdfs
          node.config.ryba.hdfs ?= {}
          node.config.ryba.hdfs.site = capacity.hdfs_site
        print_yarn_rm = not params.modules or multimatch(params.modules, 'ryba/hadoop/yarn_rm').length
        if ctx.has_service('ryba/hadoop/yarn_rm') and print_yarn_rm
          node.config.ryba.yarn ?= {}
          node.config.ryba.yarn.rm ?= {}
          node.config.ryba.yarn.rm.site = capacity.rm_yarn_site
          node.config.ryba.yarn.capacity_scheduler = capacity.capacity_scheduler
        print_yarn_nm = not params.modules or multimatch(params.modules, 'ryba/hadoop/yarn_nm').length
        if ctx.has_service('ryba/hadoop/yarn_nm') and print_yarn_nm
          node.config.ryba.yarn ?= {}
          node.config.ryba.yarn.site = capacity.yarn_site
        print_mapred_client = not params.modules or multimatch(params.modules, 'ryba/hadoop/mapred_client').length
        if ctx.has_service('ryba/hadoop/mapred_client') and print_mapred_client
          node.config.ryba.mapred ?= {}
          node.config.ryba.mapred.site = capacity.mapred_site
        print_tez_client = not params.modules or multimatch(params.modules, 'ryba/tez').length
        if ctx.has_service('ryba/tez') and print_tez_client
          node.config.ryba.tez ?= {}
          node.config.ryba.tez.site = capacity.tez_site
        print_hive_client = not params.modules or multimatch(params.modules, 'ryba/hive/client').length
        if ctx.has_service('ryba/hive/client') and print_hive_client
          node.config.ryba.hive ?= {}
          node.config.ryba.hive.site = capacity.hive_site
        print_hbase_regionserver = not params.modules or multimatch(params.modules, 'ryba/hbase/regionserver').length
        if ctx.has_service('ryba/hbase/regionserver') and print_hbase_regionserver
          node.config.ryba.hbase ?= {}
          node.config.ryba.hbase.rs ?= {}
          node.config.ryba.hbase.rs.heapsize ?= capacity.regionserver_opts
        nodes[ctx.config.host] = node
        print_kafka_broker = not params.modules or multimatch(params.modules, 'ryba/kafka/broker').length
        if ctx.has_service('ryba/kafka/broker') and print_kafka_broker
          node.config.ryba.kafka ?= {}
          node.config.ryba.kafka.broker = capacity.kafka_broker
        print_nifi = not params.modules or multimatch(params.modules, 'ryba/nifi').length
        if ctx.has_service('ryba/nifi') and print_nifi
          node.config.ryba.nifi ?= {}
          node.config.ryba.nifi.config ?= {}
          node.config.ryba.nifi.config.properties ?= capacity.nifi_properties
        nodes[ctx.config.host] = node
      nodes

    exports.rounded_memory = (memory) ->
      exports.rounded_memory_mb(memory / 1024 / 1024) * 1024 * 1024

    exports.rounded_memory_mb = (memory_mb) ->
      denominator_mb = 128
      if memory_mb > 4096
        denominator_mb = 1024
      else if memory_mb > 2048
        denominator_mb = 512
      else if memory_mb > 1024
        denominator_mb = 256
      else
        denominator_mb = 128
      Math.floor( memory_mb / denominator_mb ) * denominator_mb

## Resources

*   [HDP Configuration Utils](https://github.com/hortonworks/hdp-configuration-utils/blob/master/2.1/hdp-configuration-utils.py)
*   [12 key steps to keep your Hadoop Cluster running strong and performing optimum](https://cloudcelebrity.wordpress.com/2013/08/14/12-key-steps-to-keep-your-hadoop-cluster-running-strong-and-performing-optimum/)
*   [Commonly Used Yarn Memory Settings](http://blogs.msdn.com/b/bigdatasupport/archive/2014/11/11/some-commonly-used-yarn-memory-settings.aspx)
*   [How to Plan and Configure YARN and MapReduce](http://hortonworks.com/blog/how-to-plan-and-configure-yarn-in-hdp-2-0/)
*   [Avoiding 6 Time-Consuming "Gotchas"](http://blog.cloudera.com/blog/2014/04/apache-hadoop-yarn-avoiding-6-time-consuming-gotchas/)


## Dependencies

    fs = require 'fs'
    ssh2fs = require 'ssh2-fs'
    run = require 'masson/lib/run'
    {merge} = require 'mecano/lib/misc'
    string = require 'mecano/lib/misc/string'
    parameters = require 'parameters'
    multimatch = require 'multimatch'
    each = require 'each'
    prink = require 'prink'
    path = require 'path'
    js2coffee = require 'js2coffee'
    properties = require '../properties'
