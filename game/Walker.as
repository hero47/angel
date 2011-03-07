package angel.game {
	import flash.display.Bitmap;
	import flash.geom.Point;
	
	public class Walker extends Entity {
		
		private var images:WalkerImage;
		private static const walkFrames:Vector.<int> = Vector.<int>([WalkerImage.LEFT, WalkerImage.STAND,
			WalkerImage.RIGHT, WalkerImage.STAND, WalkerImage.LEFT, WalkerImage.STAND, WalkerImage.RIGHT, WalkerImage.STAND]);
		
		public function Walker(images:WalkerImage) {
			this.images = images;
			facing = 2;
			super(new Bitmap(images.bitsFacing(2)));
		}

		override protected function adjustImage():void {
			var foot:int = frameOfMove * walkFrames.length / coordsForEachFrameOfMove.length;
			(getChildAt(0) as Bitmap).bitmapData = images.bitsFacing(facing, walkFrames[foot]);
		}
		
		
	}

}