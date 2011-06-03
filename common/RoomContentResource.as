package angel.common {
	import flash.display.BitmapData;
	import angel.common.CatalogEntry;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class RoomContentResource implements ICatalogedResource {
		
		private static var animationNameToDataClass:Object = {
				prop:SingleImageAnimationData,
				single:SingleImageAnimationData,
				spinner:SpinnerAnimationData,
				walker:WalkerAnimationData,
				unknown:UnknownAnimationData // temporary, when new character being created in editor
		};
		
		private var entry:CatalogEntry;
		public var animationData:IAnimationData;
		public var solidness:uint = Prop.DEFAULT_SOLIDITY;
		public var unusedPixelsAtTopOfCell:int = 0;
		public var characterStats:CharacterStats;
		
		public function RoomContentResource() {
			
		}
		
		/* INTERFACE angel.common.ICatalogedResource */
		
		public function get catalogEntry():CatalogEntry {
			return entry;
		}
		
		public function prepareTemporaryVersionForUse(id:String, entry:CatalogEntry):void {
			this.entry = entry;
			
			if (animationData == null) { // first time we've been created
				if (entry.type == CatalogEntry.CHARACTER) {
					characterStats = new CharacterStats();
					characterStats.setFromCatalogXml(entry.xml);
					solidness = Prop.DEFAULT_CHARACTER_SOLIDITY; // characters can't change this currently
				} else {
					solidness = Prop.DEFAULT_SOLIDITY;
				}
				
				Util.setUintFromXml(this, "solidness", entry.xml, "solid");
				Util.setIntFromXml(this, "unusedPixelsAtTopOfCell", entry.xml, "top");
				
				var animationName:String = (entry.xml == null ? "" : entry.xml.@animate);
				
				//UNDONE For backwards compatibility; remove this once old catalogs have been rewritten
				if ((entry.xml != null) && (entry.xml.name() == "walker")) {
					animationName = "walker";
				}
				
				entry.xml = null;
				
				var animationDataClass:Class;
				if (animationName != "") {
					animationDataClass = animationNameToDataClass[animationName];
					if (animationDataClass == null) {
						Alert.show("Unknown animation type [" + animationName + "] in catalog for id " + id);
					}
				}
				if (animationDataClass == null) {
					animationDataClass = SingleImageAnimationData;
				}
				
				animationData = new animationDataClass(id, unusedPixelsAtTopOfCell);
				
			}
			
		}
		
		public function dataFinishedLoading(bitmapData:BitmapData):void {
			animationData.dataFinishedLoading(bitmapData, entry);
		}
		
		public function standardImage():BitmapData {
			return animationData.standardImage();
		}
		
	}

}