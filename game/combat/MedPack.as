package angel.game.combat {
	import angel.common.GizmoResource;
	import angel.common.WeaponResource;
	import angel.game.ComplexEntity;
	import angel.game.inventory.CanBeInInventory;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class MedPack extends CombatUsableBase implements ICombatUseFromPile {
		
		private var value:int;
		
		public function MedPack(resource:GizmoResource, id:String) {
			super(resource, id);
			value = resource.value;
		}
		
		public function stacksWith(other:CanBeInInventory):Boolean {
			var otherPack:MedPack = other as MedPack;
			return ((otherPack != null) && (otherPack.id == myId));
		}
		
		public function useOn(user:ComplexEntity, target:Object):void {
			user.actionsRemaining -= 2;
			user.inventory.removeFromPileOfStuff(this, 1);
			user.takeDamage( -value, false);
		}
		
		
	}

}