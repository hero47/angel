package angel.game {
	import flash.geom.Point;
	
	public interface RoomMode {
	
		function cleanup():void;
		function playerMoved(newLocation:Point):void; // called with null when move finishes
		
	}
	
	
}