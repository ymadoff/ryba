
# NagVis Install

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/yum'

## IPTables

| Service           | Port  | Proto | Parameter       |
|-------------------|-------|-------|-----------------|
|  nagvis           | 50000 |  tcp  |                 |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

    module.exports.push header: 'NagVis # IPTables', handler: ->
      {nagvis} = @config.ryba
      rules = [{ chain: 'INPUT', jump: 'ACCEPT', dport: nagvis.port, protocol: 'tcp', state: 'NEW', comment: "NagVis" }]
      @iptables
       rules: rules
       if: @config.iptables.action is 'start'

## Packages

    module.exports.push header: 'NagVis # Packages', handler: ->
      @service name: 'httpd'
      @service name: 'php'
      @service name: 'php-common'
      @service name: 'php-pdo'
      @service name: 'php-gd'
      @service name: 'php-mbstring'
      @service name: 'php-mysql'
      # @service name: 'php-php-gettext'
      @service name: 'graphviz-php'

## Install

    module.exports.push header: 'NagVis # Install', handler: ->
      {nagvis, shinken} = @config.ryba
      @download
        source: nagvis.source
        destination: "/tmp/nagvis-#{nagvis.version}.tar.gz"
        unless_exists: "#{nagvis.install_dir}/COPYING"
      @extract
        source: "/tmp/nagvis-#{nagvis.version}.tar.gz"
        unless_exists: "#{nagvis.install_dir}/COPYING"
      @chmod
        destination: "/tmp/nagvis-#{nagvis.version}/install.sh"
        mode: 0o755
        unless_exists: "#{nagvis.install_dir}/COPYING"
      @execute
        cmd: """
        cd /tmp/nagvis-#{nagvis.version}
        ./install.sh -n #{shinken.user.home} -p #{nagvis.install_dir} \
        -l 'tcp:127.0.0.1:#{nagvis.port}' -b mklivestatus -u apache -g apache -w /etc/httpd/conf.d -a y -q
        """
        unless_exists: "#{nagvis.install_dir}/COPYING"
      @remove destination: "/tmp/nagvis-#{nagvis.version}.tar.gz"
      @remove destination: "/tmp/nagvis-#{nagvis.version}"
