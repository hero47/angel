package angel.common {
	import angel.game.combat.IWeapon;
	import angel.game.combat.SingleTargetWeapon;
	import angel.game.combat.ThrownWeapon;
	import angel.game.combat.TimeDelayGrenade;
	import angel.game.Icon;
	import angel.game.inventory.IInventoryResource;
	import angel.game.Settings;
	import flash.display.BitmapData;
	import angel.common.CatalogEntry;
	import flash.geom.Point;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	
	// Currently this is the only type of inventory item we have.
	// Later this may expand into a general class for inventory items, or it may become a subclass of such a class.
	public class WeaponResource extends ImageResourceBase implements IInventoryResource {		
		
		[Embed(source = '../EmbeddedAssets/default_hand.png')]
		public static const DEFAULT_HAND_ICON:Class;
		[Embed(source='../EmbeddedAssets/default_thrown.png')]
		public static const DEFAULT_THROWN_ICON:Class;
		
		private static const typeToClass:Object = { "hand":SingleTargetWeapon, "thrown":ThrownWeapon };
		
		public var id:String;
		public var type:String;
		public var weaponClass:Class;
		public var displayName:String = Defaults.GUN_DISPLAY_NAME;
		public var damage:int = Defaults.GUN_DAMAGE;
		public var range:int = Defaults.WEAPON_RANGE;
		public var cooldown:int = Defaults.WEAPON_COOLDOWN;
		public var ignoreUserGait:Boolean = false;
		public var ignoreTargetGait:Boolean = false;
		public var delay:int = 0;
		
		public var iconBitmapData:BitmapData;
		
		public static const TAG:String = "weapon";
		
		public function WeaponResource() {
			
		}
		
		override protected function expectedBitmapSize():Point {
			return Icon.ICON_SIZED_POINT;
		}
		
		override public function prepareTemporaryVersionForUse(id:String, entry:CatalogEntry, errors:MessageCollector):void {
			super.prepareTemporaryVersionForUse(id, entry, errors);
			
			// We don't have graphics for weapons yet, so this is the only version there is
			this.id = id;
			if (entry.xml != null) {
				type = entry.xml.@type;
			}
			if (Util.nullOrEmpty(type)) {
				type = Defaults.WEAPON_TYPE;
			}
			weaponClass = typeToClass[type];
			if (weaponClass == null) {
				MessageCollector.collectOrShowMessage(errors, "Unknown weapon type " + type);
				weaponClass = SingleTargetWeapon;
			}
			
			Util.setTextFromXml(this, "displayName", entry.xml, "displayName");
			Util.setIntFromXml(this, "damage", entry.xml, "damage");
			Util.setIntFromXml(this, "range", entry.xml, "range");
			Util.setIntFromXml(this, "cooldown", entry.xml, "cooldown");
			Util.setBoolFromXml(this, "ignoreUserGait", entry.xml, "ignoreUserGait");
			Util.setBoolFromXml(this, "ignoreTargetGait", entry.xml, "ignoreTargetGait");
			Util.setIntFromXml(this, "delay", entry.xml, "delay");
			entry.xml = null;
			
			if ((weaponClass == ThrownWeapon) && (delay > 0)) {
				weaponClass = TimeDelayGrenade;
			}
			
			iconBitmapData = defaultBitmapData();
		}
		
		private function defaultBitmapData():BitmapData {
			var bitmapData:BitmapData = new BitmapData(Icon.STANDARD_ICON_SIZE, Icon.STANDARD_ICON_SIZE);
			Icon.copyIconData(type == "hand" ? DEFAULT_HAND_ICON : DEFAULT_THROWN_ICON, bitmapData);
			return bitmapData;
		}
		
		public function dataFinishedLoading(bitmapData:BitmapData, param:Object = null):void {
			iconBitmapData.copyPixels(bitmapData, Icon.ICON_SIZED_RECTANGLE, Icon.ZEROZERO);
		}
		
		public function makeOne():IWeapon {
			return new weaponClass(this, id);
		}
		
	}

}