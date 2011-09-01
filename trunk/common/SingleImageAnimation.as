package angel.common {
	import angel.game.SimpleEntity;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.text.TextField;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	
	// The simple case, a one-frame non-animated entity. Does nothing in response to all calls!
	// CONSIDER: do an explosion for death animation.  Actually, that might be better as a character property that can
	// be applied on top of any animation.
	public class SingleImageAnimation implements IEntityAnimation {
		
		private var me:SimpleEntity;
		
		public function SingleImageAnimation(animationData:IAnimationData, imageBitmap:Bitmap) {
			Assert.assertTrue(animationData is SingleImageAnimationData, "Mismatched animation type");
		}
		
		public function cleanup():void {
			
		}
		
		public function adjustImageForMove(facing:int, frameOfMove:int, totalFramesInMove:int, gait:int):void {
			
		}
		
		public function turnToFacing(newFacing:int, newGait:int):void {
			
		}
		
		public function startDeathAnimation():void {
			
		}
		
		public function startHuddleAnimation():void {
			
		}
		
	}

}