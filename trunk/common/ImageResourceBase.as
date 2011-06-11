package angel.common {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import angel.common.CatalogEntry;
	import flash.events.Event;
	import flash.geom.Point;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class ImageResourceBase  {
		protected var entry:CatalogEntry;
		
		public function ImageResourceBase() {
			
		}
		
		/* INTERFACE angel.common.ICatalogedResource */
		
		public function get catalogEntry():CatalogEntry {
			return entry;
		}
		
		public function prepareTemporaryVersionForUse(id:String, entry:CatalogEntry, errors:MessageCollector):void {
			this.entry = entry;
			
			if (!Util.nullOrEmpty(entry.filename)) {
				LoaderWithErrorCatching.LoadBytesFromFile(entry.filename,
					function(event:Event, param:Object, filename:String):void {
						var bitmap:Bitmap = event.target.content;
						warnIfBitmapIsWrongSize(entry, bitmap.bitmapData, errors);
						entry.data.dataFinishedLoading(bitmap.bitmapData);
					}
				);
			}
			
		}
		
		protected function expectedBitmapSize():Point {
			return null;
		}
		
		protected function warnIfBitmapIsWrongSize(entry:CatalogEntry, bitmapData:BitmapData, errors:MessageCollector = null):void {
			var expectedSize:Point = expectedBitmapSize();
			if (expectedSize == null) {
				return;
			}
			if ((bitmapData.width != expectedSize.x) || (bitmapData.height != expectedSize.y)) {
				var typeName:String = entry.type.TAG;
				MessageCollector.collectOrShowMessage(errors, "Warning: " + typeName + " file " + entry.filename + " is not " +
						expectedSize.x + "x" + expectedSize.y + ".  Please fix!");
			}
		}
		
	}

}