package angel.common {
	import flash.display.Bitmap;
	import flash.utils.Timer;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	
	// CONSIDER: do an explosion for death animation.  Actually, that might be better as a character property that can
	// be applied on top of any animation.
	public class SpinnerAnimation implements IEntityAnimation {
		
		private var imageBitmap:Bitmap;
		private var animationData:SpinnerAnimationData;
		//private var deathTimer:Timer;
		
		public function SpinnerAnimation(animationData:IAnimationData, imageBitmap:Bitmap) {
			Assert.assertTrue(animationData is SpinnerAnimationData, "Mismatched animation type");
			this.animationData = SpinnerAnimationData(animationData);
			this.imageBitmap = imageBitmap;
		}
		
		/* INTERFACE angel.game.IEntityAnimation */
		
		public function cleanup():void {
			
		}
		
		public function adjustImageForMove(facing:int, frameOfMove:int, totalFramesInMove:int):void {
			turnToFacing(facing);
		}
		
		public function turnToFacing(newFacing:int):void {
			imageBitmap.bitmapData = animationData.bitsFacing(newFacing);
		}
		
		public function startDeathAnimation():void {
			imageBitmap.bitmapData = animationData.bitsFacing(SpinnerAnimationData.FACE_DYING);
		}
		
	}

}