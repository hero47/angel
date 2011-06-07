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
	public class SplashResource implements ICatalogedResource {
		private var entry:CatalogEntry;
		private var bits:BitmapData;
		
		public static const WIDTH:int = 1000;
		public static const HEIGHT:int = 600;
		private static const COLOR_BEFORE_IMAGE_LOADS:uint = 0xffffcc;
		
		public function SplashResource() {
		}
		
		/* INTERFACE angel.common.ICatalogedResource */
		
		public function get catalogEntry():CatalogEntry {
			return entry;
		}
		
		public function prepareTemporaryVersionForUse(id:String, entry:CatalogEntry):void {
			this.entry = entry;
			bits = new BitmapData(WIDTH, HEIGHT, false, COLOR_BEFORE_IMAGE_LOADS);
		}
		
		public function dataFinishedLoading(bitmapData:BitmapData):void {
			bits.copyPixels(bitmapData, new Rectangle(0, 0, WIDTH, HEIGHT), new Point(0, 0));
		}
		
		public function get bitmapData():BitmapData {
			return bits;
		}
		
	}

}