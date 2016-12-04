# Ambari Agent Install

The ambari server must be set in the configuration file.

    module.exports = header: 'Ambari Agent Install', timeout: -1, handler: ->
      {ambari_agent} = @config.ryba
      {ambari_server} = @contexts('ryba/ambari/server')[0].config.ryba

## Package & Repository

Declare the Ambari custom repository.
Install Ambari server package.

      @file.download
        header: 'Ambari Server Repo'
        source: ambari_server.repo
        target: '/etc/yum.repos.d/ambari.repo'
      @execute
        cmd: "yum clean metadata; yum update -y"
        if: -> @status -1
      @service
        header: 'Ambari Agent Startup'
        name: 'ambari-agent'
        startup: true

## Ambari Agent Configure

      @file.ini
        header: 'Ambari Agent Configure'
        target: "#{ambari_agent.conf_dir}/ambari-agent.ini"
        content: ambari_agent.ini
        parse: misc.ini.parse_multi_brackets_multi_lines
        stringify: misc.ini.stringify_multi_brackets
        indent: ''
        merge: true
        comment: '#'
        backup: true
      @file
        header: 'Hostname Script'
        target: ambari_agent.ini.agent['hostname_script']
        content: """
          #!/bin/sh
          echo #{@config.host}
        """
        mode: 0o751


## Non-Root

      @file
        if: ambari_agent.sudo
        target: '/etc/sudoers.d/ambari_agent'
        content: """
        # Ambari Customizable Users
        ambari ALL=(ALL) NOPASSWD:SETENV: /bin/su hdfs *,/bin/su ambari-qa *,/bin/su ranger *,/bin/su zookeeper *,/bin/su knox *,/bin/su falcon *,/bin/su ams *, /bin/su flume *,/bin/su hbase *,/bin/su spark *,/bin/su accumulo *,/bin/su hive *,/bin/su hcat *,/bin/su kafka *,/bin/su mapred *,/bin/su oozie *,/bin/su sqoop *,/bin/su storm *,/bin/su tez *,/bin/su atlas *,/bin/su yarn *,/bin/su kms *,/bin/su activity_analyzer *,/bin/su livy *,/bin/su zeppelin *
        # Ambari: Core System Commands
        ambari ALL=(ALL) NOPASSWD:SETENV: /usr/bin/yum,/usr/bin/zypper,/usr/bin/apt-get, /bin/mkdir, /usr/bin/test, /bin/ln, /bin/ls, /bin/chown, /bin/chmod, /bin/chgrp, /bin/cp, /usr/sbin/setenforce, /usr/bin/test, /usr/bin/stat, /bin/mv, /bin/sed, /bin/rm, /bin/kill, /bin/readlink, /usr/bin/pgrep, /bin/cat, /usr/bin/unzip, /bin/tar, /usr/bin/tee, /bin/touch, /usr/bin/mysql, /sbin/service mysqld *, /usr/bin/dpkg *, /bin/rpm *, /usr/sbin/hst * 
        # Ambari: Hadoop and Configuration Commands
        ambari ALL=(ALL) NOPASSWD:SETENV: /usr/bin/hdp-select, /usr/bin/conf-select, /usr/hdp/current/hadoop-client/sbin/hadoop-daemon.sh, /usr/lib/hadoop/bin/hadoop-daemon.sh, /usr/lib/hadoop/sbin/hadoop-daemon.sh, ambari-python-wrap /usr/bin/conf-select
        # Ambari: System User and Group Commands
        ambari ALL=(ALL) NOPASSWD:SETENV: /usr/sbin/groupadd, /usr/sbin/groupmod, /usr/sbin/useradd, /usr/sbin/usermod
        # Ambari: Knox Commands
        ambari ALL=(ALL) NOPASSWD:SETENV: /usr/bin/python2.6 /var/lib/ambari-agent/data/tmp/validateKnoxStatus.py *, /usr/hdp/current/knox-server/bin/knoxcli.sh
        # Ambari: Ranger Commands
        ambari ALL=(ALL) NOPASSWD:SETENV: /usr/hdp/*/ranger-usersync/setup.sh, /usr/bin/ranger-usersync-stop, /usr/bin/ranger-usersync-start, /usr/hdp/*/ranger-admin/setup.sh *, /usr/hdp/*/ranger-knox-plugin/disable-knox-plugin.sh *, /usr/hdp/*/ranger-storm-plugin/disable-storm-plugin.sh *, /usr/hdp/*/ranger-hbase-plugin/disable-hbase-plugin.sh *, /usr/hdp/*/ranger-hdfs-plugin/disable-hdfs-plugin.sh *, /usr/hdp/current/ranger-admin/ranger_credential_helper.py, /usr/hdp/current/ranger-kms/ranger_credential_helper.py, /usr/hdp/*/ranger-*/ranger_credential_helper.py
        # Allows sudo to being invoked from a non-interactive shell
        Defaults exempt_group = ambari
        Defaults !env_reset,env_delete-=PATH
        Defaults: ambari !requiretty 
        """

    misc = require 'mecano/lib/misc'
