
# Benchmarks for an Hadoop Cluster

http://www.michael-noll.com/blog/2011/04/09/benchmarking-and-stress-testing-an-hadoop-cluster-with-terasort-testdfsio-nnbench-mrbench/

Benchmarking consists of running a number of tests stressing the Hadoop cluster
to measure its maximum computing capabilities and validate its configuration.

In the Hadoop context of this script, Benchmarking consists of determining the
DataNode's resources (disk, cpu, ram), running the following tests multiple times
and extract reporting informations :
  * TeraSort suite

    module.exports =
      configure:
        'ryba/benchmark/configure'
      commands:
        'benchmark' : [
          'ryba/benchmark/discover'
          'ryba/benchmark/terasort'
        ]
