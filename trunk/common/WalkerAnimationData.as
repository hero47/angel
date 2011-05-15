package angel.common {
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class WalkerAnimationData implements IAnimationData {
		public static const STAND:int = 0;
		public static const RIGHT:int = 1;
		public static const LEFT:int = 2;
		
		[Embed(source = '../../../EmbeddedAssets/temp_default_walker.png')]
		private static const DefaultWalkerBitmap:Class;
		
		public var unusedPixelsAtTopOfCell:int = Defaults.TOP;
		
		//mapping from facing to position on image sheet
		//(facing 8 == DYING holds the death images)
		private static const imageColumn:Vector.<int> = Vector.<int>([1, 0, 7, 6, 5, 4, 3, 2, 8]);
		public static const FACE_DYING:int = 8;
		
		private var bits:Vector.<Vector.<BitmapData>>;
		
		public function WalkerAnimationData() {
			
		}

		//NOTE: set unusedPixelsAtTopOfCell before calling this
		public function prepareTemporaryVersionForUse(labelForTemporaryVersion:String):void {
			// Prepare temporary version for use until bitmap data is loaded from file
			createBlankBits();
			copyBitsFromImagePane((new DefaultWalkerBitmap()).bitmapData);
			
			var label:TextField = new TextField();
			label.text = labelForTemporaryVersion;
			for (var facing:int = 0; facing < 9; facing++) {
				for (var foot:int = 0; foot < 3; foot++) {
					bits[facing][foot].draw(label);
				}
			}
		}
		
		public function dataFinishedLoading(bitmapData:BitmapData):void {
			copyBitsFromImagePane(bitmapData);
			bitmapData.dispose();
		}
		
		public function standardImage():BitmapData {
			return bitsFacing(0);
		}
		
		// Facing == rotation/45 if we were in a top-down view.
		public function bitsFacing(facing:int, step:int=0):BitmapData {
			return bits[facing][step];
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
		
		// for use in editor only; this (plus code in editor) is ugly.
		public function increaseTop(additionalTop:int):int {
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
			return unusedPixelsAtTopOfCell;
		}
		
		
		
	}

}