package angel.game {
	import angel.common.ICleanup;
	import flash.geom.Point;
	
	public interface IRoomMode extends ICleanup {
	
		function activePlayer():ComplexEntity;
		
		//NOTE: addEntity and removeEntity affect only the mode; these are called as a part of adding/removing from the room.
		function entityAddedToRoom(entity:SimpleEntity):void; // Add an entity to an already-initialized mode
		function entityWillBeRemovedFromRoom(entity:SimpleEntity):void;
		
		function playerControlChanged(entity:ComplexEntity, pc:Boolean):void;
		
	}
	
	
}