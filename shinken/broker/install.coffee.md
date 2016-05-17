
# Shinken Broker Install

    module.exports = header: 'Shinken Broker Install', handler: ->
      {shinken} = @config.ryba
      {broker} = @config.ryba.shinken

## IPTables

| Service           | Port  | Proto | Parameter       |
|-------------------|-------|-------|-----------------|
|  shinken-broker   | 7772  |  tcp  |   config.port   |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      rules = [{ chain: 'INPUT', jump: 'ACCEPT', dport: broker.config.port, protocol: 'tcp', state: 'NEW', comment: "Shinken Broker" }]
      for name, mod of broker.modules
        if mod.config?.port?
          rules.push { chain: 'INPUT', jump: 'ACCEPT', dport: mod.config.port, protocol: 'tcp', state: 'NEW', comment: "Shinken Broker #{name}" }
      @iptables
        rules: rules
        if: @config.iptables.action is 'start'

## Packages

      @call header: 'Packages', handler: ->
        @service name: 'shinken-broker'
        @service name: 'python-requests'
        @service name: 'python-arrow'

## WebUI Dependencies

      @call header: 'Install WebUI Dependencies', if: 'webui2' in broker.config.modules, handler: ->
        for k, v of broker.modules['webui2'].pip_modules
          @call unless_exec: "pip list | grep #{k}", handler: ->
            @download
              source: v.url
              destination: "/var/tmp/shinken/#{k}-#{v.version}.tar.gz"
              md5: v.md5
            @extract
              source: "/var/tmp/shinken/#{k}-#{v.version}.tar.gz"
            @execute
              cmd:"""
              cd /var/tmp/shinken/#{k}-#{v.version}
              python setup.py build
              python setup.py install
              """
            @remove destination: "/var/tmp/shinken/#{k}-#{v.version}.tar.gz"
            @remove destination: "/var/tmp/shinken/#{k}-#{v.version}"

## Additional Shinken Modules

      @call header: 'Modules', handler: ->
        installmod = (name, mod) =>
          @call unless_exec: "shinken inventory | grep #{name}", handler: ->
            @download
              destination: "/var/tmp/shinken/#{mod.archive}.zip"
              source: mod.source
              cache_file: "#{mod.archive}.zip"
              unless_exec: "shinken inventory | grep #{name}"
              shy: true
            @extract
              source: "/var/tmp/shinken/#{mod.archive}.zip"
              shy: true
            @execute
              cmd: "shinken install --local /var/tmp/shinken/#{mod.archive}"
            @execute
              cmd: "rm -rf /var/tmp/shinken"
              shy: true
          for subname, submod of mod.modules then installmod subname, submod
        for name, mod of broker.modules then installmod name, mod

## Fix Groups View

Fix the hierarchical view in WebUI.
Could also be natively corrected in the next shinken version. (actually 2.4)

      @call header: 'Fix Groups View', handler: ->
        for object in  ['host', 'service']
          @write
            destination: "/usr/lib/python2.7/site-packages/shinken/objects/#{object}group.py"
            write: [
              match: new RegExp "'#{object}group_name': StringProp.*,$", 'm'
              replace:  "'#{object}group_name': StringProp(fill_brok=['full_status']), # RYBA\n        '#{object}group_members': StringProp(fill_brok=['full_status']),"
            ]
