package angel.game.script.action {
	import angel.common.SimplerButton;
	import angel.common.SplashResource;
	import angel.game.script.Script;
	import angel.game.script.ScriptContext;
	import angel.game.Settings;
	import angel.game.SplashScreen;
	import flash.display.Bitmap;
	import flash.geom.Point;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class SplashAction implements IAction {
		private var splashId:String;
		private var buttons:Vector.<ButtonInfo>;
		
		public static const TAG:String = "splash";
		
		public function SplashAction(splashId:String, buttons:Vector.<ButtonInfo>) {
			this.splashId = splashId;
			this.buttons = buttons;
		}
		
		public static function createFromXml(actionXml:XML, script:Script):IAction {
			if (script.requires(TAG, "id", actionXml)) {
				return null;
			}
			var splashId:String = actionXml.@id;
			
			
			var numberOfButtons:int = actionXml.button.length();
			var buttons:Vector.<ButtonInfo>;
			
			if (numberOfButtons > 0) {
				buttons = new Vector.<ButtonInfo>(numberOfButtons);
				for (var buttonIndex:int = 0; buttonIndex < numberOfButtons; ++buttonIndex) {
					buttons[buttonIndex] = buttonInfoFromXml(actionXml.button[buttonIndex], buttonIndex, numberOfButtons, script);
					
				}
			} else {
				buttons = new Vector.<ButtonInfo>(1);
				buttons[0] = buttonInfoFromXml(<button text="Continue" />, 0, 1, script);
			}
			buttons.fixed = true;
			
			return new SplashAction(splashId, buttons);
		}
		
		private static function buttonInfoFromXml(buttonXml:XML, index:int, totalButtons:int, rootScript:Script):ButtonInfo {
			var text:String;
			var script:Script;
			var location:Point;

			text = buttonXml.@text;
			location = new Point(10, Settings.STAGE_HEIGHT - ((totalButtons - index) * (SimplerButton.HEIGHT + 10)));
			if (buttonXml.@x.length() > 0) {
				location.x = int(buttonXml.@x);
			}
			if (buttonXml.@y.length() > 0) {
				location.y = int(buttonXml.@y);
			}
			script = new Script(buttonXml, rootScript);
			return new ButtonInfo(text, location, script);
		}
		
		/* INTERFACE angel.game.script.action.IAction */
		
		public function doAction(context:ScriptContext):Object {
			context.doThisAtEnd(startSplash);
			return null;
		}
		
		private function startSplash(context:ScriptContext):void {
			var splash:SplashScreen = new SplashScreen(splashId, context.main, context.entityWithSpecialId("it"));
			for each (var buttonInfo:ButtonInfo in buttons) {
				splash.addButton(buttonInfo.text, buttonInfo.location, buttonInfo.script);
			}
		}
		
	}

}
import angel.game.script.Script;
import flash.geom.Point;

internal class ButtonInfo {
	public var text:String;
	public var script:Script;
	public var location:Point;
	
	public function ButtonInfo(text:String, location:Point, script:Script) {
		this.text = text;
		this.script = script;
		this.location = location;
	}
}
