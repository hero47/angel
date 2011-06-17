package angel.common {
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	
	// Spinner image file has one row of images, containing eight facings (first column facing camera, rotating 45 degrees
	// counterclockwise each image) plus a "dead" image
	public class SpinnerAnimationData implements IAnimationData {
		
		private var paddingAtTop:int = Defaults.TOP;
		
		//mapping from facing to position on image sheet
		//(facing 8 == DYING holds the death images)
		private static const imageColumn:Vector.<int> = Vector.<int>([1, 0, 7, 6, 5, 4, 3, 2, 8]);
		public static const FACE_DYING:int = 8;
		
		private var bits:Vector.<BitmapData>;
		
		public function SpinnerAnimationData(labelForTemporaryVersion:String, unusedPixelsAtTopOfCell:int) {
			paddingAtTop = unusedPixelsAtTopOfCell;
			prepareTemporaryVersionForUse(labelForTemporaryVersion);
		}
		
		/* INTERFACE angel.common.IAnimationData */
		
		public function get animationClass():Class {
			return SpinnerAnimation;
		}
		
		private function prepareTemporaryVersionForUse(labelForTemporaryVersion:String):void {
			// Prepare temporary version for use until bitmap data is loaded from file
			bits = new Vector.<BitmapData>(9);
			for (var i:int = 0; i < 9; i++) {
				var imageData:BitmapData = new BitmapData(Prop.WIDTH, Prop.HEIGHT - paddingAtTop, true, 0xffff00ff);
				var label:TextField = new TextField();
				label.text = labelForTemporaryVersion;
				label.y = Prop.HEIGHT / 2;
				imageData.draw(label);
				bits[i] = imageData;
			}
		}
		
		public function dataFinishedLoading(bitmapData:BitmapData, entry:CatalogEntry):void {
			if ((bitmapData.width != Prop.WIDTH * 9) || (bitmapData.height != Prop.HEIGHT)) {
				Alert.show("Warning: expected " + entry.filename + " to be a spinner animation, but image size is wrong.");
			}
			// If image file is an odd size, try to do something reasonable with it.
			var useFullWidth:Boolean = (bitmapData.width > Prop.WIDTH);
			
			var zerozero:Point = new Point(0, 0);
			var sourceRect:Rectangle = new Rectangle(0, paddingAtTop, Prop.WIDTH, Prop.HEIGHT - paddingAtTop);
			for (var facing:int = 0; facing < 9; facing++) {
				if (useFullWidth) {
					sourceRect.x = imageColumn[facing] * Prop.WIDTH;
				}
				bits[facing].fillRect(bits[facing].rect, 0); // is this needed?
				bits[facing].copyPixels(bitmapData, sourceRect, zerozero);	
			}
			bitmapData.dispose();
		}
		
		public function standardImage(down:Boolean = false):BitmapData {
			return bitsFacing(down ? FACE_DYING : 1);
		}
		
		// Facing == rotation/45 if we were in a top-down view, or 8 for dead/down.
		public function bitsFacing(facing:int):BitmapData {
			return bits[facing];
		}
		
		// for use in editor only; this (plus code in editor) is awkward.
		public function increaseTop(additionalTop:int):int {
			paddingAtTop += additionalTop;
			/*
			var zerozero:Point = new Point(0, 0);
			var sourceRect:Rectangle = new Rectangle(0, additionalTop, Prop.WIDTH, Prop.HEIGHT - paddingAtTop);
			var clearRect:Rectangle = new Rectangle(0, bits[0][0].rect.height - additionalTop, Prop.WIDTH, additionalTop);
			for (var facing:int = 0; facing < 9; facing++) {
				for (var foot:int = 0; foot < 3; foot++) {
					bits[facing][foot].copyPixels(bits[facing][foot], sourceRect, zerozero);
					bits[facing][foot].fillRect(clearRect, 0xffffffff);
				}
			}
			*/
			return paddingAtTop;
		}
		
	}

}