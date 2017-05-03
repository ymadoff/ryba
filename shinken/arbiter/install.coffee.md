
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
        for subsrv in ['arbiter', 'broker', 'poller', 'reactionner', 'receiver', 'scheduler']
          @file.render
            header: subsrv
            target: "/etc/shinken/#{subsrv}s/#{subsrv}-master.cfg"
            source: "#{__dirname}/resources/#{subsrv}.cfg.j2"
            local: true
            context: "#{subsrv}s": @contexts "ryba/shinken/#{subsrv}"
            backup: true
        @file.properties
          target: '/etc/shinken/resource.d/resources.cfg'
          content:
            "$PLUGINSDIR$": shinken.plugin_dir
            "$DOCKER_EXEC$": 'docker exec poller-executor'
          backup: true
        @file
          target: '/etc/shinken/shinken.cfg'
          write: for k, v of shinken.config.shinken
            match: ///^#{k}=.*$///mg
            replace: "#{k}=#{v}"
            append: true
          backup: true
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
              type: mod.type
              config: mod.config
            backup: true
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
            header: obj
            target: "/etc/shinken/#{obj}/#{obj}.cfg"
            source: "#{__dirname}/objects/resources/#{obj}.cfg.j2"
            local: true
            context:
              "#{obj}": shinken.config[obj]
              brokers: brokers
            backup: true
        # Templated objects
        for obj in ['hosts', 'services', 'contacts']
          real = {}
          templated = {}
          for k, v of shinken.config[obj]
            if "#{v.register}" is '0' then templated[k] = v
            else real[k] = v
          @file.render
            header: "#{obj} templates"
            target: "/etc/shinken/templates/#{obj}.cfg"
            source: "#{__dirname}/objects/resources/#{obj}.cfg.j2"
            local: true
            context: "#{obj}": templated
            backup: true
          @file.render
            header: obj
            target: "/etc/shinken/#{obj}/#{obj}.cfg"
            source: "#{__dirname}/objects/resources/#{obj}.cfg.j2"
            local: true
            context: "#{obj}": real
            backup: true

## Check Config

This will execute a dry-run: arbiter will only check the configuration and exit
This output is more verbose than a failed start so it runs at the end of install

      @system.execute
        header: 'Check config'
        cmd: 'shinken-arbiter -v -r -c /etc/shinken/shinken.cfg'
