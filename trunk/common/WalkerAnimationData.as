package angel.common {
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	
	
	// Walker image file has three rows of images (first column facing camera, rotating 45 degrees
	// counterclockwise each image).  The first row of images are standing, second row right foot forward,
	// third row left foot forward.  The ninth column contains a three-frame "death animation": first row
	// starting to collapse, second row fallen further, third row dead.
	public class WalkerAnimationData implements IAnimationData {
		public static const STAND:int = 0;
		public static const RIGHT:int = 1;
		public static const LEFT:int = 2;
		
		private var paddingAtTop:int = Defaults.TOP;
		
		[Embed(source = '../EmbeddedAssets/default_walker.png')]
		private static const DefaultWalkerBitmap:Class;
		
		//mapping from facing to position on image sheet
		public static const FACE_DYING:int = 8;
		public static const FACE_HUDDLE:int = 9;
		private static const NUMBER_OF_COLUMNS:int = 10;
		private static const imageColumn:Vector.<int> = Vector.<int>([1, 0, 7, 6, 5, 4, 3, 2, 8, 9]);
		public static const STEP_DEAD:int = 2;
		private static const NUMBER_OF_ROWS:int = 3;
		
		private var bits:Vector.<Vector.<BitmapData>>;
		
		public function WalkerAnimationData(labelForTemporaryVersion:String, unusedPixelsAtTopOfCell:int) {
			paddingAtTop = unusedPixelsAtTopOfCell;
			prepareTemporaryVersionForUse(labelForTemporaryVersion);
		}
		
		public function get animationClass():Class {
			return WalkerAnimation;
		}

		//NOTE: set unusedPixelsAtTopOfCell before calling this
		private function prepareTemporaryVersionForUse(labelForTemporaryVersion:String):void {
			// Prepare temporary version for use until bitmap data is loaded from file
			createBlankBits();
			copyBitsFromImagePane((new DefaultWalkerBitmap()).bitmapData);
			
			var label:TextField = new TextField();
			label.text = labelForTemporaryVersion;
			for (var facing:int = 0; facing < NUMBER_OF_COLUMNS; facing++) {
				for (var foot:int = 0; foot < NUMBER_OF_ROWS; foot++) {
					bits[facing][foot].draw(label);
				}
			}
		}
		
		public function dataFinishedLoading(bitmapData:BitmapData, entry:CatalogEntry):void {
			if ((bitmapData.width != Prop.WIDTH * NUMBER_OF_COLUMNS) || (bitmapData.height != Prop.HEIGHT * NUMBER_OF_ROWS)) {
				Alert.show("Warning: expected " + entry.filename + " to be a walker animation, but image size is wrong.");
			}
			copyBitsFromImagePane(bitmapData);
			bitmapData.dispose();
		}
		
		public function standardImage(down:Boolean = false):BitmapData {
			return down ? bitsFacing(WalkerAnimationData.FACE_DYING, WalkerAnimationData.STEP_DEAD) : bitsFacing(1);
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
			for (var facing:int = 0; facing < NUMBER_OF_COLUMNS; facing++) {
				for (var foot:int = 0; foot < NUMBER_OF_ROWS; foot++) {
					bits[facing][foot].draw(textField);
				}
			}
		}
		
		private function createBlankBits():void {
			bits = new Vector.<Vector.<BitmapData>>(NUMBER_OF_COLUMNS);
			bits.fixed = true;
			for (var facing:int = 0; facing < NUMBER_OF_COLUMNS; facing++) {
				bits[facing] = new Vector.<BitmapData>(NUMBER_OF_ROWS);
				bits[facing].fixed = true;
				for (var foot:int = 0; foot < NUMBER_OF_ROWS; foot++) {
					bits[facing][foot] = new BitmapData(Prop.WIDTH, Prop.HEIGHT - paddingAtTop);
				}
			}
		}

		private function copyBitsFromImagePane(bitmapData:BitmapData):void {
			// If image file is an odd size, try to do something reasonable with it.
			var useFullWidth:Boolean = (bitmapData.width > Prop.WIDTH);
			var useFullHeight:Boolean = (bitmapData.height > Prop.HEIGHT);
			
			var zerozero:Point = new Point(0, 0);
			var sourceRect:Rectangle = new Rectangle(0, paddingAtTop, Prop.WIDTH, Prop.HEIGHT - paddingAtTop); // x,y will change as we loop
			for (var facing:int = 0; facing < NUMBER_OF_COLUMNS; facing++) {
				for (var foot:int = 0; foot < NUMBER_OF_ROWS; foot++) {
					if (useFullWidth) {
						sourceRect.x = imageColumn[facing] * Prop.WIDTH;
					}
					if (useFullHeight) {
						sourceRect.y = (foot * Prop.HEIGHT) + paddingAtTop;
					}
					bits[facing][foot].copyPixels(bitmapData, sourceRect, zerozero);
				}
			}
		}
		
		// for use in editor only; this (plus code in editor) is awkward.
		public function increaseTop(additionalTop:int):int {
			paddingAtTop += additionalTop;
			var zerozero:Point = new Point(0, 0);
			var sourceRect:Rectangle = new Rectangle(0, additionalTop, Prop.WIDTH, Prop.HEIGHT - paddingAtTop);
			var clearRect:Rectangle = new Rectangle(0, bits[0][0].rect.height - additionalTop, Prop.WIDTH, additionalTop);
			for (var facing:int = 0; facing < NUMBER_OF_COLUMNS; facing++) {
				for (var foot:int = 0; foot < NUMBER_OF_ROWS; foot++) {
					bits[facing][foot].copyPixels(bits[facing][foot], sourceRect, zerozero);
					bits[facing][foot].fillRect(clearRect, 0xffffffff);
				}
			}
			return paddingAtTop;
		}
		
		
		
	}

}