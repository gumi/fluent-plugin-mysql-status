# fluent-plugin-mysql-status

[fluentd](http://fluentd.org) input plugin that monitor status of MySQL Server.

[![Build Status](https://travis-ci.org/gumi/fluent-plugin-mysql-status.svg?branch=master)](https://travis-ci.org/gumi/fluent-plugin-mysql-status)
[![Code Climate](https://codeclimate.com/github/gumi/fluent-plugin-mysql-status/badges/gpa.svg)](https://codeclimate.com/github/gumi/fluent-plugin-mysql-status)

## Installation

Install with gem or fluent-gem command as:

```
# for fluentd
$ gem install fluent-plugin-mysql-status

# for td-agent
$ sudo /usr/lib64/fluent/ruby/bin/fluent-gem install fluent-plugin-mysql-status
```

## Configuration

```
<source>
  type mysql_status
  tag mysql_status                  # Required

  host 127.0.0.1                    # Optional (default: localhost)
  port 3306                         # Optional (default: 3306)
  username ham                      # Optional (default: root)
  password egg                      # Optional (default: nopassword)
  database spam                     # Optional (default: unselected database)
  encoding utf8                     # Optional (default: utf8)

  comment Fluent::MySQLStatusInput  # Optional (default: Fluent::MySQLStatusInput)

  <query>
    type processlist  # Required if path and string is undefined
    tag processlist   # Required
    interval 1        # Optional (default: 10)
  </query>

  <query>
    path /path/to/statements_with_errors.sql  # Required if type and string is undefined
    tag errors
  </query>

  <query>
    string SHOW STATUS                  # Required if type and path is undefined
    tag status
    omit_variable_name_from_record true # Optional (default: false)
    clump_records true                  # Optional (default: false)
  </query>

  <query>
    string SELECT DIGEST_TEXT FROM performance_schema.events_statements_summary_by_digest
    tag summary
    clump_records true          # Optional (default: false)
    clumped_records_key records # Optional (default: records)
  </query>
</source>
```

Since this plugin runs multiple queries with a single connection, it doesn't put too much load on the MySQL server.
However, since queries run sequentially, slow queries hinder other queries from running.

### query.type

The following types are available.

- processlist - SHOW FULL PROCESSLIST
- status - SHOW OPEN TABLES
- open_tables - SHOW /*!50002 GLOBAL */ STATUS

### query.string

If you don't like the types mentioned above, you can write a query freely.

### query.path

If your query is long, write the query to a file and set the file path to this setting.

### tag + query.tag

If you set the following configuration:

```
<source>
  tag ham

  <query>
    tag egg
  </query>
</source>
```

This plugin make the following tag:

```
ham.egg
```

### query.interval

Set the interval at which the query runs in seconds.

### query.omit_variable_name_from_record

If the result of the query is in the following format:

```
2016-12-23 23:09:56 +0900 mysql_status.spam: {'Variable_name': 'ham', 'Value': 'egg'}
2016-12-23 23:09:56 +0900 mysql_status.spam: {'Variable_name': 'foo', 'Value': 'bar'}
```

Setting this to true results in the following result:

```
2016-12-23 23:09:56 +0900 mysql_status.spam.ham: 'egg'
2016-12-23 23:09:56 +0900 mysql_status.spam.foo: 'bar'
```

### query.clump_records

If the result of the query is in the following format:

```
2016-12-23 23:09:56 +0900 mysql_status.spam: {'ham': 1, 'egg': 2}
2016-12-23 23:09:56 +0900 mysql_status.spam: {'ham': 3, 'egg': 4}
```

Setting this to true results in the following result:

```
2016-12-23 23:09:56 +0900 mysql_status.spam: {'records': [{'ham': 1, 'egg': 2}, {'ham': 3, 'egg': 4}]}
```

### query.clumped_records_key

Set the key name to clump the records.

### comment

This setting is added as a comment to all queries.

If you set the following configuration:

```
<source>
  comment This query was ran by fluentd

  <query>
    string SELECT spam FROM ham.egg
  </query>

  <query>
    string SELECT foo FROM bar.baz
  </query>
</source>
```

This plugin executes the following queries:

```
SELECT spam FROM ham.egg /* This query was ran by fluentd */
SELECT foo FROM bar.baz /* This query was ran by fluentd */
```

## Copyright

- Copyright
  - Copyright (C) 2016- gumi Inc.
- License
  - Apache License, Version 2.0
