package angel.game {
	import flash.events.Event;
	
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class EntityEvent extends Event {
		public static const MOVED:String = "entityMoved";
		public static const FINISHED_ONE_TILE_OF_MOVE:String = "entityFinishedTile";
		public static const FINISHED_MOVING:String = "entityFinishedMoving";
		public static const START_TURN:String = "entityStartTurn";
		public static const DEATH:String = "entityDied";
		
		public var entity:SimpleEntity;
		
		public function EntityEvent(type:String,
									bubbles:Boolean = false,
									cancelable:Boolean = false,
									entity:SimpleEntity = null
									) { 
			super(type, bubbles, cancelable);
			this.entity = entity;
		} 
		
		public override function clone():Event {
			return new EntityEvent(type, bubbles, cancelable, entity);
		} 
		
		public override function toString():String { 
			return formatToString("EntityEvent", "type", "bubbles", "cancelable", "eventPhase", "entity"); 
		}
		
	}
	
}

