package angel.common {
	import angel.game.SingleImageAnimation;
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.text.TextField;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class SingleImageAnimationData implements IAnimationData {
		private var imageData:BitmapData;
		
		public function SingleImageAnimationData() {
			
		}
		
		public function get animationClass():Class {
			return SingleImageAnimation;
		}

		public function prepareTemporaryVersionForUse(labelForTemporaryVersion:String):void {
			// Prepare temporary version for use until bitmap data is loaded from file
			imageData = new BitmapData(Prop.WIDTH, Prop.HEIGHT, true, 0xffff00ff);
			var label:TextField = new TextField();
			label.text = labelForTemporaryVersion;
			label.y = Prop.HEIGHT / 2;
			imageData.draw(label);
		}
		
		public function dataFinishedLoading(bitmapData:BitmapData):void {
			imageData.fillRect(imageData.rect, 0);
			imageData.copyPixels(bitmapData, imageData.rect, new Point(0, 0));	
		}
		
		public function standardImage():BitmapData {
			return imageData;
		}
		
	}

}