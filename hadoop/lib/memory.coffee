
{merge} = require 'mecano/lib/misc'

# https://github.com/hortonworks/hdp-configuration-utils/blob/master/2.1/hdp-configuration-utils.py

memory = (ctx) ->
  {yarn, hadoop_conf_dir} = ctx.config.hdp
  yarn_site = yarn
  # yarn.nodemanager.log.retain-seconds (cherif mettre la valeur à 10800 au lie de 604800)
  # yarn.log-aggregation.retain-seconds (cherif)

  # Follow [Hortonworks example](http://hortonworks.com/blog/how-to-plan-and-configure-yarn-in-hdp-2-0/)
  # As a general recommendation, Hortonworks found that allowing for 1-2 
  # Containers per disk and per core gives the best balance for cluster utilization.
  # Each machine in our cluster has 96 GB of RAM. Some of this RAM should be 
  # reserved for Operating System usage. On each node, we’ll reserve 10% 
  # with a maximum of 8 GB for the Operating System.
  coreNumber = ctx.cpuinfo.length
  diskNumber = yarn_site['yarn.nodemanager.local-dirs'].length
  memoryTotalMb = Math.floor ctx.meminfo.MemTotal / 1000 / 1000
  memoryAvailableMb = memoryTotalMb - memory.getReservedMemory(memoryTotalMb, false)
  # minimum container size (in RAM)
  mininumContainerSize = memory.getMininumContainerSize memoryAvailableMb
  # Maximum number of containers allowed per node:
  # min (2*CORES, 1.8*DISKS, (Total available RAM / MIN_CONTAINER_SIZE) )
  maxNumberOfcontainers = Math.floor Math.min coreNumber*2, diskNumber * 1.8, (memoryAvailableMb / mininumContainerSize)
  # Amount of RAM per container
  # max(MIN_CONTAINER_SIZE, (Total Available RAM) / containers))
  memoryPerContainer = Math.floor Math.max mininumContainerSize, memoryAvailableMb / maxNumberOfcontainers
  # Get default
  yarnNodeManagerResourceMemoryMb = ['yarn.nodemanager.resource.memory-mb']
  YarnNodemanagerVirtualMemoryRatio = yarn_site['yarn.nodemanager.vmem-pmem-ratio']
  yarnSchedulerMinimumAllocationMb = yarn_site['yarn.scheduler.minimum-allocation-mb']
  yarnSchedulerMaximumAllocationMb = yarn_site['yarn.scheduler.maximum-allocation-mb']
  yarnAppMapreduceAmResourceMb = yarn_site['yarn.app.mapreduce.am.resource.mb']
  yarnAppMapreduceAmCommandOpts = /-Xmx(.*)m/.exec(yarn_site['yarn.app.mapreduce.am.command-opts'])?[1]
  # Compute
  yarnNodeManagerResourceMemoryMb ?= maxNumberOfcontainers * memoryPerContainer
  yarnSchedulerMinimumAllocationMb ?= memoryPerContainer
  yarnSchedulerMaximumAllocationMb ?= maxNumberOfcontainers * memoryPerContainer # containers * RAM-per-container
  yarnAppMapreduceAmResourceMb ?= 2 * memoryPerContainer # 2 * RAM-per-container
  yarnAppMapreduceAmCommandOpts ?= Math.floor(.8 * 2 * memoryPerContainer) # 0.8 * 2 * RAM-per-container
  YarnNodemanagerVirtualMemoryRatio ?= 2.1 # Virtual memory (physical + paged memory) upper limit for each Map and Reduce task
  mapreduceMapMemoryMb = memoryPerContainer
  mapreduceReduceMemoryMb = 2 * memoryPerContainer # 2 * RAM-per-container
  # Constrain
  yarnAppMapreduceAmResourceMb = Math.min yarnAppMapreduceAmResourceMb, yarnSchedulerMaximumAllocationMb
  yarnAppMapreduceAmCommandOpts = Math.min yarnAppMapreduceAmCommandOpts, yarnSchedulerMaximumAllocationMb
  mapreduceMapMemoryMb = Math.min mapreduceMapMemoryMb, yarnSchedulerMaximumAllocationMb # RAM-per-container cannot exceed YARN maximum allocation, example: "Invalid resource request, requested memory < 0, or requested memory > max configured, requestedMemory=1922, maxMemory=1800"
  mapreduceReduceMemoryMb = Math.min mapreduceReduceMemoryMb, yarnSchedulerMaximumAllocationMb # RAM per reduce task cannot exceed YARN minimum allocation, example: "REDUCE capability required is more than the supported max container capability in the cluster. Killing the Job. reduceResourceReqt: 3844 maxContainerCapability:1922"
  result =
    info:
      'coreNumber': coreNumber
      'diskNumber': diskNumber
      'memoryTotalMb': memoryTotalMb
      'memoryAvailableMb': memoryAvailableMb
      'mininumContainerSize': mininumContainerSize
      'maxNumberOfcontainers': maxNumberOfcontainers
      'memoryPerContainer': memoryPerContainer
    yarn_site:
      'yarn.nodemanager.resource.memory-mb': "#{yarnNodeManagerResourceMemoryMb}" # containers * RAM-per-container
      'yarn.nodemanager.vmem-pmem-ratio': "#{YarnNodemanagerVirtualMemoryRatio}"
      'yarn.scheduler.minimum-allocation-mb': "#{yarnSchedulerMinimumAllocationMb}" # RAM-per-container
      'yarn.scheduler.maximum-allocation-mb': "#{yarnSchedulerMaximumAllocationMb}"
      'yarn.app.mapreduce.am.resource.mb': "#{yarnAppMapreduceAmResourceMb}"
      'yarn.app.mapreduce.am.command-opts': "-Xmx#{yarnAppMapreduceAmCommandOpts}m"
    mapred_site:
      'mapreduce.map.memory.mb': "#{mapreduceMapMemoryMb}"
      'mapreduce.reduce.memory.mb': "#{mapreduceReduceMemoryMb}"
      'mapreduce.map.java.opts': "-Xmx#{Math.floor .8 * memoryPerContainer}m" # 0.8 * RAM-per-container
      'mapreduce.reduce.java.opts': "-Xmx#{Math.floor .8 * 2 * memoryPerContainer}m" # 0.8 * 2 * RAM-per-container
      'mapreduce.task.io.sort.mb': "#{Math.floor .4 * memoryPerContainer}"
  # merge result.yarn_site, ctx.config.hdp.yarn
  for k, v of result.yarn_site
    result.yarn_site[k] = ctx.config.hdp.yarn[k] if ctx.config.hdp.yarn[k]?
  # merge result.mapred_site, ctx.config.hdp.mapred
  for k, v of result.mapred_site
    result.mapred_site[k] = ctx.config.hdp.mapred[k] if ctx.config.hdp.mapred[k]?
  result

