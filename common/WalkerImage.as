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
		
		public var health:int;
		
		[Embed(source = '../../../EmbeddedAssets/temp_default_walker.png')]
		private var DefaultWalkerBitmap:Class;
		
		private var entry:CatalogEntry;
		
		//mapping from facing to position on image sheet
		//(facing 8 == 360 degrees hold the attacking/death images)
		private static const imageColumn:Vector.<int> = Vector.<int>([1, 0, 7, 6, 5, 4, 3, 2, 8]);
		
		private var bits:Vector.<Vector.<BitmapData>>;
		
		public function WalkerImage() {
			
		}
		
		public function prepareTemporaryVersionForUse(id:String, entry:CatalogEntry):void {
			this.entry = entry;
			
			bits = new Vector.<Vector.<BitmapData>>(9);
			bits.fixed = true;
			for (var facing:int = 0; facing < 9; facing++) {
				bits[facing] = new Vector.<BitmapData>(3);
				bits[facing].fixed = true;
				for (var j:int = 0; j < 3; j++) {
					bits[facing][j] = new BitmapData(Prop.WIDTH, Prop.HEIGHT);
				}
			}
			
			var bitmap:Bitmap = new DefaultWalkerBitmap();
			copyBitsFromImagePane(bitmap.bitmapData);
			
			var textField:TextField = new TextField();
			textField.text = id;
			textField.y = Prop.HEIGHT / 2;
			for (facing = 0; facing < 9; facing++) {
				for (j = 0; j < 3; j++) {
					bits[facing][j].draw(textField);
				}
			}
			
			health = 1;
			if (entry.xml != null) {
				var healthString:String = entry.xml.@health;
				if (healthString != "") {
					health = int(healthString);
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

		private function copyBitsFromImagePane(bitmapData:BitmapData):void {
			var fullPane:Boolean = true;
			// If we were given a single image instead of a pane of images, copy it into every animation frame
			// so we at least show something meaningful
			if (bitmapData.height == Prop.HEIGHT && bitmapData.width == Prop.WIDTH) {
				fullPane = false;
			}
			var zerozero:Point = new Point(0, 0);
			var sourceRect:Rectangle = new Rectangle(0, 0, Prop.WIDTH, Prop.HEIGHT);
			for (var facing:int = 0; facing < 9; facing++) {
				for (var j:int = 0; j < 3; j++) {
					if (fullPane) {
						sourceRect.x = imageColumn[facing] * Prop.WIDTH;
						sourceRect.y = j * Prop.HEIGHT;
					}
					bits[facing][j].fillRect(bits[facing][j].rect, 0);
					bits[facing][j].copyPixels(bitmapData, sourceRect, zerozero);
				}
			}
		}
		
		// Facing == rotation/45 if we were in a top-down view.
		public function bitsFacing(facing:int, step:int=0):BitmapData {
			return bits[facing][step];
		}
		
		
	}

}