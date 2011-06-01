package angel.common {
	import angel.game.Settings;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	
	//NOTE: Currently (May 2011) this contains both character stats and values used to initialize character's inventory.
	//The inventory parts may be separated out once inventory becomes better developed.
	public class CharacterStats {
		public var health:int = Defaults.CHARACTER_HEALTH;
		public var movePoints:int = Defaults.MOVE_POINTS;
		public var displayName:String = Defaults.CHARACTER_DISPLAY_NAME;
		public var maxGait:int = Defaults.MAX_GAIT;
		
		// inventory initializers
		public var mainGun:String = Defaults.MAIN_WEAPON_ID;
		public var grenades:int = Defaults.GRENADES;
		
		public function CharacterStats() {
			
		}
		
		public function setFromCatalogXml(xml:XML):void {
			Util.setIntFromXml(this, "health", xml, "health");
			Util.setTextFromXml(this, "mainGun", xml, "mainGun");
			Util.setIntFromXml(this, "movePoints", xml, "movePoints");
			Util.setTextFromXml(this, "displayName", xml, "displayName");
			Util.setIntFromXml(this, "maxGait", xml, "maxGait");
			Util.setIntFromXml(this, "grenades", xml, "grenades");
		}
		
	}

}