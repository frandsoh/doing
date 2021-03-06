require 'fileutils'
require 'tempfile'
require 'time'

require 'doing-helpers'
require 'test_helper'

class DoingChronifyTest < Test::Unit::TestCase
  include DoingHelpers
  ENTRY_TS_REGEX = /\s*(?<ts>[^\|]+) \s*\|/

  def setup
    @tmpdirs = []
    @basedir = mktmpdir
    @wwid_file = File.join(@basedir, 'wwid.md')
    @config_file = File.join(File.dirname(__FILE__),'test.doingrc')
  end

  def teardown
    FileUtils.rm_rf(@tmpdirs)
  end

  def test_back_rejects_empty_args
    assert_raises(RuntimeError) { doing('now', '--back', '', 'should fail') }
  end

  def test_back_interval
    now = Time.now.to_i
    doing('now', '--back', '20m', 'test interval format')
    m = doing('show').match(ENTRY_TS_REGEX)
    assert(m)
    assert_equal(Time.parse(m['ts']).to_i, trunc_minutes(now - 20*60),
        "New task should be equal to the nearest minute")
  end

  def test_back_strftime
    ts = '2016-03-15 15:32:04 EST'
    doing('now', '--back', ts, 'test strftime format')
    m = doing('show').match(ENTRY_TS_REGEX)
    assert(m)
    assert_equal(Time.parse(m['ts']).to_i, trunc_minutes(Time.parse(ts)),
        "New task should be equal to the nearest minute")
  end

  def test_back_semantic
    yesterday = Time.parse((Time.now - 3600*24).strftime('%Y-%m-%d 18:30 %Z'))
    doing('now', '--back', 'yesterday 6:30pm', 'test semantic format')
    m = doing('show').match(ENTRY_TS_REGEX)
    assert(m)
    assert_equal(Time.parse(m['ts']), yesterday, "new task is the wrong time")
  end

  private

  def uncolor(string)
    string.gsub(/\\e\[[\d;]+m/,'')
  end

  def trunc_minutes(ts)
    ts.to_i / 60 * 60
  end

  def mktmpdir
    tmpdir = Dir.mktmpdir
    @tmpdirs.push(tmpdir)

    tmpdir
  end

  def doing(*args)
    doing_with_env({}, '--config_file', @config_file, '--doing_file', @wwid_file, *args)
  end
end

