package angel.game {
	import flash.display.Sprite;
	import flash.events.Event;
	
	/**
	 * ...
	 * @author Beth Moursund
	 */
	
	// Sprite that removes itself a set number of frames after being added to stage
	public class TimedSprite extends Sprite {
		
		private var lifetime:int;
		private var framesRemaining:int;
		
		public function TimedSprite(frames:int) {
			lifetime = frames;
			addEventListener(Event.ADDED_TO_STAGE, addedToStageListener);
		}
		
		private function addedToStageListener(event:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, addedToStageListener);
			framesRemaining = lifetime;
			addEventListener(Event.ENTER_FRAME, enterFrameListener);
		}
		
		private function enterFrameListener(event:Event):void {
			alpha = (framesRemaining / lifetime);
			if (framesRemaining-- == 0) {
				parent.removeChild(this);
				removeEventListener(Event.ENTER_FRAME, enterFrameListener);
			}
		}
		
	}

}