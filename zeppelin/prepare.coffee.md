
# Zeppelin Prepare

Builds Zeppelin from as [required][zeppelin-build]. For now it's the single way to get Zeppelin.
It uses several containers. One to build zeppelin and an other for deploying zeppelin.
Requires Internet to download repository & maven.
Zeppelin 0.6 builds for Hadoop Cluster on Yarn with Spark.
Version:
  - Spark: 1.3
  - Hadoop: 2.7 (HDP 2.3)

    module.exports = []
    module.exports.push 'masson/bootstrap/log'

## Prepare Build

Intermetiate container to build zeppelin from source. Builds ryba/zeppelin-build
image.

    module.exports.push header: 'Zeppelin # Prepare Build', ssh: null, retry: 1, timeout: -1, handler: ->
      {zeppelin} = @config.ryba
      machine = 'ryba'
      @docker_build
        machine: machine
        image: zeppelin.build.tag
        cwd: zeppelin.build.cwd
      @docker_run
        machine: machine
        image: zeppelin.build.tag
        rm: true
        volume: "#{@config.mecano.cache_dir}:/target"
      @mkdir
        destination: "#{@config.mecano.cache_dir}/zeppelin"
      @copy
        source: "#{zeppelin.prod.cwd}/Dockerfile"
        destination: "#{@config.mecano.cache_dir}/zeppelin"
      @copy
        source: "#{@config.mecano.cache_dir}/zeppelin-build.tar.gz"
        destination: "#{@config.mecano.cache_dir}/zeppelin"

## Prepare Container

Build the Docker container and place it inside the cache directory.

    module.exports.push header: 'Zeppelin # Prepare Container', retry: 1, timeout: -1, handler: ->
      {zeppelin} = @config.ryba
      machine = 'ryba'
      @docker_build
        machine: machine
        tag: "#{zeppelin.prod.tag}"
        cwd: "#{@config.mecano.cache_dir}/zeppelin"
      @docker_save
        image: "#{zeppelin.prod.tag}"
        machine: machine
        destination: "#{@config.mecano.cache_dir}/zeppelin.tar"

## Instructions

[zeppelin-build]:http://zeppelin.incubator.apache.org/docs/install/install.html
[github-instruction]:https://github.com/apache/incubator-zeppelin
[hortonwork-instruction]:http://fr.hortonworks.com/blog/introduction-to-data-science-with-apache-spark/
