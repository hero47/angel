package angel.common {
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class UnknownAnimationData extends SingleImageAnimationData {
		private var id:String;
		private var callback:Function;
		
		public function UnknownAnimationData(labelForTemporaryVersion:String, unusedPixelsAtTopOfCell:int) {
			super(labelForTemporaryVersion, unusedPixelsAtTopOfCell);
		}
		
		override public function get animationClass():Class {
			return null;
		}
		
		override public function dataFinishedLoading(bitmapData:BitmapData, entry:CatalogEntry):void {
			var sourceRect:Rectangle = new Rectangle(0, paddingAtTop, Prop.WIDTH, Prop.HEIGHT - paddingAtTop);
			imageData.fillRect(imageData.rect, 0); // is this needed?
			imageData.copyPixels(bitmapData, sourceRect, new Point(0, 0));
			
			if (callback != null) {
				callback(id, bitmapData.width, bitmapData.height, entry.filename);
				callback = null;
			}
		}
		
		public function askForCallback(callbackWithIdImageSizeFilename:Function, id:String):void {
			this.id = id;
			this.callback = callbackWithIdImageSizeFilename;
		}
		
	}

}