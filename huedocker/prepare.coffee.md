#  Hue  build

Follows Cloudera   [build-instruction][cloudera-hue] for Hue 3.8 version.
An internet Connection is needed to be able to download.
Becareful when used with docker-machine mecano might exit before finishing
the execution. you can resume build by executing again prepare script or directly
by taking the command launched by mecano and start it by hand

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

    module.exports = []

    hue = {}
    hue.build ?= {}
    hue.build.name ?= 'ryba/hue-build'
    hue.build.dockerfile ?= "#{__dirname}/resources/build/Dockerfile"
    hue.build.directory ?= '/tmp/ryba/hue-build'
    hue.prod ?= {}
    hue.prod.image ?= 'ryba/hue:3.8'
    machine = 'dev'

# Hue compiling build from Dockerfile

Builds Hue in two steps:
1 - the first step creates a docker container to build hue from source with all the tools needed
2 - the second step builds a production ready ryba/hue image by setting:
  * the needed yum packages
  * user and group layout
It's the install middleware which takes care about mounting the differents volumes
for hue to be able to communicate with the hadoop cluster in secure mode.



    module.exports.push name: 'Hue Build # Docker', timeout: -1, (options, next) ->
      fs.stat "#{hue.build.directory}/resources/hue-build.tar.gz", (err, stats) ->
        return ( if err.code == 'ENOENT' then do_build() else err ) if err
        fs.stat "#{__dirname}/resources/hue.tar", (err, stats) ->
            return do_end() unless  err
            return if err.code == 'ENOENT' then do_image() else err
      do_build = =>
        @
        .download
          source: hue.build.dockerfile
          destination: "#{hue.build.directory}/Dockerfile"
          force: true
        .docker_build
          image: hue.build.name
          cwd: hue.build.directory
          machine: machine
        .docker_stop
          machine: machine
          container: 'extractor'
          code_skipped: 1
        .docker_rm
          machine: machine
          container: 'extractor'
          code_skipped: 1
        .docker_run
          image: hue.build.name
          container: 'extractor'
          entrypoint: '/bin/bash'
          machine: machine
        .mkdir
          destination: "#{hue.build.directory}"
        .docker_cp
          source: '/hue-build.tar.gz'
          destination: "#{hue.build.directory}/resources/"
          machine: machine
          container: 'extractor'
        .docker_stop
          machine: machine
          container: 'extractor'
          code_skipped: 1
        .docker_rm
          machine: machine
          container: 'extractor'
          code_skipped: 1
        .then (err) ->
          return err if err
          fs.stat "#{hue.build.directory}/hue.tar", (err, stats) ->
            return do_end() unless  err
            return if err.code == 'ENOENT' then do_image() else err
      # Builds the production image
      # Stores the image inside resources/ directory
      do_image = =>
        @
        .download
          source: "#{__dirname}/resources/prod/Dockerfile"
          destination: "#{hue.build.directory}/Dockerfile"
          local: true
          force: true
        .download
          source: "#{__dirname}/resources/hue_init.sh"
          destination: "#{hue.build.directory}/resources/hue_init.sh"
          local: true
          force: true
        .docker_build
          image: hue.prod.image
          machine: machine
          cwd: hue.build.directory
        .then do_save
      do_save = =>
        @
        .docker_save
          image: 'ryba/hue:3.8'
          machine: machine
          destination: "#{__dirname}/resources/hue.tar"
        .then do_end
      do_end = =>
        console.log 'Hue Prepare Done'
        return

## Dependencies

    fs = require 'fs'

## Instructions

[cloudera-hue]:(https://github.com/cloudera/hue#development-prerequisites)
