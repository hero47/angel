package angel.game {
	import flash.geom.Point;
	
	public interface RoomMode {
	
		function cleanup():void;
		function addEntity(entity:SimpleEntity):void;
		function removeEntity(entity:SimpleEntity):void;
		
	}
	
	
}