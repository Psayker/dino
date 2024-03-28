namespace Dino.Plugins.NotificationSound {

public class Plugin : RootInterface, Object {

    public Dino.Application app;

    public void registered(Dino.Application app) {
        this.app = app;

        app.stream_interactor.get_module(NotificationEvents.IDENTITY).notify_content_item.connect((item, conversation) => {
            Gdk.beep();
        });
    }

    public void shutdown() { }
}

}
