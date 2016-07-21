# Apache Zeppelin

Zeppelin is a web-based notebook that enables interactive data analytics. You 
can make beautiful data-driven, interactive and collaborative documents with 
SQL, Scala and more. 

    module.exports = ->
      'configure':
        'ryba/zeppelin/configure'
      'prepare':
        'ryba/zeppelin/prepare'
      'install': [
        'masson/commons/docker'
        'ryba/spark/client'
        'ryba/hive/client'
        'ryba/zeppelin/install'
      ]







