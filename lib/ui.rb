class UI
    def initialize(app, builder, window)
        @app = app
        @builder = builder
        @window = window
        @player = nil
        @station = nil

        load_controls
        set_window_size
        connect_event_handlers
        build_last_played_list
        toggle_play_state
        keep_statusbar_updated
        keep_last_played_list_updated
    end

    def load_controls
        @btn_refresh_last_played = @builder.get_object('btn_refresh_last_played')
        @channel_selector = @builder.get_object('channel_selector')
        @tree_last_played = @builder.get_object('tree_last_played')
        @btn_play_pause = @builder.get_object('btn_play_pause')
        @lbl_status = @builder.get_object('lbl_status')
        @statusbar = @builder.get_object('statusbar')
        @play_icon = @builder.get_object('play_icon')
        @stop_icon = @builder.get_object('stop_icon')

        @statusbar_context_id = @statusbar.get_context_id('main')
    end

    def set_window_size
        @window.set_size_request(700, 600)
    end

    def connect_event_handlers
        @btn_play_pause.signal_connect(:clicked) { toggle_play_state }
        @btn_refresh_last_played.signal_connect(:clicked) { refresh_last_played_async }
        @channel_selector.signal_connect(:changed) { change_channel }

        @window.signal_connect(:key_press_event) do |_, e|
            toggle_play_state if e.keyval == 32
        end
    end

    def build_last_played_list
        renderer = Gtk::CellRendererText.new

        time   = Gtk::TreeViewColumn.new('Time',   renderer, text: 0)
        artist = Gtk::TreeViewColumn.new('Artist', renderer, text: 1)
        track  = Gtk::TreeViewColumn.new('Track',  renderer, text: 2)

        @tree_last_played.append_column(time)
        @tree_last_played.append_column(artist)
        @tree_last_played.append_column(track)

        @last_played_store = Gtk::ListStore.new(String, String, String)
        @tree_last_played.set_model(@last_played_store)
    end

    def toggle_play_state
        if @player.nil?
            start_player
        else
            stop_player
        end
    end

    def statusbar_msg
        if @last_played_last_updated
            'Last updated ' + time_ago(@last_played_last_updated)
        else
            ''
        end
    end

    def keep_statusbar_updated
        Thread.new do
            loop do
                @statusbar.push(@statusbar_context_id, statusbar_msg)
                sleep(1)
            end
        end
    end

    def keep_last_played_list_updated
        Thread.new do
            loop do
                refresh_last_played
                sleep(30)
            end
        end
    end

    def change_channel
        terminate
        start_player
        refresh_last_played_async
    end

    def refresh_last_played_async
        Thread.new do
            refresh_last_played
        end
    end

    def refresh_last_played
        if @station
            if @station.channel > 0 && @station.channel <= 3
                load_into_liststore(@last_played_store, @station.last_played_rows)
                @last_played_last_updated = Time.now.to_i
            else
                @last_played_last_updated = nil
                @last_played_store.clear
            end
        end
    end

    def bytes2human(b)
        return '0B' if b <= 0

        k = 1024
        suffixes = %w[T G M K B]

        suffixes.each_with_index do |suffix, i|
            threshold = k ** (suffixes.length - i - 1)
            if b >= threshold
                return (b / threshold).to_s + suffix
            end
        end
    end

    def start_player
        @station = Station.new(@channel_selector.active_text)
        @player = Thread.new do
            total_bytes = 0
            @station.play do |bytes|
                total_bytes += bytes
                @lbl_status.set_text(bytes2human(total_bytes) + ' transferred')
            end
        end

        @btn_play_pause.set_image(@stop_icon)
        @lbl_status.set_text("Connecting to radio #{@station.channel}...")
        @btn_play_pause.set_label('Stop')
        @window.set_title("Radio #{@station.channel}")
    end

    def stop_player
        terminate
        @player = nil
        @btn_play_pause.set_image(@play_icon)
        @lbl_status.set_text('Not connected')
        @btn_play_pause.set_label('Play')
        @window.set_title('Radio off')
    end

    def terminate
        if @player
            @station.stop
            @player.join
        end
    end
end

def time_ago(timestamp)
    delta = Time.now.to_i - timestamp
    case delta
    when 0..59           then "#{delta}s ago"
    when 60              then 'a minute ago'
    when 61..119         then 'about a minute ago'
    when 120..3599       then "#{delta / 60} minutes ago"
    when 3600..86_399    then "#{(delta / 3600).round} hours ago"
    when 86_400..259_199 then "#{(delta / 86_400).round} days ago"
    else Time.at(timestamp).strftime('%d %B %Y %H:%M')
    end
end

def load_into_liststore(store, rows)
    store.clear
    rows.each do |row|
        store.append.set_values(row)
    end
end

def build_ui(window_name: 'main_window', ns: nil, file: '../ui/main.glade')
    raise 'Missing namespace' if ns.nil?

    app = Gtk::Application.new(ns, :flags_none)

    builder = Gtk::Builder.new
    builder.add_from_file(File.dirname(__FILE__) + '/' + file)
    builder.set_application(app)

    app.signal_connect(:activate) do
        main_window = builder.get_object(window_name)

        yield app, builder, main_window

        app.add_window(main_window)
        main_window.show_all
    end

    app.run
end
