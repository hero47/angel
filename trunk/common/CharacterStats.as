package angel.common {
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class CharacterStats {
		public var health:int = Defaults.HEALTH;
		public var damage:int = Defaults.DAMAGE;
		public var movePoints:int = Defaults.MOVE_POINTS;
		public var displayName:String = Defaults.DISPLAY_NAME;
		public var unusedPixelsAtTopOfCell:int = Defaults.TOP;
		
		public function CharacterStats() {
			
		}
		
		public function setFromCatalogXml(xml:XML):void {
			Util.setIntFromXml(this, "health", xml, "health");
			Util.setIntFromXml(this, "damage", xml, "damage");
			Util.setIntFromXml(this, "unusedPixelsAtTopOfCell", xml, "top");
			Util.setIntFromXml(this, "movePoints", xml, "movePoints");
			Util.setTextFromXml(this, "displayName", xml, "displayName");
		}
		
	}

}