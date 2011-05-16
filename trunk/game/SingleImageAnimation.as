package angel.game {
	import angel.common.Assert;
	import angel.common.IAnimationData;
	import angel.common.Prop;
	import angel.common.RoomContentResource;
	import angel.common.SingleImageAnimationData;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.text.TextField;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	
	// The simple case, a one-frame non-animated entity. Does nothing in response to all calls!
	// CONSIDER: do an explosion for death animation.
	public class SingleImageAnimation implements IEntityAnimation {
		
		private var me:SimpleEntity;
		
		public function SingleImageAnimation(animationData:IAnimationData, imageBitmap:Bitmap) {
			Assert.assertTrue(animationData is SingleImageAnimationData, "Mismatched animation type");
		}
		
		public function cleanup():void {
			
		}
		
		public function adjustImageForMove(facing:int, frameOfMove:int, totalFramesInMove:int):void {
			
		}
		
		public function turnToFacing(newFacing:int):void {
			
		}
		
		public function startDeathAnimation():void {
			
		}
		
	}

}