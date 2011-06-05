package angel.game.combat {
	import angel.game.ComplexEntity;
	import angel.game.inventory.CanBeInInventory;
	
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public interface IWeapon extends CanBeInInventory {
		
		function attack(user:ComplexEntity, target:Object):void; // target type differs -- either an entity or a location
		
	}
	
}