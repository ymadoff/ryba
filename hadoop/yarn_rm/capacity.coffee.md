

# Capacity Scheduler

The [CapacityScheduler][capacity], a pluggable scheduler for Hadoop which allows for
multiple-tenants to securely share a large cluster such that their applications
are allocated resources in a timely manner under constraints of allocated
capacities

Note about the property "yarn.scheduler.capacity.resource-calculator": The
default i.e. "org.apache.hadoop.yarn.util.resource.DefaultResourseCalculator"
only uses Memory while DominantResourceCalculator uses Dominant-resource to
compare multi-dimensional resources such as Memory, CPU etc. A Java
ResourceCalculator class name is expected.

    module.exports = 
      header: 'YARN RM # Capacity Scheduler',
      if: -> @config.ryba.yarn.site['yarn.resourcemanager.scheduler.class'] is 'org.apache.hadoop.yarn.server.resourcemanager.scheduler.capacity.CapacityScheduler'
      handler: ->
        {hadoop_conf_dir, capacity_scheduler} = @config.ryba
        @hconfigure
          destination: "#{hadoop_conf_dir}/capacity-scheduler.xml"
          default: "#{__dirname}/../../resources/core_hadoop/capacity-scheduler.xml"
          local_default: true
          properties: capacity_scheduler
          merge: false
          backup: true
        @execute
          cmd: mkcmd.hdfs @, 'service hadoop-yarn-resourcemanager status && yarn rmadmin -refreshQueues || exit'
          if: -> @status -1

## Dependencies

    mkcmd = require '../../lib/mkcmd'
