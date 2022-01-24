# Salvo

## What is Salvo

This is a framework that abstracts executing multiple benchmarks of the Envoy Proxy using [NightHawk](https://github.com/envoyproxy/nighthawk).

## Goals of Salov

Salvo allows Envoy developers to perform A/B testing to monitor performance change of Envoy. Salvo provides the local excution mode allowing developers to run a benchark on their own machine and also provides the remote excution mode allowing run a benchmark on remote machines, such as remote CI systems.

## Dependencies

The `install_deps.sh` script can be used to install any dependencies required by Salvo.

## Building Salvo

To build Salvo, use the following command:

```bash
bazel build //...
```

## Benchmark Test Cases for Salvo

Benchmark test cases for Salvo are defined as Python files with test cases written in pytest framework, here is an example: https://github.com/envoyproxy/nighthawk/blob/main/benchmarks/test/test_discovery.py. Users can provide thier own test cases files into Savlo.

## Control Documents

The control document defines the data needed to execute a benchmark. At the moment, we support the fully dockerized benchmark and the scavenging benchmark. The work for the binary benchmark is in progress.

### Fully Dockerized Benchmark

The Fully Dockerized Benchmark discoveres user supplied tests for execution and uses docker images to run the tests. In the example below, the user supplied tests files are located in `/home/ubuntu/nighthawk_tests` and are mapped to a volume in the docker container.

To run the dockerized benchmark, create a file with the following example contents:

JSON Example:

```json
{
  "remote": false,
  "dockerizedBenchmark": true,
  "images": {
    "reuseNhImages": true,
    "nighthawkBenchmarkImage": "envoyproxy/nighthawk-benchmark-dev:latest",
    "nighthawkBinaryImage": "envoyproxy/nighthawk-dev:latest",
    "envoyImage": "envoyproxy/envoy:v1.21.0"
  },
  "environment": {
    "testVersion": "IPV_V4ONLY",
    "envoyPath": "envoy",
    "outputDir": "/home/ubuntu/nighthawk_output",
    "testDir": "/home/ubuntu/nighthawk_tests"
  }
}
```

YAML Example:

```yaml
remote: false
dockerizedBenchmark: true
environment:
  outputDir: '/home/ubuntu/nighthawk_output'
  testDir: '/home/ubuntu/nighthawk_tests'
  testVersion: IPV_V4ONLY
  envoyPath: 'envoy'
images:
  reuseNhImages: true
  nighthawkBenchmarkImage: 'envoyproxy/nighthawk-benchmark-dev:latest'
  nighthawkBinaryImage: 'envoyproxy/nighthawk-dev:latest'
  envoyImage: "envoyproxy/envoy:v1.21.0"
```

`remote`: Whether to enable remote excution mode.

`dockerizedBenchmark`: It will run fully dockerized benchmarks.

`environment.outputDir`: The directory where benchmark result will be placed.

`environment.testDir`: The directory where test case files placed, it's optional. If you want to provide your own test cases, put test files like [this one](https://github.com/envoyproxy/nighthawk/blob/main/benchmarks/test/test_discovery.py) into the testDir.

`environment.testVersion`: Specify the ip address family to use, choose from "IPV_V4ONLY", "IPV_V6ONLY" and "ALL".

`environment.envoyPath`: Envoy is called 'Envoy' in the Envoy Docker image.

`images.reuseNhImages`: Whether to reuse Nighthawk image if it exsists on the machine.

`images.nighthawkBenchmarkImage`: The image of nighthawk benchmarking tests.   

`images.nighthawkBinaryImage`: Nighthawk tools will be sourced from this Docker image.

`images.envoyImage`: The specific Envoy docker image to test.

In both examples above, the envoy image being tested is a specific tag. This tag can be replaced with "latest" to test the most recently created image against the previous image built from the prior tag. If a commit hash is used, we find the previous commit hash and benchmark that container. In summary, tags are compared to tags, hashes are compared to hashes.

### Scavenging Benchmark

The 'Scavenging' Benchmark runs the benchmark on the local machine and uses a specified Envoy image for testing. Tests are discovered in the specified directory in the Environment object:

```yaml
remote: false
scavengingBenchmark: true
environment:
  envoyPath: envoy
  outputDir: /home/ubuntu/nighthawk_output
  testDir: /home/ubuntu/nighthawk_tests
  testVersion: IPV_V4ONLY
images:
  nighthawkBenchmarkImage: envoyproxy/nighthawk-benchmark-dev:latest
  nighthawkBinaryImage: envoyproxy/nighthawk-dev:latest
  envoyImage: envoyproxy/envoy:v1.21.0
  reuseNhImages: true
source:
- identity: SRCID_ENVOY
  commit_hash: v1.21.0
  source_url: https://github.com/envoyproxy/envoy.git
  bazelOptions:
  - parameter: --jobs 4
  - parameter: --define tcmalloc=gperftools
- identity: SRCID_NIGHTHAWK
  source_url: https://github.com/envoyproxy/nighthawk.git
```

`scavengingBenchmark`: It will run scavenging benchmarks.

`source.identity`: Specify whether this source location is Envoy or NightHawk.

`source.commit_hash`: Specify a commit hash if applicable. If not specified we will determine this from the source tree. We will also use this field to identify the corresponding NightHawk or Envoy image used for the benchmark.

`source.BazelOption`: A list of compiler options and flags to supply to bazel when building the source of NightHawk or Envoy. 

In this example, the v1.21.0 Envoy tag is pulled and an Envoy image generated where the Envoy binary has profiling enabled. The user may specify option strings supported by bazel to adjust the compilation process.

### Binary Benchmark

The binary benchmark runs an envoy binary as the test target.  The binary is compiled from the source commit specified. As is the case with other benchmarks as well, the previous commit is deduced and a benchmark is executed for these code points. All NightHawk components are built from source. This benchmark runs on the local host directly.

Example Job Control specification for executing a binary benchmark:

```yaml
remote: false
binaryBenchmark: true
environment:
  outputDir: /home/ubuntu/nighthawk_output
  testDir: /home/ubuntu/nighthawk_tests
  testVersion: IPV_V4ONLY
images:
  nighthawkBenchmarkImage: envoyproxy/nighthawk-benchmark-dev:latest
  nighthawkBinaryImage: envoyproxy/nighthawk-dev:latest
source:
- identity: SRCID_ENVOY
  commit_hash: v1.21.0
  source_url: https://github.com/envoyproxy/envoy.git
- identity: SRCID_NIGHTHAWK
  source_url: https://github.com/envoyproxy/nighthawk.git
```

`binaryBenchmark`: It will run binary benchmarks.


## Running Salvo

The resulting 'binary' in the bazel-bin directory can then be invoked with a job control document:

```bash
bazel-bin/salvo --job <path to>/demo_jobcontrol.yaml
```

Salvo creates a symlink in the local directory to the location of the  output artifacts for each Envoy version tested.

## Testing Salvo

From the envoy-perf project directory, run the do_ci.sh script with the "test" argument. Since this installs packages packages, it will need to be run as root.

To test Salvo itself, change into the salvo directory and use:

```bash
bazel test //...
```
