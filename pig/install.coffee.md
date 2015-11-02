
# Pig

Learn more about Pig optimization by reading ["Making Pig Fly"][fly].

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/bootstrap/utils'
    module.exports.push 'ryba/hadoop/mapred_client'
    module.exports.push 'ryba/hadoop/yarn_client'
    module.exports.push 'ryba/hive/client' # In case pig is run through hcat
    module.exports.push 'ryba/lib/hdp_select'
    # module.exports.push require('./index').configure

## Users & Groups

By default, the "pig" package create the following entries:

```bash
cat /etc/passwd | grep pig
pig:x:490:502:Used by Hadoop Pig service:/home/pig:/bin/bash
cat /etc/group | grep hadoop
hadoop:x:502:yarn,mapred,hdfs,hue
```

    module.exports.push name: 'Hadoop Pig # Users & Groups', handler: ->
      {hadoop_group, pig} = @config.ryba
      @group hadoop_group
      @user pig.user

## Install

The pig package is install.

    module.exports.push name: 'Hadoop Pig # Install', timeout: -1, handler: ->
      @service
        name: 'pig'
      console.log 'TODO: pig-client not registered in hdp-select'
      # pig-client not registered in hdp-select
      # need to see if hadoop-client will switch pig as well
      # @hdp_select
      #   name: 'pig-client'

    module.exports.push name: 'Hadoop Pig # Users', handler: ->
      # 6th feb 2014: pig user isnt created by YUM, might change in a future HDP release
      {hadoop_group} = @config.ryba
      @execute
        cmd: "useradd pig -r -M -g #{hadoop_group.name} -s /bin/bash -c \"Used by Hadoop Pig service\""
        code: 0
        code_skipped: 9

## Configure

TODO: Generate the "pig.properties" file dynamically, be carefull, the HDP
companion file defines no properties while the YUM package does.

    module.exports.push name: 'Hadoop Pig # Configure', handler: ->
      {pig} = @config.ryba
      @ini
        destination: "#{pig.conf_dir}/pig.properties"
        content: pig.config
        separator: '='
        merge: true
        backup: true

    module.exports.push name: 'Hadoop Pig # Env', handler: ->
      {java_home} = @config.java
      {hadoop_group, pig} = @config.ryba
      @write
        source: "#{__dirname}/resources/pig-env.sh"
        destination: "#{pig.conf_dir}/pig-env.sh"
        local_source: true
        write: [
          match: /^JAVA_HOME=.*$/mg
          replace: "JAVA_HOME=#{java_home}"
        ]
        uid: pig.user.name
        gid: hadoop_group.name
        mode: 0o755
        backup: true

    module.exports.push name: 'Hadoop Pig # Fix Pig', handler: ->
      @write
        write: [
          match: /^(\s)*slfJarVersion=.*/mg
          replace: "$1slfJarVersion=''"
        ,
          match: new RegExp quote('/usr/lib/hcatalog'), 'g'
          replace: '/usr/lib/hive-hcatalog'
        ]
        destination: '/usr/lib/pig/bin/pig'
        backup: true

## Dependencies

    quote = require 'regexp-quote'

[fly]: http://chimera.labs.oreilly.com/books/1234000001811/ch08.html
