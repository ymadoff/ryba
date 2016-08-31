
#  Hue Prepare

Follows Cloudera   [build-instruction][cloudera-hue] for Hue 3.7 and later version.
An internet Connection is needed to be able to download.
Becareful when used with docker-machine mecano might exit before finishing
the execution. you can resume build by executing again prepare

First container
```
cd /tmp/ryba/hue-build/
eval "$(docker-machine env dev)" && docker build -t "ryba/hue-build" .
```

Second container
```
cd /tmp/ryba/hue-build/
eval "$(docker-machine env dev)" && docker build -t "ryba/hue-build" .
```

Builds Hue from source


    module.exports = header: 'Hue Docker Prepare', timeout: -1,  handler: ->
      {hue_docker} = @config.ryba


# Hue compiling build from Dockerfile

Builds Hue in two steps:
1 - the first step creates a docker container to build hue from source with all the tools needed
2 - the second step builds a production ready ryba/hue image by setting:
  * the needed yum packages
  * user and group layout
It's the install middleware which takes care about mounting the differents volumes
for hue to be able to communicate with the hadoop cluster in secure mode.

# Hue Build dockerfile execution

      @call header: 'Build Prepare', timeout: -1,  handler: ->
        @mkdir
          target: "#{@config.mecano.cache_dir}/huedocker"
        @mkdir
          target: "#{hue_docker.build.directory}/"
        @copy
          unless: hue_docker.build.source.indexOf('.git') > 0
          source: hue_docker.build.source
          target: "#{hue_docker.build.directory}/hue"
        @git
          if: hue_docker.build.source.indexOf('.git') > 0
          source: hue_docker.build.source
          target: "#{hue_docker.build.directory}/hue"
          revision: hue_docker.build.revision
        @render
          source: hue_docker.build.dockerfile
          target: "#{hue_docker.build.directory}/Dockerfile"
          context: 
            source: 'hue'
            user: hue_docker.user.name
            uid: hue_docker.user.uid
            gid: hue_docker.user.uid
        @docker_build
          image: "#{hue_docker.build.name}:#{hue_docker.build.version}"
          file: "#{hue_docker.build.directory}/Dockerfile"
        @docker_service
          image: "#{hue_docker.build.name}:#{hue_docker.build.version}"
          name: 'ryba_hue_extractor'
          entrypoint: '/bin/bash'
        @mkdir
          target: "#{hue_docker.prod.directory}"
        @docker_cp
          container: 'ryba_hue_extractor'
          source: 'ryba_hue_extractor:/hue-build.tar.gz'
          target: hue_docker.prod.directory
        @docker_rm
          container: 'ryba_hue_extractor'
          force: true

# Hue Production dockerfile execution

This production container running as hue service

      @call header: 'Production Container', timeout: -1, handler: ->
        @render
          source: hue_docker.prod.dockerfile
          target: "#{hue_docker.prod.directory}/Dockerfile"
          context:
            user: hue_docker.user.name
            uid: hue_docker.user.uid
            gid: hue_docker.user.uid
        @render
          source: "#{__dirname}/resources/hue_init.sh"
          target: "#{hue_docker.prod.directory}/hue_init.sh"
          context:
            pid_file: hue_docker.pid_file
            user: hue_docker.user.name
        # docker build -t "ryba/hue-build:3.9" .
        @docker_build
          image: "#{hue_docker.image}:#{hue_docker.version}"
          file: "#{hue_docker.prod.directory}/Dockerfile"
        , (err, _, checksum) ->
          throw err if err
          @write
            content: "#{checksum}"
            target: "#{hue_docker.prod.directory}/checksum"
        @docker_save
          image: "#{hue_docker.image}:#{hue_docker.version}"
          output: "#{hue_docker.prod.directory}/#{hue_docker.prod.tar}"

## Instructions

[cloudera-hue]:(https://github.com/cloudera/hue#development-prerequisites)
