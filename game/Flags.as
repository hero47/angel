package angel.game {
	import angel.common.Alert;
	import angel.common.CatalogEntry;
	import angel.common.LoaderWithErrorCatching;
	import angel.common.Util;
	import angel.game.event.QEvent;
	import flash.events.Event;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	
	// A flag id can be a simple id, or flagId@catalogId.  (For now, we will store them all in a single hashtable, but
	// we could switch to a two-level lookup.)  When used in scripts, catalogId can also be a special scriptId, for
	// example myFlag@*me would be translated to myFlag@foo if found in a script on entity with id foo.
	public class Flags {
		private static const FLAG_FILENAME:String = "AngelFlags.xml";
		
		//NOTE: Currently flags are boolean, but we may decide later to make them integers
		private static var flags:Object = new Object(); // mapping from flag to boolean
		
		public function Flags() {
			
		}
		
		public static function initFlagsFromXml(setFlags:XMLList):void {
			for each (var flagToSet:XML in setFlags) {
				flags[String(flagToSet.@id)] = true;
			}
		}
		
		private static function isValidFlagId(id:String):Boolean {
			if ((id == null) || (id == "")) {
				Alert.show("Error: empty flag id");
				return false;
			}
			var at:int = id.indexOf("@");
			if (at >= 0) {
				var catalogId:String = id.substr(at + 1);
				var entry:CatalogEntry = Settings.catalog.entry(catalogId);
				if (entry == null) {
					Alert.show("Error: no catalog entry " + catalogId + " for flag " + id);
				}
			}
			return true;
		}
		
		public static function setValue(id:String, value:Boolean):void {
			if (isValidFlagId(id)) {
				flags[id] = value;
			}
		}
		
		public static function getValue(id:String):Boolean {
			if (isValidFlagId(id)) {
				return flags[id];
			} else {
				return false;
			}
		}
		
		public static function haveAllFlagsIn(list:Vector.<String>):Boolean {
			if (list == null) {
				return true;
			}
			for (var i:int = 0; i < list.length; ++i) {
				if (!getValue(list[i])) {
					return false;
				}
			}
			return true;
		}
		
		public static function toText():String {
			var text:String = "";
			for (var flagId:String in flags) {
				if (getValue(flagId)) {
					text += flagId + ",";
				}
			}
			return text.substr(0, text.length-1); // eliminate extra comma
		}
		
		public static function setFlagsFromText(text:String):void {
			var flagId:String;
			for (flagId in flags) {
				setValue(flagId, false);
			}
			
			if (Util.nullOrEmpty(text)) {
				return;
			}
			var flagList:Array = text.split(",");
			for each (flagId in flagList) {
				setValue(flagId, true);
			}
		}
		
	} // end class Flags

}