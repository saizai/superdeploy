  namespace :log do
    desc 'Tail logs. Optionally pass name of log you want to check - e.g. cap util:logs mongrel. Defaults to #{rails_env}.log'
    task :default, :roles => :app do
      # NOTE: This is ARGV[2] not ARGV[1] because we use  cap *staging* util:logs instead of just cap *util:logs*. Put it back if needed, or better, do a smart regex
      log_file = ARGV[2] ? ARGV[2] : fetch(:rails_env, "production")
      run "tail -f #{shared_path}/log/#{log_file}.log" do |channel, stream, data|
        puts  # for an extra line break before the host name
        puts "#{channel[:host]}: #{data}" 
        break if stream == :err
      end
    end
    
    desc 'Tail just the hits and errors; pass name of log if not #{rails_env}.log'
    task :short, :roles => :app do
      log_file = ARGV[2] ? ARGV[2] : fetch(:rails_env, "production")
      run "tail -f #{shared_path}/log/#{log_file}.log | egrep -i 'Processing|Error|:in'" do |channel, stream, data|
        puts  # for an extra line break before the host name
        puts "#{channel[:host]}: #{data}" 
        break if stream == :err
      end
    end

    desc <<-DESC
      Display live timings, hitcounts, unique IP counts, errors, etc - all aggregated and prettylike.

      Last column shows last ~1s of totals. Each * = 1 hit. UnqIP = Unique IPs. H/m = hits per minute (exponential weighted average).

      This depends on usage of standard naming, i.e. FooController#bar = http://someip/foo/bar. \
      It is not routing-savvy, so named/special routes (e.g. root) will be displayed twice - once for \
      the URL, once for the controller/action pair. Just add them together manually.
      Written by Sai Emrys - http://saizai.com
    DESC
    task :smart, :roles => :app do
      log_file = ARGV[2] ? ARGV[2] : fetch(:rails_env, "production")
      aggregate = []
      agg_errors = []
      recent_agg = []
      max_act_size = 6
      max_ctl_size = 10
      total_size = 11
      render_size = 12
      db_size = 11 # minimum size of "0.0 (0.000)"
      hits_size = 4
      uniq_ip_size = 5
      start_time = Time.now
      last_time = Time.now
      hpmx = nil
      run "tail -f #{shared_path}/log/#{log_file}.log" do |channel, stream, data|
      # Aggregate format:
      # [ {:controller => "User", :action => "home", 
      #     :total_time => 30, :render_time => 20, :db_time => 10, :hits => 3,
      #     :results => [{:name => "200 OK", :hits => 20}],
      #     :ips => [{:ip => "23.2.1.1", :hits => 1}, {:ip => "1.2.3.4", :hits => 2}]}, ...]
        recent_agg.each {|a| # clear out recent aggregate data
          a[:total_time] = 0
          a[:render_time] = 0
          a[:db_time] = 0
          a[:hits] = 0
        }

  # get an array of arrays of the item processed (FooController#method), and the IP it was processed for
  new_hits = data.scan(/Processing (\S*) \(for (\S*) at/).collect{|item|
         processee = item[0]
         item[0] = item[0].scan /(\w*)Controller#(\w*)/
         item.flatten
        }

        new_hits.each {|hit|
          # e.g. ["User", "index", "204.15.23.170"]
          controller = hit[0].capitalize
          action = hit[1].downcase
          ip = hit[2]
          found = false
          aggregate.each {|a|
            next unless a[:controller] == controller and a[:action] == action 
            found_ip = false
            a[:ips].each {|ipx|
              next unless ipx[:ip] == ip
              ipx[:hits] += 1
              found_ip = true
              break
            }
            a[:ips] << {:ip => ip, :hits => 1} if !found_ip
            found = true
            break
          }
          if !found
            aggregate << {:controller => controller, :action => action, :total_time => 0, :render_time => 0, :db_time => 0, :hits => 0,
                        :results => [], :ips => [{:ip => ip, :hits => 1}] }
            aggregate.sort! {|a,b| a[:controller] + a[:action] <=> b[:controller] + b[:action] }
            recent_agg << {:controller => controller, :action => action, :total_time => 0, :render_time => 0, :db_time => 0, :hits => 0 }
            recent_agg.sort! {|a,b| a[:controller] + a[:action] <=> b[:controller] + b[:action] }
            max_ctl_size = controller.size if controller.size > max_ctl_size
            max_act_size = action.size if action.size > max_act_size
          end
        }
        
  # get an array of arrays of the total time, render time, db time, result, & URL processed
  new_process = data.scan(/Completed in (\S*) .* Rendering: (\S*) .* DB: (\S*) .* (\S* \S*) \[(\S*)\]/).collect{|item|
          url = item[4]
          item[4] = item[4].scan(/\/\/[^\/]*\/([^\/]*)\/([^\/?&]*)/) # extracts foo,bar from http://blahblahblah/foo/bar/blahblah
          item[4] = ["Application", ""] if item[4].empty?
          item.flatten
        }

        new_process.each {|hit|
          # e.g. ["0.02212", "0.00006", "0.01457", "200 OK", "user", "up"]
          total = hit[0].to_f
          render = hit[1].to_f
          db = hit[2].to_f
          result = hit[3]
          controller = hit[4].capitalize
          action = hit[5].downcase
          found = false
          aggregate.each_with_index {|a,i|
            next unless a[:controller] == controller and a[:action] == action 
            a[:total_time] = a[:total_time] + total
            a[:render_time] = a[:render_time] + render
            a[:db_time] = a[:db_time] + db
            a[:hits] = a[:hits] + 1
            recent_agg[i][:total_time] = recent_agg[i][:total_time] + total
            recent_agg[i][:render_time] = recent_agg[i][:render_time] + render
            recent_agg[i][:db_time] = recent_agg[i][:db_time] + db
            recent_agg[i][:hits] = recent_agg[i][:hits] + 1
            found_result = false
            a[:results].each {|resultx|
              next unless resultx[:result] == result
              resultx[:hits] += 1
              found_result = true
              break
            }
            a[:results] << {:result => result, :hits => 1} if !found_result
            found = true
            break
          }
          if !found
            aggregate << {:controller => controller, :action => action, :total_time => total, :render_time => render, :db_time => db, :hits => 1,
                          :results => [{:result => result, :hits => 1}], :ips => [] }
            aggregate.sort! {|a,b| a[:controller] + a[:action] <=> b[:controller] + b[:action] }
            recent_agg << {:controller => controller, :action => action, :total_time => total, :render_time => render, :db_time => db, :hits => 1 }
            recent_agg.sort! {|a,b| a[:controller] + a[:action] <=> b[:controller] + b[:action] }
            max_ctl_size = controller.size if controller.size > max_ctl_size
            max_act_size = action.size if action.size > max_act_size
          end
        }

        # get an array of arrays of error code and backtrace
        backtrace_regex = '(\s*[^:\n]*:?\d*:in[^\n]*)?' # must be ' not " so it doesn't interpret the \n etc
        # NOTE: * after () grouping matches the backreference (i.e. whatever that group matched), not the pattern itself (unlike e.g. \d*);
        #      therefore we have to use this total hack to get what we actually want. Fortunately it doesn't really need to be arbitrary size...
  new_errors = data.scan(/(\S*Error[^\n]*:)#{backtrace_regex * 15}/m).collect{|item| # first get the entire error + backtrace together
          [item[0], item[1..item.size].select{|x| x =~ /Error/ or x =~ /#{deploy_to}/}.join('\n').strip] # trim backtrace to get only the relevant errors
#          item[1] = backtrace.scan(/.*#{deploy_to}.*:\d*:in.*/).join("\n") rescue "" # trim backtrace to get only the relevant errors
#   item.flatten
  }
        comm_errors = data.scan(/(COMM ERROR.*)/).collect{|item| 
          [item[0], ""]
  }

        new_errors += comm_errors unless comm_errors.empty?

        new_errors.each {|error|
          code = error[0]
          backtrace = error[1]
          found = false
          agg_errors.each {|a|
            next unless a[:code] == code
            a[:count] = a[:count] + 1
            found = true
          }
          agg_errors << {:code => code, :backtrace => backtrace, :count => 1} if !found
        }

        puts  # for an extra line break before the host name
        puts "#{channel[:host]}:" #: #{data}" 
        puts
        puts "Count | Error         "
        puts "----------------------"
        puts "    No Errors! Yay!   " if agg_errors.empty?
        agg_errors.each {|a|
          puts "%5d | %s\n%s" % [a[:count], a[:code], a[:backtrace]]
        }
        
        puts

        now = Time.now
        elapsed_time = "%dh %dm %ds" % [(((now - start_time).abs)/3600), (((now - start_time).abs)/60) % 60, (((now - start_time).abs) % 60)]
        recent_time = "%.2fs" % (now - last_time)
      
        puts "Controller#{' ' * (max_ctl_size - 10)} | Action#{' ' * (max_act_size - 6)} | Total (avg)#{' ' * (total_size - 11)} | Render (avg)#{' ' * (render_size - 12)
                                } | DB (avg)#{' ' * (db_size - 8)} | Hits#{' ' * (hits_size - 4)} | UnqIP#{' ' * (uniq_ip_size - 5)} | Last #{recent_time}"
        puts "---------------------------------------------------------------------------------------#{'-' * (max_ctl_size + max_act_size + total_size + render_size + db_size + hits_size + uniq_ip_size - 56)}"
        totalx = 0
        renderx = 0
        dbx = 0
        hitsx = 0
        ips = []
        totalx_rec = 0
        hitsx_rec = 0

        aggregate.each_with_index {|a,i|
          puts "%-#{max_ctl_size}.#{max_ctl_size}s | %-#{max_act_size}.#{max_act_size}s | %#{total_size - 8}.1f (%4.3f) | %#{render_size - 8}.1f (%4.3f) | %#{db_size - 8}.1f (%4.3f) | %#{hits_size
                 }i | %#{uniq_ip_size}i | %6.3f %-s" % [a[:controller], a[:action], 
                 a[:total_time], (a[:total_time] / a[:hits] rescue 0),
                 a[:render_time], (a[:render_time] / a[:hits] rescue 0), a[:db_time], (a[:db_time] / a[:hits] rescue 0), a[:hits], a[:ips].size, 
                 (recent_agg[i][:total_time] / recent_agg[i][:hits] rescue 0), "*" * (recent_agg[i][:hits] rescue 0)]
          totalx += a[:total_time]
          renderx += a[:render_time]
          dbx += a[:db_time]
          hitsx += a[:hits]
          totalx_rec += recent_agg[i][:total_time]
          hitsx_rec += recent_agg[i][:hits]
          ips << a[:ips].collect{|ip| ip[:ip]}
        }

        total_size = ("%3.1f (%4.3f)" % [totalx, (totalx / hitsx rescue 0)]).size
        render_size = ("%4.1f (%4.3f)" % [renderx, (renderx / hitsx rescue 0)]).size
        db_size = ("%1.1f (%4.3f)" % [dbx, (dbx / hitsx rescue 0)]).size
        hits_size = [hitsx.to_s.size, 4].max
        uniq_ips = ips.uniq.size
        uniq_ip_size = [uniq_ips.to_s.size, 5].max  
        # exponential weighted average
        hpmx ||= (hitsx / ((now - start_time) / 60.0)) # start with an approximation
        # this is almost the same as hpmx = hpmx * 59/60 + hitsx_rec * 1/60, just doesn't assume that one slice = 1s
        hpmx = (hpmx * ((60.0 - (now - last_time).abs) / 60.0)) + # ~59/60 of previous value
               (hitsx_rec * 60.0 * ((now - last_time).abs / 60.0)) # + ~1/60 of estimated current value 
        hpm = "%d H/m" % hpmx

        puts "---------------------------------------------------------------------------------------#{'-' * (max_ctl_size + max_act_size + total_size + render_size + db_size + hits_size + uniq_ip_size - 56)}"
        puts "%-#{max_ctl_size + max_act_size + 3}.#{max_ctl_size + max_act_size + 3}s | %#{total_size - 8}.1f (%4.3f) | %#{render_size - 8}.1f (%4.3f) | %#{db_size - 10}.1f (%4.3f) | %#{hits_size
                 }i | %#{uniq_ip_size}i | %6.3f %-s" % [ elapsed_time + ', ' + hpm, totalx, 
              (totalx / hitsx rescue 0), renderx, (renderx / hitsx rescue 0), dbx, (dbx / hitsx rescue 0),
              hitsx, uniq_ips, (totalx_rec / hitsx_rec rescue 0), ("*" * hitsx_rec) + ' ' + hitsx_rec.to_s]

        break if stream == :err
        last_time = Time.now
        
      end # run
    end # task

    desc <<-DESC
      Display live google analytics info

      Last column shows last ~1s of totals. Each * = 1 hit. UnqIP = Unique IPs. H/m = hits per minute (exponential weighted average).

      Written by Sai Emrys - http://saizai.com
    DESC
    task :google, :roles => :app do
      log_file = ARGV[2] ? ARGV[2] : fetch(:rails_env, "production")
      agg_google = []
      recent_google = []
      size = {:campaign => 8, :medium => 6, :source => 6, :content => 7, :hits => 4}
      start_time = Time.now
      last_time = Time.now
      hpmx = nil
      hitsx = 0
      hitsx_rec = 0
      run "tail -f #{shared_path}/log/#{log_file}.log" do |channel, stream, data|
        recent_google.each{|a|
          a[:hits] = 0
        }
        
        new_google = []
  # get an array of arrays of the total time, render time, db time, result, & URL processed
  new_process = data.scan(/Completed in (\S*) .* Rendering: (\S*) .* DB: (\S*) .* (\S* \S*) \[(\S*)\]/).collect{|item|
          url = item[4]
          source = url.match(/[?&]utm_source=([\w]*?)($|[&\s])/)[1] rescue ""
          medium = url.match(/[?&]utm_medium=([\w]*?)($|[&\s])/)[1] rescue ""
          campaign = url.match(/[?&]utm_campaign=([\w]*?)($|[&\s])/)[1] rescue ""
          content = url.match(/[?&]utm_content=([\w]*?)($|[&\s])/)[1] rescue ""
          has_ga_cruft = ((source + medium + campaign + content).length > 0)
          new_google << {:source => source, :medium => medium, :campaign => campaign, :content => content} if has_ga_cruft
        }

        new_google.each {|hit|
          content = hit[:content]
          campaign = hit[:campaign]
          source = hit[:source]
          medium = hit[:medium]
          found = false
          agg_google.each_with_index{|a,i|
            next unless a[:campaign] == campaign and a[:source] == source and a[:medium] == medium # and a[:content] == content
            a[:content] = content # show most recent content served
            a[:hits] = a[:hits] + 1
            recent_google[i][:hits] = recent_google[i][:hits] + 1
            found = true
            break
          }
          if !found
            size[:content] = content.size if content.size > size[:content]
            size[:medium] = medium.size if medium.size > size[:medium]
            size[:campaign] = campaign.size if campaign.size > size[:campaign]
            size[:source] = source.size if source.size > size[:source]
            agg_google << {:content => content, :campaign => campaign, :source => source, :medium => medium, :hits => 1}
            agg_google.sort! {|a,b| "%-#{size[:campaign]}s %-#{size[:source]}s %-#{size[:medium]}s %-#{size[:content]}s" % [a[:campaign], a[:source], a[:medium], a[:content]] <=>
                                    "%-#{size[:campaign]}s %-#{size[:source]}s %-#{size[:medium]}s %-#{size[:content]}s" % [b[:campaign], b[:source], b[:medium], b[:content]]}
            recent_google << {:content => content, :campaign => campaign, :source => source, :medium => medium, :hits => 1}
            recent_google.sort! {|a,b| "%-#{size[:campaign]}s %-#{size[:source]}s %-#{size[:medium]}s %-#{size[:content]}s" % [a[:campaign], a[:source], a[:medium], a[:content]] <=>
                                       "%-#{size[:campaign]}s %-#{size[:source]}s %-#{size[:medium]}s %-#{size[:content]}s" % [b[:campaign], b[:source], b[:medium], b[:content]]}
          end
        }

        puts

        now = Time.now
        elapsed_time = "%dh %dm %ds" % [(((now - start_time).abs)/3600), (((now - start_time).abs)/60) % 60, (((now - start_time).abs) % 60)]
        recent_time = "%.2fs" % (now - last_time)

        # exponential weighted average
        hpmx ||= (hitsx / ((now - start_time) / 60.0)) # start with an approximation
        # this is almost the same as hpmx = hpmx * 59/60 + hitsx_rec * 1/60, just doesn't assume that one slice = 1s
        hpmx = (hpmx * ((60.0 - (now - last_time).abs) / 60.0)) + # ~59/60 of previous value
               (hitsx_rec * 60.0 * ((now - last_time).abs / 60.0)) # + ~1/60 of estimated current value 
        hpm = "%d H/m" % hpmx

        puts

        hitsx = 0
        hitsx_rec = 0

        puts "Campaign#{' ' * (size[:campaign] - 8)} | Source#{' ' * (size[:source] - 6)} | Medium#{' ' * (size[:medium] - 6)} | Content#{' ' * (size[:content] - 7)} | Hits #{recent_time}"
        puts '-' * (size[:campaign] + size[:source] + size[:medium] + size[:content] + 3 * 4 + 4)
        agg_google.each_with_index {|a,i|
          puts  "%-#{size[:campaign]}s | %-#{size[:source]}s | %-#{size[:medium]}s | %-#{size[:content]}s | %#{size[:hits]}d %-s" % [a[:campaign], a[:source], a[:medium], a[:content], a[:hits], 
                  "*" * (recent_google[i][:hits] rescue 0)]
          hitsx += a[:hits]
          hitsx_rec += recent_google[i][:hits]
        }
        size[:hits] = [hitsx.to_s.size, 4].max
        puts '-' * (size[:campaign] + size[:source] + size[:medium] + size[:content] + 3 * 4 + 4)
        puts "%-#{size[:campaign] + size[:source] + size[:medium] + size[:content] + 3 * 3}.#{size[:campaign] + size[:source] + size[:medium] + size[:content] + 3 * 3}s | %#{size[:hits]}d %-s" % [ 
              elapsed_time + ', ' + hpm, hitsx, ("*" * hitsx_rec) + ' ' + hitsx_rec.to_s]

        break if stream == :err
        last_time = Time.now
        
      end # run
    end # task

    desc <<-DESC
      Display live google analytics info, by subtotals for each campaign / medium /source / content (independently).

      Written by Sai Emrys - http://saizai.com
    DESC
    task :google_subtotals, :roles => :app do
      log_file = ARGV[2] ? ARGV[2] : fetch(:rails_env, "production")
      agg_google = []
      size = {:campaign => 8, :medium => 6, :source => 6, :content => 7, :campaign_hits => 6, :medium_hits => 6, :source_hits => 6, :content_hits => 6}
      subtotals = {:campaign => [], :medium => [], :source => [], :content => []}
      recent = {:campaign => [], :medium => [], :source => [], :content => []}
      start_time = Time.now
      last_time = Time.now
      hpmx = nil
      hitsx = 0
      hitsx_rec = 0
      run "tail -f #{shared_path}/log/#{log_file}.log" do |channel, stream, data|
