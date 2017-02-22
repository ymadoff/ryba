
# NagVis Install

    module.exports = header: 'NagVis Install', handler: ->
      {httpd} = @config
      {nagvis} = @config.ryba

## IPTables

| Service           | Port  | Proto | Parameter       |
|-------------------|-------|-------|-----------------|
|  nagvis           | 50000 |  tcp  |                 |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      @tools.iptables
        header: 'IPTables'
        rules: [
          chain: 'INPUT', jump: 'ACCEPT', dport: nagvis.port, protocol: 'tcp', state: 'NEW', comment: "NagVis"
        ]
        if: @config.iptables.action is 'start'

## Packages

      @call header: 'Packages', handler: ->
        @service name: 'php'
        @service name: 'php-common'
        @service name: 'php-pdo'
        @service name: 'php-gd'
        @service name: 'php-mbstring'
        @service name: 'php-mysql'
        # @service name: 'php-php-gettext'
        @service name: 'graphviz-php'

## Install

      @call unless_exec: "[ `cat #{nagvis.install_dir}/version` = #{nagvis.version} ]", header: 'Archive', handler: ->
        @file.download
          source: nagvis.source
          target: "/var/tmp/nagvis-#{nagvis.version}.tar.gz"
        @tools.extract
          source: "/var/tmp/nagvis-#{nagvis.version}.tar.gz"
        @system.chmod
          target: "/var/tmp/nagvis-#{nagvis.version}/install.sh"
          mode: 0o755
        @execute
          cmd: """
          cd /var/tmp/nagvis-#{nagvis.version};
          ./install.sh -n #{nagvis.base_dir} -p #{nagvis.install_dir} \
          -l 'tcp:#{nagvis.livestatus_address}' -b mklivestatus -u #{httpd.user.name} -g #{httpd.group.name} -w /etc/httpd/conf.d -a y -q
          """
        @service.restart
          name: 'httpd'
        @file
          target: "#{nagvis.install_dir}/version"
          content: "#{nagvis.version}"
        @system.remove target: "/var/tmp/nagvis-#{nagvis.version}.tar.gz"
        @system.remove target: "/var/tmp/nagvis-#{nagvis.version}"

      write = ""
      for k, v of nagvis.config
        write += "[#{k}]\n"
        for sk, sv of v
          write += "#{sk}=" + if typeof sv is 'string' then "\"#{sv}\"\n" else "#{sv}\n"
        write += "\n"
      @file
        target: "#{nagvis.install_dir}/etc/nagvis.ini.php"
        content: write
        backup: true

## Dependencies

    glob = require 'glob'
    path = require 'path'
