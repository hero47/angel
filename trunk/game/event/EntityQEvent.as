package angel.game.event {
	import angel.game.ComplexEntity;
	import angel.game.SimpleEntity;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class EntityQEvent extends QEvent {
		public static const START_TURN:String = "entityStartTurn";
		public static const END_TURN:String = "entityEndTurn";
		public static const MOVED:String = "entityMoved";
		public static const FINISHED_ONE_TILE_OF_MOVE:String = "entityFinishedTile";
		public static const FINISHED_MOVING:String = "entityFinishedMoving";
		public static const MOVE_INTERRUPTED:String = "entityMoveInterrupted"; // sent instead of FINISHED_MOVING if interrupted
		public static const LOCATION_CHANGED_DIRECTLY:String = "entityLocationChanged"; // changed not as part of move
		public static const DEATH:String = "entityDied";
		public static const HEALTH_CHANGE:String = "entityHealthChange";
		public static const ADDED_TO_ROOM:String = "entityAddedToRoom";
		public static const REMOVED_FROM_ROOM:String = "entityRemovedFromRoom";
		public static const JOINED_COMBAT:String = "entityJoinedCombat";
		public static const CHANGED_FACTION:String = "entityChangedFaction";
		public static const BECAME_VISIBLE:String = "entityBecameVisible";
		
		public function EntityQEvent(source:SimpleEntity, eventId:String, param:Object = null) {
			super(source, eventId, param);
		}
		
		public function get complexSource():ComplexEntity {
			return source as ComplexEntity;
		}
		
		public function get simpleSource():SimpleEntity {
			return source as SimpleEntity;
		}
		
	}

}