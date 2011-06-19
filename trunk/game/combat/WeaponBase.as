package angel.game.combat {
	import angel.common.WeaponResource;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class WeaponBase {
		protected var myId:String;
		public var name:String;
		public var baseDamage:int;
		
		public function WeaponBase(resource:WeaponResource, id:String) {
			this.myId = id;
			this.baseDamage = resource.damage;
			this.name = resource.displayName;
			
		}
		
		public function get id():String {
			return myId;
		}
		
		public function get displayName():String {
			return name;
		}
		
	}

}