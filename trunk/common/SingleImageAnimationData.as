package angel.common {
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class SingleImageAnimationData implements IAnimationData {
		protected var imageData:BitmapData;
		
		protected var paddingAtTop:int = Defaults.TOP;
		
		public function SingleImageAnimationData(labelForTemporaryVersion:String, unusedPixelsAtTopOfCell:int) {
			paddingAtTop = unusedPixelsAtTopOfCell;
			prepareTemporaryVersionForUse(labelForTemporaryVersion);
		}
		
		public function get animationClass():Class {
			return SingleImageAnimation;
		}
		
		private function prepareTemporaryVersionForUse(labelForTemporaryVersion:String):void {
			// Prepare temporary version for use until bitmap data is loaded from file
			imageData = new BitmapData(Prop.WIDTH, Prop.HEIGHT - paddingAtTop, true, 0xffff00ff);
			var label:TextField = new TextField();
			label.text = labelForTemporaryVersion;
			label.y = Prop.HEIGHT / 2;
			imageData.draw(label);
		}
		
		public function dataFinishedLoading(bitmapData:BitmapData, entry:CatalogEntry):void {
			if ((bitmapData.width != Prop.WIDTH) || (bitmapData.height != Prop.HEIGHT)) {
				Alert.show("Warning: expected " + entry.filename + " to be a single prop-sized image, but image size is wrong.");
			}
			var sourceRect:Rectangle = new Rectangle(0, paddingAtTop, Prop.WIDTH, Prop.HEIGHT - paddingAtTop);
			imageData.fillRect(imageData.rect, 0); // is this needed?
			imageData.copyPixels(bitmapData, sourceRect, new Point(0, 0));	
		}
		
		public function standardImage():BitmapData {
			return imageData;
		}
		
		
		// for use in editor only; this (plus code in editor) is awkward.
		public function increaseTop(additionalTop:int):int {
			paddingAtTop += additionalTop;
			var zerozero:Point = new Point(0, 0);
			var sourceRect:Rectangle = new Rectangle(0, additionalTop, Prop.WIDTH, Prop.HEIGHT - paddingAtTop);
			var clearRect:Rectangle = new Rectangle(0, imageData.rect.height - additionalTop, Prop.WIDTH, additionalTop);
			imageData.copyPixels(imageData, sourceRect, zerozero);
			imageData.fillRect(clearRect, 0xffffffff);
			return paddingAtTop;
		}
		
	}

}