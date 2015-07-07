# Apache Zeppelin build

Builds Zeppelin from as [required][zeppelin-build]. For now it's the single way to get Zeppelin.
Requires Internet to download repository & maven.

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push (ctx) ->
      ctx.ssh = null
    module.exports.push 'masson/commons/java'
    module.exports.push 'masson/commons/nodejs'
    module.exports.push 'masson/commons/maven'
    module.exports.push require('./index').configure

## Build repository download

    module.exports.push name: 'Zeppelin Source # Download', timeout: -1, handler: (ctx, next) ->
      {zeppelin} = ctx.config.ryba
      ctx
      .git
        ssh: null
        source: zeppelin.repository
        destination: path.resolve process.cwd(), './resources/zeppelin'
        # destination: zeppelin.destination
      .then next

## Maven build from source

    module.exports.push name: 'Zeppelin Build # Maven', timeout: -1,  handler: (ctx, next) ->
      {zeppelin} = ctx.config.ryba
      return next null, null unless zeppelin.build  
      ctx
      .execute
        ssh: null
        cmd: """
        #yum install -y npm
        cd #{path.resolve process.cwd(), './resources/zeppelin'}
        mvn clean package -Pspark-1.2 -Dspark.version=1.2.1 -Dhadoop.version=2.6.0 -Phadoop-2.4 -Pyarn -DskipTests
        """
      .then next

## Dependencies

    path = require 'path'

[zeppelin-build]:http://zeppelin.incubator.apache.org/docs/install/install.html