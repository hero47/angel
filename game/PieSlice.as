package angel.game {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	
	 // Data for one "slice" of a pie menu
	public class PieSlice {
		public var icon:BitmapData;
		public var text:String;
		public var callback:Function;
		
		public function PieSlice(icon:BitmapData, text:String, callback:Function) {
			this.icon = (icon == null ? new BitmapData(PieMenu.ICON_SIZE, PieMenu.ICON_SIZE, false, 0xff00dd) : icon); // default to pink square
			this.text = text;
			this.callback = callback;
		}
		
	}

}