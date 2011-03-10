package angel.common {
	import angel.common.CatalogEntry;
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class PropImage implements ICatalogedResource {
		
		private var entry:CatalogEntry;
		public var imageData:BitmapData;
		
		public function PropImage() {
			
		}
		
		/* INTERFACE angel.common.CatalogedResource */
		
		public function prepareTemporaryVersionForUse(id:String, entry:CatalogEntry):void {
			this.entry = entry;
			imageData = new BitmapData(Prop.WIDTH, Prop.HEIGHT, true, 0xffff00ff);
			var myTextField:TextField = new TextField();
			myTextField.text = id;
			myTextField.y = Prop.HEIGHT / 2;
			imageData.draw(myTextField);
		}
		
		public function get catalogEntry():CatalogEntry {
			return entry;
		}
		
		// Copy new image onto the already-existing bitmap (which may already be displayed)
		public function dataFinishedLoading(bitmapData:BitmapData):void {
			var zerozero:Point = new Point(0, 0);
			imageData.fillRect(imageData.rect, 0);
			imageData.copyPixels(bitmapData, imageData.rect, zerozero);			
		}
		
	}

}