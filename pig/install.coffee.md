
# Pig Install

Learn more about Pig optimization by reading ["Making Pig Fly"][fly].

    module.exports = header: 'Pig # Install', handler: ->
      {hadoop_group, pig} = @config.ryba
      {java_home} = @config.java
      
## Users & Groups

By default, the "pig" package create the following entries:

```bash
cat /etc/passwd | grep pig
pig:x:490:502:Used by Pig service:/home/pig:/bin/bash
cat /etc/group | grep hadoop
hadoop:x:502:yarn,mapred,hdfs,hue
```

      @call header: 'Pig # Users & Groups', handler: ->
        @group hadoop_group
        @user pig.user

## Install

The pig package is install.

      @call header: 'Pig # Service', timeout: -1, handler: ->
        @service
          header: 'Pig # Service'
          name: 'pig'
        console.log 'TODO: pig-client not registered in hdp-select'
        # pig-client not registered in hdp-select
        # need to see if hadoop-client will switch pig as well
        # @hdp_select
        #   name: 'pig-client'
        # 6th feb 2014: pig user isnt created by YUM, might change in a future HDP release
        @execute
          header: 'Pig # Users'
          cmd: "useradd pig -r -M -g #{hadoop_group.name} -s /bin/bash -c \"Used by Pig service\""
          code: 0
          code_skipped: 9

## Configure

TODO: Generate the "pig.properties" file dynamically, be carefull, the HDP
companion file defines no properties while the YUM package does.

      @call header: 'Pig # Configure', handler: ->
        @ini
          header: 'Pig # Properties'
          destination: "#{pig.conf_dir}/pig.properties"
          content: pig.config
          separator: '='
          merge: true
          backup: true
        @write
          header: 'Pig # Env'
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
        @write
          header: 'Pig # Fix Pig'
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
