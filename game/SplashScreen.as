package angel.game {
	import angel.common.ICleanup;
	import angel.common.SimplerButton;
	import angel.common.SplashResource;
	import angel.game.script.Script;
	import angel.game.script.ScriptContext;
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class SplashScreen extends Sprite implements ICleanup {
		
		public static const BUTTON_COLOR:uint = 0xffcccc;
		
		private var main:Main;
		private var suspendedRoom:Room;
		private var activePlayer:ComplexEntity;
		private var scriptTriggeredBy:SimpleEntity;
		private var background:Bitmap;
		private var buttons:Vector.<SimplerButton> = new Vector.<SimplerButton>();
		private var scripts:Vector.<Script> = new Vector.<Script>();
		
		public function SplashScreen(splashId:String, main:Main, scriptTriggeredBy:SimpleEntity = null) {
			this.main = main;
			if (main.currentRoom != null) {
				suspendedRoom = main.currentRoom;
				activePlayer = suspendedRoom.activePlayer();
				suspendedRoom.suspendUi(this);
			}
			this.scriptTriggeredBy = scriptTriggeredBy;
			var splash:SplashResource = Settings.catalog.retrieveSplashResource(splashId);
			background = new Bitmap(splash.bitmapData);
			addChild(background);
			main.addChild(this);
		}
		
		public function cleanup():void {
			for each (var button:SimplerButton in buttons) {
				button.cleanup();
			}
			buttons = null;
			removeChild(background);
			if (parent != null) {
				parent.removeChild(this);
			}
			main.currentRoom.restoreUiAfterSuspend(this, suspendedRoom);
		}
		
		public function addButton(text:String, location:Point, script:Script):void {
			trace("Splash adding button", text, location);
			var button:SimplerButton = new SimplerButton(text, clickListener, BUTTON_COLOR);
			button.resizeToFitText(SimplerButton.WIDTH);
			addChild(button);
			button.x = location.x;
			button.y = location.y;
			buttons.push(button);
			scripts.push(script);
		}
		
		private function clickListener(event:Event):void {
			var i:int = buttons.indexOf(event.target);
			// If any of the button script produces messages, we want that to happen and wait for player ok before
			// closing down the splash.  So instead of just telling the script to run, we'll micromanage it and
			// add our own close at the end of the list of "do at end" stuff before it processes those.
			var context:ScriptContext = new ScriptContext(main.currentRoom, activePlayer, scriptTriggeredBy);
			scripts[i].doActions(context);
			context.doThisAtEnd(closeMeDown);
			context.finish();
		}
		
		private function closeMeDown(context:ScriptContext):void {
			cleanup();
		}
		
	}

}