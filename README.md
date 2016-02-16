Package: alinex-dbreport
=================================================

[![Build Status](https://travis-ci.org/alinex/node-dbreport.svg?branch=master)](https://travis-ci.org/alinex/node-dbreport)
[![Coverage Status](https://coveralls.io/repos/alinex/node-dbreport/badge.png?branch=master)](https://coveralls.io/r/alinex/node-dbreport?branch=master)
[![Dependency Status](https://gemnasium.com/alinex/node-dbreport.png)](https://gemnasium.com/alinex/node-dbreport)

Run some database queries and send their results using email. The main features are:

- work on any database
- fully configurable
- send results as csv
- cli interface

It can be started from command line or triggered using cron.

> It is one of the modules of the [Alinex Universe](http://alinex.github.io/code.html)
> following the code standards defined in the [General Docs](http://alinex.github.io/node-alinex).


Install
-------------------------------------------------

[![NPM](https://nodei.co/npm/alinex-dbreport.png?downloads=true&downloadRank=true&stars=true)
 ![Downloads](https://nodei.co/npm-dl/alinex-dbreport.png?months=9&height=3)
](https://www.npmjs.com/package/alinex-dbreport)

Install the package globally using npm on a central server. From there all your
machines may be checked:

``` sh
sudo npm install -g alinex-dbreport --production
```

After global installation you may directly call `dbreport` from anywhere.

``` sh
dbreport --help
```

Always have a look at the latest [changes](Changelog.md).


Usage
-------------------------------------------------

You can simple call the `dbreport` command with at least one of the configured
reports:

    > dbreport <job>... [<options>]...

    Initializing...
    Run the jobs...
    Goodbye

To get some more information call it with debugging:

    > DEBUG=dbreport dbreport <job>... [<options>]...

    Initializing...
    Run the jobs...
      dbreport start tables job +0ms
      dbreport run query tables: SELECT table_schema, table_name FROM information_schema.tables ORDER BY table_schema, table_name +1ms
      dbreport sending email to betriebsteam@divibib.com... +547ms
      dbreport using SMTP +3ms
      dbreport message send {accepted: [ 'betriebsteam@divibib.com' ],
      rejected: [],
      response: '250 2.0.0 from MTA(smtp:[172.16.51.30]:10025): 250 2.0.0 Ok: queued as 7C61520AB5',
      envelope:
       { from: 'alexander.schilling@divibib.com',
         to: [ 'betriebsteam@divibib.com' ] },
      messageId: '1454671119582-6f16f637-c8a84be8-46bf2d0c@divibib.com' } +2ms
    Goodbye

Global options:

    -C, --nocolors  turn of color output
    -v, --verbose   run in verbose mode
    -h, --help      Show help

Use other email address for test:

    -m, --mail      give a specific mail address


Configuration
-------------------------------------------------
The most parts are configurable without any code change.


### Email Templates

This templates are used for sending emails out. They will be defined under
`/dbreport/email`:

``` yaml
# Email Templates
# =================================================


# Default Email Templates
# -------------------------------------------------
This will extend/overwrite the allready existing setup within the code.
default:
  # specify how to connect to the server
  transport: smtp://alexander.schilling%40divibib.com:<<<env://PW_ALEX_DIVIBIB_COM>>>@mail.divibib.com
  # sender address
  from: alexander.schilling@divibib.com

  # content
  locale: en
  subject: >
    Database Report: {{name}}
  body: |+
    {{conf.title}}
    ==========================================================================

    {{conf.description}}

    > Started at {{date}}

    See the attached files!
```

Like you see, you can use handlebar syntax to use some variables from the code.
You can also define different templates which can be referenced from within the
job.

### jobs

The main part is the configuration of each single, possible job. At best this
should be done each in it's own file like `/dbreport/job/xxxx`:

``` yaml
# Test Job
# =================================================

# Job Meta
# -------------------------------------------------
title: Vorhandene Tabellen
description: |+
  Dieser Bericht zeigt alle Tabellen die zum Zeitpunkt der Ausführung in der manage
  life Datenbank existieren. Die genaue Liste liegt als tables.csv dieser Email bei.

# Queries to Run
# -------------------------------------------------
query:
  tables:
    database: dvb_manage_live
    command: >
      SELECT    table_schema, table_name
      FROM      information_schema.tables
      ORDER BY  table_schema, table_name

# Where to Send them to
# -------------------------------------------------
email:
  base: default
  to: betriebsteam@divibib.com
```

As you see above you have the three parts to fill up:
- meta data to be used in the email like: '{{conf.title}}'
- queries with a name, the db reference name and code to execute
- email sending

The database is defined below. While the email mostly uses a 'base' template
and only defines the parts which are changed to the base template. So a propper
use of the templates will help you minimize the configuration for the jobs.

### Database

Also you need the setup under `/database` like described in
[Database](http://alinex.github.io/node-database).
This is used to make the specific database connections.


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
