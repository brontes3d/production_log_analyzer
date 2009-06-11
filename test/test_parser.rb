require File.dirname(__FILE__) + '/test_helper'

class TestLogEntry < TestTwice

  setup do
    @entry = LogParser::LogEntry.new <<-EOF
Processing TwinklerController#index (for 81.109.96.173 at Wed Dec 01 16:01:56 CST 2004)
Parameters: {\"action\"=>\"index\", \"controller\"=>\"twinkler\"}
Browser Load First (0.001114)   SELECT * FROM browsers WHERE ubid = 'ixsXHgUo7U9PJGgBzr7e9ocaDOc=' LIMIT 1
Goal Count (0.001762)   SELECT COUNT(*) FROM goals WHERE browser_id = '96181' and is_active = 1 
Rendering twinkler/index within layouts/default
Rendering layouts/default (200 OK)
Completed in 0.616122 (1 reqs/sec) | Rendering: 0.242475 (39%) | DB: 0.002876 (0%)
EOF

    @kong_entry = LogParser::LogEntry.new <<-EOF
Completed in 0.57672 (1 reqs/sec) | Rendering: 0.47752 (82%) | DB: 0.08223 (14%) | Rows: 75 | Queries: 32 | Method: GET | Request Size: 0 | Request Type: unknown | Response Format: html | Response Size: 71604 | Processed: FeaturedGamesController#index | 200 OK [http://www.kongregatetrunk.com/]
EOF
  end

  twice_test :test_parse do
    request = <<-EOF
Processing RssController#uber (for 67.18.200.5 at Mon Mar 07 00:00:25 CST 2005)
Parameters: {:id=>"author", :"rss/uber/author.html/uber/author"=>nil, :action=>"uber", :username=>"looch", :controller=>"rss"}
Cookie set: auth=dc%2FGUP20BwziF%2BApGecc0pXB0PF0obi55az63ubAFtsnOOdJPkhfJH2U09yuzQD3WtdmWnydLzFcRA78kwi7Gw%3D%3D; path=/; expires=Thu, 05 Mar 2015 06:00:25 GMT
Cookie set: ubid=kF05DqFH%2F9hRCOxTz%2Bfb8Q7UV%2FI%3D; path=/; expires=Thu, 05 Mar 2015 06:00:25 GMT
Browser Load (0.003963)   SELECT * FROM browsers WHERE ubid = 'kF05DqFH/9hRCOxTz+fb8Q7UV/I=' LIMIT 1
Person Load (0.002445)   SELECT * FROM people WHERE username = 'looch' AND active = '1' LIMIT 1
ProfileImage Load (0.001554)   SELECT * FROM profile_images WHERE id = 2782 LIMIT 1
Rendering rss/rss2.0 (200 OK)
Completed in 0.034519 (28 reqs/sec) | Rendering: 0.011770 (34%) | DB: 0.007962 (23%)
EOF
    request = request.split "\n"

    entry = LogParser::LogEntry.new []

    entry.parse request
    assert_kind_of LogParser::LogEntry, entry
    assert_equal "RssController#uber", entry.page
    assert_equal 3, entry.queries.length
    assert_equal ['Browser Load', 0.003963], entry.queries.first
    assert_equal 0.034519, entry.request_time
  end

  twice_test :test_kong_style_page do
    assert_equal "FeaturedGamesController#index.html", @kong_entry.page
  end

  twice_test :test_bad_kong_entry do
    assert_nothing_raised do
      bad = LogParser::LogEntry.new <<-EOF
Completed in 0.00904 (110 reqs/sec) | Rendering: 0.00572 (63%) | DB: 0.00093 (10%) | Rows: 2 | Queries: 2 | Guest | Method: GET | Request Size: 0 | Request Type: unknown | Response Format: Accept: application/xhtml+xml | Response Size: 8637 | Processed: MyCardsController#show | 200 OK [http://www.kongregate.com/accounts/orc22/cards/688263]
EOF
    end
  end

  twice_test :test_row_count do
    assert_equal 75, @kong_entry.row_count
  end

  twice_test :test_query_count do
    assert_equal 32, @kong_entry.query_count
  end

  twice_test :test_request_size do
    assert_equal 0, @kong_entry.request_size
  end

  twice_test :test_response_size do
    assert_equal 71604, @kong_entry.response_size
  end

  twice_test :test_page do
    assert_equal "TwinklerController#index", @entry.page
  end

  twice_test :test_ip do
    assert_equal "81.109.96.173", @entry.ip
  end

  twice_test :test_time do
    assert_equal "Wed Dec 01 16:01:56 CST 2004", @entry.time
  end

  twice_test :test_queries do
    expected = []
    expected << ["Browser Load First", 0.001114]
    expected << ["Goal Count", 0.001762]
    assert_equal expected, @entry.queries
  end

  twice_test :test_request_time do
    assert_equal 0.616122, @entry.request_time

    @entry = LogParser::LogEntry.new "Processing TwinklerController#add_thing (for 144.164.232.114 at Wed Dec 01 16:01:56 CST 2004)
Completed in 0.261485 (3 reqs/sec) | DB: 0.009325 (3%)"

    assert_equal 0.261485, @entry.request_time

    @entry = LogParser::LogEntry.new "Completed in 13ms (View: 12, DB: 1) | 200 OK [http://www.example.com/]"
    assert_equal 13/1000.0, @entry.request_time
  end

  twice_test :test_render_time do
    assert_equal 0.242475, @entry.render_time

    @entry = LogParser::LogEntry.new "Processing TwinklerController#add_thing (for 144.164.232.114 at Wed Dec 01 16:01:56 CST 2004)
Completed in 0.261485 (3 reqs/sec) | DB: 0.009325 (3%)"

    assert_equal 0, @entry.render_time

    @entry = LogParser::LogEntry.new 'Completed in 13ms (View: 12, DB: 1) | 200 OK [http://www.example.com/]'
    assert_equal 12/1000.0, @entry.render_time
  end

  twice_test :test_db_time do
    assert_equal 0.002876, @entry.db_time

    @entry = LogParser::LogEntry.new 'Completed in 13ms (View: 12, DB: 1) | 200 OK [http://www.example.com/]'
    assert_equal 1/1000.0, @entry.db_time
  end

end

class TestLogParser < TestTwice

  twice_test :test_class_parse_with_only_completed_at do
    if test_sys_log_style?
      log = StringIO.new <<-EOF
Jul 23 12:08:50 trunk rails[27221]: Completed in 0.00507 (197 reqs/sec) | Rendering: 0.00027 (5%) | DB: 0.00055 (10%) | Rows: 88 | Queries: 1 | Guest | Method: GET | Request Size: 0 | Request Type: unknown | Response Format: all | Response Size: 3696 | Processed: RoomsController#list | 200 OK [http://kongregate.com/rooms/list]
Jul 23 12:09:18 trunk rails[27221]: Completed in 0.11838 (8 reqs/sec) | Rendering: 0.10371 (87%) | DB: 0.00671 (5%) | Rows: 103 | Queries: 20 | Guest | Method: GET | Request Size: 0 | Request Type: unknown | Response Format: html | Response Size: 27254 | Processed: CategoriesController#show | 200 OK [http://kongregate.com/strategy-defense-games]
      EOF
    else
      log = StringIO.new <<-EOF
Completed in 0.00507 (197 reqs/sec) | Rendering: 0.00027 (5%) | DB: 0.00055 (10%) | Rows: 88 | Queries: 1 | Guest | Method: GET | Request Size: 0 | Request Type: unknown | Response Format: all | Response Size: 3696 | Processed: RoomsController#list | 200 OK [http://kongregate.com/rooms/list]
Completed in 0.11838 (8 reqs/sec) | Rendering: 0.10371 (87%) | DB: 0.00671 (5%) | Rows: 103 | Queries: 20 | Guest | Method: GET | Request Size: 0 | Request Type: unknown | Response Format: html | Response Size: 27254 | Processed: CategoriesController#show | 200 OK [http://kongregate.com/strategy-defense-games]
      EOF
    end
    
    entries = []
    LogParser.parse log do |entry|
      entries << entry
    end
    
    assert_equal 2, entries.length
  end

  twice_test :test_class_parse do
    if test_sys_log_style?
      log = StringIO.new <<-EOF
Mar  7 00:00:25 online1 rails[59628]: Processing RssController#uber (for 67.18.200.5 at Mon Mar 07 00:00:25 CST 2005)
Mar  7 00:00:25 online1 rails[59628]: Parameters: {:id=>"author", :"rss/uber/author.html/uber/author"=>nil, :action=>"uber", :username=>"looch", :controller=>"rss"}
Mar  7 00:00:25 online1 rails[59628]: Cookie set: auth=dc%2FGUP20BwziF%2BApGecc0pXB0PF0obi55az63ubAFtsnOOdJPkhfJH2U09yuzQD3WtdmWnydLzFcRA78kwi7Gw%3D%3D; path=/; expires=Thu, 05 Mar 2015 06:00:25 GMT
Mar  7 00:00:25 online1 rails[59628]: Cookie set: ubid=kF05DqFH%2F9hRCOxTz%2Bfb8Q7UV%2FI%3D; path=/; expires=Thu, 05 Mar 2015 06:00:25 GMT
Mar  7 00:00:25 online1 rails[59628]: Browser Load (0.003963)   SELECT * FROM browsers WHERE ubid = 'kF05DqFH/9hRCOxTz+fb8Q7UV/I=' LIMIT 1
Mar  7 00:00:25 online1 rails[59628]: Person Load (0.002445)   SELECT * FROM people WHERE username = 'looch' AND active = '1' LIMIT 1
Mar  7 00:00:25 online1 rails[59628]: ProfileImage Load (0.001554)   SELECT * FROM profile_images WHERE id = 2782 LIMIT 1
Mar  7 00:00:25 online1 rails[59628]: Rendering rss/rss2.0 (200 OK)
Mar  7 00:00:25 online1 rails[59628]: Completed in 0.034519 (28 reqs/sec) | Rendering: 0.011770 (34%) | DB: 0.007962 (23%)
        EOF
    else
      log = StringIO.new <<-EOF
Processing RssController#uber (for 67.18.200.5 at Mon Mar 07 00:00:25 CST 2005)
Parameters: {:id=>"author", :"rss/uber/author.html/uber/author"=>nil, :action=>"uber", :username=>"looch", :controller=>"rss"}
Cookie set: auth=dc%2FGUP20BwziF%2BApGecc0pXB0PF0obi55az63ubAFtsnOOdJPkhfJH2U09yuzQD3WtdmWnydLzFcRA78kwi7Gw%3D%3D; path=/; expires=Thu, 05 Mar 2015 06:00:25 GMT
Cookie set: ubid=kF05DqFH%2F9hRCOxTz%2Bfb8Q7UV%2FI%3D; path=/; expires=Thu, 05 Mar 2015 06:00:25 GMT
Browser Load (0.003963)   SELECT * FROM browsers WHERE ubid = 'kF05DqFH/9hRCOxTz+fb8Q7UV/I=' LIMIT 1
Person Load (0.002445)   SELECT * FROM people WHERE username = 'looch' AND active = '1' LIMIT 1
ProfileImage Load (0.001554)   SELECT * FROM profile_images WHERE id = 2782 LIMIT 1
Rendering rss/rss2.0 (200 OK)
Completed in 0.034519 (28 reqs/sec) | Rendering: 0.011770 (34%) | DB: 0.007962 (23%)
        EOF
    end
    
    entries = []

    LogParser.parse log do |entry|
      entries << entry
    end

    assert_equal 1, entries.length
    assert_equal 'RssController#uber', entries.first.page
  end

  twice_test :test_class_parse_components do
    if test_sys_log_style?
      log = StringIO.new <<-EOF
Jul 11 10:05:20 www rails[61243]: Processing ChatroomsController#launch (for 213.152.37.169 at Mon Jul 11 10:05:20 CDT 2005)
Jul 11 10:05:20 www rails[61243]: Start rendering component ({:action=>"online_count", :controller=>"members"}):
Jul 11 10:05:20 www rails[34216]: Processing ChatroomsController#launch (for 213.152.37.169 at Mon Jul 11 10:05:20 CDT 2005)
Jul 11 10:05:20 www rails[34216]: Start rendering component ({:action=>"online_count", :controller=>"members"}):
Jul 11 10:05:20 www rails[34216]: Processing MembersController#online_count (for 213.152.37.169 at Mon Jul 11 10:05:20 CDT 2005)
Jul 11 10:05:20 www rails[34216]: Completed in 0.00741 (135 reqs/sec) | DB: 0.00320 (43%)
Jul 11 10:05:20 www rails[34216]: End of component rendering
Jul 11 10:05:28 www rails[34216]: Completed in 8.65005 (0 reqs/sec) | Rendering: 8.64820 (99%) | DB: 0.00000 (0%)
Jul 11 10:05:20 www rails[34216]: Processing ChatroomsController#launch (for 213.152.37.169 at Mon Jul 11 10:05:20 CDT 2005)
Jul 11 10:05:20 www rails[34216]: Start rendering component ({:action=>"online_count", :controller=>"members"}):
Jul 11 10:05:20 www rails[34216]: Processing MembersController#online_count (for 213.152.37.169 at Mon Jul 11 10:05:20 CDT 2005)
Jul 11 10:05:20 www rails[34216]: Completed in 0.00741 (135 reqs/sec) | DB: 0.00320 (43%)
Jul 11 10:05:20 www rails[34216]: End of component rendering
Jul 11 10:05:28 www rails[34216]: Completed in 8.65005 (0 reqs/sec) | Rendering: 8.64820 (99%) | DB: 0.00000 (0%)
Jul 11 10:05:20 www rails[61243]: Processing MembersController#online_count (for 213.152.37.169 at Mon Jul 11 10:05:20 CDT 2005)
Jul 11 10:05:20 www rails[61243]: Completed in 0.00741 (135 reqs/sec) | DB: 0.00320 (43%)
Jul 11 10:05:20 www rails[61243]: End of component rendering
Jul 11 10:05:28 www rails[61243]: Completed in 8.65005 (0 reqs/sec) | Rendering: 8.64820 (99%) | DB: 0.00000 (0%)
        EOF
      else
        log = StringIO.new <<-EOF
Processing ChatroomsController#launch (for 213.152.37.169 at Mon Jul 11 10:05:20 CDT 2005)
Start rendering component ({:action=>"online_count", :controller=>"members"}):
Processing MembersController#online_count (for 213.152.37.169 at Mon Jul 11 10:05:20 CDT 2005)
Completed in 0.00741 (135 reqs/sec) | DB: 0.00320 (43%)
End of component rendering
Completed in 8.65005 (0 reqs/sec) | Rendering: 8.64820 (99%) | DB: 0.00000 (0%)
Processing ChatroomsController#launch (for 213.152.37.169 at Mon Jul 11 10:05:20 CDT 2005)
Start rendering component ({:action=>"online_count", :controller=>"members"}):
Processing MembersController#online_count (for 213.152.37.169 at Mon Jul 11 10:05:20 CDT 2005)
Completed in 0.00741 (135 reqs/sec) | DB: 0.00320 (43%)
End of component rendering
Completed in 8.65005 (0 reqs/sec) | Rendering: 8.64820 (99%) | DB: 0.00000 (0%)
Processing ChatroomsController#launch (for 213.152.37.169 at Mon Jul 11 10:05:20 CDT 2005)
Start rendering component ({:action=>"online_count", :controller=>"members"}):
Processing MembersController#online_count (for 213.152.37.169 at Mon Jul 11 10:05:20 CDT 2005)
Completed in 0.00741 (135 reqs/sec) | DB: 0.00320 (43%)
End of component rendering
Completed in 8.65005 (0 reqs/sec) | Rendering: 8.64820 (99%) | DB: 0.00000 (0%)
        EOF
    end
    
    entries = []
    LogParser.parse(log) { |entry| entries << entry }

    assert_equal 3, entries.length
    assert_equal 'ChatroomsController#launch', entries.first.page
    assert_equal 8.65005, entries.first.request_time
  end

  twice_test :test_class_parse_entries_with_pre_processing_garbage do
    if test_sys_log_style?    
      log = StringIO.new <<-EOF
Jan 03 12:51:34 duo2 rails[4347]: [4;36;1mFont Load (0.000475)[0m   [0;1mSELECT * FROM fonts ORDER BY name [0m
Jan 03 12:51:34 duo2 rails[4347]: Processing StylesheetsController#show (for 127.0.0.1 at 2007-01-03 12:51:34) [GET]
Jan 03 12:51:34 duo2 rails[4347]: Parameters: {"action"=>"show", "id"=>"1", "controller"=>"stylesheets"}
Jan 03 12:51:34 duo2 rails[4347]: [4;35;1mNewspaper Load (0.000970)[0m   [0mSELECT newspapers.* FROM newspapers INNER JOIN users ON newspapers.editor_in_chief = users.id WHERE (users.login = 'geoff') LIMIT 1[0m
Jan 03 12:51:34 duo2 rails[4347]: [4;36;1mLayout Load (0.000501)[0m   [0;1mSELECT * FROM layouts WHERE (layouts.id = 1) LIMIT 1[0m
Jan 03 12:51:34 duo2 rails[4347]: Completed in 0.00807 (123 reqs/sec) | Rendering: 0.00006 (0%) | DB: 0.00195 (24%) | 200 OK [http://geoff.localhost.com/stylesheets/show/1/styles.css]
      EOF
    else
      log = StringIO.new <<-EOF
[4;36;1mFont Load (0.000475)[0m   [0;1mSELECT * FROM fonts ORDER BY name [0m
Processing StylesheetsController#show (for 127.0.0.1 at 2007-01-03 12:51:34) [GET]
Parameters: {"action"=>"show", "id"=>"1", "controller"=>"stylesheets"}
[4;35;1mNewspaper Load (0.000970)[0m   [0mSELECT newspapers.* FROM newspapers INNER JOIN users ON newspapers.editor_in_chief = users.id WHERE (users.login = 'geoff') LIMIT 1[0m
[4;36;1mLayout Load (0.000501)[0m   [0;1mSELECT * FROM layouts WHERE (layouts.id = 1) LIMIT 1[0m
Completed in 0.00807 (123 reqs/sec) | Rendering: 0.00006 (0%) | DB: 0.00195 (24%) | 200 OK [http://geoff.localhost.com/stylesheets/show/1/styles.css]
      EOF
    end
    entries = []
    LogParser.parse(log) { |entry| entries << entry }

    assert_equal 1, entries.length, "Number of entries was incorrect"
    assert_equal 'StylesheetsController#show', entries.first.page
    assert_equal 0.00807, entries.first.request_time
  end

  twice_test :test_class_parse_rails_engines_plugin do
    if test_sys_log_style?        
      log = StringIO.new <<-EOF
Jan 03 12:24:21 duo2 rails[4277]: Trying to start engine 'login_engine' from '/Users/topfunky/web/rails/repos/roughunderbelly/vendor/plugins/login_engine'
Jan 03 12:24:21 duo2 rails[4277]: adding /Users/topfunky/web/rails/repos/roughunderbelly/vendor/plugins/login_engine/lib/login_engine to the load path
Jan 03 12:24:21 duo2 rails[4277]: adding /Users/topfunky/web/rails/repos/roughunderbelly/vendor/plugins/login_engine/app/views/user_notify to the load path
Jan 03 12:24:21 duo2 rails[4277]: adding /Users/topfunky/web/rails/repos/roughunderbelly/vendor/plugins/login_engine/app/views/user to the load path
Jan 03 12:24:21 duo2 rails[4277]: adding /Users/topfunky/web/rails/repos/roughunderbelly/vendor/plugins/login_engine/app/views to the load path
Jan 03 12:24:21 duo2 rails[4277]: adding /Users/topfunky/web/rails/repos/roughunderbelly/vendor/plugins/login_engine/app/models to the load path
Jan 03 12:24:21 duo2 rails[4277]: adding /Users/topfunky/web/rails/repos/roughunderbelly/vendor/plugins/login_engine/app/helpers to the load path
Jan 03 12:24:21 duo2 rails[4277]: adding /Users/topfunky/web/rails/repos/roughunderbelly/vendor/plugins/login_engine/app/controllers to the load path
Jan 03 12:24:21 duo2 rails[4277]: Attempting to copy public engine files from '/Users/topfunky/web/rails/repos/roughunderbelly/config/../vendor/plugins/login_engine/public'
Jan 03 12:24:21 duo2 rails[4277]: source dirs: ["/Users/topfunky/web/rails/repos/roughunderbelly/config/../vendor/plugins/login_engine/public/stylesheets"]
Jan 03 12:24:22 duo2 rails[4277]: finally loading from application: 'exception_notifier.rb'
Jan 03 12:24:22 duo2 rails[4277]: requiring file 'exception_notifier_helper'
Jan 03 12:24:22 duo2 rails[4277]: checking 'login_engine' for /Users/topfunky/web/rails/repos/roughunderbelly/config/../vendor/plugins/login_engine/exception_notifier_helper.rb
Jan 03 12:24:22 duo2 rails[4277]: finally loading from application: 'exception_notifier_helper.rb'
Jan 03 12:24:23 duo2 rails[4277]: finally loading from application: '/Users/topfunky/web/rails/repos/roughunderbelly/config/../app/controllers/application.rb'
Jan 03 12:24:23 duo2 rails[4277]: requiring file 'application_helper'
Jan 03 12:24:23 duo2 rails[4277]: checking 'login_engine' for /Users/topfunky/web/rails/repos/roughunderbelly/config/../vendor/plugins/login_engine/application_helper.rb
Jan 03 12:24:23 duo2 rails[4277]: finally loading from application: 'application_helper.rb'
Jan 03 12:24:23 duo2 rails[4277]: finally loading from application: 'exception_notifiable.rb'
Jan 03 12:24:23 duo2 rails[4277]: requiring file 'user_helper'
Jan 03 12:24:23 duo2 rails[4277]: checking 'login_engine' for /Users/topfunky/web/rails/repos/roughunderbelly/config/../vendor/plugins/login_engine/user_helper.rb
Jan 03 12:24:23 duo2 rails[4277]: finally loading from application: 'user_helper.rb'
Jan 03 12:24:23 duo2 rails[4277]: finally loading from application: 'user.rb'
Jan 03 12:24:23 duo2 rails[4277]: finally loading from application: 'task.rb'
Jan 03 12:24:23 duo2 rails[4277]: finally loading from application: 'client.rb'
Jan 03 12:24:23 duo2 rails[4277]: finally loading from application: 'email.rb'
Jan 03 12:24:23 duo2 rails[4277]: finally loading from application: 'worth.rb'
Jan 03 12:24:23 duo2 rails[4277]: finally loading from application: 'column_pref.rb'
Jan 03 12:24:23 duo2 rails[4277]: finally loading from application: 'timer.rb'
Jan 03 12:24:23 duo2 rails[4277]: requiring file '/Users/topfunky/web/rails/repos/roughunderbelly/config/../app/controllers/tasks_controller.rb'
Jan 03 12:24:23 duo2 rails[4277]: detected RAILS_ROOT, rewriting to 'app/controllers/tasks_controller.rb'
Jan 03 12:24:23 duo2 rails[4277]: checking 'login_engine' for /Users/topfunky/web/rails/repos/roughunderbelly/config/../vendor/plugins/login_engine/app/controllers/tasks_controller.rb
Jan 03 12:24:23 duo2 rails[4277]: finally loading from application: '/Users/topfunky/web/rails/repos/roughunderbelly/config/../app/controllers/tasks_controller.rb'
Jan 03 12:24:23 duo2 rails[4277]: requiring file 'tasks_helper'
Jan 03 12:24:23 duo2 rails[4277]: checking 'login_engine' for /Users/topfunky/web/rails/repos/roughunderbelly/config/../vendor/plugins/login_engine/tasks_helper.rb
Jan 03 12:24:23 duo2 rails[4277]: finally loading from application: 'tasks_helper.rb'
Jan 03 12:24:23 duo2 rails[4277]: requiring file 'sparklines_helper'
Jan 03 12:24:23 duo2 rails[4277]: checking 'login_engine' for /Users/topfunky/web/rails/repos/roughunderbelly/config/../vendor/plugins/login_engine/sparklines_helper.rb
Jan 03 12:24:23 duo2 rails[4277]: finally loading from application: 'sparklines_helper.rb'
Jan 03 12:24:24 duo2 rails[4277]: [4;36;1mSQL (0.000072)[0m   [0;1mBEGIN[0m
Jan 03 12:24:24 duo2 rails[4277]: [4;35;1mSQL (0.000240)[0m   [0mINSERT INTO sessions (`updated_at`, `session_id`, `data`) VALUES('2007-01-03 20:24:24', 'bdbb75323d5da69f707d5576e907706e', 'BAh7AA==\n')[0m
Jan 03 12:24:24 duo2 rails[4277]: [4;36;1mSQL (0.000400)[0m   [0;1mCOMMIT[0m
Jan 03 12:24:24 duo2 rails[4277]: Processing TasksController#index (for 127.0.0.1 at 2007-01-03 12:24:24) [GET]
Jan 03 12:24:24 duo2 rails[4277]: Parameters: {"action"=>"index", "controller"=>"tasks"}
Jan 03 12:24:24 duo2 rails[4277]: Redirected to http://localhost:3000/tasks/list
Jan 03 12:24:24 duo2 rails[4277]: Completed in 0.00112 (896 reqs/sec) | DB: 0.00071 (63%) | 302 Found [http://localhost/]
      EOF
    else
      log = StringIO.new <<-EOF
Trying to start engine 'login_engine' from '/Users/topfunky/web/rails/repos/roughunderbelly/vendor/plugins/login_engine'
adding /Users/topfunky/web/rails/repos/roughunderbelly/vendor/plugins/login_engine/lib/login_engine to the load path
adding /Users/topfunky/web/rails/repos/roughunderbelly/vendor/plugins/login_engine/app/views/user_notify to the load path
adding /Users/topfunky/web/rails/repos/roughunderbelly/vendor/plugins/login_engine/app/views/user to the load path
adding /Users/topfunky/web/rails/repos/roughunderbelly/vendor/plugins/login_engine/app/views to the load path
adding /Users/topfunky/web/rails/repos/roughunderbelly/vendor/plugins/login_engine/app/models to the load path
adding /Users/topfunky/web/rails/repos/roughunderbelly/vendor/plugins/login_engine/app/helpers to the load path
adding /Users/topfunky/web/rails/repos/roughunderbelly/vendor/plugins/login_engine/app/controllers to the load path
Attempting to copy public engine files from '/Users/topfunky/web/rails/repos/roughunderbelly/config/../vendor/plugins/login_engine/public'
source dirs: ["/Users/topfunky/web/rails/repos/roughunderbelly/config/../vendor/plugins/login_engine/public/stylesheets"]
finally loading from application: 'exception_notifier.rb'
requiring file 'exception_notifier_helper'
checking 'login_engine' for /Users/topfunky/web/rails/repos/roughunderbelly/config/../vendor/plugins/login_engine/exception_notifier_helper.rb
finally loading from application: 'exception_notifier_helper.rb'
finally loading from application: '/Users/topfunky/web/rails/repos/roughunderbelly/config/../app/controllers/application.rb'
requiring file 'application_helper'
checking 'login_engine' for /Users/topfunky/web/rails/repos/roughunderbelly/config/../vendor/plugins/login_engine/application_helper.rb
finally loading from application: 'application_helper.rb'
finally loading from application: 'exception_notifiable.rb'
requiring file 'user_helper'
checking 'login_engine' for /Users/topfunky/web/rails/repos/roughunderbelly/config/../vendor/plugins/login_engine/user_helper.rb
finally loading from application: 'user_helper.rb'
finally loading from application: 'user.rb'
finally loading from application: 'task.rb'
finally loading from application: 'client.rb'
finally loading from application: 'email.rb'
finally loading from application: 'worth.rb'
finally loading from application: 'column_pref.rb'
finally loading from application: 'timer.rb'
requiring file '/Users/topfunky/web/rails/repos/roughunderbelly/config/../app/controllers/tasks_controller.rb'
detected RAILS_ROOT, rewriting to 'app/controllers/tasks_controller.rb'
checking 'login_engine' for /Users/topfunky/web/rails/repos/roughunderbelly/config/../vendor/plugins/login_engine/app/controllers/tasks_controller.rb
finally loading from application: '/Users/topfunky/web/rails/repos/roughunderbelly/config/../app/controllers/tasks_controller.rb'
requiring file 'tasks_helper'
checking 'login_engine' for /Users/topfunky/web/rails/repos/roughunderbelly/config/../vendor/plugins/login_engine/tasks_helper.rb
finally loading from application: 'tasks_helper.rb'
requiring file 'sparklines_helper'
checking 'login_engine' for /Users/topfunky/web/rails/repos/roughunderbelly/config/../vendor/plugins/login_engine/sparklines_helper.rb
finally loading from application: 'sparklines_helper.rb'
[4;36;1mSQL (0.000072)[0m   [0;1mBEGIN[0m
[4;35;1mSQL (0.000240)[0m   [0mINSERT INTO sessions (`updated_at`, `session_id`, `data`) VALUES('2007-01-03 20:24:24', 'bdbb75323d5da69f707d5576e907706e', 'BAh7AA==\n')[0m
[4;36;1mSQL (0.000400)[0m   [0;1mCOMMIT[0m
Processing TasksController#index (for 127.0.0.1 at 2007-01-03 12:24:24) [GET]
Parameters: {"action"=>"index", "controller"=>"tasks"}
Redirected to http://localhost:3000/tasks/list
Completed in 0.00112 (896 reqs/sec) | DB: 0.00071 (63%) | 302 Found [http://localhost/]
      EOF
    end
    
    entries = []
    LogParser.parse(log) { |entry| entries << entry }

    assert_equal 1, entries.length, "The number of entries was incorrect"
    assert_equal 'TasksController#index', entries.first.page
    assert_equal 0.00112, entries.first.request_time
  end

  twice_test :test_class_parse_multi do
    entries = []
    if test_sys_log_style?
      File.open "#{File.dirname(__FILE__)}/test_syslogs/test.syslog.log" do |fp|
        LogParser.parse fp do |entry|
          entries << entry
        end
      end
    else
      logs_dir = File.expand_path(File.join(File.dirname(__FILE__), 'test_vanilla','test_log_parts'))
      Dir.new(logs_dir).each do |file|
        unless file.to_s[0,1] == "."
          File.open File.join(logs_dir, file) do |fp|
            LogParser.parse fp do |entry|
              entries << entry
            end
          end
        end
      end
    end
        
    assert_equal 13, entries.length
    assert_equal 0.300741, entries.first.request_time
    
    entries = entries.sort_by{|e| e.page.to_s}
    
    redirect = entries[8]
    assert_equal 'TeamsController#progress', redirect.page
    assert_equal 0, redirect.render_time
    
    last = entries[3]    
    assert_equal 'PeopleController#progress', last.page
    assert_equal 0, last.request_time
  end

  twice_test :test_class_parse_0_14_x do
    entries = []
    File.open "#{File.dirname(__FILE__)}/test_syslogs/test.syslog.0.14.x.log" do |fp|
      LogParser.parse fp do |entry|
        entries << entry
      end
    end
  end

end

