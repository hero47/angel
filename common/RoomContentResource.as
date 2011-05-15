package angel.common {
	import flash.display.BitmapData;
	import angel.common.CatalogEntry;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class RoomContentResource implements ICatalogedResource {
		
		private static var typeNameToAnimationDataClass:Object = { walker:WalkerAnimationData, prop:SingleImageAnimationData };
		
		private var entry:CatalogEntry;
		public var animationData:IAnimationData;
		public var solidness:uint = Prop.DEFAULT_SOLIDITY;
		public var characterStats:CharacterStats;
		
		public function RoomContentResource() {
			
		}
		
		/* INTERFACE angel.common.ICatalogedResource */
		
		public function get catalogEntry():CatalogEntry {
			return entry;
		}
		
		public function prepareTemporaryVersionForUse(id:String, entry:CatalogEntry):void {
			this.entry = entry;
			var typeName:String = CatalogEntry.xmlTag[entry.type]; //NOTE: this may be replaced by an attribute later
			
			if (animationData == null) { // first time we've been created
				// NOTE: this will be all characters, once that's decoupled from walker-ness
				if (entry.type == CatalogEntry.WALKER) {
					characterStats = new CharacterStats();
					solidness = Prop.DEFAULT_CHARACTER_SOLIDITY; // characters can't change this currently
				} else {
					solidness = Prop.DEFAULT_SOLIDITY;
				}
				
				if (entry.xml != null) { 
					// NOTE: this will be all characters, once that's decoupled from walker-ness
					if (characterStats != null) {
						characterStats.setFromCatalogXml(entry.xml);
					}
					if (String(entry.xml.@solid) != "") {
						solidness = uint(entry.xml.@solid);
					}
					entry.xml = null;
				}
				
				var animationDataClass:Class = typeNameToAnimationDataClass[typeName];
				if (animationDataClass == null) {
					Alert.show("Unknown animation type [" + typeName + "] in catalog for id " + id);
					animationDataClass = SingleImageAnimationData;
				}
				animationData = new animationDataClass();
				
				// CONSIDER: Might extend this to all types later, and make prepareTemporaryVersion into constructor
				if (animationData is WalkerAnimationData) {
					(animationData as WalkerAnimationData).unusedPixelsAtTopOfCell = characterStats.unusedPixelsAtTopOfCell;
				}
				
				animationData.prepareTemporaryVersionForUse(id);
			}
			
		}
		
		public function dataFinishedLoading(bitmapData:BitmapData):void {
			animationData.dataFinishedLoading(bitmapData);
		}
		
		public function standardImage():BitmapData {
			return animationData.standardImage();
		}
		
	}

}