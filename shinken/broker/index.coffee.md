
# Shinken Broker

Has multiple modules (usually running in their own processes). Gets broks from
the scheduler and forwards them to the broker modules.
Modules decide if they handle a brok depending on a brok's type
(log, initial service/host status, check result, begin/end downtime, ...).
Modules process the broks in many different ways.
Some of the modules are:

* webui - updates in-memory objects and provides a webserver for the native Shinken GUI
* livestatus - updates in-memory objects which can be queried using an API by GUIs like Thruk or Check_MK Multisite
* graphite - exports data to a Graphite database
* ndodb - updates an ndo database (MySQL or Oracle)
* simple_log - centralize the logs of all the Shinken processes
* status_dat - writes to a status.dat file which can be read by the classic cgi-based GUI

To automatically download and install a module, please at least provide a version number,
and a type if different from the name.

    module.exports = ->
      'configure': [
        'ryba/shinken/configure'
        'ryba/shinken/broker/configure'
      ]
      'check':
        'ryba/shinken/broker/configure'
      'install': [
        'masson/core/yum'
        'masson/core/iptables'
        'ryba/shinken/commons'
        #'ryba/mongodb'
        'ryba/shinken/broker/install'
        'ryba/shinken/broker/start'
        'ryba/shinken/broker/check'
      ]
      'start':
        'ryba/shinken/broker/start'
      'stop':
        'ryba/shinken/broker/stop'
