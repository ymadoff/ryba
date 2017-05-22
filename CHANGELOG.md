
# Changelog

## Trunk

* refactor hdp and initial commit for hdf
* ambari: reliable wait and check
* ambari: prevent ambari principal collision
* spark historyserver: configure heapsize
* hadoop: add systemd scripts
* knox: add HBase WebUI service
* hcatalog: autoconfig when mariadb is installed
* shinken: add tests for Phoenix QS, Atlas, Ranger, WebHCat
* ambari: new standalone service
* package: latest dependencies
* ambari server: ssl, trustore and jaas
* hdfs: validate hostnames
* ambari agent: dont wait for ambari server
* ambari server: create hadoop group
* druid: default values for max direct memory size
* ambari server: wait before check
* oozie: improve and isolate checks
* src: refactor wait to prepare options
* huedocker: update docker files preparation
* huedocker: password required
* huedocker: refactor ssl usage
* webhcat: fix metastore principal
* webhcat: fix log4j
* yarn: config normalisation when site not defined
* hdfs: krb5 password now required
* ambari server: re-ordonnate ambari-server init and security
* src: factor multi string indentation
* yarn rm: retry ha check 3 times
* kafka: refactor and sleep 1s before producers
* src: fix backup renamed as remove
* yarn: cgroup labels
* lib mkcmd: generic command
* hadoop: move distributed shell into mapreduce
* hive hcatalog: port defined in configuration
* hadoop: honors user environmental variables #74
* hdfs: fix log cleanup in jn and zkfc
* pig: disabled old fix
* druid: database password now required
* oozie: database password now required
* hive: database password now required
* src: normalize identies creation
* hdfs nn: fix fsck check by using nn config
* benchmark: first refactor
* ambari server: desactivate sudo
* ambari server: master key support
* ambari server: export blueprint definition
* ambari server: write urls based on ssl activation
* yarn nm: enforce memory check #70
* src: remove depracated usage of destination
* oozie: fix lzo package incompatibility
* hdfs dn: fix lzo package incompatibility
* ambari server: fix typos
* druid: mysql support
* druid: upgrade to version 0.10.0
* druid: init script support for rh7
* druid: remove calls to base install
* ambari: remove jdbc options from setup
* ambari: set default https port
* kafka broker: add log and run dirs in layout
* replace system.discover by if_os condition
* ambari: update admin password
* huedocker: ssh configuration from configuration
* ambari server: check
* ambari: agents wait for server
