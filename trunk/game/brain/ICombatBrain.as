package angel.game.brain {
	
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public interface ICombatBrain extends IBrain {
		function chooseMoveAndDrawDots():void;
		function doMove():void;
		function doFire():void;
	}
	
}