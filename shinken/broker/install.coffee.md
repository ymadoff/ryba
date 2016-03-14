
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
        @service name: 'python-pip'
        @service name: 'python-devel'
        @service name: 'python-requests'
        @service name: 'python-arrow'

## Webui Dependencies
  
      if 'webui2' in broker.config.modules

        @call header: 'Install Bottle', unless_exec: 'pip list | grep bottle', handler: ->
          @download
            source: 'https://pypi.python.org/packages/source/b/bottle/bottle-0.12.8.tar.gz'
            destination: 'bottle-0.12.8.tar.gz'
            md5: '13132c0a8f607bf860810a6ee9064c5b'
          @extract
            source: 'bottle-0.12.8.tar.gz'
          @execute
            cmd:"""
            cd bottle-0.12.8
            python setup.py build
            python setup.py install
            """
          @remove destination: 'bottle-0.12.8.tar.gz'
          @remove destination: 'bottle-0.12.8'

        @call header: 'Install Pymongo 3', unless_exec: 'pip list | grep pymongo', handler: ->
          # Bottle
          @download
            source: 'https://pypi.python.org/packages/source/p/pymongo/pymongo-3.0.3.tar.gz'
            destination: 'pymongo-3.0.3.tar.gz'
            md5: '0425d99c2a453144b9c95cb37dbc46e9'
          @extract
            source: 'pymongo-3.0.3.tar.gz'
          @execute
            cmd:"""
            cd pymongo-3.0.3
            python setup.py build
            python setup.py install
            """
          @remove destination: 'pymongo-3.0.3.tar.gz'
          @remove destination: 'pymongo-3.0.3'

## Layout

      @call header: 'Layout', handler: ->
        @mkdir
          destination: "#{shinken.user.home}/share"
          uid: shinken.user.name
          gid: shinken.group.name
        @mkdir
          destination: "#{shinken.user.home}/doc"
          uid: shinken.user.name
          gid: shinken.group.name
        @chown
          destination: shinken.log_dir
          uid: shinken.user.name
          gid: shinken.group.name
        @execute
          cmd: 'shinken --init'
          unless_exists: '.shinken.ini'

## Additional Shinken Modules

      @call header: 'Modules', handler: ->
        @execute
          cmd: 'shinken --init'
          unless_exists: '.shinken.ini'
        installmod = (name, mod) =>
          if mod.archive?
            @call unless_exec: "shinken inventory | grep #{name}", handler: ->
              @download
                destination: "#{mod.archive}.zip"
                source: mod.source
                cache_file: "#{mod.archive}.zip"
                unless_exec: "shinken inventory | grep #{name}"
              @extract
                source: "#{mod.archive}.zip"
              @execute
                cmd: "shinken install --local #{mod.archive}"
          else throw Error "Missing parameter: archive for broker.modules.#{name}"
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
