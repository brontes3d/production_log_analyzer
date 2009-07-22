#generated with rake debug_gem
Gem::Specification.new do |s|
  s.name = %q{production_log_analyzer}
  s.version = "2009072200"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Eric Hodel"]
  s.date = %q{2009-06-11}
  s.description = %q{production_log_analyzer provides three tools to analyze log files created by SyslogLogger.  pl_analyze for getting daily reports, action_grep for pulling log lines for a single action and action_errors to summarize errors with counts.}
  s.email = %q{drbrain@segment7.net}
  s.executables = ["action_errors", "action_grep", "pl_analyze"]
  s.extra_rdoc_files = ["History.txt", "LICENSE.txt", "Manifest.txt", "README.txt"]
  s.files = ["History.txt", "LICENSE.txt", "Manifest.txt", "README.txt", "Rakefile", "bin/action_errors", 
    "bin/action_grep", "bin/pl_analyze", "lib/production_log/action_grep.rb", "lib/production_log/analyzer.rb", 
    "lib/production_log/parser.rb", "test/test_action_grep.rb", "test/test_analyzer.rb", "test/test_parser.rb", 
    "test/test_helper.rb", "lib/rack_logging_per_proc.rb", "test/test_rack_logging_per_proc.rb",
    "test/test_syslogs/test.syslog.0.14.x.log", "test/test_syslogs/test.syslog.1.2.shortname.log", "test/test_syslogs/test.syslog.empty.log", "test/test_syslogs/test.syslog.log", "test/test_vanilla/test.0.14.x.log", "test/test_vanilla/test.1.2.shortname.log", "test/test_vanilla/test.empty.log", "test/test_vanilla/test.log", "test/test_vanilla/test_log_parts/1_online1-rails-59600.log", "test/test_vanilla/test_log_parts/2_online2-rails-59628.log", "test/test_vanilla/test_log_parts/3_online1-rails-59628.log", "test/test_vanilla/test_log_parts/4_online1-rails-59645.log", "test/test_vanilla/test_log_parts/5_online1-rails-59629.log", "test/test_vanilla/test_log_parts/6_online1-rails-60654.log", "test/test_vanilla/test_log_parts/7_online1-rails-59627.log", "test/test_vanilla/test_log_parts/8_online1-rails-59635.log"]
  s.has_rdoc = true
  s.homepage = %q{http://seattlerb.rubyforge.org/production_log_analyzer}
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{seattlerb}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{production_log_analyzer lets you find out which actions on a Rails site are slowing you down.}
  s.test_files = ["test/test_action_grep.rb", "test/test_analyzer.rb", "test/test_helper.rb", "test/test_parser.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rails_analyzer_tools>, [">= 1.4.0"])
      s.add_development_dependency(%q<hoe>, [">= 1.12.2"])
    else
      s.add_dependency(%q<rails_analyzer_tools>, [">= 1.4.0"])
      s.add_dependency(%q<hoe>, [">= 1.12.2"])
    end
  else
    s.add_dependency(%q<rails_analyzer_tools>, [">= 1.4.0"])
    s.add_dependency(%q<hoe>, [">= 1.12.2"])
  end
end
