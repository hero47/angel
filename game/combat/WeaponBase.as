package angel.game.combat {
	import angel.common.WeaponResource;
	import angel.game.inventory.CanBeInInventory;
	import angel.game.Settings;
	import flash.display.BitmapData;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class WeaponBase {
		protected var myId:String;
		public var name:String;
		public var baseDamage:int;
		private var iconBitmapData:BitmapData;
		
		public function WeaponBase(resource:WeaponResource, id:String) {
			this.myId = id;
			this.baseDamage = resource.damage;
			this.name = resource.displayName;
			this.iconBitmapData = resource.iconBitmapData;
		}
		
		public function get id():String {
			return myId;
		}
		
		public function get displayName():String {
			return name;
		}
		
		public function get iconData():BitmapData {
			return iconBitmapData;
		}
		
		public function clone():CanBeInInventory {
			var resource:WeaponResource = Settings.catalog.retrieveWeaponResource(id);
			var copy:CanBeInInventory = new resource.weaponClass(resource, id);
			return copy;
		}
		
		public function copyBaseTo(copy:WeaponBase):void {
			copy.myId = this.myId;
			copy.baseDamage = this.baseDamage;
			copy.name = this.name;
			copy.iconBitmapData = this.iconBitmapData;
		}
		
	}

}