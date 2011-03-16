package angel.game {
	import angel.common.WalkerImage;
	import flash.display.Bitmap;
	import flash.geom.Point;
	
	public class Walker extends Entity {
		
		private var images:WalkerImage;
		private static const walkFrames:Vector.<int> = Vector.<int>([WalkerImage.LEFT, WalkerImage.STAND,
			WalkerImage.RIGHT, WalkerImage.STAND, WalkerImage.LEFT, WalkerImage.STAND, WalkerImage.RIGHT, WalkerImage.STAND]);
		
		public function Walker(images:WalkerImage) {
			this.images = images;
			facing = 1;
			super(new Bitmap(images.bitsFacing(1)));
		}

		override protected function adjustImage():void {
			var foot:int = frameOfMove * walkFrames.length / coordsForEachFrameOfMove.length;
			imageBitmap.bitmapData = images.bitsFacing(facing, walkFrames[foot]);
		}
		
		
	}

}