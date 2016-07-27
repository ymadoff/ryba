
# Shinken Poller Configure

    module.exports = handler: ->
      {shinken} = @config.ryba
      # Add shinken to docker group
      shinken.user.groups ?= ['docker']
      poller = shinken.poller ?= {}
      # Executor
      poller.executor ?= {}
      poller.executor.krb5 ?= {}
      poller.executor.krb5.privileged ?= {}
      poller.executor.krb5.privileged.principal ?= "#{shinken.user.name}_admin/#{@config.host}@#{@config.ryba.realm}"
      poller.executor.krb5.privileged.keytab ?= "/etc/security/keytabs/shinken-poller.privileged.keytab"
      poller.executor.krb5.unprivileged ?= {}
      poller.executor.krb5.unprivileged.principal ?= "#{shinken.user.name}/#{@config.host}@#{@config.ryba.realm}"
      poller.executor.krb5.unprivileged.keytab ?= "/etc/security/keytabs/shinken-poller.unprivileged.keytab"
      poller.executor.resources_dir ?= shinken.user.home
      # Python modules to install
      poller.python_modules ?= {}
      poller.python_modules.requests ?= {}
      poller.python_modules.requests.archive ?= 'requests-2.5.1'
      poller.python_modules.requests.source ?= 'https://github.com/kennethreitz/requests/archive/v2.5.1.tar.gz'
      poller.python_modules.kerberos ?= {}
      poller.python_modules.kerberos.archive ?= 'kerberos-1.1.1'
      poller.python_modules.kerberos.source ?= 'https://pypi.python.org/packages/source/k/kerberos/kerberos-1.1.1.tar.gz'
      poller.python_modules.requests_kerberos ?= {}
      poller.python_modules.requests_kerberos.archive ?= 'requests-kerberos-0.7.0'
      poller.python_modules.requests_kerberos.source ?= 'https://github.com/requests/requests-kerberos/archive/0.7.0.tar.gz'
      # Additionnal Modules to install
      poller.modules ?= {}
      # Config
      poller.config ?= {}
      poller.config.port ?= 7771
      poller.config.spare ?= '0'
      poller.config.realm ?= 'All'
      poller.config.modules = [poller.config.modules] if typeof poller.config.modules is 'string'
      poller.config.modules ?= Object.keys poller.modules
      poller.config.tags = [poller.config.tags] if typeof poller.config.tags is 'string'
      poller.config.tags ?= []
      poller.config.use_ssl ?= shinken.config.use_ssl
      poller.config.hard_ssl_name_check ?= shinken.config.hard_ssl_name_check
