package angel.common {
	import flash.display.Bitmap;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class WalkerAnimation implements IEntityAnimation {
		
		private var imageBitmap:Bitmap;
		private var animationData:WalkerAnimationData;
		private var deathTimer:Timer;
		
		private static const DEATH_DURATION:int = 500; // milliseconds
		private static const WALK_FRAMES:Vector.<int> = Vector.<int>([WalkerAnimationData.LEFT, WalkerAnimationData.STAND,
			WalkerAnimationData.RIGHT, WalkerAnimationData.STAND, WalkerAnimationData.LEFT, WalkerAnimationData.STAND,
			WalkerAnimationData.RIGHT, WalkerAnimationData.STAND]);
		
		public function WalkerAnimation(animationData:IAnimationData, imageBitmap:Bitmap) {
			Assert.assertTrue(animationData is WalkerAnimationData, "Mismatched animation type");
			this.animationData = WalkerAnimationData(animationData);
			this.imageBitmap = imageBitmap;
		}
		
		public function cleanup():void {
			stopDeathAnimation();
		}
		
		public function adjustImageForMove(facing:int, frameOfMove:int, totalFramesInMove:int, gait:int):void {
			stopDeathAnimation();
			var step:int;
			if ((totalFramesInMove == 0) || (frameOfMove >= totalFramesInMove)) {
				step = WalkerAnimationData.STAND;
			} else {
				var foot:int = frameOfMove * WALK_FRAMES.length / totalFramesInMove;
				step = WALK_FRAMES[foot];
			}
			imageBitmap.bitmapData = animationData.bitsFacing(facing, step, gait);
		}
		
		// Facing == rotation/45 if we were in a top-down view, or 8 for dead/down
		public function turnToFacing(newFacing:int, newGait:int):void {
			stopDeathAnimation();
			imageBitmap.bitmapData = animationData.bitsFacing(newFacing,
					(newFacing == WalkerAnimationData.FACE_DYING ? WalkerAnimationData.STEP_DEAD : WalkerAnimationData.STAND),
					newGait);
		}
		
		private function stopDeathAnimation():void {
			if (deathTimer != null) {
				deathTimer.stop();
				deathTimer.removeEventListener(TimerEvent.TIMER, advanceDeathAnimation);
				deathTimer = null;
			}
		}
		
		// Start death animation unless it's already in progress, in which case just let it continue
		// NOTE: this is a real-time animation; it continues even when game pauses.
		public function startDeathAnimation():void {
			if (deathTimer == null) {
				imageBitmap.bitmapData = animationData.bitsFacing(WalkerAnimationData.FACE_DYING, 0);
				deathTimer = new Timer(DEATH_DURATION / 2, 2);
				deathTimer.addEventListener(TimerEvent.TIMER, advanceDeathAnimation);
				deathTimer.start();
			}
		}
		
		private function advanceDeathAnimation(event:TimerEvent):void {
			imageBitmap.bitmapData = animationData.bitsFacing(WalkerAnimationData.FACE_DYING, deathTimer.currentCount);
			if (deathTimer.currentCount == 2) {
				stopDeathAnimation();
			}
		}
		
		public function startHuddleAnimation():void {
			imageBitmap.bitmapData = animationData.bitsFacing(WalkerAnimationData.FACE_HUDDLE);
		}
		
	} // end class Walker

}