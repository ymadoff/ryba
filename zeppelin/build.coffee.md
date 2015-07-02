# Apache Zeppelin build

Builds Zeppelin from as [required][zeppelin-build]. For now it's the single way to get Zeppelin.
Requires Internet to download repository & maven.

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/commons/java'
    module.exports.push 'masson/commons/maven'
    module.exports.push require('./index').configure

## Build repository download

    module.exports.push name: 'Zeppelin Source # Download',  handler: (ctx, next) ->
      zeppelin = ctx.config.ryba.zeppelin
      ctx
        .git
          source: zeppelin.repository
          destination: zeppelin.destination
        .then next

## Maven build from source

    module.exports.push name: 'Zeppelin Build # Maven', timeout: -1,  handler: (ctx, next) ->
      zeppelin = ctx.config.ryba.zeppelin
      return next null, null unless zeppelin.build  
      ctx
        .execute
          cmd: """
              yum install -y npm
              cd #{zeppelin.destination}
              /usr/lib/maven/apache-maven-3.3.3/bin/mvn clean package -Pspark-1.2 -Dspark.version=1.2.1 -Dhadoop.version=2.6.0 -Phadoop-2.4 -Pyarn -DskipTests
              """
        .then next

[zeppelin-build]:http://zeppelin.incubator.apache.org/docs/install/install.html