package angel.roomedit {
	import angel.common.FloorTile;
	

	public interface IRoomEditorPalette {
		
		function applyToTile(floorTile:FloorTile):void;
		
	}
	
}