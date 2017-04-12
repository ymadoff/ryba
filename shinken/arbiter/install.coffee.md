
# Shinken Arbiter Install

    module.exports = header: 'Shinken Arbiter Install', handler: ->
      {shinken} = @config.ryba
      {arbiter} = @config.ryba.shinken

## IPTables

| Service          | Port  | Proto | Parameter              |
|------------------|-------|-------|------------------------|
| shinken-arbiter  | 7770  |  tcp  |  arbiter.config.port   |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      rules = [{ chain: 'INPUT', jump: 'ACCEPT', dport: arbiter.config.port, protocol: 'tcp', state: 'NEW', comment: "Shinken Arbiter" }]
      for name, mod of arbiter.modules
        if mod.config?.port?
          rules.push { chain: 'INPUT', jump: 'ACCEPT', dport: mod.config.port, protocol: 'tcp', state: 'NEW', comment: "Shinken Arbiter #{name}" }
      @tools.iptables
        header: 'IPTables'
        rules: rules
        if: @config.iptables.action is 'start'

## Packages

      @service
        header: 'Packages'
        name: 'shinken-arbiter'

## Remove default config files

      @call header: 'Clean Install', ->
        @system.remove target: '/etc/shinken/realms/all.cfg'
        @system.remove target: '/etc/shinken/contacts/nagiosadmin.cfg'
        @system.remove target: '/etc/shinken/services/linux_disks.cfg'
        @system.remove target: '/etc/shinken/hosts/localhost.cfg'
        @system.remove target: '/etc/shinken/templates/templates.cfg'
        @system.remove target: '/etc/shinken/resource.d/path.cfg'

## Additional Modules

      @call header: 'Modules', ->
        installmod = (name, mod) =>
          @call unless_exec: "shinken inventory | grep #{name}", ->
            @file.download
              target: "#{shinken.build_dir}/#{mod.archive}.zip"
              source: mod.source
              cache_file: "#{mod.archive}.zip"
              unless_exec: "shinken inventory | grep #{name}"
              shy: true
            @tools.extract
              source: "#{shinken.build_dir}/#{mod.archive}.zip"
              shy: true
            @system.execute
              cmd: "shinken install --local #{shinken.build_dir}/#{mod.archive}"
            @system.execute
              cmd: "rm -rf #{shinken.build_dir}"
              shy: true
          for subname, submod of mod.modules then installmod subname, submod
        for name, mod of arbiter.modules then installmod name, mod

## Configuration

### Shinken Config

      @call header: 'Shinken Config', ->
        for service in ['arbiter', 'broker', 'poller', 'reactionner', 'receiver', 'scheduler']
          @file.render
            target: "/etc/shinken/#{service}s/#{service}-master.cfg"
            source: "#{__dirname}/resources/#{service}-master.cfg.j2"
            local: true
            context: "#{service}s": @contexts "ryba/shinken/#{service}"
        @file.properties
          target: '/etc/shinken/resource.d/resources.cfg'
          content:
            "$PLUGINSDIR$": shinken.plugin_dir
            "$DOCKER_EXEC$": 'docker exec poller-executor'
        @file
          target: '/etc/shinken/shinken.cfg'
          write: for k, v of {
            'date_format': 'iso8601'
            'shinken_user': shinken.user.name
            'shinken_group': shinken.group.name
            'interval_length': '1'
            'enable_flap_detection': '1'
            'no_event_handlers_during_downtimes': '1' }
              match: ///^#{k}=.*$///mg
              replace: "#{k}=#{v}"
              append: true
          eof: true

### Modules Config

      @call header: 'Modules Config', ->
        config_mod = (name, mod) =>
          @file.render
            target: "/etc/shinken/modules/#{mod.config_file}"
            source: "#{__dirname}/resources/module.cfg.j2"
            local: true
            context:
              name: name
              type: mod.type or name
              config: mod.config
          if mod.modules?
            config_mod sub_name, sub_mod for sub_name, sub_mod of mod.modules
        # Loop on all services
        for service in ['arbiter', 'broker', 'poller', 'reactionner', 'receiver', 'scheduler']
          [ctx] = @contexts "ryba/shinken/#{service}"
          for name, mod of ctx.config.ryba.shinken[service].modules
            config_mod name, mod

### Objects Config

Objects config

      @call header: 'Objects Config', ->
        # Un-templated objects
        ## Some commands need the lists of brokers (for their livestatus module)
        brokers = @contexts('ryba/shinken/broker').map( (ctx) -> ctx.config.host ).join ','
        #for obj in ['hostgroups', 'servicegroups', 'contactgroups', 'commands', 'realms', 'dependencies', 'escalations', 'timeperiods']
        for obj in ['hostgroups', 'contactgroups', 'commands', 'realms', 'dependencies', 'escalations', 'timeperiods']
          @file.render
            target: "/etc/shinken/#{obj}/#{obj}.cfg"
            source: "#{__dirname}/resources/#{obj}.cfg.j2"
            local: true
            context:
              "#{obj}": shinken.config[obj]
              brokers: brokers
        # Templated objects
        for obj in ['hosts', 'services', 'contacts']
          real = {}
          templated = {}
          for k, v of shinken.config[obj]
            if v.register is '0' then templated[k] = v
            else real[k] = v
          @file.render
            target: "/etc/shinken/templates/#{obj}.cfg"
            source: "#{__dirname}/resources/#{obj}.cfg.j2"
            local: true
            context: "#{obj}": templated
          @file.render
            target: "/etc/shinken/#{obj}/#{obj}.cfg"
            source: "#{__dirname}/resources/#{obj}.cfg.j2"
            local: true
            context: "#{obj}": real

### Services Config

      # @call header: 'Ryba Services Config', ->
        # @file.render
        #   target: '/etc/shinken/services/hadoop-services.cfg'
        #   source: "#{__dirname}/resources/hadoop-services.cfg.j2"
        #   local: true
        #   context: hosts: shinken.config.hosts
        # @file.render
        #   target: '/etc/shinken/services/watchers-services.cfg'
        #   source: "#{__dirname}/resources/watchers-services.cfg.j2"
        #   local: true
        #   context: hosts: shinken.config.hosts
        # @file.render
        #   target: '/etc/shinken/dependencies/hadoop-dependencies.cfg'
        #   source: "#{__dirname}/resources/hadoop-dependencies.cfg.j2"
        #   local: true
        #   context: hosts: shinken.config.hosts
