
# TeraSort benchmark 

MapReduce tera tests ensure that MR is running correctly.

Depending on the parameters and the numbers of time it is ran in a row, the test
suite can be used to assess regularity, balance or workload on a cluster.

    module.exports = header: 'Benchmark', handler: ->
      {benchmark} = @config.ryba
      node_output_header = "Number of maps,Number of rows,Bytes written, Bytes read, Blocks written, Blocks read, Blocks replicated, Blocks removed, Blocks replicated"
      username = /^(.*?)(@|$)/.exec(benchmark.kerberos.principal)[1]
      teragen_output_dir = "/user/#{username}/benchmark_teragen"
      teragen_output_file = "#{benchmark.output}/teragen.csv"
      terasort_output_dir = "/user/#{username}/benchmark_terasort"
      terasort_output_file = "#{benchmark.output}/terasort.csv"
      job_output_header = "Number of maps,Number of rows,#{benchmark.terasort.stdout_value_names.join ","},Real time"

## Prepare job output files
      
      @call header: 'Preparation', handler: ->
        @file
          ssh: null 
          target: teragen_output_file
          content: job_output_header
          unless_exists: true
        @file
          ssh: null 
          target: terasort_output_file
          content: job_output_header
          unless_exists: true
        @file (
          ssh: null 
          target: "#{benchmark.output}/#{node.name}.csv"
          content: node_output_header
          unless_exists: true
        ) for node in benchmark.datanodes

Run each jobs N times (defined by parameter `iterations`)
      
      @each benchmark.terasort.parameters, (options) ->
        parameters = options.key
        @each [0...benchmark.iterations], (options) ->
          iteration = options.key

## Clean HDFS directories 
  
          @system.execute 
            header: "#{iteration} HDFS Cleanup"
            cmd: """
            echo #{benchmark.kerberos.password} | kinit #{benchmark.kerberos.principal} >/dev/null 2>&1
            hdfs dfs -rm -r -skipTrash '#{teragen_output_dir}' '#{terasort_output_dir}'
            """ 
            code_skipped: 1 
            trap: true

## DN Metrics Before 
    
Before (and after) each test, request the following information for every 
datanode using the node's JMX interface :

* Bytes written 
* Bytes read 
* Blocks written 
* Blocks read 
* Blocks replicated 
* Blocks removed  
* Blocks validated 

These can be used to validate data repartition in the cluster.
          
          @call header: "#{iteration} Collect Before", handler: ->
            @each benchmark.datanodes, (options, cb) ->
              node = options.key
              @system.execute 
                cmd: """
                echo #{benchmark.kerberos.password} | kinit #{benchmark.kerberos.principal} >/dev/null 2>&1
                curl --fail -k --negotiate -u: \
                  -H "Content-Type: application/json" \
                  -X GET #{node.urls.metrics}
                """
              , (err, execute, stdout) ->
                throw err if err
                data = JSON.parse stdout
                throw Error "Invalid Response" unless new RegExp("Hadoop:service=DataNode,name=DataNodeActivity-#{node.name}-1004").test data?.beans[0]?.name
                @file 
                  ssh: null 
                  target: "#{benchmark.output}/#{node.name}.csv"
                  content: "\n#{parameters.maps},#{parameters.rows},#{parse_datanode_jmx data.beans[0]}"
                  append: true  
              @then cb

## TeraGen 
        
          @call header: "#{iteration} Teragen", handler: ->
            @system.execute 
              cmd: """
              echo #{benchmark.kerberos.password} | kinit #{benchmark.kerberos.principal} >/dev/null 2>&1
              time hadoop jar #{benchmark.jars.current} \
                teragen \
                -Dmapreduce.job.maps=#{parameters.maps} \
                '#{parameters.rows}' \
                '#{teragen_output_dir}'
              """
            , (err, _, stdout, stderr) ->
              @file
                unless: !!err
                ssh: null
                target: teragen_output_file
                content: parse_metrics stderr, parameters.maps, parameters.rows
                append: true

# ## TeraSort
          
          @call header: "#{iteration} Terasort", handler: ->
            @system.execute
              cmd: """
              echo #{benchmark.kerberos.password} | kinit #{benchmark.kerberos.principal} >/dev/null 2>&1
              time hadoop jar #{benchmark.jars.current} \
                terasort \
                -Dmapreduce.job.maps=#{parameters.maps} \
                '#{teragen_output_dir}' \
                '#{terasort_output_dir}'
              """
            , (err, _, stdout, stderr) ->
              @file
                unless: !!err
                ssh: null
                target: terasort_output_file
                content: parse_metrics stderr, parameters.maps, parameters.rows
                append: true

## DN Metrics After
          
          @call header: "#{iteration} Collect After", handler: ->
            @each benchmark.datanodes, (options, cb) ->
              node = options.key
              @system.execute
                cmd: """
                curl  --fail -k --negotiate -u: \
                  -H "Content-Type: application/json" -k \
                  -X GET #{node.urls.metrics}
                """
              , (err, execute, stdout) ->
                throw err if err
                data = JSON.parse stdout
                throw Error "Invalid Response" unless new RegExp("Hadoop:service=DataNode,name=DataNodeActivity-#{node.name}-1004").test data?.beans[0]?.name
                @file 
                  ssh: null 
                  target: "#{benchmark.output}/#{node.name}.csv"
                  content: "\n#{parameters.maps},#{parameters.rows},#{parse_datanode_jmx data.beans[0]}"
                  append: true
              @then cb

## Utils 

Parse the output of the Datanode JMX query run before and after each teragen /
terasort job

      parse_datanode_jmx = (bean) ->
        line = ""
        line += "#{bean.BytesWritten},"
        line += "#{bean.BytesRead},"
        line += "#{bean.BlocksWritten},"
        line += "#{bean.BlocksRead},"
        line += "#{bean.BlocksReplicated},"
        line += "#{bean.BlocksRemoved},"
        line += "#{bean.BlocksVerified}"
        line

Parse the output of a teragen / terasort job to retrieve job metrics

      parse_metrics = (output, maps, rows) ->
        metrics = [
          maps
          rows
        ]
        for line in output.split "\n"
          if /.*Running job: .*/.test line
            metrics.applicationId = line.replace /.*Running job: /, ""
          for name in benchmark.terasort.stdout_value_names
            unless line.indexOf(name) == -1
              metrics.push line.split("=")[1]
          unless line.indexOf("real") == -1 # job duration 
            metrics.push line.substring line.lastIndexOf "\t"
        "\n#{metrics.join ','}"
