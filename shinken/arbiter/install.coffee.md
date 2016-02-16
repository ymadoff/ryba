
# Shinken Arbiter Install

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/yum'
    module.exports.push 'ryba/shinken'

## IPTables

| Service          | Port  | Proto | Parameter              |
|------------------|-------|-------|------------------------|
| shinken-arbiter  | 7770  |  tcp  |  arbiter.config.port   |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

    module.exports.push header: 'Shinken Arbiter # IPTables', handler: ->
      {arbiter} = @config.ryba.shinken
      rules = [{ chain: 'INPUT', jump: 'ACCEPT', dport: arbiter.config.port, protocol: 'tcp', state: 'NEW', comment: "Shinken Arbiter" }]
      for name, mod of arbiter.modules
        if mod.config?.port?
          rules.push { chain: 'INPUT', jump: 'ACCEPT', dport: mod.config.port, protocol: 'tcp', state: 'NEW', comment: "Shinken Arbiter #{name}" }
      @iptables
        rules: rules
        if: @config.iptables.action is 'start'

## Packages

    module.exports.push header: 'Shinken Arbiter # Packages', handler: ->
      @service name: 'shinken-arbiter'

## Layout

    module.exports.push header: 'Shinken Arbiter # Layout', handler: ->
      {shinken} = @config.ryba
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

## Additional Modules

    module.exports.push header: 'Shinken Arbiter # Modules', handler: ->
      {shinken, shinken:{arbiter}} = @config.ryba
      return unless Object.keys(arbiter.modules).length > 0
      for name, mod of arbiter.modules
        if mod.archive?
          @download
            destination: "#{mod.archive}.zip"
            source: mod.source
            cache_file: "#{mod.archive}.zip"
            unless_exec: "shinken inventory | grep #{name}"
          @extract
            source: "#{mod.archive}.zip"
            unless_exec: "shinken inventory | grep #{name}"
          @execute
            cmd: "shinken install --local #{mod.archive}"
            unless_exec: "shinken inventory | grep #{name}"
        else throw Error "Missing parameter: archive for arbiter.modules.#{name}"

## Remove default config files

Some default files in the configuration define properties that are configured elsewhere.
Conflicts can appear.

    module.exports.push header: 'Shinken Arbiter # Clean Config', handler: ->
      @remove destination: '/etc/shinken/realms/all.cfg'
      @remove destination: '/etc/shinken/contacts/nagiosadmin.cfg'
      @remove destination: '/etc/shinken/services/linux_disks.cfg'
      @remove destination: '/etc/shinken/hosts/localhost.cfg'
      @remove destination: '/etc/shinken/templates/templates.cfg'
      @remove destination: '/etc/shinken/resource.d/path.cfg'
      #TODO remove default modules conf with a non predictive name
      #@remove destination: '/etc/shinken/modules/TODO'

## Configuration

### Shinken Config

    module.exports.push header: 'Shinken Arbiter # Shinken Config', handler: ->
      {shinken} = @config.ryba
      for service in ['arbiter', 'broker', 'poller', 'reactionner', 'receiver', 'scheduler']
        @render
          destination: "/etc/shinken/#{service}s/#{service}-master.cfg"
          source: "#{__dirname}/resources/#{service}-master.cfg.j2"
          local_source: true
          context: "#{service}s": @contexts "ryba/shinken/#{service}"
      @write_properties
        destination: '/etc/shinken/resource.d/resources.cfg'
        content:
          "$PLUGINSDIR$": shinken.plugin_dir
          "$DOCKER_EXEC$": 'docker exec poller-executor'
      @write
        destination: '/etc/shinken/shinken.cfg'
        write: for k, v of {
          'date_format': 'iso8601'
          'shinken_user': shinken.user.name
          'shinken_group': shinken.group.name
          'interval_length': '1' }
            match: ///^#{k}=.*$///mg
            replace: "#{k}=#{v}"
            append: true
        eof: true

### Modules Config

    module.exports.push header: 'Shinken Arbiter # Modules Config', handler: ->
      config_mod = (name, mod) =>
        @render
          destination: "/etc/shinken/modules/#{name}.cfg"
          source: "#{__dirname}/resources/module.cfg.j2"
          local_source: true
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

Objects config, except services

    module.exports.push header: 'Shinken Arbiter # Objects Config', handler: ->
      {shinken} = @config.ryba
      # Un-templated objects
      for obj in ['hostgroups', 'servicegroups', 'contactgroups', 'commands', 'realms', 'dependencies', 'escalations', 'timeperiods']
        @render
          destination: "/etc/shinken/#{obj}/#{obj}.cfg"
          source: "#{__dirname}/resources/#{obj}.cfg.j2"
          local_source: true
          context: "#{obj}": shinken.config[obj]
      # Templated objects
      for obj in ['hosts', 'services', 'contacts']
        real = {}
        templated = {}
        for k, v of shinken.config[obj]
          if parseInt(v.register) is 0 then templated[k] = v
          else real[k] = v
        @render
          destination: "/etc/shinken/templates/#{obj}.cfg"
          source: "#{__dirname}/resources/#{obj}.cfg.j2"
          local_source: true
          context: "#{obj}": templated
        @render
          destination: "/etc/shinken/#{obj}/#{obj}.cfg"
          source: "#{__dirname}/resources/#{obj}.cfg.j2"
          local_source: true
          context: "#{obj}": real

### Services Config

    module.exports.push header: 'Shinken Arbiter # Services Config', handler: ->
      {shinken} = @config.ryba
      @render
        destination: "/etc/shinken/services/hadoop-services.cfg"
        source: "#{__dirname}/resources/hadoop-services.cfg.j2"
        local_source: true
        context: hosts: shinken.config.hosts
      @render
        destination: "/etc/shinken/dependencies/hadoop-dependencies.cfg"
        source: "#{__dirname}/resources/hadoop-dependencies.cfg.j2"
        local_source: true
        context: hosts: shinken.config.hosts

## Dependencies

    fs = require 'fs'
    url = require 'url'
