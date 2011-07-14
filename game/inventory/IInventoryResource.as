package angel.game.inventory {
	import angel.common.ICatalogedResource;
	
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public interface IInventoryResource extends ICatalogedResource {
		function makeOne():CanBeInInventory;
	}
	
}