# Zeppelin install

Install Zeppelin from build.
Install Zeppelin, configured for a YARN  cluster. Configured also for running on spark 1.2.1.
Spark comes with 1.2.1 in HDP 2.2.4.

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push require '../lib/hconfigure'
    module.exports.push require('./index').configure

## Build Directory download

    module.exports.push name: 'Zeppelin Package # Download',  handler: (ctx, next) ->
      zeppelin = ctx.config.ryba.zeppelin
      tmp = "/tmp/zeppelin.tar.gz"
      ctx
        .download
          source: zeppelin.source
          destination: tmp
          cache: true
        .mkdir
          destination: zeppelin.destination
          mode: 0o0750
        .execute
          cmd:  "tar xzf #{tmp} -C #{zeppelin.destination} --strip-components 1"
          mode: 0o0750
        # to uncomment when mecano.extract will be update with strip_level option :
        # Done , waiting for test before mecano upgrade:     
        # .extract
        #   source: '/tmp/zeppelin.tar.gz'
        #   destination: '/var/lib/zeppelin'
        #   strip_level: 1
        .then next

## Zeppelin properties configuration
    
    module.exports.push name: 'Zeppelin Package # Configure',  handler: (ctx, next) ->
      {hadoop_group,hadoop_conf_dir, hdfs, zeppelin} = ctx.config.ryba
      write  = for k, v of zeppelin.env
        match: RegExp "^export\\s+(#{quote k})(.*)$", 'm'
        replace: "export #{k}=#{v}"
        append: true
      ctx
        .download
          source: "#{__dirname}/../resources/zeppelin/zeppelin-site.xml"
          destination: "#{zeppelin.conf_dir}/zeppelin-site.xml"
          uid: hdfs.user.name
          gid: hadoop_group.name
          mode: 0o755
          if_not_exists: "#{zeppelin.conf_dir}/zeppelin-site.xml"
        .download
          source: "#{__dirname}/../resources/zeppelin/zeppelin-env.sh"
          destination: "#{zeppelin.conf_dir}/zeppelin-env.sh"
          uid: hdfs.user.name
          gid: hadoop_group.name
          mode: 0o755
          if_not_exists: "#{zeppelin.conf_dir}/zeppelin-env.sh"
        .hconfigure
          destination: "#{zeppelin.conf_dir}/zeppelin-site.xml"
          default: "#{__dirname}/../resources/zeppelin/zeppelin-site.xml"
          local_default: true
          properties: zeppelin.site
          merge: true
          backup: true
        .write
          destination: "#{zeppelin.conf_dir}/zeppelin-env.sh"
          write: write
          backup: true
          eof: true
        .then next


## Zeppelin start 

TODO : move to start.coffee.md && create stop, check files


    module.exports.push name: 'Zeppelin Server # Start',  handler: (ctx, next) ->
      zeppelin = ctx.config.ryba.zeppelin
      ctx
        .execute
          cmd: "/var/lib/zeppelin/bin/zeppelin-daemon.sh --config #{zeppelin.destination}/conf start"
        .then next

## Dependencies
    
    quote = require 'regexp-quote'
