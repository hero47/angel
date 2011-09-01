package angel.common {
	
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public interface IEntityAnimation {
		
		function cleanup():void;
		function adjustImageForMove(facing:int, frameOfMove:int, totalFramesInMove:int, gait:int):void;
		function turnToFacing(newFacing:int, newGait:int):void;
		function startDeathAnimation():void;
		function startHuddleAnimation():void;
	}
	
}