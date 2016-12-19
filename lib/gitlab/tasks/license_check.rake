namespace :license do
  task :check do

    good = Regexp.union([/^MIT/, /^LGPL/, /^Apache/, /^Ruby/, /^BSD-[23]{1}/, /^ISO/])
    bad = Regexp.union([/^GPL/, /^AGPL/])

    puts "###### BEGIN LICENSE CHECK ######"

    install_dir = File.open('config/projects/gitlab.rb').grep(/install_dir *"/)[0].match(/install_dir[ \t]*"(?<install_dir>.*)"/)['install_dir']

    if not File.exists?(install_dir)
      puts "Unable to retrieve install_dir, thus unable to check #{install_dir}/LICENSE"
      exit 1
    else
      puts "Checking licenses via the contents of '#{install_dir}/LICENSE'"
    end

    if not File.exists?("#{install_dir}/LICENSE")
      puts "Unable to open #{install_dir}/LICENSE"
      exit 1
    end

    reg = Regexp.compile(/product bundles (?<software>.*?),?\n(,\n)?.*available under a "(?<license>.*)" License/)
    matches = File.open("#{install_dir}/LICENSE").read.scan(reg)
    matches.each do |software, license|
      if license.match(good)
        puts "Good   : #{software} uses #{license}"
      elsif license.match(bad)
        puts "Check  ! #{software} uses #{license}"
      else
        puts "Unknown? #{software} uses #{license}"
      end
    end

    puts "###### END LICENSE CHECK ######"
  end
end
