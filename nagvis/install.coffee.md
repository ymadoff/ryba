
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

      @iptables
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
        @download
          source: nagvis.source
          destination: "/tmp/nagvis-#{nagvis.version}.tar.gz"
        @extract
          source: "/tmp/nagvis-#{nagvis.version}.tar.gz"
        @chmod
          destination: "/tmp/nagvis-#{nagvis.version}/install.sh"
          mode: 0o755
        @execute
          cmd: """
          /tmp/nagvis-#{nagvis.version}/install.sh -n #{nagvis.base_dir} -p #{nagvis.install_dir} \
          -l 'tcp:#{nagvis.livestatus_address}' -b mklivestatus -u #{httpd.user.name} -g #{httpd.group.name} -w /etc/httpd/conf.d -a y -q
          """
        @service_restart
          name: 'httpd'
        @write
          destination: "#{nagvis.install_dir}/version"
          content: "#{nagvis.version}"
        @remove destination: "/tmp/nagvis-#{nagvis.version}.tar.gz"
        @remove destination: "/tmp/nagvis-#{nagvis.version}"
