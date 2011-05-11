package angel.game {
	import angel.common.Alert;
	import angel.common.LoaderWithErrorCatching;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class Flags {
		private static const FLAG_FILENAME:String = "AngelFlags.xml";
		
		//NOTE: Currently flags are boolean, but we may decide later to make them integers
		private static var flags:Object; // mapping from flag to boolean
		
		public static var loader:EventDispatcher = new EventDispatcher;
		
		public function Flags() {
			
		}
		
		public static function loadFlagListFromXmlFile():void {
			LoaderWithErrorCatching.LoadFile(FLAG_FILENAME, flagListXmlLoaded);
		}
		
		private static function flagListXmlLoaded(event:Event, filename:String):void {
			var duplicateNames:String = "";
			flags = new Object();
			var xml:XML = new XML(event.target.data);
			
			for each (var flagXml:XML in xml.flag) {
				var flagId:String = flagXml.@id;
				if (flags[flagId] != null) {
					duplicateNames += flagId + "\n";
				}
				flags[flagId] = false;
			}
			
			if (duplicateNames != "") {
				Alert.show("Warning: Duplicate id(s) in " + FLAG_FILENAME + ":\n" + duplicateNames);
			}
			
			loader.dispatchEvent(new Event(Event.COMPLETE));
		}
		
		public static function initFlagsFromXml(setFlags:XMLList):void {
			var missing:String = "";
			for each (var flagToSet:XML in setFlags) {
				var flagId:String = flagToSet.@id;
				if (flags[flagId] == null) {
					missing += flagId + "\n";
				}
				flags[flagId] = true;
			}
			if (missing != "") {
				Alert.show("Warning: unknown flag(s) in init file:\n" + missing);
			}
		}
		
		public static function setValue(id:String, value:Boolean):void {
			if (flags[id] == null) {
				Alert.show("Warning: unknown flag [" + id + "].");
			}
			flags[id] = value;
		}
		
		public static function getValue(id:String):Boolean {
			if (flags[id] == null) {
				Alert.show("Warning: unknown flag [" + id + "].");
				flags[id] = false;
			}
			return flags[id];
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
		
	} // end class Flags

}