package angel.common {
	import angel.game.Icon;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class EvidenceResource extends InventoryResourceBase {
		
		public static const TAG:String = "evidence";
		
		[Embed(source='../EmbeddedAssets/item_icon_default.png')]
		public static const DEFAULT_EVIDENCE_ICON:Class;
		[Embed(source='../EmbeddedAssets/item_image_default.png')]
		public static const DEFAULT_IMAGE:Class;
		
		public static const IMAGE_WIDTH:int = 125;
		public static const IMAGE_HEIGHT:int = 175;
		
		public var imageFile:String = null;
		
		private var imageDone:Boolean = false;
		private var imageData:BitmapData = null;
		
		public function EvidenceResource() {
			
		}
		
		override public function prepareTemporaryVersionForUse(id:String, entry:CatalogEntry, errors:MessageCollector):void {
			super.prepareTemporaryVersionForUse(id, entry, errors);
			myItemClass = Evidence;	
			iconBitmapData = defaultBitmapData(DEFAULT_EVIDENCE_ICON);
			Util.setTextFromXml(this, "imageFile", entry.xml, "imageFile");
			
			entry.xml = null;
		}
		
		private function prepareTemporaryImageForUse():void {
			imageData = new BitmapData(IMAGE_WIDTH, IMAGE_HEIGHT, true, 0x00000000);
			imageData.copyPixels(new DEFAULT_IMAGE().bitmapData, new Rectangle(0, 0, IMAGE_WIDTH, IMAGE_HEIGHT), new Point(0,0));
			if (!Util.nullOrEmpty(imageFile)) {
				LoaderWithErrorCatching.LoadBytesFromFile(imageFile, imageFinishedLoading);
			}
			imageDone = true;
		}
		
		private function imageFinishedLoading(event:Event, param:Object, filename:String):void {
			var bitmap:Bitmap = event.target.content;
			imageData.copyPixels(bitmap.bitmapData, new Rectangle(0, 0, IMAGE_WIDTH, IMAGE_HEIGHT), new Point(0,0));
		}
		
		public function get imageBitmapData():BitmapData {
			if (!imageDone) {
				prepareTemporaryImageForUse();
			}
			return imageData;
		}
		
	}

}