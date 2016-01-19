#!/usr/bin/ruby
require 'optparse'

hdfs_path="/usr/bin/hdfs"

options = {}
option_parser = OptionParser.new do |opts|
# 这里是这个命令行工具的帮助信息
    opts.banner = 'usage:check_hdfs_stat.rb [options] -w warnning -c critical,-h for help'
#
#     # Option 作为switch，不带argument，用于将 switch 设置成 true 或 false
    options[:switch] = false
#         # 下面第一项是 Short option（没有可以直接在引号间留空），第二项是 Long option，第三项是对 Option 的描述
    opts.on('-d', 'check hdfs disk urate') do
#               # 这个部分就是使用这个Option后执行的代码
        options['-d'] = true
    end
    opts.on('-u', 'check Under replicated blocks num') do
#               # 这个部分就是使用这个Option后执行的代码
        options['-u'] = true
    end
    opts.on('-r', 'check Blocks with corrupt replicas num') do
#               # 这个部分就是使用这个Option后执行的代码
        options['-r'] = true
    end
    opts.on('-m', 'check Missing blocks num') do
#               # 这个部分就是使用这个Option后执行的代码
        options['-m'] = true
    end
    opts.on('-l', 'check Live datanodes num') do
#               # 这个部分就是使用这个Option后执行的代码
        options['-l'] = true
    end
#
#                       # Option 作为 flag，带argument，用于将argument作为数值解析，比如"name"信息
#                         #下面的“value”就是用户使用时输入的argument
    opts.on('-w warn', '--warnning warn', 'Pass in warnning value') do |value|
        options['warn'] = value
    end
    opts.on('-c crit', '--critical crit', 'Pass in critical value') do |value|
        options['crit'] = value
    end
#
#                                   # Option 作为 flag，带一组用逗号分割的arguments，用于将arguments作为数组解析#    opts.on('-a A,B', '--array A,B', Array, 'List of arguments') do |value|
#        options[:array] = value
#    end
end.parse!
#puts options

if !options['warn']
    warn=80
else
    warn=options['warn'].to_f
end
if !options['crit']
    crti=90
else
    crti=options['crit'].to_f
end
#puts warn
#puts crti
info=`#{hdfs_path} dfsadmin -report`

def check_disk(info,warn,crti)
    if warn>crti
        puts "critical > warnning must"
        exit 255
    end
    use_info=info.match(/DFS Used%:.*$/).to_s.split(/:/)[1].gsub(/ /,"").to_f
    if use_info>=crti
        puts "critical:DFS Used:#{use_info}%"
        exit 1
    elsif use_info>=warn and use_info<crti
        puts "warnning:DFS Used:#{use_info}%"
        exit 2
    else
        puts "OK:DFS Used:#{use_info}%"
        exit 0
    end
end

def check_Under_replicated_blocks(info,warn,crti)
    if warn>crti
        puts "critical > warnning must"
        exit 255
    end
    urb_info=info.match(/Under replicated blocks:.*$/).to_s.split(/:/)[1].gsub(/ /,"").to_i
    if urb_info>=crti
        puts "critical:Under replicated blocks:#{urb_info}"
        exit 1
    elsif urb_info>=warn and urb_info<crti
        puts "warnning:Under replicated blocks:#{urb_info}"
        exit 2
    else
        puts "OK:Under replicated blocks:#{urb_info}"
        exit 0
    end
end

def check_corrupt_replicas_blocks(info,warn,crti)
    if warn>crti
        puts "critical > warnning must"
        exit 255
    end
    crb_info=info.match(/Blocks with corrupt replicas:.*$/).to_s.split(/:/)[1].gsub(/ /,"").to_i
    if use_info>=crti
        puts "critical:Blocks with corrupt replicas:#{crb_info}"
        exit 1
    elsif crb_info>=warn and crb_info<crti
        puts "warnning:Blocks with corrupt replicas:#{crb_info}"
        exit 2
    else
        puts "OK:Blocks with corrupt replicas:#{crb_info}"
        exit 0
    end
end

def check_Missing_blocks(info,warn,crti)
    if warn>crti
        puts "critical > warnning must"
        exit 255
    end
    mb_info=info.match(/Missing blocks:.*$/).to_s.split(/:/)[1].gsub(/ /,"").to_i
    if mb_info>=crti
        puts "critical:Missing blocks:#{mb_info}"
        exit 1
    elsif mb_info>=warn and mb_info<crti
        puts "warnning:Missing blocks:#{mb_info}"
        exit 2
    else
        puts "OK:Missing blocks:#{mb_info}"
        exit 0
    end
end

def check_Live_datanodes(info,warn,crti)
    if crti>warn
        puts "critical < warnning must"
        exit 255
    end
    ldn_info=info.match(/Live datanodes \(\d+\):/).to_s.match(/\d+/).to_s.to_i
    if ldn_info<=crti
        puts "critical:Live datanodes:#{ldn_info}"
        exit 1
    elsif ldn_info<=warn and ldn_info>crti
        puts "warnning:Live datanodes:#{ldn_info}"
        exit 2
    else
        puts "OK:Live datanodes:#{ldn_info}"
        exit 0
    end
end
if options['-l']
    check_Live_datanodes(info,warn,crti)
elsif options['-d']
    check_disk(info,warn,crti)
elsif options['-m']
    check_Missing_blocks(info,warn,crti)
elsif options['-r']
    check_corrupt_replicas_blocks(info,warn,crti)
elsif options['-u']
    check_Under_replicated_blocks(info,warn,crti)
else
    puts 'usage:check_hdfs_stat.rb [options] -w warnning -c critical,-h for help'
end
