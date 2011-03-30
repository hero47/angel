package angel.game {
	import angel.common.Assert;
	import angel.common.WalkerImage;
	import flash.display.Bitmap;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.utils.Timer;
	
	public class Walker extends Entity {
		
		private var walkerImage:WalkerImage;
		private var deathTimer:Timer;
		
		private static const DEATH_DURATION:int = 500; // milliseconds
		private static const WALK_FRAMES:Vector.<int> = Vector.<int>([WalkerImage.LEFT, WalkerImage.STAND,
			WalkerImage.RIGHT, WalkerImage.STAND, WalkerImage.LEFT, WalkerImage.STAND, WalkerImage.RIGHT, WalkerImage.STAND]);
		
		// id is for debugging use only
		public function Walker(walkerImage:WalkerImage, id:String="") {
			this.walkerImage = walkerImage;
			facing = WalkerImage.FACE_CAMERA;
			super(new Bitmap(walkerImage.bitsFacing(facing)), id);
			this.health = walkerImage.health;
		}

		override protected function adjustImageForMove():void {
			Assert.assertTrue(health >= 0, "Dead entity " + aaId + " moving");
			stopDying();
			var step:int;
			if (coordsForEachFrameOfMove == null) {
				step = WalkerImage.STAND;
			} else {
				var foot:int = frameOfMove * WALK_FRAMES.length / coordsForEachFrameOfMove.length;
				step = WALK_FRAMES[foot];
			}
			imageBitmap.bitmapData = walkerImage.bitsFacing(facing, step);
		}
		override public function turnToFacing(newFacing:int):void {
			Assert.assertTrue(health >= 0, "Dead entity " + aaId + " turning");
			stopDying();
			super.turnToFacing(newFacing);
			imageBitmap.bitmapData = walkerImage.bitsFacing(facing);
		}
		
		override public function initHealth():void {
			stopDying();
			imageBitmap.bitmapData = walkerImage.bitsFacing(facing); // stand back up if we were dead
			this.health = (isPlayerControlled ? Settings.playerHealth : walkerImage.health);
		}
		
		private function stopDying():void {
			if (deathTimer != null) {
				deathTimer.stop();
			}
		}
		
		// Start death animation unless it's already in progress, in which case just let it continue
		// NOTE: this is a real-time animation; it continues even when game pauses.
		override public function startDeathAnimation():void {
			if (deathTimer == null) {
				imageBitmap.bitmapData = walkerImage.bitsFacing(WalkerImage.FACE_DYING, 0);
				deathTimer = new Timer(DEATH_DURATION / 2, 2);
				deathTimer.addEventListener(TimerEvent.TIMER, advanceDeathAnimation);
				deathTimer.start();
			}
		}
		
		private function advanceDeathAnimation(event:TimerEvent):void {
			imageBitmap.bitmapData = walkerImage.bitsFacing(WalkerImage.FACE_DYING, deathTimer.currentCount);
			if (deathTimer.currentCount == 2) {
				deathTimer.stop();
				deathTimer.removeEventListener(TimerEvent.TIMER, advanceDeathAnimation);
				deathTimer = null;
			}
		}
		
	} // end class Walker

}