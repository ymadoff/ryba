
# Apache Nifi

Apache nifi supports powerful and scalable directed graphs of data routing, transformation,
and system mediation logic. Some of the high-level capabilities and objectives of Apache NiFi includes:
  * Web-based user interface
  * Highly configurable
  * Data Provenance
  * Designed for extension
  * SSL, SSH, HTTPS, encrypted content, etc...
  
  The NiFi Cluster Manager is an instance of NiFi that provides the sole management point for the cluster. 
  It communicates dataflow changes to the nodes and receives health and status information from the nodes
  
      module.exports = -> 
        'prepare': [
          'ryba/nifi/manager/prepare'
        ]
        'configure': [
          'ryba/nifi/manager/configure'
        ]
        'install': [
          'ryba/hadoop/core'
          'ryba/nifi/manager/install'
          'ryba/nifi/manager/start'
          'ryba/nifi/manager/wait'
          'ryba/nifi/manager/check'
        ]
        'check': [
          'ryba/nifi/manager/check'
        ]
        'status': [
          'ryba/nifi/manager/status'
        ]
        'start': [
          'ryba/nifi/manager/start'
        ]
        'stop': [
          'ryba/nifi/manager/stop'
        ]
