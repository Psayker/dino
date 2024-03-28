using Dino.Entities;
using Xmpp;
using Gst;

namespace Dino.Plugins.PhoneRinger {

public class StreamPlayer {

    private MainLoop loop = new MainLoop ();
    private Element player = ElementFactory.make("playbin", "play");

    private void foreach_tag (Gst.TagList list, string tag) {
        switch (tag) {
        case "title":
            string tag_string;
            list.get_string (tag, out tag_string);
            stdout.printf ("tag: %s = %s\n", tag, tag_string);
            break;
        default:
            break;
        }
    }

    private bool bus_callback (Gst.Bus bus, Gst.Message message) {
        switch (message.type) {
        case MessageType.ERROR:
            GLib.Error err;
            string debug;
            message.parse_error (out err, out debug);
            stdout.printf ("Error: %s\n", err.message);
            loop.quit();
            break;
        case MessageType.EOS:
            stdout.printf("end of stream\n");
            break;
        case MessageType.STATE_CHANGED:
            Gst.State oldstate;
            Gst.State newstate;
            Gst.State pending;
            message.parse_state_changed (out oldstate, out newstate,
                                            out pending);
            stdout.printf("state changed: %s->%s:%s\n",
                            oldstate.to_string (), newstate.to_string (),
                            pending.to_string ());
            break;
        case MessageType.TAG:
            Gst.TagList tag_list;
            stdout.printf("taglist found\n");
            message.parse_tag (out tag_list);
            tag_list.foreach((TagForeachFunc) foreach_tag);
            break;
        default:
            break;
        }

        return true;
    }

    public void play (string stream) {
        playerplayer.uri = stream;

        Gst.Bus bus = player.get_bus ();
        bus.add_watch(0, bus_callback);

        player.set_state(State.PLAYING);

        loop.run ();
    }

    public void stop() {
        player.set_state(State.PLAYING_TO_PAUSED);
    }
}

public class Plugin : RootInterface, NotificationProvider, GLib.Object {

    private const int GAP = 1;
    private const int RINGER_ID = 0;
    private const int DIALER_ID = 1;
    private StreamPlayer sound_player;
    private bool ringing = false;
    private bool dialing = false;

    private void loop_ringer() {
        sound_player.play("resource://org/ringer.mp3");
    }

    private void loop_dialer() {
        sound_player.play("resource://org/dialer.mp3");
    }

    public void registered(Dino.Application app) {

        Gst.init (ref args);
        sound_player = new StreamPlayer();

        NotificationEvents notification_events = app.stream_interactor.get_module(NotificationEvents.IDENTITY);
        notification_events.register_notification_provider.begin(this);
    }

    public void shutdown() { }

    public async void notify_call(Call call, Conversation conversation, bool video, bool multiparty, string conversation_display_name){
        ringing = true;
        loop_ringer();
    }

    public async void retract_call_notification(Call call, Conversation conversation){
        ringing = false;
        sound_player.stop();
    }

    public async void notify_dialing(){
        dialing = true;
        loop_dialer();
    }

    public async void retract_dialing(){
        dialing = false;
        sound_player.stop();
    }

    public double get_priority(){
        return 0;
    }

    public async void notify_message(Dino.Entities.Message message, Conversation conversation, string conversation_display_name, string? participant_display_name){}
    public async void notify_file(FileTransfer file_transfer, Conversation conversation, bool is_image, string conversation_display_name, string? participant_display_name){}
    public async void notify_subscription_request(Conversation conversation){}
    public async void notify_connection_error(Account account, ConnectionManager.ConnectionError error){}
    public async void notify_muc_invite(Account account, Jid room_jid, Jid from_jid, string inviter_display_name){}
    public async void notify_voice_request(Conversation conversation, Jid from_jid){}
    public async void retract_content_item_notifications(){}
    public async void retract_conversation_notifications(Conversation conversation){}

}

}
