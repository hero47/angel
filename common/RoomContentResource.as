package angel.common {
	import flash.display.BitmapData;
	import angel.common.CatalogEntry;
	import flash.geom.Point;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class RoomContentResource extends ImageResourceBase implements ICatalogedResource{
		public var solidness:uint = Prop.DEFAULT_SOLIDITY;
		public var unusedPixelsAtTopOfCell:int = 0;
		public var animationData:IAnimationData;
		
		public function RoomContentResource() {
			
		}
		
		/* INTERFACE angel.common.ICatalogedResource */
		
		override public function prepareTemporaryVersionForUse(id:String, entry:CatalogEntry, errors:MessageCollector):void {
			super.prepareTemporaryVersionForUse(id, entry, errors);
			
			if (entry.xml != null) {
				Util.setUintFromXml(this, "solidness", entry.xml, "solid");
				Util.setIntFromXml(this, "unusedPixelsAtTopOfCell", entry.xml, "top");
				entry.xml = null;
			}
		}
		
		public function dataFinishedLoading(bitmapData:BitmapData, param:Object = null):void {
			animationData.dataFinishedLoading(bitmapData, entry);
		}
		
		public function standardImage():BitmapData {
			return animationData.standardImage();
		}
		
	}

}