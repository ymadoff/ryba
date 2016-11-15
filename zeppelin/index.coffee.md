# Apache Zeppelin

Zeppelin is a web-based notebook that enables interactive data analytics. You 
can make beautiful data-driven, interactive and collaborative documents with 
SQL, Scala and more. 

    module.exports =
      use:
        'hadoop': implicit: true, module: 'ryba/hadoop/core'
        'docker': 'masson/commons/docker'
        'spark': 'ryba/spark/client'
        'hive': 'ryba/hive/client'
      configure:
        'ryba/zeppelin/configure'
      commands:
        'prepare':
          'ryba/zeppelin/prepare'
        'install':
          'ryba/zeppelin/install'
