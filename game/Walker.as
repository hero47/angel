package angel.game {
	import angel.common.WalkerImage;
	import flash.display.Bitmap;
	import flash.geom.Point;
	
	public class Walker extends Entity {
		
		private var walkerImage:WalkerImage;
		private static const walkFrames:Vector.<int> = Vector.<int>([WalkerImage.LEFT, WalkerImage.STAND,
			WalkerImage.RIGHT, WalkerImage.STAND, WalkerImage.LEFT, WalkerImage.STAND, WalkerImage.RIGHT, WalkerImage.STAND]);
		
		// id is for debugging use only
		public function Walker(walkerImage:WalkerImage, id:String="") {
			this.walkerImage = walkerImage;
			facing = WalkerImage.FACE_CAMERA;
			super(new Bitmap(walkerImage.bitsFacing(facing)), id);
			this.health = walkerImage.health;
		}

		override protected function adjustImageForMove():void {
			var step:int;
			if (coordsForEachFrameOfMove == null) {
				step = WalkerImage.STAND;
			} else {
				var foot:int = frameOfMove * walkFrames.length / coordsForEachFrameOfMove.length;
				step = walkFrames[foot];
			}
			imageBitmap.bitmapData = walkerImage.bitsFacing(facing, step);
		}
		
		override public function turnToFacing(newFacing:int):void {
			super.turnToFacing(newFacing);
			imageBitmap.bitmapData = walkerImage.bitsFacing(facing);
		}
		
	}

}