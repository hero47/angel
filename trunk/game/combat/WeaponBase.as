package angel.game.combat {
	import angel.common.WeaponResource;
	import angel.game.inventory.CanBeInInventory;
	import angel.game.Settings;
	import flash.display.BitmapData;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class WeaponBase extends CombatUsableBase {
		public var baseDamage:int;
		
		public function WeaponBase(resource:WeaponResource, id:String){
			super(resource, id);
			this.baseDamage = resource.damage;
		}
		
	}

}