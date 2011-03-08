package angel.game {
	import angel.common.Prop;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	
	public class WalkerImage {
		public static const STAND:int = 0;
		public static const RIGHT:int = 1;
		public static const LEFT:int = 2;
		
		//mapping from facing (rotation/45 if we were in a top-down view) to position on image sheet
		//(facing 8 == 360 degrees hold the attacking/death images)
		private static const imageColumn:Vector.<int> = Vector.<int>([1, 0, 7, 6, 5, 4, 3, 2, 8]);
		
		private var bits:Vector.<Vector.<BitmapData>>;
		
		public function WalkerImage(groupBitmapData:BitmapData) {
			var image:BitmapData;
			var onlyOneImage:Boolean = false;
			
			// If we were given a single image instead of a pane of images, stash it into all our references so we
			// at least show something meaningful
			if (groupBitmapData.height == Prop.HEIGHT && groupBitmapData.width == Prop.WIDTH) {
				onlyOneImage = true;
				image = groupBitmapData;
			}
			var zerozero:Point = new Point(0, 0);
			bits = new Vector.<Vector.<BitmapData>>(9);
			bits.fixed = true;
			for (var facing:int = 0; facing < 9; facing++) {
				bits[facing] = new Vector.<BitmapData>(3);
				bits[facing].fixed = true;
				for (var j:int = 0; j < 3; j++) {
					if (!onlyOneImage) {
						image = new BitmapData(Prop.WIDTH, Prop.HEIGHT);
						image.copyPixels(groupBitmapData,
								new Rectangle(imageColumn[facing] * Prop.WIDTH, j * Prop.HEIGHT, Prop.WIDTH, Prop.HEIGHT),
								zerozero);
					}
					bits[facing][j] = image;
				}
			}
		}
		
		// Facing == rotation/45 if we were in a top-down view.
		public function bitsFacing(facing:int, step:int=0):BitmapData {
			return bits[facing][step];
		}
		
		
	}

}