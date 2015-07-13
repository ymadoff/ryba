# Apache Zeppelin build

Builds Zeppelin from as [required][zeppelin-build]. For now it's the single way to get Zeppelin.
Requires Internet to download repository & maven.
Sometimes you have to restar docker service because container can't acces the internet
This script can build the final zeppelin docker image either completely from source or from docker repository
The intermediate image and final image can be built locally. 
The final zeppelin docker image will alwayse be deployed on the server.

    module.exports = []
    module.exports.push 'masson/bootstrap'
    #module.exports.push 'masson/commons/docker'
    module.exports.push require('./index').configure

## Zeppelin compiling build from Dockerfile

Intermetiate container to build zeppelin from source. Builds ryba/zeppelin-build image

    module.exports.push name: 'Zeppelin Build # Docker', timeout: -1, handler: (ctx, next) ->
      {zeppelin} = ctx.config.ryba
      ssh = if zeppelin.build.local then null else ctx.ssh 
      return next unless zeppelin.build.execute
      ctx
      .docker_build
        name: zeppelin.build.name
        source: zeppelin.build.dockerfile
        ssh: ssh
      .execute
        cmd: "docker stop extractor && docker rm extractor "
        ssh: ssh
        code_skipped: 1
      .docker_run
        image: zeppelin.build.name
        name: 'extractor'
        ssh: ssh
        entrypoint: '/bin/bash'
        not_if_exists: "#{zeppelin.build.directory}/resources/zeppelin-build.tar.gz"
      .mkdir
        destination: "#{zeppelin.build.directory}"
        ssh: ssh
        not_if_exists: "#{zeppelin.build.directory}/resources/zeppelin-build.tar.gz"
      .execute
        cmd: "docker cp extractor:/zeppelin-build.tar.gz  #{zeppelin.build.directory}/resources/"
        ssh: ssh
        not_if_exists: "#{zeppelin.build.directory}/resources/zeppelin-build.tar.gz"
      .execute
        ssh: ssh
        cmd: """
              docker stop extractor
              docker rm extractor
             """
        not_if_exists: "#{zeppelin.build.directory}/resources/zeppelin-build.tar.gz"
      .then next

## Zeppelin final production docker image

Builds zeppelin using the resources previously constructed. The dockerfile for building ryba/zeppelin
needs zeppelin-built resource. Get it from ryba/zeppelin-build image.

    module.exports.push name: 'Zeppelin Build # Package', timeout: -1, handler: (ctx, next) ->
      {zeppelin} = ctx.config.ryba
      ssh = if zeppelin.build.local then null else ctx.ssh 
      ctx
      .download
        source: "#{__dirname}/../resources/zeppelin/supervisord.conf"
        destination: "#{zeppelin.build.directory}resources/supervisord.conf"
        ssh: ssh
      .docker_build
        name: 'ryba/zeppelin'
        source: '/Users/Bakalian/Developpement/docker/zeppelin/ryba/Dockerfile'
        cwd: "#{zeppelin.build.directory}"
        ssh: ssh
      .then next

## Docker image extract and download

    module.exports.push name: 'Zeppelin Build # Import', timeout: -1, handler: (ctx, next) ->
      {zeppelin} = ctx.config.ryba
      #executing docker-machine environment initialization by hand until mecano support all docker commands
      #eval \"$(docker-machine env dev )\" 1>&2 /dev/null
      return next null, null unless zeppelin.build.local
      ctx
      .execute 
        cmd: """
              docker export ryba/zeppelin -o #{zeppelin.build.directory}/zeppelin.tar
             """
        ssh: null if zeppelin.build.local
      .download
        source: "#{zeppelin.build.directory}/zeppelin.tar"
        destination: "#{zeppelin.build.directory}/zeppelin.tar"
      .execute
        cmd:"docker load < #{zeppelin.build.directory}/zeppelin.tar"
      .then next  

## Dependencies  

[zeppelin-build]:http://zeppelin.incubator.apache.org/docs/install/install.html