package angel.common {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import angel.common.CatalogEntry;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class SplashResource extends ImageResourceBase implements ICatalogedResource {
		private var bits:BitmapData;
		
		public static const WIDTH:int = 1000;
		public static const HEIGHT:int = 600;
		private static const COLOR_BEFORE_IMAGE_LOADS:uint = 0xffffcc;
		
		public static const TAG:String = "splash";
		
		public function SplashResource() {
		}
		
		/* INTERFACE angel.common.ICatalogedResource */
		
		override public function prepareTemporaryVersionForUse(id:String, entry:CatalogEntry, errors:MessageCollector):void {
			super.prepareTemporaryVersionForUse(id, entry, errors);
			bits = new BitmapData(WIDTH, HEIGHT, false, COLOR_BEFORE_IMAGE_LOADS);
		}
		
		override protected function expectedBitmapSize():Point {
			return new Point(WIDTH, HEIGHT);
		}
		
		public function dataFinishedLoading(bitmapData:BitmapData, param:Object = null):void {
			bits.copyPixels(bitmapData, new Rectangle(0, 0, WIDTH, HEIGHT), new Point(0, 0));
		}
		
		public function get bitmapData():BitmapData {
			return bits;
		}
		
	}

}