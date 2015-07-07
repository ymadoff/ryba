#!/bin/bash
#Zeppelin server port. Note that port+1 is used for web socket
export ZEPPELIN_PORT=8080  
#Where notebook file is saved
export ZEPPELIN_NOTEBOOK_DIR=notebook  
#Comma separated interpreter configurations [Class]. First interpreter become a default
export ZEPPELIN_INTERPRETERS=org.apache.zeppelin.spark.SparkInterpreter,org.apache.zeppelin.spark.PySparkInterpreter,org.apache.zeppelin.spark.SparkSqlInterpreter,org.apache.zeppelin.spark.DepInterpreter,org.apache.zeppelin.markdown.Markdown,org.apache.zeppelin.shell.ShellInterpreter,org.apache.zeppelin.hive.HiveInterpreter  
export ZEPPELIN_INTERPRETER_DIR=zeppelin.interpreter.dir  interpreter Zeppelin interpreter directory
#MASTER    N/A Spark master url. eg. spark://master_addr:7077. Leave empty if you want to use local mode
#ZEPPELIN_JAVA_OPTS