Package: alinex-dbreport
=================================================

[![Build Status](https://travis-ci.org/alinex/node-dbreport.svg?branch=master)](https://travis-ci.org/alinex/node-dbreport)
[![Coverage Status](https://coveralls.io/repos/alinex/node-dbreport/badge.png?branch=master)](https://coveralls.io/r/alinex/node-dbreport?branch=master)
[![Dependency Status](https://gemnasium.com/alinex/node-dbreport.png)](https://gemnasium.com/alinex/node-dbreport)

Run some database queries and send their results using email. The main features are:

- work on any database
- fully configurable
- send results as csv
- pretty email format
- combine queries

It can be started from command line or triggered using cron.

> It is one of the modules of the [Alinex Universe](http://alinex.github.io/code.html)
> following the code standards defined in the [General Docs](http://alinex.github.io/develop).


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
    -> tables
    Goodbye

To get some more information call it with debugging:

    > DEBUG=dbreport dbreport <job>... [<options>]...

    Initializing...
    Run the jobs...
    -> tables
      dbreport start tables job +0ms
      dbreport run query tables: SELECT table_schema, table_name FROM information_schema.tables ORDER BY table_schema, table_name +1ms
      dbreport tables: 641 rows fetched +88ms
      dbreport sending email to betriebsteam@mycompany.com.. +547ms
      dbreport using SMTP +3ms
      dbreport message send {accepted: [ 'betriebsteam@mycompany.com' ],
      rejected: [],
      response: '250 2.0.0 from MTA(smtp:[172.16.51.30]:10025): 250 2.0.0 Ok: queued as 7C61520AB5',
      envelope:
       { from: 'alexander.schilling@mycompany.com',
         to: [ 'betriebsteam@mycompany.com' ] },
      messageId: '1454671119582-6f16f637-c8a84be8-46bf2d0c@mycompany.com' } +2ms
    Goodbye

Global options:

    -C, --nocolors  turn of color output
    -v, --verbose   run in verbose mode
    -h, --help      Show help

Use other email address for test:

    -m, --mail      give a specific mail address
    -j, --json      give an optional object of variables to the job


Configuration
-------------------------------------------------
The most parts are configurable without any code change.


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
variables:
  schema:
    type: 'string'

# Queries to Run
# -------------------------------------------------
query:
  tables:
    title: List of Tables
    description: a complete list of all relations in the database
    database: test_postgresql
    command: >
      SELECT relname
      FROM pg_class
      WHERE relname !~ '^(pg_|sql_)' AND relkind = 'r'
      AND relname not like '{{schema}}.%';
  indexes:
    title: List of Indexes
    description: a complete list of all indexes in the database
    database: test_postgresql
    command: >
      SELECT relname
      FROM pg_class
      WHERE relname !~ '^(pg_|sql_)' AND relkind = 'i';

# Compose
# -------------------------------------------------
compose:
  all:
    title: List of Objects
    description: a complete list of all objects in the database
    append:
      - tables
      - indexes
    # sort the list
    sort: relname
    reverse: true

# Where to Send them to
# -------------------------------------------------
# also go on for empty results
sendEmpty: true

email:
  base: default
  to: betrieb@mycompany.com
```

As you see above you have the four parts to fill up:

- meta data to be used in the email like: '{{conf.title}}'
- queries with a name, the db reference name and code to execute
- compose options (optional)
- email sending

#### Meta Data

Here only the `title` and `description` can be set tzo be used within the email
template. They are useable as  `{{conf.title}}` or `{{conf.description}}` in the
template.

The variables object define which variables are used within this job. You have to
give them from the command line by `--json ...`.

#### Queries

This let you define multiple database queries to execute. They are given as an
object with an alias name as key. This name can be used later in composing
multiple queries together.

If no `compose` setting is given they will used directly as the attached csv files.
Therefore the `title`, `description` and `sort` settings may be given. The resulting
CSV file names will use the title or alias.

The `database` setting is a reference to the database connection to use. This is
defined separately (see below).

The `command` string is the SQL to be executed. This will be send as is to the
database server. So there are no variables possible.

#### Compose

If you want to compose multiple query results together this section allows for.
It should contain an object of compositions to send as separate files. The
key of each entry is used as an alias.

Each composition contains:

- title <string> - to be used as filename and as template variable
- description <string> - to be used as template variable
- append 'true' or <list of query aliases>
- sort [<field>]... - list of sort fields (prepend with '-' for decreasing order)

Other composition methods may follow later.

#### Email

Here you have the option to prevent sending empty emails (without attached csv)
by setting `sendEmpty` to `false`.

The email part is exactly like defined above in the base email settings. So you
have the possibility to overwrite each value written there with the ones here.

While the email mostly uses a 'base' template and only defines the parts which
are changed to the base template. So a proper use of the templates will help
you minimize the configuration for the jobs.

### Email Templates

This templates are used for sending emails out. They will be defined under
`/email`:

``` yaml
# Email Templates
# =================================================


# Default Email Templates
# -------------------------------------------------
This will extend/overwrite the already existing setup within the code.
default:
  # specify how to connect to the server
  transport: smtp://alexander.schilling%40mycompany.de:<PASSWORD>@mail.mycompany.de
  # sender address
  from: alexander.schilling@mycompany.de
  replyTo: somebody@mycompany.de

  # content
  locale: en
  subject: >
    Database Report: {{name}}
  body: |+
    {{conf.title}}
    ==========================================================================

    {{conf.description}}

    Started at {{dateFormat date "LLL"}}:

    | Zeilen | Datei    | Beschreibung |
    | ------:| -------- | ------------ |
    {{#each result}}
    | {{rows}} | {{file}} | {{description}} |
    {{/each}}

    Find the files attached to your mail if data available!
```

To make it more modular you may also add a `base` setting to use the setting defined
there as a base and the options here may overwrite or enhance the base setup.

#### Transport

The transport setting defines how to send the email. This should specify the
connection for the mail server to use for sending. It is possible to do this using
a connection url like above with the syntax:

    <protocol>://<user>:<password>@<server>:<port>

Or you may specify it as object like:

``` yaml
transport:
  pool: <boolean> # use pooled connections defaults to false
  direct: <boolean> # set to true to try to connect directly to recipients MX
  service: <string> # name of well-known service (will set host, port and secure options)
  # services: 1und1, AOL, DebugMail.io, DynectEmail, FastMail, GandiMail, Gmail,
  # Godaddy, GodaddyAsia, GodaddyEurope, hot.ee, Hotmail, iCloud, mail.ee, Mail.ru,
  # Mailgun, Mailjet, Mandrill, Naver, Postmark, QQ, QQex, SendCloud, SendGrid,
  # SES, Sparkpost, Yahoo, Yandex, Zoho
  host: <string> # the hostname or IP address to connect to
  port: <integer> # the port to connect to (defaults to 25 or 465)
  secure: <boolean> # if true the connection will only use TLS else (the default)
  # TLS may still be upgraded to if available via the STARTTLS command
  ignoreTLS: <boolean> # if this is true and secure is false, TLS will not be used
  requireTLS: <boolean> # if this is true and secure is false, it uses STARTTLS
  # even if the server does not advertise support for it
  tls: <object> # additional socket options like `{rejectUnauthorized: true}`
  auth: # authentication objects
    user: <string> # the username
    pass: <string> # the password for the user
  authMethod: <string> # preferred authentication method, eg. ‘PLAIN’
  name: <string> # hostname of the client, used for identifying to the server
  localAddress: <string> # the local interface to bind to for network connections
  connectionTimeout: <integer> # milliseconds to wait for the connection to establish
  greetingTimeout: <integer> # milliseconds to wait for the greeting after connection is established
  socketTimeout: <integer> # milliseconds of inactivity to allow
  debug: <boolean> # set to true to log the complete SMTP traffic
  # if pool is set to true:
  maxConnections: <integer> # the count of maximum simultaneous connections (defaults to 5)
  maxMessages: <integer> # limits the message count to be sent using a single connection (defaults to 100)
  rateLimit: <integer> # limits the message count to be sent in a second (defaults to false)    
```

#### Addressing

First you can define the sender address using:

``` yaml
from: <string> # the address used as sender(often the same as used in transport)
replyTo: <string> # address which should be used for replys
```

And you give the addresses to send the mail to. In the following fields: `to`, `cc`
and `bcc` you may give a single address or a list of addresses to use.
All e-mail addresses can be plain e-mail addresses

    name@mymailserver.com

or with formatted name (includes unicode support)

    "My Name" <name@mymailserver.com>

#### Content

The content of the mail consists of an subject line which should be not to long
and the body. The body is given as [Markdown](http://alinex.github.io/develop/lang/markdown.html)
syntax and supports all possibilities from
[report](http://alinex.github.io/node-report/README.md.html#markup%20syntax).
This will be converted to a plain text and html version for sending so that the
mail client can choose the format to display.

Like you see above, you can use handlebar syntax to use some variables from the
code. This is possible in subject and body. And you may specify a
local to use for date formatting.

You can also define different templates which can be referenced from within the
job.

The following context variables are possible:

- name - the alias name for this job
- conf... - configuration of job (object)
- date - the date then the job was done (now)
- result
  - <job> - one entry for each job
    - rows - number of rows in result
    - file - filename
    - description - description of job (from config)

Find more examples at [validator](http://alinex.github.io/node-validator/README.md.html#handlebars).

### Database

Also you need the setup under `/database` like described in
[Database](http://alinex.github.io/node-database).
This is used to make the specific database connections.


Compose
-------------------------------------------------
Like seen above the compose section can be used to


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
