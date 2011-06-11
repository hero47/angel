package angel.common {
	import flash.display.BitmapData;
	import angel.common.MessageCollector;
	import angel.common.CatalogEntry;
	import flash.geom.Point;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class PropResource extends RoomContentResource {
		
		public function PropResource() {
			
		}
		
		/* INTERFACE angel.common.ICatalogedResource */
		
		override public function prepareTemporaryVersionForUse(id:String, entry:CatalogEntry, errors:MessageCollector):void {
			super.prepareTemporaryVersionForUse(id, entry, errors);
			animationData = new SingleImageAnimationData(id, unusedPixelsAtTopOfCell);
		}
		
		override protected function expectedBitmapSize():Point {
			return new Point(Prop.WIDTH, Prop.HEIGHT);
		}
		
	}

}