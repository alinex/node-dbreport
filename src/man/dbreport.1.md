dbreport
=================================================

Run some database queries and send their results using email. The main features are:

- work on any database
- fully configurable
- send results as csv or xlsx
- cli interface

It can be started from command line or triggered using cron.


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


Read more
-------------------------------------------------
To get the full documentation including configuration description look into
[DbReport](http://alinex.github.io/node-dbreport).


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
