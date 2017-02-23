
# Pig Install

Learn more about Pig optimization by reading ["Making Pig Fly"][fly].

    module.exports = header: 'Pig Install', handler: (options) ->
      {hadoop_group, pig} = @config.ryba
      {java_home} = @config.java

## Install

The pig package is install.

      @call header: 'Pig Service', timeout: -1, ->
        @service
          header: 'Service'
          name: 'pig'
        options.log 'TODO: pig-client not registered in hdp-select'
        # pig-client not registered in hdp-select
        # need to see if hadoop-client will switch pig as well
        # @call once: true, 'ryba/lib/hdp_select'
        # @hdp_select
        #   name: 'pig-client'
        # 6th feb 2014: pig user isnt created by YUM, might change in a future HDP release
        @system.execute
          header: 'Users'
          cmd: "useradd pig -r -M -g #{hadoop_group.name} -s /bin/bash -c \"Used by Pig service\""
          code: 0
          code_skipped: 9

## Configure

TODO: Generate the "pig.properties" file dynamically, be carefull, the HDP
companion file defines no properties while the YUM package does.


      @file.ini
        header: 'Properties'
        target: "#{pig.conf_dir}/pig.properties"
        content: pig.config
        separator: '='
        merge: true
        backup: true
      @file
        header: 'Env'
        source: "#{__dirname}/resources/pig-env.sh"
        target: "#{pig.conf_dir}/pig-env.sh"
        local_source: true
        write: [
          match: /^JAVA_HOME=.*$/mg
          replace: "JAVA_HOME=#{java_home}"
        ]
        mode: 0o755
        backup: true
      @file
        header: 'Fix Pig'
        write: [
          match: /^(\s)*slfJarVersion=.*/mg
          replace: "$1slfJarVersion=''"
        ,
          match: new RegExp quote('/usr/lib/hcatalog'), 'g'
          replace: '/usr/lib/hive-hcatalog'
        ]
        target: '/usr/lib/pig/bin/pig'
        backup: true

## Dependencies

    quote = require 'regexp-quote'

[fly]: http://chimera.labs.oreilly.com/books/1234000001811/ch08.html
