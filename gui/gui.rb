require 'gtk3'
require 'pathname'

def time_ago timestamp
    delta = Time.now.to_i - timestamp
    case delta
    when 0..59         then "#{delta}s ago"
    when 60            then 'a minute ago'
    when 61..119       then 'about a minute ago'
    when 120..3599     then "#{delta / 60} minutes ago"
    when 3600..86399   then "#{(delta / 3600).round} hours ago"
    when 86400..259199 then "#{(delta / 86400).round} days ago"
    else Time.at(timestamp).strftime('%d %B %Y %H:%M')
    end
end

def load_into_liststore store, rows
  store.clear
  rows.each do |row|
    store.append.set_values row
  end
end

def build_gui window_name: 'main_window', ns: nil, gui_file: 'gui.glade'
  raise 'Missing namespace' if ns.nil?

  app = Gtk::Application.new ns, :flags_none

  builder = Gtk::Builder.new
  builder.add_from_file File.dirname(__FILE__) + '/' + gui_file
  builder.set_application app

  app.signal_connect :activate do
    main_window = builder.get_object window_name
    
    yield app, builder, main_window

    app.add_window main_window
    main_window.show_all
  end

  app.run
end