package angel.common {
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	
	// "Small sheet" format:
	// Walker image file has three rows of images (first column facing camera, rotating 45 degrees
	// counterclockwise each image).  The first row of images are standing, second row right foot forward,
	// third row left foot forward.  The ninth column contains a three-frame "death animation": first row
	// starting to collapse, second row fallen further, third row dead.  The tenth column has a "huddle" image.
	//
	// "Large sheet" format:
	// The first eight columns of those three rows are repeated in additional sets of three rows for
	// each gait.  The ninth and tenth column of those extra gaits are currently unused.
	public class WalkerAnimationData implements IAnimationData {
		public static const STAND:int = 0;
		public static const RIGHT:int = 1;
		public static const LEFT:int = 2;
		
		private var paddingAtTop:int = Defaults.TOP;
		
		[Embed(source = '../EmbeddedAssets/default_walker.png')]
		private static const DefaultWalkerBitmap:Class;
		
		// The image data as used inside the program
		private var movementBits:Vector.<Vector.<BitmapData>>;
		private var dyingBits:Vector.<BitmapData>;
		private var huddleBits:BitmapData;
		private static const MOVEMENT_COLUMNS:int = 8;
		private static const MOVEMENT_ROWS:int = 12;
		private static const MOVEMENT_STEP_ROWS:int = 3;
		private static const DEATH_ROWS:int = 3;
		public static const FACE_DYING:int = -1;
		public static const FACE_HUDDLE:int = -2;
		public static const STEP_DEAD:int = 2;
		
		//info about the raw image sheet, which will be chopped up and copied into individual sprite images
		private static const RAW_COLUMNS:int = 10;
		private static const SMALL_SHEET_RAW_ROWS:int = 3;
		private static const LARGE_SHEET_RAW_ROWS:int = 12;
		private static const mapFacingToRawImageColumn:Vector.<int> = Vector.<int>([1, 0, 7, 6, 5, 4, 3, 2]);
		private static const DYING_COLUMN:int = 8;
		private static const HUDDLE_COLUMN:int = 9;		
		
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
			for (var facing:int = 0; facing < MOVEMENT_COLUMNS; facing++) {
				for (var foot:int = 0; foot < MOVEMENT_ROWS; foot++) {
					movementBits[facing][foot].draw(label);
				}
			}
			for (var i:int = 0; i < DEATH_ROWS; i++) {
				dyingBits[i].draw(label);
			}
			huddleBits.draw(label);
		}
		
		public function dataFinishedLoading(bitmapData:BitmapData, entry:CatalogEntry):void {
			if (!isRecognizedImageSheetSize(bitmapData)) {
				Alert.show("Warning: expected " + entry.filename + " to be a walker animation, but image size doesn't match a known format.");
			}
			copyBitsFromImagePane(bitmapData);
			bitmapData.dispose();
		}
		
		private function isRecognizedImageSheetSize(bitmapData:BitmapData):Boolean {
			if (bitmapData.width != Prop.WIDTH * RAW_COLUMNS) {
				return false;
			}
			if ((bitmapData.height == Prop.HEIGHT * LARGE_SHEET_RAW_ROWS) || (bitmapData.height == Prop.HEIGHT * SMALL_SHEET_RAW_ROWS)) {
				return true;
			}
			return false;
		}
		
		public function standardImage(down:Boolean = false):BitmapData {
			return down ? bitsFacing(WalkerAnimationData.FACE_DYING, WalkerAnimationData.STEP_DEAD) : bitsFacing(1);
		}
		
		// Facing == rotation/45 if we were in a top-down view.
		public function bitsFacing(facing:int, step:int = 0, gait:int = 0):BitmapData {
			switch (facing) {
				case FACE_DYING:
					return dyingBits[step];
				case FACE_HUDDLE:
					return huddleBits;
			}
			step += gait * MOVEMENT_STEP_ROWS;
			return movementBits[facing][step];
		}
		
		private function createBlankBits():void {
			movementBits = new Vector.<Vector.<BitmapData>>(MOVEMENT_COLUMNS, true);
			for (var facing:int = 0; facing < MOVEMENT_COLUMNS; facing++) {
				movementBits[facing] = new Vector.<BitmapData>(MOVEMENT_ROWS, true);
				for (var foot:int = 0; foot < MOVEMENT_ROWS; foot++) {
					movementBits[facing][foot] = new BitmapData(Prop.WIDTH, Prop.HEIGHT - paddingAtTop);
				}
			}
			dyingBits = new Vector.<BitmapData>(DEATH_ROWS, true);
			for (var i:int = 0; i < DEATH_ROWS; i++) {
				dyingBits[i] = new BitmapData(Prop.WIDTH, Prop.HEIGHT - paddingAtTop);
			}
			huddleBits = new BitmapData(Prop.WIDTH, Prop.HEIGHT - paddingAtTop);
		}

		private function copyBitsFromImagePane(bitmapData:BitmapData):void {
			// If image file is an odd size, try to do something reasonable with it.
			var singleRow:Boolean = (bitmapData.height <= Prop.HEIGHT);
			var singleColumn:Boolean = (bitmapData.width <= Prop.WIDTH);
			var hasGaitRows:Boolean = (bitmapData.height > Prop.HEIGHT * 3);
			
			if (hasGaitRows) {
				trace("Found some gait rows");
			}
			
			var zerozero:Point = new Point(0, 0);
			var sourceRect:Rectangle = new Rectangle(0, paddingAtTop, Prop.WIDTH, Prop.HEIGHT - paddingAtTop); // x,y will change as we loop
			var rawColumn:int;
			var rawRow:int;
			for (var facing:int = 0; facing < MOVEMENT_COLUMNS; facing++) {
				for (var foot:int = 0; foot < MOVEMENT_STEP_ROWS; foot++) {
					for (var gait:int = 0; gait < 4; gait++) {
						if (!singleColumn) {
							sourceRect.x = mapFacingToRawImageColumn[facing] * Prop.WIDTH;
						}
						if (!singleRow) {
							if (hasGaitRows) {
								sourceRect.y = ((foot + (gait * MOVEMENT_STEP_ROWS)) * Prop.HEIGHT) + paddingAtTop;
							} else {
								sourceRect.y = (foot * Prop.HEIGHT) + paddingAtTop;
							}
						}
						movementBits[facing][foot+(gait*MOVEMENT_STEP_ROWS)].copyPixels(bitmapData, sourceRect, zerozero);
					}
				}
			}
			
			sourceRect.x = DYING_COLUMN * Prop.WIDTH;
			for (var i:int = 0; i < DEATH_ROWS; i++) {
				sourceRect.y = (i * Prop.HEIGHT) + paddingAtTop;
				dyingBits[i].copyPixels(bitmapData, sourceRect, zerozero);
			}
			
			sourceRect.x = HUDDLE_COLUMN * Prop.WIDTH;
			sourceRect.y = paddingAtTop;
			huddleBits.copyPixels(bitmapData, sourceRect, zerozero);
		}
		
		// for use in editor only; this (plus code in editor) is awkward.
		public function increaseTop(additionalTop:int):int {
			paddingAtTop += additionalTop;
			var zerozero:Point = new Point(0, 0);
			var sourceRect:Rectangle = new Rectangle(0, additionalTop, Prop.WIDTH, Prop.HEIGHT - paddingAtTop);
			var clearRect:Rectangle = new Rectangle(0, movementBits[0][0].rect.height - additionalTop, Prop.WIDTH, additionalTop);
			
			// Since this is only used in editor, and editor only displays standard images, don't bother fixing the rest!
			var standardUp:BitmapData = standardImage(true);
			standardUp.copyPixels(standardUp, sourceRect, zerozero);
			standardUp.fillRect(clearRect, 0xffffffff);
			var standardDown:BitmapData = standardImage(false);
			standardDown.copyPixels(standardDown, sourceRect, zerozero);
			standardDown.fillRect(clearRect, 0xffffffff);
			
			return paddingAtTop;
		}
		
		
		
	}

}