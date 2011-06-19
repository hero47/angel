package angel.game.inventory {
	import angel.common.ICatalogedResource;
	import angel.game.combat.IWeapon;
	
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public interface IInventoryResource extends ICatalogedResource {
		function makeOne():IWeapon;
	}
	
}