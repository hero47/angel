package angel.common {
	import angel.common.CatalogEntry;
	import angel.game.combat.SingleTargetWeapon;
	import angel.game.combat.ThrownWeapon;
	import angel.game.combat.TimeDelayGrenade;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	
	// Currently this is the only type of inventory item we have.
	// Later this may expand into a general class for inventory items, or it may become a subclass of such a class.
	public class WeaponResource extends InventoryResourceBase {
		
		[Embed(source = '../EmbeddedAssets/default_hand.png')]
		public static const DEFAULT_HAND_ICON:Class;
		[Embed(source='../EmbeddedAssets/default_thrown.png')]
		public static const DEFAULT_THROWN_ICON:Class;
		
		private static const typeToClass:Object = { "hand":SingleTargetWeapon, "thrown":ThrownWeapon};
		
		public var type:String;
		public var damage:int = Defaults.GUN_DAMAGE;
		public var range:int = Defaults.WEAPON_RANGE;
		public var cooldown:int = Defaults.WEAPON_COOLDOWN;
		public var ignoreUserGait:Boolean = false;
		public var ignoreTargetGait:Boolean = false;
		public var delay:int = 0;
		public var view:Boolean = false;
		
		public static const TAG:String = "weapon";
		
		public function WeaponResource() {
			super();
		}
		
		override public function prepareTemporaryVersionForUse(id:String, entry:CatalogEntry, errors:MessageCollector):void {
			displayName = Defaults.GUN_DISPLAY_NAME;
			super.prepareTemporaryVersionForUse(id, entry, errors);
			
			if (entry.xml != null) {
				type = entry.xml.@type;
			}
			if (Util.nullOrEmpty(type)) {
				type = Defaults.WEAPON_TYPE;
			}
			itemClass = typeToClass[type];
			if (itemClass == null) {
				MessageCollector.collectOrShowMessage(errors, "Unknown weapon type " + type);
				itemClass = SingleTargetWeapon;
			}
			 
			Util.setIntFromXml(this, "damage", entry.xml, "damage");
			Util.setIntFromXml(this, "range", entry.xml, "range");
			Util.setIntFromXml(this, "cooldown", entry.xml, "cooldown");
			Util.setBoolFromXml(this, "ignoreUserGait", entry.xml, "ignoreUserGait");
			Util.setBoolFromXml(this, "ignoreTargetGait", entry.xml, "ignoreTargetGait");
			Util.setIntFromXml(this, "delay", entry.xml, "delay");
			Util.setBoolFromXml(this, "view", entry.xml, "view");
			entry.xml = null;
			
			if ((itemClass == ThrownWeapon) && (delay > 0)) {
				itemClass = TimeDelayGrenade;
			}
			
			iconBitmapData = defaultBitmapData(type == "hand" ? DEFAULT_HAND_ICON : DEFAULT_THROWN_ICON);
		}
		
	}

}