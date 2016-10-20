#!/bin/sh
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

### BEGIN INIT INFO
# Provides:          solr
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Description:       Controls Apache Solr as a Service
### END INIT INFO

# Example of a very simple *nix init script that delegates commands to the bin/solr script
# Typical usage is to do:
#
#   cp bin/init.d/solr /etc/init.d/solr
#   chmod 755 /etc/init.d/solr
#   chown root:root /etc/init.d/solr
#   update-rc.d solr defaults
#   update-rc.d solr enable

# Where you extracted the Solr distribution bundle
SOLR_INSTALL_DIR={{ryba.solr.cloud_docker.latest_dir}}
SOLR_CONF_DIR={{ryba.solr.cloud_docker.conf_dir}}
SOLR_ENV={{ryba.solr.cloud_docker.conf_dir}}/solr.in.sh
RUNAS={{ryba.solr.user.name}}
ZK_NODE=
PORT=
EXEC_BOOTSTRAP=false



args=( "$@" )
{% raw %} arraylength=${#args[@]}  {% endraw %} 

for (( i=1; i<${arraylength}+1; i++ )); do
   if [ "${args[$i-1]}" == "--zk_node" ] ; 
    then ZK_NODE="${args[$i]}";
   fi
   if [ "${args[$i-1]}" == "--bootstrap" ] ; 
    then EXEC_BOOTSTRAP=true; 
   fi
   if [ "${args[$i-1]}" == "--port" ] ; 
    then PORT="${args[$i]}"; 
   fi
   
done;

if [ "$ZK_NODE" == "" ]; 
  then 
    echo "Missing --zk_node option"
    printusage;
    exit 1;
fi

#if [ "$PORT" ==  "" ]; 
  #then 
    #echo "No --port option specified"
  #else
    #echo "Setting Solr Instance port to ${PORT}"
    #echo "SOLR_PORT=\"${PORT}\" # RYBA DON'T OVERWRITE" >> {{ryba.solr.cloud_docker.conf_dir}}/solr.in.sh
#fi

echo "Linking solr.xml file"
if [ -L  "{{ryba.solr.user.home}}/solr.xml" ] || [ -e "{{ryba.solr.user.home}}/default" ] ; 
  then 
    source=`readlink {{ryba.solr.user.home}}/default`
    if [ "$source" == "{{ryba.solr.cloud_docker.conf_dir}}/solr.xml" ];
      then 
        echo 'File solr.xml is already linked'
      else
        rm -f {{ryba.solr.user.home}}/solr.xml
        ln -sf {{ryba.solr.cloud_docker.conf_dir}}/solr.xml  {{ryba.solr.user.home}}/solr.xml;
    fi;
  else
    rm -f {{ryba.solr.user.home}}/solr.xml
    ln -sf {{ryba.solr.cloud_docker.conf_dir}}/solr.xml  {{ryba.solr.user.home}}/solr.xml;
fi;

CMD="{{ryba.solr.cloud_docker.latest_dir}}/server/scripts/cloud-scripts/zkcli.sh -zkhost {{ryba.solr.cloud_docker.zk_connect}}/${ZK_NODE} -cmd list"


if $EXEC_BOOTSTRAP;
  then
    if `$CMD`;
    then 
      echo "Skipping: Zookeeper - Node already exists"
    else
      echo "Bootstrap Zookeeper Node ${ZK_NODE}"
      echo "{{ryba.solr.cloud_docker.latest_dir}}/server/scripts/cloud-scripts/zkcli.sh -zkhost {{ryba.solr.cloud_docker.zk_connect}}/${ZK_NODE} -cmd bootstrap -solrhome {{ryba.solr.user.home}}"
      ls -l /var/solr/data
      {{ryba.solr.cloud_docker.latest_dir}}/server/scripts/cloud-scripts/zkcli.sh -zkhost {{ryba.solr.cloud_docker.zk_connect}}/${ZK_NODE} -cmd bootstrap -solrhome {{ryba.solr.user.home}}
      echo "Uploading Security Configuration"
      {{ryba.solr.cloud_docker.latest_dir}}/server/scripts/cloud-scripts/zkcli.sh -zkhost {{ryba.solr.cloud_docker.zk_connect}} -cmd putfile /${ZK_NODE}/security.json {{ryba.solr.user.home}}/security.json
      echo "Enable SSL Scheme in Zookeeper"
      {{ryba.solr.cloud_docker.latest_dir}}/server/scripts/cloud-scripts/zkcli.sh -zkhost {{ryba.solr.cloud_docker.zk_connect}}/${ZK_NODE} -cmd clusterprop -name urlScheme -val https
    fi;
fi    

function printusage() {
  echo 'docker_entrypoint.sh --zk_node solr-cluster-1 --port 8983 [--bootstrap]'
}

function wait_execute() {
  until $CMD
do
  echo "Bootstraping Zookeeper node: $ZK_NODE"
  echo "Waiting 3 seconds...."
  sleep 3
  
done
}

wait_execute;



if [ ! -d "$SOLR_INSTALL_DIR" ]; then
  echo "$SOLR_INSTALL_DIR not found! Please check the SOLR_INSTALL_DIR setting in your $0 script."
  exit 1
fi



  ${SOLR_INSTALL_DIR}/bin/solr start -c -z {{ryba.solr.cloud_docker.zk_connect}}/${ZK_NODE} -s /var/solr/data -f
