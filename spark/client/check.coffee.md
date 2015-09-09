# Apache Spark Install Check

## Run twice "[Spark Pi][Spark-Pi]" example for validating installation . The configuration is a 10 stages run.
[Spark on Yarn][Spark-yarn] cluster can turn into two different mode :  yarn-client mode and yarn-cluster mode.
Spark programs are divide into a driver part and executors part.
The driver program manages the executors task.

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/hadoop/yarn_rm/wait'
    module.exports.push 'ryba/spark/history_server/wait'
    # module.exports.push require('./index').configure

## Validate Spark installation with Pi-example in yarn-cluster mode
The yarn cluster mode makes the driver part of the spark submitted program to run inside yarn.
In this mode the driver is the yarn application master (running inside yarn)

    module.exports.push name: 'Spark Client # Check Cluster Mode', timeout: -1, label_true: 'CHECKED', handler: ->
      {spark} = @config.ryba
      applicationId = null
      @execute
        cmd: mkcmd.test @, """
        spark-submit \
          --class org.apache.spark.examples.SparkPi \
          --queue default \
          --master yarn-cluster --num-executors 2 --driver-memory 512m \
          --executor-memory 512m --executor-cores 1 \
          #{spark.client_dir}/lib/spark-examples*.jar 10 2>&1 /dev/null \
        | grep -m 1 "proxy\/application_"
        """
      , (err, executed, stdout, stderr) ->
        return if err
        tracking_url_result = stdout.trim().split("/") if executed
        applicationId = tracking_url_result[tracking_url_result.length - 2]
      @call ->
        @execute
          cmd: mkcmd.test @, """
            yarn logs -applicationId #{applicationId} 2>&1 /dev/null | grep -m 1 "Pi is roughly"
            """
        , (err, executed, stdout, stderr) ->
          return if err
          log_result = stdout.split(" ")
          pi = parseFloat(log_result[log_result.length - 1])
          throw Error 'Invalid Output' unless pi > 3.00 and pi < 3.20

## Validate Spark installation with Pi-example in yarn-client mode
The yarn client mode makes the driver part of program to run on the local machine.
The local machine is the one from which the job has been submitted ( called the client ).
In this mode the driver is the spark master running outside yarn

TODO Search the logs after the job has finished elsewhere, the yarn-client prevent the yarn history 
server to access logs.

    # module.exports.push name: 'Spark Client  # Check Client Mode', timeout: -1, label_true: 'CHECKED', handler: ->
    #   {spark} = @config.ryba
    #   applicationId = ""
    #   ctx
    #     .child().execute
    #           cmd: mkcmd.test ctx, """
    #                 spark-submit --class org.apache.spark.examples.SparkPi --master yarn-client --num-executors 2 --driver-memory 512m --executor-memory 512m --executor-cores 1 #{spark.client_dir}/lib/spark-examples*.jar 10 2>&1 /dev/null | grep -m 1 "proxy\/application_"
    #                 """
    #   , (err, executed, stdout, stderr) ->
    #     return err if err
    #     tracking_url_result = stdout.trim().split("/") if executed
    #     applicationId =tracking_url_result[tracking_url_result.length - 2]
    #     ctx
    #         .child().execute
    #               cmd: mkcmd.test ctx, """
    #                     yarn logs -applicationId #{applicationId} 2>&1 /dev/null | grep -m 1 "Pi is roughly"
    #                     """
    #       , (err, executed, stdout, stderr) ->
    #         return next err if err
    #         log_result = stdout.split(" ")
    #         pi = parseFloat(log_result[log_result.length - 1])
    #         return next null, true if pi>3.00 and pi<3.20
    #         return next null, false

## Dependencies

    mkcmd = require '../../lib/mkcmd'

[Spark-Pi]:http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.2.4/Apache_Spark_Quickstart_v224/content/run_spark_pi.html
[Spark-yarn]:http://blog.cloudera.com/blog/2014/05/apache-spark-resource-management-and-yarn-app-models/
