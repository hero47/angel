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
			facing = Entity.FACE_CAMERA;
			super(new Bitmap(images.bitsFacing(facing)));
		}

		override protected function adjustImageForMove():void {
			var step:int;
			if (coordsForEachFrameOfMove == null) {
				step = WalkerImage.STAND;
			} else {
				var foot:int = frameOfMove * walkFrames.length / coordsForEachFrameOfMove.length;
				step = walkFrames[foot];
			}
			imageBitmap.bitmapData = images.bitsFacing(facing, step);
		}
		
		override public function turnToFacing(newFacing:int):void {
			super.turnToFacing(newFacing);
			imageBitmap.bitmapData = images.bitsFacing(facing);
		}
		
	}

}