package angel.game.combat {
	import angel.common.WeaponResource;
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
		
	}

}