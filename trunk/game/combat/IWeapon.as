package angel.game.combat {
	import angel.game.CanBeInInventory;
	import angel.game.ComplexEntity;
	
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public interface IWeapon extends CanBeInInventory {
		
		function attack(user:ComplexEntity, target:Object):void; // target type differs -- either an entity or a location
		
	}
	
}