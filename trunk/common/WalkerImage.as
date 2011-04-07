package angel.common {
	import angel.common.Prop;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;

	// UNDONE: This has expanded to more than just an image, and should be renamed at some point
	// or the non-image stuff moved.  Same with PropImage.
	public class WalkerImage implements ICatalogedResource {
		public static const STAND:int = 0;
		public static const RIGHT:int = 1;
		public static const LEFT:int = 2;
		
		// Facing == rotation/45 if we were in a top-down view.
		// This will make it convenient if we ever want to determine facing from actual angles
		public static const FACE_CAMERA:int = 1;
		public static const FACE_DYING:int = 8;
		
		public var health:int = 1;
		public var unusedPixelsAtTopOfCell:int = 0;
		
		[Embed(source = '../../../EmbeddedAssets/temp_default_walker.png')]
		private var DefaultWalkerBitmap:Class;
		
		private var entry:CatalogEntry;
		
		//mapping from facing to position on image sheet
		//(facing 8 == DYING holds the death images)
		private static const imageColumn:Vector.<int> = Vector.<int>([1, 0, 7, 6, 5, 4, 3, 2, 8]);
		
		private var bits:Vector.<Vector.<BitmapData>>;
		
		public function WalkerImage() {
			
		}
		
		public function prepareTemporaryVersionForUse(id:String, entry:CatalogEntry):void {
			this.entry = entry;
			
			parseAndDeleteCatalogXml(entry);	
			createPlaceholderImages(id);
		}
		
		private function parseAndDeleteCatalogXml(entry:CatalogEntry):void {
			if (entry.xml != null) {
				var value:String;
				
				value = entry.xml.@health;
				if (value != "") {
					health = int(value);
				}
				
				value = entry.xml.@top;
				if (value != "") {
					unusedPixelsAtTopOfCell = int(value);
				}
				
				entry.xml = null;
			}
		
		}
		
		public function get catalogEntry():CatalogEntry {
			return entry;
		}
		
		// Copy new images over the already-existing bitmapData (which may already be displayed)
		public function dataFinishedLoading(bitmapData:BitmapData):void {
			copyBitsFromImagePane(bitmapData);
			bitmapData.dispose();
		}
		
		private function createPlaceholderImages(id:String):void {
			createBlankBits();
			copyBitsFromImagePane((new DefaultWalkerBitmap()).bitmapData);
			
			var textField:TextField = new TextField();
			textField.text = id;
			for (var facing:int = 0; facing < 9; facing++) {
				for (var foot:int = 0; foot < 3; foot++) {
					bits[facing][foot].draw(textField);
				}
			}
		}
		
		private function createBlankBits():void {
			bits = new Vector.<Vector.<BitmapData>>(9);
			bits.fixed = true;
			for (var facing:int = 0; facing < 9; facing++) {
				bits[facing] = new Vector.<BitmapData>(3);
				bits[facing].fixed = true;
				for (var foot:int = 0; foot < 3; foot++) {
					bits[facing][foot] = new BitmapData(Prop.WIDTH, Prop.HEIGHT - unusedPixelsAtTopOfCell);
				}
			}
		}

		private function copyBitsFromImagePane(bitmapData:BitmapData):void {
			var fullPane:Boolean = true;
			// If we were given a single image instead of a pane of images, copy it into every animation frame
			// so we at least show something meaningful
			if (bitmapData.height == Prop.HEIGHT && bitmapData.width == Prop.WIDTH) {
				fullPane = false;
			}
			var zerozero:Point = new Point(0, 0);
			var sourceRect:Rectangle = new Rectangle(0, 0, Prop.WIDTH, Prop.HEIGHT - unusedPixelsAtTopOfCell); // x,y will change as we loop
			for (var facing:int = 0; facing < 9; facing++) {
				for (var foot:int = 0; foot < 3; foot++) {
					if (fullPane) {
						sourceRect.x = imageColumn[facing] * Prop.WIDTH;
						sourceRect.y = (foot * Prop.HEIGHT) + unusedPixelsAtTopOfCell;
					}
					bits[facing][foot].copyPixels(bitmapData, sourceRect, zerozero);
				}
			}
		}
		
		// Facing == rotation/45 if we were in a top-down view.
		public function bitsFacing(facing:int, step:int=0):BitmapData {
			return bits[facing][step];
		}
		
		// for use in editor only
		public function increaseTop(additionalTop:int):void {
			unusedPixelsAtTopOfCell += additionalTop;
			var zerozero:Point = new Point(0, 0);
			var sourceRect:Rectangle = new Rectangle(0, additionalTop, Prop.WIDTH, Prop.HEIGHT - unusedPixelsAtTopOfCell);
			var clearRect:Rectangle = new Rectangle(0, bits[0][0].rect.height - additionalTop, Prop.WIDTH, additionalTop);
			for (var facing:int = 0; facing < 9; facing++) {
				for (var foot:int = 0; foot < 3; foot++) {
					bits[facing][foot].copyPixels(bits[facing][foot], sourceRect, zerozero);
					bits[facing][foot].fillRect(clearRect, 0xffffffff);
				}
			}
		}
		
	}

}