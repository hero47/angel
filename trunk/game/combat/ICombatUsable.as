package angel.game.combat {
	import angel.game.ComplexEntity;
	import angel.game.inventory.CanBeInInventory;
	
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public interface ICombatUsable extends CanBeInInventory {
		
		function useOn(user:ComplexEntity, target:Object):void; // target type differs -- either an entity or a location
		
	}
	
}