#        recent_google.each{|a|
 #         a[:hits] = 0
  #      }
        
        new_google = []
  # get an array of arrays of the total time, render time, db time, result, & URL processed
  new_process = data.scan(/Completed in (\S*) .* Rendering: (\S*) .* DB: (\S*) .* (\S* \S*) \[(\S*)\]/).collect{|item|
          url = item[4]
          source = url.match(/[?&]utm_source=([\w]*?)($|[&\s])/)[1] rescue ""
          medium = url.match(/[?&]utm_medium=([\w]*?)($|[&\s])/)[1] rescue ""
          campaign = url.match(/[?&]utm_campaign=([\w]*?)($|[&\s])/)[1] rescue ""
          content = url.match(/[?&]utm_content=([\w]*?)($|[&\s])/)[1] rescue ""
          has_ga_cruft = ((source + medium + campaign + content).length > 0)
          new_google << {:source => source, :medium => medium, :campaign => campaign, :content => content} if has_ga_cruft
        }

        new_google.each {|hit|
          [:content, :campaign, :source, :medium].each {|foo|
            found = false
            subtotals[foo].each_with_index{|a,i|
              next unless a[:name] == hit[foo]
              a[:hits] = a[:hits] + 1
              recent[foo][i][:hits] = recent[foo][i][:hits] + 1
              size[(foo.to_s + "_hits").to_sym] = a[:hits].to_s.length if a[:hits].to_s.length > size[(foo.to_s + "_hits").to_sym]
              found = true
              break
            }
          
            if !found
              size[foo] = hit[foo].size if hit[foo].size > size[foo]
              subtotals[foo] << {:name => hit[foo], :hits => 1}
              subtotals[foo].sort! {|a,b| a[:name] <=> b[:name]}
              recent[foo] << {:name => hit[foo], :hits => 1}
              recent[foo].sort! {|a,b| a[:name] <=> b[:name]}
            end
          } # foo
        } # new_google

        puts

        now = Time.now
        elapsed_time = "%dh %dm %ds" % [(((now - start_time).abs)/3600), (((now - start_time).abs)/60) % 60, (((now - start_time).abs) % 60)]
        recent_time = "%.2fs" % (now - last_time)

        # exponential weighted average
        hpmx ||= (hitsx / ((now - start_time) / 60.0)) # start with an approximation
        # this is almost the same as hpmx = hpmx * 59/60 + hitsx_rec * 1/60, just doesn't assume that one slice = 1s
        hpmx = (hpmx * ((60.0 - (now - last_time).abs) / 60.0)) + # ~59/60 of previous value
               (hitsx_rec * 60.0 * ((now - last_time).abs / 60.0)) # + ~1/60 of estimated current value 
        hpm = "%d H/m" % hpmx

        puts

        hitsx = 0
        hitsx_rec = 0
        puts "Campaign#{' ' * (size[:campaign] - 8)} (hits) | Source#{' ' * (size[:source] - 6)} (hits) | Medium#{' ' * (size[:medium] - 6)} (hits) | Content#{' ' * (size[:content] - 7)} (hits)"
        puts '-' * (size[:campaign] + size[:source] + size[:medium] + size[:content] + size[:campaign_hits] + size[:source_hits] + size[:medium_hits] + size[:content_hits]  + 3 * 4+ 4)
        lines = [subtotals[:campaign].size, subtotals[:source].size, subtotals[:medium].size, subtotals[:content].size].max
        lines.times {|i|
          puts  "%-#{size[:campaign]}s %#{size[:campaign_hits]}s | %-#{size[:source]}s %#{size[:source_hits]}s | %-#{size[:medium]}s %#{size[:medium_hits]}s | %-#{size[:content]}s %#{size[:content_hits]}s" % [
                  (subtotals[:campaign][i][:name] rescue ""), (subtotals[:campaign][i][:hits] rescue ""),
                  (subtotals[:source][i][:name] rescue ""), (subtotals[:source][i][:hits] rescue ""),
                  (subtotals[:medium][i][:name] rescue ""), (subtotals[:medium][i][:hits] rescue ""),
                  (subtotals[:content][i][:name] rescue ""), (subtotals[:content][i][:hits] rescue "")]
  #        hitsx += a[:hits]
  #       hitsx_rec += recent_google[i][:hits]
        }
  #      size[:hits] = [hitsx.to_s.size, 4].max
   #     puts '-' * (size[:campaign] + size[:source] + size[:medium] + size[:content] + 3 * 4 + 4)
  #      puts "%-#{size[:campaign] + size[:source] + size[:medium] + size[:content] + 3 * 3}.#{size[:campaign] + size[:source] + size[:medium] + size[:content] + 3 * 3}s | %#{size[:hits]}d %-s" % [ 
  #            elapsed_time + ', ' + hpm, hitsx, ("*" * hitsx_rec) + ' ' + hitsx_rec.to_s]

        break if stream == :err
        last_time = Time.now
        
      end # run
    end # task
  end # logs
