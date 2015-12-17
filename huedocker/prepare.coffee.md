#  Hue  build

Follows Cloudera   [build-instruction][cloudera-hue] for Hue 3.7 and later versionz.
An internet Connection is needed to be able to download.
Becareful when used with docker-machine mecano might exit before finishing
the execution. you can resume build by executing again prepare

    module.exports = []
    module.exports.push 'masson/bootstrap/log'

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


# Hue compiling build from Dockerfile

Builds Hue in two steps:
1 - the first step creates a docker container to build hue from source with all the tools needed
2 - the second step builds a production ready ryba/hue image by setting:
  * the needed yum packages
  * user and group layout
It's the install middleware which takes care about mounting the differents volumes
for hue to be able to communicate with the hadoop cluster in secure mode.


# Hue Build dockerfile execution

    module.exports.push header: 'Hue Docker # Build Prepare', timeout: -1,  handler: ->
      machine = 'dev'
      {hue_docker} = @config.ryba
      @mkdir
        destination: "#{hue_docker.build.directory}/"
      @git
        source: 'https://github.com/cloudera/hue.git'
        destination: "#{hue_docker.build.directory}/hue"
      @render
        source: hue_docker.build.dockerfile
        destination: "#{hue_docker.build.directory}/Dockerfile"
        context: { git_source: 'hue' }
      # docker build -t "ryba/hue-build" .
      @docker_build
        image: hue_docker.build.name
        cwd: hue_docker.build.directory
        machine: machine
      @docker_rm
        machine: machine
        container: 'extractor'
      @docker_run
        image: hue_docker.build.name
        container: 'extractor'
        entrypoint: '/bin/bash'
        machine: machine
      @mkdir
        destination: "#{hue_docker.prod.directory}"
      @docker_cp
        source: '/hue-build.tar.gz'
        destination: hue_docker.prod.directory
        machine: machine
        container: 'extractor'


# Hue Production dockerfile execution

This production container running as hue service

    module.exports.push header: 'Hue Docker # Production Container', timeout: -1, handler: ->
      {hue_docker} = @config.ryba
      machine = 'dev'
      @render
        source: "#{__dirname}/resources/prod/Dockerfile"
        destination: "#{hue_docker.prod.directory}/Dockerfile"
        context: {
          user : hue_docker.user.name
          uid : hue_docker.user.uid
          gid : hue_docker.user.uid
        }
      @render
        source: "#{__dirname}/resources/hue_init.sh"
        destination: "#{hue_docker.prod.directory}/hue_init.sh"
        context: {
          pid_file: hue_docker.pid_file
        }
      # docker build -t "ryba/hue-build:3.9" .
      @docker_build
        image: "#{hue_docker.image}:#{hue_docker.version}"
        machine: 'dev'
        cwd: hue_docker.prod.directory
      , (err, _, __, ___, checksum ) =>
        return err if err
        @write
          content: "#{checksum}"
          destination: "#{hue_docker.prod.directory}/checksum"
      @docker_save
        image: "#{hue_docker.image}:#{hue_docker.version}"
        machine: machine
        destination: "#{__dirname}/resources/hue_docker.tar"



## Instructions

[cloudera-hue]:(https://github.com/cloudera/hue#development-prerequisites)
