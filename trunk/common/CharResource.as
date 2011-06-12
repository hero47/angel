package angel.common {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import angel.common.MessageCollector;
	import angel.common.CatalogEntry;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class CharResource extends RoomContentResource {
		
		private static const animationNameToDataClass:Object = {
				prop:SingleImageAnimationData,
				single:SingleImageAnimationData,
				spinner:SpinnerAnimationData,
				walker:WalkerAnimationData,
				unknown:UnknownAnimationData // temporary, when new character being created in editor
		};
		
		private static const MAX_PORTRAIT_WIDTH:int = 329;
		private static const MAX_PORTRAIT_HEIGHT:int = 276;
		
		public var characterStats:CharacterStats;
		private var portraitDone:Boolean = false;
		private var portraitData:BitmapData = null;
		
		public static const TAG:String = "char";
		
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
		
		private function prepareTemporaryPortraitForUse():void {
			if (!Util.nullOrEmpty(characterStats.portraitFile)) {
				portraitData = new BitmapData(MAX_PORTRAIT_WIDTH, MAX_PORTRAIT_HEIGHT, true, 0x00000000);
				LoaderWithErrorCatching.LoadBytesFromFile(characterStats.portraitFile, portraitFinishedLoading);
			}
			portraitDone = true;
		}
		
		private function portraitFinishedLoading(event:Event, param:Object, filename:String):void {
			var bitmap:Bitmap = event.target.content;
			var sourceRect:Rectangle = new Rectangle(0, 0, (bitmap.width > MAX_PORTRAIT_WIDTH ? MAX_PORTRAIT_WIDTH : bitmap.width),
													(bitmap.height > MAX_PORTRAIT_HEIGHT ? MAX_PORTRAIT_HEIGHT : bitmap.height));
			var destPoint:Point = new Point((portraitData.width - sourceRect.width) / 2, (portraitData.height - sourceRect.height) / 2);
			portraitData.copyPixels(bitmap.bitmapData, sourceRect, destPoint);
		}
		
		public function get portraitBitmapData():BitmapData {
			if (!portraitDone) {
				prepareTemporaryPortraitForUse();
			}
			return portraitData;
		}
		
	}

}