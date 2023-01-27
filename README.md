# Overview

This module lets you manage the ALICE XrootD storage element with Puppet. The module can install, configure and ensure the correct state of the `xrood` and `cmsd` daemons. It also configures the monitoring daemon `mlsensor`.

# Usage

The user has to set the following parameters:

* `$se_name` - the ALICE storage element name (e.g. ALICE::Prague::SE)
* `$manager_hostname` - hostname of the server, that has the manager role in the xrootd cluster
* `$monalisa_host` - hostname of the server running the monalisa monitoring metric collecting daemon, usually the VOBox

The following parameters should be passed either directly, or set in hiera:

* `$filesystem_mounts` - root directories of the data space (usually filesystem mounts, hence the name)
* `$service_ensure` - the services can be either running or stopped (deafult is 'running')
* `$readonly` - if set to `true`, the node is set readonly. Useful for draining. (default is `false`)

The rest of the parameters are optional and their names should be self-explanatory

# Work to do:
* branch to support more operating systems than centos7
* add repository management
* improve documentation
