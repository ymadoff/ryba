
# Pig

Learn more about Pig optimization by reading ["Making Pig Fly"][fly].

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/bootstrap/utils'
    module.exports.push 'ryba/hadoop/mapred_client'
    module.exports.push 'ryba/hadoop/yarn_client'
    module.exports.push 'ryba/hive/client' # In case pig is run through hcat
    module.exports.push require '../lib/hdp_select'
    module.exports.push require('./pig').configure

## Users & Groups

By default, the "pig" package create the following entries:

```bash
cat /etc/passwd | grep pig
pig:x:490:502:Used by Hadoop Pig service:/home/pig:/bin/bash
cat /etc/group | grep hadoop
hadoop:x:502:yarn,mapred,hdfs,hue
```

    module.exports.push name: 'Hadoop Pig # Users & Groups', handler: (ctx, next) ->
      {hadoop_group, pig_user} = ctx.config.ryba
      ctx.group hadoop_group, (err, gmodified) ->
        return next err if err
        ctx.user pig_user, (err, umodified) ->
          next err, gmodified or umodified

## Install

The pig package is install.

    module.exports.push name: 'Hadoop Pig # Install', timeout: -1, handler: (ctx, next) ->
      ctx
      .service
        name: 'pig'
      # .hdp_select
      #   name: 'pig-client'
      .then next

    module.exports.push name: 'Hadoop Pig # Users', handler: (ctx, next) ->
      # 6th feb 2014: pig user isnt created by YUM, might change in a future HDP release
      {hadoop_group} = ctx.config.ryba
      ctx.execute
        cmd: "useradd pig -r -M -g #{hadoop_group.name} -s /bin/bash -c \"Used by Hadoop Pig service\""
        code: 0
        code_skipped: 9
      , next

## Configure

TODO: Generate the "pig.properties" file dynamically, be carefull, the HDP
companion file defines no properties while the YUM package does.

    module.exports.push name: 'Hadoop Pig # Configure', handler: (ctx, next) ->
      {pig_conf_dir, pig_conf} = ctx.config.ryba
      ctx.ini
        destination: "#{pig_conf_dir}/pig.properties"
        content: pig_conf
        separator: '='
        merge: true
        backup: true
      , next

    module.exports.push name: 'Hadoop Pig # Env', handler: (ctx, next) ->
      {java_home} = ctx.config.java
      {hadoop_group, pig_conf_dir, pig_user} = ctx.config.ryba
      ctx.write
        source: "#{__dirname}/../resources/pig/pig-env.sh"
        destination: "#{pig_conf_dir}/pig-env.sh"
        local_source: true
        write: [
          match: /^JAVA_HOME=.*$/mg
          replace: "JAVA_HOME=#{java_home}"
        ]
        uid: pig_user.name
        gid: hadoop_group.name
        mode: 0o755
        backup: true
      , next

    module.exports.push name: 'Hadoop Pig # Fix Pig', handler: (ctx, next) ->
      ctx.write
        write: [
          match: /^(\s)*slfJarVersion=.*/mg
          replace: "$1slfJarVersion=''"
        ,
          match: new RegExp quote('/usr/lib/hcatalog'), 'g'
          replace: '/usr/lib/hive-hcatalog'
        ]
        destination: '/usr/lib/pig/bin/pig'
        backup: true
      , next

## Check

    module.exports.push 'ryba/tools/pig_check'

## Module Dependencies

    quote = require 'regexp-quote'

[fly]: http://chimera.labs.oreilly.com/books/1234000001811/ch08.html
