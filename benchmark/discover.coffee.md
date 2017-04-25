
# Benchmark discovery

For each given datanode, discover count of CPUs, total RAM and count of disks.

    module.exports = header: 'Benchmark - Discovery', handler: (_, callback) ->
      {benchmark} = @config.ryba
      
      @each benchmark.datanodes, (options) ->
        datanode = options.key
        

## Discover CPU & RAM
          
        @system.execute
          cmd: """
            curl --fail -H "Content-Type: application/json" -k \
            -X GET #{datanode.urls.system}
          """
        , (err, execute, stdout) ->
          throw err if err
          
          data = JSON.parse stdout
          throw Error "Invalid Response" unless /^java.lang:type=OperatingSystem/.test data?.beans[0]?.name
          
          {AvailableProcessors, TotalPhysicalMemorySize} = data.beans[0]
          datanode.cpus = AvailableProcessors
          datanode.ram = TotalPhysicalMemorySize


## Discover Disks count

        @system.execute
          cmd: """
            curl --fail -H "Content-Type: application/json" -k \
            -X GET #{datanode.urls.disks}
          """
        , (err, execute, stdout) ->
          throw err if err
          data = JSON.parse stdout
          throw Error "Invalid Response" unless /^Hadoop:service=DataNode,name=DataNodeInfo/.test data?.beans[0]?.name
          {VolumeInfo, Version} = data.beans[0]
          datanode.disks = Object.keys(JSON.parse VolumeInfo).length
          if Version.indexOf("cdh") != -1
            benchmark.jars.current = benchmark.jars.cloudera 
          else benchmark.jars.current = benchmark.jars.hortonworks
          
      @then () ->


## Prepare TeraSort benchmarks

Generate the official GraySort input data set. The user 
specifies the number of rows and the output directory and this class runs a 
map/reduce program to generate the data. The format of the data is:

*   100 bytes: (10 bytes key) (constant 2 bytes) (32 bytes rowid) (constant 4 bytes) (48 bytes filler) (constant 4 bytes)
*   The rowid is the right justified row id as a hex number.

Tests are run with half the total number of disks, the total of disk and 5 times
the total of disks. Generated data size are: 1GB, 10GB, 100GB 1TB

        total_disks = benchmark.datanodes.length * benchmark.datanodes[0].disks
        benchmark.terasort.parameters = []
        for disks_count in [total_disks/2, total_disks, total_disks*5]
             
          # 1GB of data
          benchmark.terasort.parameters.push
            maps: disks_count
            rows: Math.pow(1024, 3) 
            
          # 10GB of data
          benchmark.terasort.parameters.push
            maps: disks_count
            rows: Math.pow(1024, 3) * 10
          #   
          # # 100GB of data
          benchmark.terasort.parameters.push
            maps: disks_count
            rows: Math.pow(1024, 3) * 100
            
          # # 1TB of data
          benchmark.terasort.parameters.push
            maps: disks_count
            rows: Math.pow(1024, 4)


## Create ouptut directory

        @system.mkdir 
          ssh: null 
          target: benchmark.output 
          
        callback()


## Imports

    each = require 'each'
        
