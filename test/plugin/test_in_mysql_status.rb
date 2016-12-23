require 'helper'

class MySQLStatusInputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  TAG = 'tag'
  HOST = 'localhost'
  PORT = 3306
  USERNAME = 'user'
  PASSWORD = 'pw'
  DATABASE = 'test_db'
  ENCODING = 'utf8'
  COMMENT = 'Fluent::MySQLStatusInput'

  PATH = File.expand_path('../../test.sql', __FILE__)

  QUERIES = [
    {
      :tag => 'tag1',
      :string => 'select * from test.test',
      :interval => 10,
      :omit_variable_name_from_record => false,
      :clump_records => false,
      :clumped_records_key => 'records',
    },
    {
      :tag => 'tag2',
      :string => 'SHOW FULL PROCESSLIST',
      :interval => 5,
      :omit_variable_name_from_record => false,
      :clump_records => false,
      :clumped_records_key => 'records',
    },
    {
      :tag => 'tag3',
      :string => 'SHOW OPEN TABLES',
      :interval => 10,
      :omit_variable_name_from_record => false,
      :clump_records => true,
      :clumped_records_key => 'results',
    },
    {
      :tag => 'tag4',
      :string => 'SHOW /*!50002 GLOBAL */ STATUS',
      :interval => 10,
      :omit_variable_name_from_record => true,
      :clump_records => true,
      :clumped_records_key => 'records',
    },
    {
      :tag => 'tag5',
      :string => File.read(PATH),
      :interval => 10,
      :omit_variable_name_from_record => false,
      :clump_records => false,
      :clumped_records_key => 'records',
    },
  ]

  CONFIG = %[
    tag #{TAG}
    host #{HOST}
    username #{USERNAME}
    password #{PASSWORD}
    database #{DATABASE}

    <query>
      tag tag1
      string select * from test.test
    </query>

    <query>
      tag tag2
      type processlist
      interval 5
    </query>

    <query>
      tag tag3
      type open_tables
      clump_records true
      clumped_records_key results
    </query>

    <query>
      tag tag4
      type status
    </query>

    <query>
      tag tag5
      path #{PATH}
    </query>
  ]

  def create_driver(conf=CONFIG)
    Fluent::Test::InputTestDriver.new(Fluent::MySQLStatusInput).configure(conf)
  end

  def test_configure
    d = create_driver
    assert_equal TAG, d.instance.tag
    assert_equal HOST, d.instance.host
    assert_equal PORT, d.instance.port
    assert_equal USERNAME, d.instance.username
    assert_equal PASSWORD, d.instance.password
    assert_equal DATABASE, d.instance.database
    assert_equal ENCODING, d.instance.encoding
    assert_equal COMMENT, d.instance.comment
    assert_equal QUERIES, d.instance.queries
  end
end
