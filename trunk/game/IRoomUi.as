package angel.game {
	import angel.common.FloorTile;
	
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public interface IRoomUi {
		
		// listeners from IUi are enabled/disabled by caller; this enable/disable are just for the extra
		// bits unique to this particular UI
		function enable():void;
		function disable():void;
		
		// Generic keys are handled by caller; this is just for the ones unique to this mode
		function keyDown(keyCode:uint):void;
		
		// x & y in local coordinates, in case we're faking a cursor
		function mouseMove(x:int, y:int, tile:FloorTile):void;
		
		function mouseClick(tile:FloorTile):void;
		
		// Return null if no pie menu should be displayed for a right-click on this tile
		function pieMenuForTile(tile:FloorTile):Vector.<PieSlice>;
		
	}
	
}