package angel.common {
	import flash.display.BitmapData;
	import angel.common.MessageCollector;
	import angel.common.CatalogEntry;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class CharResource extends RoomContentResource {
		
		private static var animationNameToDataClass:Object = {
				prop:SingleImageAnimationData,
				single:SingleImageAnimationData,
				spinner:SpinnerAnimationData,
				walker:WalkerAnimationData,
				unknown:UnknownAnimationData // temporary, when new character being created in editor
		};
		
		public static const TAG:String = "char";
		
		public var characterStats:CharacterStats;
		
		public function CharResource() {
			
		}
		
		/* INTERFACE angel.common.ICatalogedResource */
		
		override public function prepareTemporaryVersionForUse(id:String, entry:CatalogEntry, errors:MessageCollector):void {
			var xml:XML = entry.xml;
			super.prepareTemporaryVersionForUse(id, entry, errors);
			
			if (animationData == null) { // first time we've been created
				characterStats = new CharacterStats();
				characterStats.setFromCatalogXml(xml);
				solidness = Prop.DEFAULT_CHARACTER_SOLIDITY; // characters can't change this currently
				
				var animationName:String = (xml == null ? "" : xml.@animate);
				
				//UNDONE For backwards compatibility; remove this once old catalogs have been rewritten
				if ((xml != null) && (xml.name() == "walker")) {
					animationName = "walker";
				}
				
				var animationDataClass:Class;
				if (animationName != "") {
					animationDataClass = animationNameToDataClass[animationName];
					if (animationDataClass == null) {
						MessageCollector.collectOrShowMessage(errors, "Unknown animation type [" + animationName + "] in catalog for id " + id);
					}
				}
				if (animationDataClass == null) {
					animationDataClass = SingleImageAnimationData;
				}
				
				animationData = new animationDataClass(id, unusedPixelsAtTopOfCell);
				
			}
			
		}
		
	}

}