package angel.game {
	import angel.common.Util;
	import flash.display.DisplayObjectContainer;
	import flash.display.Stage;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class ToolTip {
		
		private static const BACK_COLOR:uint = 0xffcc55;
		private static const TEXT_COLOR:uint = 0x000000;
		private static const FONT_HEIGHT:int = 16;
		private static var tip:TextField;
		
		public function ToolTip() {
			trace("ERROR -- should never call this!");
		}
		
		public static function displayToolTip(parent:DisplayObjectContainer, text:String, x:int, y:int):void {
			if (tip == null) {
				createTip();
			}
			tip.text = text;
			tip.x = x;
			tip.y = y;
			parent.addChild(tip);
		}
		
		public static function removeToolTip():void {
			if ((tip != null) && (tip.parent != null)) {
				tip.parent.removeChild(tip);
			}
		}
		
		private static function createTip():void {
			tip = new TextField();
			//tip.textColor = TEXT_COLOR;
			tip.backgroundColor = BACK_COLOR;
			tip.background = true;
			tip.border = true;
			tip.height = FONT_HEIGHT + 6;
			tip.autoSize = TextFieldAutoSize.LEFT;
			tip.defaultTextFormat = new TextFormat(null, FONT_HEIGHT, TEXT_COLOR);
		}
		
	}

}