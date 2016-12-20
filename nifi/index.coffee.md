
# Apache NiFi

Apache NiFi supports powerful and scalable directed graphs of data routing,
transformation, and system mediation logic. Some of the high-level capabilities 
and objectives of Apache NiFi includes:
  * Web-based user interface
  * Highly configurable
  * Data Provenance
  * Designed for extension
  * SSL, SSH, HTTPS, encrypted content, etc...

      module.exports =
        use:
          hadoop_core: 'ryba/hadoop/core'
          openldap_server: 'masson/core/openldap_server'
          zoo_server: 'ryba/zookeeper/server'
        configure:
          'ryba/nifi/configure'
        commands:
          'install': [
            'ryba/nifi/install'
            'ryba/nifi/start'
            'ryba/nifi/check'
          ]
          'check':
            'ryba/nifi/check'
          'status':
            'ryba/nifi/status'
          'start':
            'ryba/nifi/start'
          'stop':
            'ryba/nifi/stop'
