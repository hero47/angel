package angel.game {
	import flash.geom.Point;
	
	public interface RoomMode {
	
		function cleanup():void;
		
		//NOTE: addEntity and removeEntity affect only the mode; these are called as a part of adding/removing from the room.
		function addEntity(entity:SimpleEntity):void; // Add an entity to an already-initialized mode
		function removeEntity(entity:SimpleEntity):void;
		
		function changePlayerControl(entity:ComplexEntity, pc:Boolean):void;
		
	}
	
	
}