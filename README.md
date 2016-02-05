Package: alinex-dbreport
=================================================

[![Build Status](https://travis-ci.org/alinex/node-dbreport.svg?branch=master)](https://travis-ci.org/alinex/node-dbreport)
[![Coverage Status](https://coveralls.io/repos/alinex/node-dbreport/badge.png?branch=master)](https://coveralls.io/r/alinex/node-dbreport?branch=master)
[![Dependency Status](https://gemnasium.com/alinex/node-dbreport.png)](https://gemnasium.com/alinex/node-dbreport)

Run some database queries and send their results using email. The main features are
- work on any database
- fully configurable
- send results as csv or xlsx
- cli interface


Install
-------------------------------------------------

[![NPM](https://nodei.co/npm/alinex-dbreport.png?downloads=true&stars=true)](https://nodei.co/npm/alinex-dbreport/)


Usage
-------------------------------------------------

    Usage: dbreport <job> [<options>]...

    -C, --nocolors  turn of color output
    -v, --verbose   run in verbose mode
    -h, --help      Show help

    -m, --mail      give a specific mail address


Configuration
-------------------------------------------------

``` yaml
dbreport:
  email:  # templates
    <name>: wie monitor
  job:
    <job>: # job entry
      database: reference
      query:
        <name>: select count(*)
#      combine: <func>
      email:
        base: default
        to: xxx@divibib.com
        subject: Report {{name}}
        body: See the result attached!
database:
  <name>: wie database komponente
```


Special Combine
-------------------------------------------------
For special reports a special combine method may be coded to use.


License
-------------------------------------------------

Copyright 2016 Alexander Schilling

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

>  <http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
