
# Livy Spark Server (Dockerized)

[Livy Spark Server][livy] is a rest interface to interact with  Apache Spark.
It used by [Hue][home] to provide users a spark application  notebook.

This modules builds the livy spark server in a container and should be used in combination
with ryba/huedocker to provided end to end setup.
It can also be used with any other hue installation, or even any other application.

You should start with /bin/ryba prepare -m 'ryba/spark/livy_server' command first.

    module.exports = -> 
      'configure': [
        'ryba/hadoop/core'
        'ryba/spark/livy_server/configure'
      ]
      'prepare':
        'ryba/spark/livy_server/prepare'
      'install': [
        'ryba/hadoop/core'
        'ryba/spark/client'
        'ryba/spark/livy_server/install'
        'ryba/spark/livy_server/wait'
      ]
      'start':
        'ryba/spark/livy_server/start'
      'stop':
        'ryba/spark/livy_server/stop'
      # 'status':
      #   'ryba/spark/livy_server/status'

[home]: http://gethue.com
[livy]: https://github.com/cloudera/livy