memory.reservedStack = 4:1, 8:2, 16:2, 24:4, 48:6, 64:8, 72:8, 96:12, 128:24, 256:32, 512:64

memory.reservedHBase = 4:1, 8:1, 16:2, 24:4, 48:8, 64:8, 72:8, 96:16, 128:24, 256:32, 512:64

memory.getReservedMemory = (memory_mb, withHBase=false) ->
  reservedMemory = 0
  if memory_mb < memory.reservedStack[0]
    reservedMemory += memory.reservedStack[0]
  else if memory_mb >= memory.reservedStack[memory.reservedStack.length-1]
    reservedMemory += memory.reservedStack[memory.reservedStack.length-1]
  else
    for total, reserved of memory.reservedStack
      if memory_mb < total
        reservedMemory += Math.ceil memory_mb * reserved / total
        break
  if withHBase
    if memory_mb < memory.reservedHBase[0]
      reservedMemory += memory.reservedHBase[0]
    else if memory_mb >= memory.reservedHBase[memory.reservedHBase.length-1]
      reservedMemory += memory.reservedHBase[memory.reservedHBase.length-1]
    else
      for total, reserved of memory.reservedHBase
        if memory_mb < total
          reservedMemory += Math.ceil memory_mb * reserved / total
          break
  reservedMemory

memory.getMininumContainerSize = (memory_mb) ->
  if memory_mb <= 4*1024 then 256
  else if memory_mb <= 8*1024 then 512
  else if memory_mb <= 24*1024 then 1024
  else 2048

module.exports = memory
